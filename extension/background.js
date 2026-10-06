const DEFAULT_EXCLUSIONS = [
  'mail.google.com', 'outlook.live.com', 'outlook.office.com', 'icloud.com',
  'chase.com', 'bankofamerica.com', 'wellsfargo.com', 'capitalone.com',
  'mychart.com', 'mychart.org', '1password.com', 'lastpass.com', 'bitwarden.com'
];

function isCapturable(url, exclusions) {
  if (!url || /^(chrome|edge|brave|about|moz-extension|chrome-extension):/i.test(url)) return false;
  try {
    const host = new URL(url).hostname.toLowerCase();
    return !exclusions.some(domain => host === domain || host.endsWith(`.${domain}`));
  } catch (_) {
    return false;
  }
}

function aiSafeUrl(raw) {
  try {
    const url = new URL(raw);
    return `${url.origin}${url.pathname}`;
  } catch (_) {
    return raw;
  }
}

async function settings() {
  const saved = await chrome.storage.local.get(['apiBase', 'token', 'excludedDomains']);
  return {
    apiBase: String(saved.apiBase || '').replace(/\/$/, ''),
    token: saved.token || '',
    exclusions: Array.isArray(saved.excludedDomains) ? saved.excludedDomains : DEFAULT_EXCLUSIONS,
  };
}

async function api(path, init = {}) {
  const { apiBase, token } = await settings();
  if (!apiBase || !token) throw new Error('Sign in to NanyNany in extension settings first.');
  const response = await fetch(`${apiBase}${path}`, {
    ...init,
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}`, ...(init.headers || {}) },
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(payload.error || `NanyNany request failed (${response.status}).`);
  return payload;
}

async function capture(windowOnly) {
  const { exclusions } = await settings();
  const query = windowOnly ? { currentWindow: true } : {};
  const openTabs = await chrome.tabs.query(query);
  const tabs = openTabs.filter(tab => isCapturable(tab.url, exclusions)).map(tab => ({
    title: tab.title || tab.url || 'Untitled tab',
    url: tab.url,
    safeUrl: aiSafeUrl(tab.url),
    windowId: tab.windowId,
    groupId: tab.groupId,
    lastAccessed: tab.lastAccessed || null,
    tabId: tab.id,
  }));
  if (!tabs.length) throw new Error('No capturable tabs found.');

  const sessionId = crypto.randomUUID();
  const analysis = await api('/analyze-session', {
    method: 'POST',
    body: JSON.stringify({ tabs: tabs.map(({ title, safeUrl, windowId, groupId, lastAccessed }) => ({ title, url: safeUrl, windowId, groupId, lastAccessed })) }),
  });

  const capturedAt = new Date().toISOString();
  const groups = (analysis.groups || []).map(group => ({
    title: group.title,
    whatYouWereDoing: group.whatYouWereDoing || '',
    status: 'open',
    tabs: (group.tabs || []).map(analyzed => {
      const full = tabs.find(tab => tab.url === analyzed.url || tab.safeUrl === analyzed.url || tab.title === analyzed.title);
      return { title: analyzed.title || full?.title || 'Untitled tab', url: full?.url || analyzed.url };
    }),
  }));
  const resource = {
    id: `session-${sessionId}`,
    type: 'session',
    title: analysis.title || groups.map(group => group.title).slice(0, 3).join(', ') || 'Tab session',
    summary: analysis.summary || `${groups.length} things in progress across ${tabs.length} tabs`,
    whyUseful: 'Keeps the context behind your open tabs so you can close them without losing your place.',
    useWhen: 'When returning to any of these projects',
    platform: 'Chrome tabs',
    topics: groups.map(group => group.title),
    technologies: [],
    savedAt: capturedAt,
    status: 'saved',
    session: { capturedAt, source: 'chrome-tabs', tabCount: tabs.length, groups },
  };
  await api(`/resources/${encodeURIComponent(resource.id)}`, { method: 'PUT', body: JSON.stringify({ data: resource }) });
  return { resource, tabIds: tabs.map(tab => tab.tabId).filter(Number.isInteger) };
}

async function listSessions() {
  const { exclusions } = await settings();
  const payload = await api('/resources');
  const resources = Array.isArray(payload.resources) ? payload.resources : [];
  const byDate = value => String(value || '');
  return resources
    .filter(resource => resource && resource.type === 'session' && resource.session)
    .sort((a, b) => byDate(b.session.capturedAt || b.savedAt).localeCompare(byDate(a.session.capturedAt || a.savedAt)))
    .map(resource => {
      const groups = (resource.session.groups || [])
        .map(group => ({
          title: group.title || 'Tabs',
          tabs: (group.tabs || [])
            .filter(tab => isCapturable(tab && tab.url, exclusions))
            .map(tab => ({ title: tab.title || tab.url || 'Untitled tab', url: tab.url })),
        }))
        .filter(group => group.tabs.length);
      const tabCount = groups.reduce((sum, group) => sum + group.tabs.length, 0);
      return {
        id: resource.id,
        title: resource.title || 'Tab session',
        summary: resource.summary || '',
        capturedAt: resource.session.capturedAt || resource.savedAt || '',
        tabCount,
        groups,
      };
    })
    .filter(session => session.tabCount > 0);
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === 'capture-session') {
    capture(Boolean(message.windowOnly)).then(result => sendResponse({ ok: true, ...result })).catch(error => sendResponse({ ok: false, error: error.message }));
    return true;
  }
  if (message?.type === 'close-captured-tabs') {
    chrome.tabs.remove((message.tabIds || []).filter(Number.isInteger)).then(() => sendResponse({ ok: true })).catch(error => sendResponse({ ok: false, error: error.message }));
    return true;
  }
  if (message?.type === 'list-sessions') {
    listSessions()
      .then(sessions => sendResponse({ ok: true, sessions }))
      .catch(error => sendResponse({ ok: false, error: error.message, needsSignIn: /sign in/i.test(error.message) }));
    return true;
  }
});
