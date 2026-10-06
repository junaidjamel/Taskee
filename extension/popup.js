let capturedTabIds = [];
const status = document.getElementById('status');
const closeBox = document.getElementById('closeBox');
const savedCount = document.getElementById('savedCount');
const sessionsStatus = document.getElementById('sessionsStatus');
const sessionsList = document.getElementById('sessionsList');

async function remember(windowOnly) {
  closeBox.hidden = true;
  status.textContent = 'Remembering…';
  document.querySelectorAll('button').forEach(button => button.disabled = true);
  const result = await chrome.runtime.sendMessage({ type: 'capture-session', windowOnly });
  document.querySelectorAll('button').forEach(button => button.disabled = false);
  if (!result?.ok) {
    status.textContent = result?.error || 'Could not save this session.';
    return;
  }
  capturedTabIds = result.tabIds || [];
  const count = result.resource?.session?.tabCount || capturedTabIds.length;
  status.textContent = '';
  savedCount.textContent = `Saved ${count} tab${count === 1 ? '' : 's'}.`;
  closeBox.hidden = false;
}

function normalizeUrl(raw) {
  try {
    const url = new URL(raw);
    return `${url.origin}${url.pathname}`;
  } catch (_) {
    return String(raw || '');
  }
}

function formatCapturedAt(iso) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
}

function sessionCard(session) {
  const card = document.createElement('div');
  card.className = 'session-card';

  const header = document.createElement('button');
  header.className = 'session-header';
  header.type = 'button';
  header.setAttribute('aria-expanded', 'false');

  const titleSpan = document.createElement('span');
  titleSpan.className = 'session-title';
  titleSpan.textContent = session.title || 'Tab session';

  const metaSpan = document.createElement('span');
  metaSpan.className = 'session-meta';
  const dateText = formatCapturedAt(session.capturedAt);
  metaSpan.textContent = `${session.tabCount} tab${session.tabCount === 1 ? '' : 's'}${dateText ? ` · ${dateText}` : ''}`;

  header.appendChild(titleSpan);
  header.appendChild(metaSpan);

  const body = document.createElement('div');
  body.className = 'session-body';
  body.hidden = true;

  (session.groups || []).forEach(group => {
    const groupWrap = document.createElement('div');
    groupWrap.className = 'session-group';
    const groupTitle = document.createElement('p');
    groupTitle.className = 'session-group-title';
    groupTitle.textContent = group.title || 'Tabs';
    groupWrap.appendChild(groupTitle);
    (group.tabs || []).forEach(tab => {
      const label = document.createElement('label');
      label.className = 'session-tab';
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.checked = true;
      checkbox.setAttribute('data-url', tab.url || '');
      const tabTitle = document.createElement('span');
      tabTitle.textContent = tab.title || tab.url || 'Untitled tab';
      tabTitle.title = tab.url || '';
      label.appendChild(checkbox);
      label.appendChild(tabTitle);
      groupWrap.appendChild(label);
    });
    body.appendChild(groupWrap);
  });

  const restoreRow = document.createElement('div');
  restoreRow.className = 'actions session-restore';
  const openHere = document.createElement('button');
  openHere.type = 'button';
  openHere.className = 'secondary';
  openHere.textContent = 'Open in this window';
  const openNew = document.createElement('button');
  openNew.type = 'button';
  openNew.className = 'primary';
  openNew.textContent = 'New window';
  openHere.addEventListener('click', () => restoreSession(card, false));
  openNew.addEventListener('click', () => restoreSession(card, true));
  restoreRow.appendChild(openHere);
  restoreRow.appendChild(openNew);
  body.appendChild(restoreRow);

  header.addEventListener('click', () => {
    const expanded = body.hidden;
    body.hidden = !expanded;
    header.setAttribute('aria-expanded', String(expanded));
  });

  card.appendChild(header);
  card.appendChild(body);
  return card;
}

async function restoreSession(card, toNewWindow) {
  const checks = card.querySelectorAll('input[type="checkbox"][data-url]');
  const wanted = [...checks].filter(check => check.checked).map(check => check.getAttribute('data-url')).filter(Boolean);
  if (!wanted.length) {
    sessionsStatus.textContent = 'Pick at least one tab to reopen.';
    return;
  }
  const openTabs = await chrome.tabs.query({});
  const openUrls = new Set(openTabs.map(tab => normalizeUrl(tab.url)));
  const toOpen = wanted.filter(url => !openUrls.has(normalizeUrl(url)));
  if (!toOpen.length) {
    sessionsStatus.textContent = 'All selected tabs are already open.';
    return;
  }
  if (toNewWindow) {
    await chrome.windows.create({ url: toOpen });
  } else {
    const win = await chrome.windows.getLastFocused({ windowTypes: ['normal'] });
    for (const url of toOpen) {
      await chrome.tabs.create({ windowId: win.id, url });
    }
  }
  sessionsStatus.textContent = `Reopened ${toOpen.length} tab${toOpen.length === 1 ? '' : 's'}.`;
}

async function loadSessions() {
  sessionsStatus.textContent = 'Loading saved sessions…';
  const result = await chrome.runtime.sendMessage({ type: 'list-sessions' });
  if (!result?.ok) {
    if (result?.needsSignIn) {
      sessionsStatus.textContent = 'Sign in to NanyNany in Settings to see saved sessions.';
    } else {
      sessionsStatus.textContent = result?.error || 'Could not load saved sessions.';
    }
    return;
  }
  const sessions = result.sessions || [];
  sessionsList.textContent = '';
  if (!sessions.length) {
    sessionsStatus.textContent = 'No saved sessions yet. Save your tabs above and they will appear here.';
    return;
  }
  sessionsStatus.textContent = '';
  sessions.forEach(session => sessionsList.appendChild(sessionCard(session)));
}

document.getElementById('all').addEventListener('click', () => remember(false));
document.getElementById('window').addEventListener('click', () => remember(true));
document.getElementById('settings').addEventListener('click', () => chrome.runtime.openOptionsPage());
document.getElementById('keepTabs').addEventListener('click', () => window.close());
document.getElementById('closeTabs').addEventListener('click', async () => {
  await chrome.runtime.sendMessage({ type: 'close-captured-tabs', tabIds: capturedTabIds });
  window.close();
});

loadSessions();
