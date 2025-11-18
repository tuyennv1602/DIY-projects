KStudio — Personal DIY & IoT blog (static scaffold)

Quick start

1) Preview locally (recommended to use an HTTP server to allow `fetch` to load JSON):

```bash
# from project root
python3 -m http.server 8000
# open http://localhost:8000 in your browser
```

2) Edit content:
- `data/projects.json` — list your projects; set `highlight: true` to include in the homepage slider.
- `assets/` — put project images here and reference them in `projects.json`.

3) Customize styles and behavior in `styles.css` and `main.js`.

Notes
- This is a minimal static scaffold. If you want a build system (e.g., Eleventy, Hugo, Next.js), tell me your preferred stack and I'll scaffold it.
