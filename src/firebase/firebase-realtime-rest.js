// src/firebase/firebase-realtime-rest.js
// Small helper to fetch JSON from Firebase Realtime Database using the REST API.
// Moved into `src/firebase` to group Firebase helpers.

import firebaseConfig from './firebase-config.js';

/**
 * Fetch data from Firebase Realtime Database using the REST endpoint.
 * @param {Object} opts
 * @param {string} opts.projectId - Firebase project id (optional; fallback to config)
 * @param {string} [opts.path='projects'] - Path in the DB (e.g. 'projects' or 'projects/p1')
 * @param {string|null} [opts.authToken=null] - Optional ID token for authenticated reads
 * @param {Object} [opts.fetchOptions] - Extra options to pass to fetch
 * @returns {Promise<any>} parsed JSON or throws on network/non-OK status
 */
export async function fetchFromRealtimeRest({ projectId, path = undefined, authToken = null, fetchOptions = {}, cacheBust = true } = {}) {
    const cfgProjectId = (firebaseConfig && firebaseConfig.projectId) ? firebaseConfig.projectId : null;
    const cfgPath = (firebaseConfig && firebaseConfig.defaultPath) ? firebaseConfig.defaultPath : 'projects';
    const cfgDatabaseURL = (firebaseConfig && firebaseConfig.databaseURL) ? firebaseConfig.databaseURL : null;
    const cfgAuthToken = (firebaseConfig && firebaseConfig.authToken) ? firebaseConfig.authToken : null;
    projectId = projectId || cfgProjectId;
    path = typeof path === 'undefined' || path === null ? cfgPath : path;
    authToken = authToken || cfgAuthToken || null;
    if (!projectId && !cfgDatabaseURL) throw new Error('projectId or databaseURL is required (pass in opts or set firebase-config.js)');
    const safePath = String(path || '').replace(/^\/+/, '');
    let base;
    if (cfgDatabaseURL) {
        base = cfgDatabaseURL.replace(/\/+$/, '');
    } else {
        base = `https://${projectId}.firebaseio.com`;
    }
    let url = `${base}/${encodeURIComponent(safePath)}.json`;
    const params = [];
    if (authToken) params.push(`auth=${encodeURIComponent(authToken)}`);
    if (cacheBust) params.push(`_=${Date.now()}`);
    if (params.length) url += (url.indexOf('?') === -1 ? '?' : '&') + params.join('&');

    const res = await fetch(url, Object.assign({ method: 'GET', headers: { 'Accept': 'application/json' } }, fetchOptions));
    if (!res.ok) {
        const txt = await res.text().catch(() => '');
        throw new Error(`Realtime REST fetch failed: ${res.status} ${res.statusText} ${txt}`);
    }
    const data = await res.json();
    return data;
}

export async function fetchProjectsAsArray(opts) {
    const raw = await fetchFromRealtimeRest(opts);
    if (!raw) return [];
    if (Array.isArray(raw)) return raw;
    return Object.keys(raw).map(k => (raw[k] && typeof raw[k] === 'object') ? { id: k, ...raw[k] } : { id: k, value: raw[k] });
}
