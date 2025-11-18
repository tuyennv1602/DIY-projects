// project.clean.js - single canonical implementation for project detail page
(function () {
    // Theme utilities: read persisted theme and apply to <html>
    const THEME_KEY = 'ks_theme';
    function applyTheme(theme) {
        const root = document.documentElement;
        if (theme === 'dark') {
            root.setAttribute('data-theme', 'dark');
        } else {
            root.removeAttribute('data-theme');
        }
    }
    function detectPreferredTheme() {
        const stored = localStorage.getItem(THEME_KEY);
        if (stored) return stored;
        const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        return prefersDark ? 'dark' : 'light';
    }
    // apply stored or preferred theme early so the page matches the home page
    applyTheme(detectPreferredTheme());

    function qs(key) { return new URLSearchParams(location.search).get(key); }

    function renderSection(id, title, html) {
        const wrapper = document.createElement('section');
        wrapper.id = id;
        wrapper.innerHTML = `<h3>${title}</h3><div class="section-body">${html}</div>`;
        return wrapper;
    }

    function setActiveNav(section) {
        document.querySelectorAll('.left-nav a').forEach(a => a.classList.toggle('active', a.dataset.section === section));
    }

    function moveIndicatorTo(section) {
        const indicator = document.querySelector('.nav-indicator');
        if (!indicator) return;
        const a = document.querySelector(`.left-nav a[data-section="${section}"]`);
        if (!a) { indicator.style.opacity = '0'; return; }
        const li = a.closest('li'); if (!li) { indicator.style.opacity = '0'; return; }
        // detect horizontal layout (nav shown at top) vs vertical sidebar
        const ul = a.closest('ul');
        const isHorizontal = ul && (window.getComputedStyle(ul).flexDirection || '').startsWith('row');
        if (isHorizontal) {
            // position by left/width inside the nav (nav is positioned)
            const targetLeft = Math.max(6, a.offsetLeft - 6);
            const targetWidth = Math.max(56, a.offsetWidth + 12);
            const targetHeight = a.offsetHeight; // match link height so text centers on indicator
            const targetTop = a.offsetTop; // align vertically with the link
            indicator.style.left = targetLeft + 'px';
            indicator.style.width = targetWidth + 'px';
            indicator.style.top = targetTop + 'px';
            indicator.style.height = targetHeight + 'px';
        } else {
            indicator.style.top = (li.offsetTop + 2) + 'px';
            indicator.style.height = Math.max(36, li.offsetHeight - 4) + 'px';
            // reset horizontal properties
            indicator.style.left = '';
            indicator.style.width = '';
        }
        indicator.style.opacity = '1';
    }

    // ---------- Web Serial helpers & modal UI ----------
    async function requestSerialPort() {
        if (!('serial' in navigator)) {
            alert('Web Serial API not supported in this browser.');
            return null;
        }
        try {
            const port = await navigator.serial.requestPort();
            return port;
        } catch (err) {
            return null;
        }
    }

    function createModal(innerHtml) {
        const modal = document.createElement('div');
        modal.className = 'ks-modal';
        modal.style.position = 'fixed';
        modal.style.left = 0; modal.style.top = 0; modal.style.right = 0; modal.style.bottom = 0;
        modal.style.display = 'flex'; modal.style.alignItems = 'center'; modal.style.justifyContent = 'center';
        modal.style.background = 'rgba(0,0,0,0.5)'; modal.style.zIndex = 9999;
        const panel = document.createElement('div');
        panel.className = 'ks-modal-panel';
        panel.style.background = 'var(--panel)';
        panel.style.color = 'var(--text)';
        panel.style.border = '1px solid var(--panel-border)';
        panel.style.padding = '18px'; panel.style.borderRadius = '10px'; panel.style.minWidth = '380px';
        panel.innerHTML = innerHtml;
        const closeBtn = document.createElement('button'); closeBtn.textContent = 'Close';
        closeBtn.className = 'btn btn-ghost'; closeBtn.style.marginTop = '12px';
        closeBtn.addEventListener('click', () => { document.body.removeChild(modal); });
        panel.appendChild(closeBtn);
        modal.appendChild(panel);
        document.body.appendChild(modal);
        return { modal, panel };
    }

    async function openSerialConsole(port) {
        if (!port) return;
        try {
            await port.open({ baudRate: 115200 });
        } catch (err) {
            alert('Failed to open port: ' + err.message);
            return;
        }
        const { modal, panel } = createModal(`<h4>Serial Console</h4><div class="ks-console" style="background:var(--muted-bg);padding:8px;border-radius:6px;height:220px;overflow:auto;font-family:monospace;font-size:12px;"></div><div style="margin-top:8px;"><input class="ks-console-input" style="width:100%;box-sizing:border-box;padding:6px;border-radius:6px;border:1px solid var(--panel-border);" placeholder="Type and press Enter"></div>`);
        const logEl = panel.querySelector('.ks-console');
        const input = panel.querySelector('.ks-console-input');

        const textDecoder = new TextDecoderStream();
        const readableStreamClosed = port.readable.pipeTo(textDecoder.writable);
        const reader = textDecoder.readable.getReader();

        let keepReading = true;
        (async function readLoop() {
            try {
                while (keepReading) {
                    const { value, done } = await reader.read();
                    if (done) break;
                    if (value) {
                        const node = document.createElement('div'); node.textContent = value; logEl.appendChild(node); logEl.scrollTop = logEl.scrollHeight;
                    }
                }
            } catch (err) {
                const node = document.createElement('div'); node.textContent = 'Read error: ' + err.message; logEl.appendChild(node);
            }
        })();

        const textEncoder = new TextEncoderStream();
        const writableStreamClosed = textEncoder.readable.pipeTo(port.writable);
        const writer = textEncoder.writable.getWriter();

        input.addEventListener('keydown', async (e) => {
            if (e.key === 'Enter') {
                const v = input.value + '\n';
                try { await writer.write(v); } catch (err) { const node = document.createElement('div'); node.textContent = 'Write error: ' + err.message; logEl.appendChild(node); }
                input.value = '';
            }
        });

        // cleanup when modal removed
        const observer = new MutationObserver(() => {
            if (!document.body.contains(modal)) {
                keepReading = false;
                try { reader.cancel(); } catch (e) { }
                try { writer.close(); } catch (e) { }
                try { port.close(); } catch (e) { }
                observer.disconnect();
            }
        });
        observer.observe(document.body, { childList: true, subtree: true });
    }

    function createFirmwareUI(container, project) {
        const versions = (project.content && project.content.firmwareVersions) || project.firmwareVersions || [];
        if (!versions.length) return;
        container.innerHTML = '';
        const wrapper = document.createElement('div'); wrapper.className = 'fw-versions';
        const ul = document.createElement('ul'); ul.className = 'fw-list';
        versions.forEach(v => {
            const li = document.createElement('li');
            const btn = document.createElement('button'); btn.className = 'fw-btn'; btn.type = 'button';
            btn.textContent = v.version + (v.notes ? ' — ' + v.notes : ''); btn.dataset.bin = v.bin || ''; btn.dataset.version = v.version || '';
            li.appendChild(btn); ul.appendChild(li);
        });
        const detail = document.createElement('div'); detail.id = 'firmwareDetail'; detail.className = 'fw-detail muted';
        detail.innerHTML = '<p>Select a firmware version to view install instructions.</p>';
        wrapper.appendChild(ul); wrapper.appendChild(detail);
        const repo = document.createElement('p'); repo.className = 'muted small';
        repo.innerHTML = 'Flashing uses <a href="https://github.com/espressif/esptool-js" target="_blank" rel="noopener">esptool-js</a>.';
        wrapper.appendChild(repo);
        container.appendChild(wrapper);

        wrapper.querySelectorAll('.fw-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const bin = btn.dataset.bin || 'firmware.bin';
                const ver = btn.dataset.version || '';
                const npxCmd = `npx esptool-js --port /dev/ttyUSB0 write_flash --chip esp32 0x1000 ${bin}`;
                detail.innerHTML = `\n          <h4>Install firmware ${ver}</h4>\n          <p>Firmware binary: <strong>${bin}</strong></p>\n          <pre><code id="cmdNpx">${npxCmd}</code></pre>\n          <div style="margin-top:10px;display:flex;gap:8px;">\n            <button id="connectBtn" class="btn">Connect</button>\n            <button id="consoleBtn" class="btn btn-ghost">Console</button>\n            <button id="copyCmd" class="btn btn-ghost">Copy command</button>\n          </div>\n        `;

                const copyBtn = document.getElementById('copyCmd');
                const connectBtn = document.getElementById('connectBtn');
                const consoleBtn = document.getElementById('consoleBtn');

                if (copyBtn) {
                    copyBtn.addEventListener('click', function () {
                        const cmd = document.getElementById('cmdNpx')?.textContent || npxCmd;
                        navigator.clipboard?.writeText(cmd).then(() => { this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy command', 1400); }).catch(() => alert('Copy failed — select and copy manually.'));
                    });
                }

                if (connectBtn) {
                    connectBtn.addEventListener('click', async () => {
                        const port = await requestSerialPort();
                        if (!port) return;
                        // show modal with port info and Start Flash
                        const { modal, panel } = createModal(`<h4>Flash ${ver}</h4><p>Selected port acquired.</p><p>Firmware: <strong>${bin}</strong></p><pre style="background:var(--muted-bg);padding:8px;border-radius:6px;">${npxCmd}</pre><div style=\"margin-top:8px;display:flex;gap:8px;\"><button id=\"startFlash\" class=\"btn\">Start Flash</button><button id=\"copyCmdModal\" class=\"btn btn-ghost\">Copy command</button></div>`);
                        const startBtn = panel.querySelector('#startFlash');
                        const copyModalBtn = panel.querySelector('#copyCmdModal');
                        if (copyModalBtn) copyModalBtn.addEventListener('click', () => { navigator.clipboard?.writeText(npxCmd).then(() => { copyModalBtn.textContent = 'Copied!'; setTimeout(() => copyModalBtn.textContent = 'Copy command', 1400); }); });
                        if (!startBtn) return;
                        startBtn.addEventListener('click', () => {
                            // Simulate flashing progress since real esptool requires native execution
                            startBtn.disabled = true; startBtn.textContent = 'Flashing...';
                            const prog = document.createElement('div'); prog.style.marginTop = '10px'; prog.textContent = '0%'; panel.appendChild(prog);
                            let p = 0; const t = setInterval(() => { p += Math.floor(Math.random() * 12) + 5; if (p >= 100) { p = 100; prog.textContent = 'Done — flash complete'; startBtn.textContent = 'Done'; clearInterval(t); } else { prog.textContent = p + '%'; } }, 500);
                        });
                    });
                }

                if (consoleBtn) {
                    consoleBtn.addEventListener('click', async () => {
                        const port = await requestSerialPort();
                        if (!port) return;
                        openSerialConsole(port);
                    });
                }
            });
        });
    }

    async function boot() {
        const id = qs('id');
        const container = document.getElementById('projectSections');
        if (!id) { if (container) container.innerText = 'No project id provided.'; return; }
        let projects = [];
        try { const res = await fetch('./data/projects.json'); projects = await res.json(); } catch (e) { if (container) container.innerText = 'Failed to load projects.json'; return; }
        const project = projects.find(p => p.id === id); if (!project) { if (container) container.innerText = 'Project not found'; return; }

        // hero
        const titleEl = document.getElementById('projectTitle'); if (titleEl) titleEl.textContent = project.title || '';
        const img = document.getElementById('projectImage'); if (img && project.image) img.src = project.image; if (img) img.alt = project.title || '';
        const sum = document.getElementById('projectSummary'); if (sum) sum.innerHTML = project.summary || '';
        const tagsEl = document.getElementById('projectTags'); if (tagsEl) { tagsEl.innerHTML = ''; (project.tags || []).forEach(t => { const s = document.createElement('span'); s.className = 'tag'; s.textContent = t; tagsEl.appendChild(s); }); }

        // sections
        const content = project.content || {};
        const order = ['intro', 'wiring', 'firmware', 'accessory', 'qa'];
        const titles = { intro: 'Introduction', wiring: 'Wiring Diagram', firmware: 'Install firmware', accessory: 'Accessory', qa: 'Q & A' };
        if (container) container.innerHTML = '';
        order.forEach(k => { const html = content[k] || `<p>${project.summary || 'No content.'}</p>`; if (container) container.appendChild(renderSection(k, titles[k], html)); });

        // add firmware UI inside firmware section
        const fwSection = document.getElementById('firmware');
        if (fwSection) {
            const inner = fwSection.querySelector('.section-body') || fwSection;
            createFirmwareUI(inner, project);
        }

        // wiring diagram image (if provided)
        const wiringSection = document.getElementById('wiring');
        if (wiringSection && project.content && project.content.wiringImage) {
            const inner = wiringSection.querySelector('.section-body') || wiringSection;
            const img = document.createElement('img');
            img.src = project.content.wiringImage;
            img.alt = project.title + ' wiring diagram';
            img.className = 'wiring-diagram';
            inner.appendChild(img);
        }

        // accessories list (render as links)
        const accSection = document.getElementById('accessory');
        if (accSection && project.content && Array.isArray(project.content.accessories) && project.content.accessories.length) {
            const inner = accSection.querySelector('.section-body') || accSection;
            const list = document.createElement('ul'); list.className = 'accessory-list';
            project.content.accessories.forEach(a => {
                const li = document.createElement('li');
                const aEl = document.createElement('a'); aEl.href = a.url || '#'; aEl.target = '_blank'; aEl.rel = 'noopener';
                aEl.textContent = a.name || a.url || 'Accessory';
                li.appendChild(aEl);
                list.appendChild(li);
            });
            inner.appendChild(list);
        }

        // Show only the selected section (tab-like behavior)
        function showOnlySection(section) {
            const all = document.querySelectorAll('#projectSections > section');
            all.forEach(s => {
                if (s.id === section) {
                    s.style.display = '';
                    s.removeAttribute('aria-hidden');
                } else {
                    s.style.display = 'none';
                    s.setAttribute('aria-hidden', 'true');
                }
            });
        }

        // nav: show only the clicked section instead of scrolling
        document.querySelectorAll('.left-nav a').forEach(a => a.addEventListener('click', (e) => {
            e.preventDefault();
            const section = a.dataset.section;
            setActiveNav(section);
            moveIndicatorTo(section);
            showOnlySection(section);
        }));

        // default: show first tab only
        setActiveNav('intro');
        requestAnimationFrame(() => { moveIndicatorTo('intro'); showOnlySection('intro'); });
        const headerOffset = document.querySelector('.site-header')?.offsetHeight || 84;
        const observer = new IntersectionObserver(entries => { entries.forEach(en => { if (en.isIntersecting) { setActiveNav(en.target.id); moveIndicatorTo(en.target.id); } }); }, { root: null, rootMargin: `-${headerOffset + 10}px 0px -40% 0px`, threshold: 0 });
        order.forEach(k => { const el = document.getElementById(k); if (el) observer.observe(el); });
        window.addEventListener('resize', () => { const active = document.querySelector('.left-nav a.active')?.dataset.section || 'intro'; moveIndicatorTo(active); });
    }

    boot();
})();
