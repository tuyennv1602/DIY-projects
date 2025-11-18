// main.js - simple data-driven slider and project list
const projectsUrl = './data/projects.json';

// Theme utilities: persist selection in localStorage and apply to <html> as data-theme
const THEME_KEY = 'ks_theme';
function applyTheme(theme) {
    const root = document.documentElement;
    if (theme === 'dark') {
        root.setAttribute('data-theme', 'dark');
        const btn = document.getElementById('themeToggle'); if (btn) btn.textContent = '☀️';
    } else {
        root.removeAttribute('data-theme');
        const btn = document.getElementById('themeToggle'); if (btn) btn.textContent = '🌙';
    }
}
function detectPreferredTheme() {
    const stored = localStorage.getItem(THEME_KEY);
    if (stored) return stored;
    const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    return prefersDark ? 'dark' : 'light';
}
function setupThemeToggle() {
    const toggle = document.getElementById('themeToggle');
    if (!toggle) return;
    toggle.addEventListener('click', () => {
        const current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
        const next = current === 'dark' ? 'light' : 'dark';
        applyTheme(next);
        localStorage.setItem(THEME_KEY, next);
    });
}

async function loadProjects() {
    const hostname = window.location.hostname;

    // Allow manual override to skip proxy
    const skipProxyFlag =
        window.KS_SKIP_PROXY === true ||
        !!document.querySelector('meta[name="ks-skip-proxy"][content="1"]');

    // ---------------------------------------------------------------------
    // 1) Try Cloudflare Worker proxy (ONLY if user has custom Worker deployed)
    // ---------------------------------------------------------------------
    if (!skipProxyFlag) {
        try {
            // Heuristic: Only call /api/projects if the URL actually exists
            // (Cloudflare Pages without Worker => this will 404 instantly)
            const test = await fetch('/api/projects', { method: 'HEAD' });
            if (test.ok) {
                const res = await fetch('/api/projects');
                if (res.ok) {
                    const json = await res.json();

                    if (Array.isArray(json)) return json;

                    if (json && typeof json === 'object') {
                        return Object.keys(json).map(k =>
                            (typeof json[k] === 'object')
                                ? { id: k, ...json[k] }
                                : { id: k, value: json[k] }
                        );
                    }
                }
            }
        } catch (e) {
            console.warn('Worker proxy check failed:', e);
        }
    }

    // ---------------------------------------------------------------------
    // 2) Try Firebase Realtime Database (REST)
    // ---------------------------------------------------------------------
    try {
        const cfg = await import('/src/firebase/firebase-config.js');
        const cfgDefault = cfg?.default;

        if (cfgDefault?.projectId && cfgDefault.projectId !== 'YOUR_PROJECT_ID') {
            try {
                const mod = await import('/src/firebase/firebase-realtime-rest.js');

                const opts = {};
                if (cfgDefault.authToken) opts.authToken = cfgDefault.authToken;

                const arr = await mod.fetchProjectsAsArray(opts);

                if (Array.isArray(arr) && arr.length > 0) return arr;

                // Even if empty, still return array
                if (Array.isArray(arr)) return arr;
            } catch (err) {
                console.warn('Firebase realtime fetch failed:', err);
            }
        }
    } catch (err) {
        console.warn('Could not load firebase-config.js', err);
    }

    // ---------------------------------------------------------------------
    // 3) Fallback - local JSON
    // ---------------------------------------------------------------------
    const res = await fetch(projectsUrl);
    if (!res.ok) {
        throw new Error('Failed to load projects.json');
    }
    return res.json();
}

function createSlide(p) {
    const el = document.createElement('div');
    el.className = 'slide';
    el.innerHTML = `
    <div class="meta">
      <h3>${escapeHtml(p.title)}</h3>
      <p>${escapeHtml(p.summary)}</p>
      <p style="margin-top:10px;color:rgba(255,255,255,0.8)">Tags: ${p.tags.join(', ')}</p>
    </div>
    <img src="${p.image}" alt="${escapeHtml(p.title)}" />
  `;
    return el;
}

function createCard(p) {
    const el = document.createElement('article');
    el.className = 'card';
    el.innerHTML = `
    <div class="thumb" style="background-image:url(${p.image})"></div>
    <h4>${escapeHtml(p.title)}</h4>
    <p>${escapeHtml(p.summary)}</p>
        <div class="meta">
            <span>${p.year || ''}</span>
            <a href="project.html?id=${encodeURIComponent(p.id)}">Read →</a>
        </div>
  `;
    return el;
}

function escapeHtml(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Slider logic
function initSlider(container) {
    const slidesEl = container.querySelector('.slides');
    const prev = container.querySelector('.prev');
    const next = container.querySelector('.next');
    let index = 0;
    function show(i) {
        index = (i + slidesEl.children.length) % slidesEl.children.length;
        slidesEl.style.transform = `translateX(-${index * 100}%)`;
    }
    prev.addEventListener('click', () => show(index - 1));
    next.addEventListener('click', () => show(index + 1));
    let timer = setInterval(() => show(index + 1), 4000);
    container.addEventListener('mouseenter', () => clearInterval(timer));
    container.addEventListener('mouseleave', () => timer = setInterval(() => show(index + 1), 4000));
}

// Boot
(async function () {
    // initialize theme early
    applyTheme(detectPreferredTheme());
    setupThemeToggle();

    try {
        const data = await loadProjects();
        const highlights = data.filter(p => p.highlight);

        // build slides
        const slidesContainer = document.getElementById('slides');
        if (highlights.length === 0) {
            slidesContainer.innerHTML = '<div class="slide"><div class="meta"><h3>No highlights yet</h3><p>Mark projects as highlights in data/projects.json</p></div></div>';
        } else {
            highlights.forEach(h => slidesContainer.appendChild(createSlide(h)));
        }

        initSlider(document.querySelector('.slider'));

        // build project grid
        const grid = document.getElementById('projectGrid');
        data.forEach(p => grid.appendChild(createCard(p)));
    } catch (err) {
        console.error(err);
        document.getElementById('projectGrid').innerText = 'Failed to load projects data.';
    }
})();
