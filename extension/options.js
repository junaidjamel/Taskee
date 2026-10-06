const DEFAULT_EXCLUSIONS = ['mail.google.com','outlook.live.com','outlook.office.com','icloud.com','chase.com','bankofamerica.com','wellsfargo.com','capitalone.com','mychart.com','mychart.org','1password.com','lastpass.com','bitwarden.com'];

const authForm = document.getElementById('authForm');
const connectedBox = document.getElementById('connectedBox');
const connectedEmail = document.getElementById('connectedEmail');
const authStatus = document.getElementById('authStatus');

function showConnected(email) {
  authForm.hidden = true;
  connectedEmail.textContent = email || '';
  connectedBox.hidden = false;
  authStatus.textContent = '';
}

function showForm() {
  authForm.hidden = false;
  connectedBox.hidden = true;
  connectedEmail.textContent = '';
}

async function load() {
  const saved = await chrome.storage.local.get(['apiBase','email','token','excludedDomains']);
  document.getElementById('apiBase').value = saved.apiBase || '';
  document.getElementById('email').value = saved.email || '';
  document.getElementById('excluded').value = (saved.excludedDomains || DEFAULT_EXCLUSIONS).join('\n');
  if (saved.token) showConnected(saved.email); else showForm();
}

function readCredentials() {
  const apiBase = document.getElementById('apiBase').value.trim().replace(/\/$/, '');
  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  if (!apiBase) throw new Error('Enter the server address first.');
  if (!email.includes('@')) throw new Error('Enter a valid email address.');
  if (password.length < 8) throw new Error('Use a password with at least 8 characters.');
  return { apiBase, email, password };
}

async function postAuth(endpoint, creds) {
  const response = await fetch(`${creds.apiBase}${endpoint}`, { method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify({email: creds.email, password: creds.password}) });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || !payload.token) throw new Error(payload.error || 'That did not work. Try again.');
  return payload;
}

async function connect(endpoint, workingText) {
  authStatus.textContent = workingText;
  try {
    const creds = readCredentials();
    const payload = await postAuth(endpoint, creds);
    await chrome.storage.local.set({ apiBase: creds.apiBase, email: creds.email, token: payload.token });
    document.getElementById('password').value = '';
    showConnected(creds.email);
  } catch (error) { authStatus.textContent = error.message; }
}

document.getElementById('login').addEventListener('click', () => connect('/auth/login', 'Signing in…'));
document.getElementById('register').addEventListener('click', () => connect('/auth/register', 'Creating your account…'));

document.getElementById('logout').addEventListener('click', async () => {
  try {
    const saved = await chrome.storage.local.get(['apiBase','token']);
    if (saved.apiBase && saved.token) {
      await fetch(`${saved.apiBase}/auth/logout`, { method:'POST', headers:{ authorization: `Bearer ${saved.token}` } });
    }
  } catch (_) { /* best effort: still clear local state */ }
  await chrome.storage.local.remove(['token','email']);
  document.getElementById('password').value = '';
  showForm();
  authStatus.textContent = 'Signed out.';
});

document.getElementById('save').addEventListener('click', async () => {
  const excludedDomains = document.getElementById('excluded').value.split(/\r?\n|,/).map(v => v.trim().toLowerCase()).filter(Boolean);
  await chrome.storage.local.set({ excludedDomains });
  document.getElementById('saveStatus').textContent = 'Saved.';
});

load();
