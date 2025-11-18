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
export async function fetchFromRealtimeRest({
    projectId,
    path,
    authToken = null,
    fetchOptions = {},
    cacheBust = true
} = {}) {

    // Load defaults from firebase-config.js
    const cfgProjectId = firebaseConfig?.projectId || null;
    const cfgDatabaseURL = firebaseConfig?.databaseURL || null;
    const cfgAuthToken = firebaseConfig?.authToken || null;

    projectId = projectId || cfgProjectId;
    authToken = authToken || cfgAuthToken || null;

    if (!path || path === "/") path = "";   // root path
    path = String(path).replace(/^\/+/, "").replace(/\/+$/, "");

    if (!cfgDatabaseURL && !projectId) {
        throw new Error("projectId or databaseURL is required");
    }

    // Build base URL
    const base = cfgDatabaseURL
        ? cfgDatabaseURL.replace(/\/+$/, "")
        : `https://${projectId}.firebaseio.com`;

    // Fix quan trọng: encode từng segment chứ không encode cả path
    const encodedPath = path
        ? path.split("/").map(s => encodeURIComponent(s)).join("/")
        : "";

    // Build final URL
    let url = `${base}/${encodedPath}.json`;

    const params = [];
    if (authToken) params.push(`auth=${encodeURIComponent(authToken)}`);
    if (cacheBust) params.push(`_=${Date.now()}`);
    if (params.length > 0) {
        url += (url.includes("?") ? "&" : "?") + params.join("&");
    }

    // Execute request
    const res = await fetch(
        url,
        Object.assign(
            { method: "GET", headers: { Accept: "application/json" } },
            fetchOptions
        )
    );

    if (!res.ok) {
        const txt = await res.text().catch(() => "");
        throw new Error(
            `Realtime REST fetch failed: ${res.status} ${res.statusText} ${txt}`
        );
    }

    return res.json();
}


export async function fetchProjectsAsArray(opts) {
    const raw = await fetchFromRealtimeRest(opts);
    if (!raw) return [];
    if (Array.isArray(raw)) return raw;
    return Object.keys(raw).map(k => (raw[k] && typeof raw[k] === 'object') ? { id: k, ...raw[k] } : { id: k, value: raw[k] });
}
