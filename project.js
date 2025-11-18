// project.js - single clean implementation for project detail page
(function () {
    function qs(key) { return new URLSearchParams(location.search).get(key); }

    function renderSection(id, title, html) {
        const wrapper = document.createElement('section');
        wrapper.id = id;
        wrapper.innerHTML = '<h3>' + title + '</h3><div class="section-body">' + html + '</div>';
        return wrapper;
    }

    function setActiveNav(section) {
        document.querySelectorAll('.left-nav a').forEach(a => a.classList.toggle('active', a.dataset.section === section));
    }

    function moveIndicatorTo(section) {
        const indicator = document.querySelector('.nav-indicator');
        if (!indicator) return;
        const a = document.querySelector('.left-nav a[data-section="' + section + '"]');
        if (!a) { indicator.style.opacity = '0'; return; }
        const li = a.closest('li'); if (!li) { indicator.style.opacity = '0'; return; }
        indicator.style.top = (li.offsetTop + 2) + 'px';
        indicator.style.height = Math.max(36, li.offsetHeight - 4) + 'px';
        indicator.style.opacity = '1';
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
            btn.textContent = (v.version || '') + (v.notes ? ' — ' + v.notes : '');
            btn.dataset.bin = v.bin || '';
            btn.dataset.version = v.version || '';
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
            btn.addEventListener('click', function () {
                const bin = this.dataset.bin || 'firmware.bin';
                const ver = this.dataset.version || '';
                const npxCmd = 'npx esptool-js --port /dev/ttyUSB0 write_flash --chip esp32 0x1000 ' + bin;
                detail.innerHTML = '<h4>Install firmware ' + ver + '</h4>' +
                    '<p>Firmware binary: <strong>' + bin + '</strong></p>' +
                    '<pre><code id="cmdNpx">' + npxCmd + '</code></pre>' +
                    '<button id="copyCmd" class="btn btn-ghost">Copy command</button>';
                const copyBtn = detail.querySelector('#copyCmd');
                if (copyBtn) {
                    copyBtn.addEventListener('click', function () {
                        const cmdEl = detail.querySelector('#cmdNpx');
                        const cmd = cmdEl ? cmdEl.textContent : npxCmd;
                        navigator.clipboard && navigator.clipboard.writeText(cmd).then(() => {
                            this.textContent = 'Copied!';
                            setTimeout(() => { this.textContent = 'Copy command'; }, 1400);
                        }).catch(() => { alert('Copy failed — select and copy manually.'); });
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
        order.forEach(key => { const html = content[key] || '<p>' + (project.summary || 'No content.') + '</p>'; if (container) container.appendChild(renderSection(key, titles[key], html)); });

        // add firmware UI inside firmware section
        const fwSection = document.getElementById('firmware'); if (fwSection) { const inner = fwSection.querySelector('.section-body') || fwSection; createFirmwareUI(inner, project); }

        // Show only the selected section (tab-like behavior)
        function showOnlySection(section) {
            const all = document.querySelectorAll('#projectSections > section');
            all.forEach(s => { if (s.id === section) { s.style.display = ''; s.removeAttribute('aria-hidden'); } else { s.style.display = 'none'; s.setAttribute('aria-hidden', 'true'); } });
        }

        // nav: show only the clicked section
        document.querySelectorAll('.left-nav a').forEach(a => a.addEventListener('click', (e) => { e.preventDefault(); const section = a.dataset.section; setActiveNav(section); moveIndicatorTo(section); showOnlySection(section); }));

        // default: show first tab only
        setActiveNav('intro'); requestAnimationFrame(() => { moveIndicatorTo('intro'); showOnlySection('intro'); });

        const headerOffset = document.querySelector('.site-header')?.offsetHeight || 84;
        const observer = new IntersectionObserver(entries => { entries.forEach(en => { if (en.isIntersecting) { setActiveNav(en.target.id); moveIndicatorTo(en.target.id); } }); }, { root: null, rootMargin: '-' + (headerOffset + 10) + 'px 0px -40% 0px', threshold: 0 });
        order.forEach(k => { const el = document.getElementById(k); if (el) observer.observe(el); });
        window.addEventListener('resize', () => { const active = document.querySelector('.left-nav a.active')?.dataset.section || 'intro'; moveIndicatorTo(active); });
    }

    boot();
})();
