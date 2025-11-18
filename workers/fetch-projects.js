/**
 * Cloudflare Worker: proxy requests to Firebase Realtime Database and ensure CORS headers.
 *
 * Deployment notes:
 * - Set an environment variable `FIREBASE_DB_URL` to your Realtime Database base URL,
 *   for example: https://kstudio-83ca5-default-rtdb.firebaseio.com
 * - This Worker responds to GET /api/projects (and GET /api/projects/:id) and OPTIONS preflight.
 * - It forwards responses (including 304) and always sets Access-Control-Allow-Origin.
 */

addEventListener('fetch', event => {
    event.respondWith(handle(event.request));
});

async function handle(request) {
    const url = new URL(request.url);
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
        return new Response(null, {
            status: 204,
            headers: corsHeaders(request),
        });
    }

    // Only proxy under /api/projects
    if (url.pathname === '/api/projects' || url.pathname.startsWith('/api/projects/')) {
        // Build firebase URL
        const envDb = (typeof FIREBASE_DB_URL !== 'undefined') ? FIREBASE_DB_URL : null;
        const defaultDb = 'https://kstudio-83ca5-default-rtdb.firebaseio.com';
        const base = envDb || defaultDb;

        // map /api/projects -> /projects.json
        const remainder = url.pathname.replace('/api/', ''); // e.g. projects or projects/<id>
        const firebasePath = remainder.replace(/^(projects)(?:\/)?(.*)$/, 'projects$2');
        // Build final firebase URL
        let target = `${base}/${encodeURIComponent(firebasePath)}.json`;
        // forward client query params (except internal cache-bust)
        const params = new URLSearchParams(url.search);
        if (params.toString()) target += `?${params.toString()}`;

        // Fetch from Firebase
        const resp = await fetch(target, { method: 'GET', headers: { 'Accept': 'application/json' } });

        // copy body (may be empty for 304) and ensure CORS headers
        const headers = new Headers(resp.headers);
        const origin = request.headers.get('Origin') || '*';
        headers.set('Access-Control-Allow-Origin', origin === 'null' ? '*' : origin);
        headers.set('Access-Control-Allow-Methods', 'GET,OPTIONS');
        headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        headers.set('Vary', 'Origin');

        const body = resp.status === 304 ? null : await resp.arrayBuffer();
        return new Response(body, { status: resp.status, headers });
    }

    return new Response('Not found', { status: 404 });
}

function corsHeaders(request) {
    const origin = request.headers.get('Origin') || '*';
    return {
        'Access-Control-Allow-Origin': origin === 'null' ? '*' : origin,
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
    };
}
