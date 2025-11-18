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
    // Try Firebase Realtime REST (if firebase-config.js is filled)
    try {
        const cfg = await import('./src/firebase/firebase-config.js');
        const cfgDefault = cfg && cfg.default;
        if (cfgDefault && cfgDefault.projectId && cfgDefault.projectId !== 'YOUR_PROJECT_ID') {
            try {
                const mod = await import('./src/firebase/firebase-realtime-rest.js');
                // pass authToken from config if present
                const opts = {};
                if (cfgDefault && cfgDefault.authToken) opts.authToken = cfgDefault.authToken;
                const arr = await mod.fetchProjectsAsArray(opts);
                if (arr && arr.length) return arr;
            } catch (err) {
                console.warn('Firebase realtime fetch failed, falling back to local data:', err);
            }
        }
    } catch (err) {
        // ignore missing config
    }

    // Fallback to local JSON file
    const res = await fetch(projectsUrl);
    if (!res.ok) throw new Error('Failed to load projects.json');
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
