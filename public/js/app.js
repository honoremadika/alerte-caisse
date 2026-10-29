// Alerte Caisse — web app (/caisse pour l'ordinateur, /manager pour le téléphone).
// Mêmes comptes et même base que l'app Windows/Android.

/* ======================= Textes FR / EN ======================= */
const T = {
  fr: {
    appCaisse: 'Alerte Caisse · Poste', appManager: 'Alerte Caisse · Manager', loading: 'Chargement…',
    loginId: 'Identifiant', loginIdPh: 'ex. meya', password: 'Mot de passe', show: 'Voir', hide: 'Masquer', signIn: 'Se connecter', signOut: 'Se déconnecter',
    errFill: 'Remplissez l’identifiant et le mot de passe.', errCred: 'Identifiant ou mot de passe incorrect.',
    errLoginFmt: 'Identifiant invalide : lettres, chiffres, point ou tiret, sans espace.', errNet: 'Pas de connexion internet. Réessayez.',
    errMany: 'Trop de tentatives. Patientez quelques minutes.', errGeneric: 'Une erreur est survenue. Réessayez.',
    errRelogin: 'Reconnectez-vous puis réessayez.', errDenied: 'Action refusée par le serveur (droits du compte).',
    noProfile: 'Ce compte n’a pas encore de profil (caissier ou manager). Demandez à l’administrateur de le configurer.',
    wrongCaisse: 'Ce compte est un compte manager. Ouvrez l’app Manager sur votre téléphone.',
    wrongManager: 'Ce compte est un compte caissier. Ouvrez l’app Caisse sur l’ordinateur de la caisse.',
    openOther: 'Ouvrir l’autre app',
    changePw: 'Changer le mot de passe', currentPw: 'Mot de passe actuel', newPw: 'Nouveau mot de passe', confirmPw: 'Confirmer le nouveau mot de passe',
    pwRule: 'Au moins 6 caractères.', pwShort: 'Le nouveau mot de passe doit contenir au moins 6 caractères.', pwMismatch: 'Les deux nouveaux mots de passe ne sont pas identiques.',
    pwWrong: 'Mot de passe actuel incorrect.', pwChanged: 'Mot de passe modifié.', cancel: 'Annuler', save: 'Enregistrer',
    register: 'Caisse {n}', managersOnDuty: 'Managers en service', noneOnDuty: 'Personne pour le moment',
    noMgr: 'Aucun manager n’est en service dans ce magasin : l’alerte ne fera sonner personne.',
    whatProblem: 'Quel est le problème ?', details: 'Précision (facultatif)', detailsPh: 'Ex. : article 3, 12 au lieu de 2',
    send: 'ENVOYER L’ALERTE', sending: 'Envoi…', sent: 'Alerte envoyée', sendFail: 'Échec de l’envoi. Vérifiez la connexion internet.',
    hint: 'Raccourcis : touches <kbd>1</kbd> à <kbd>9</kbd> pour choisir, <kbd>Ctrl</kbd> + <kbd>Entrée</kbd> pour envoyer.',
    myAlerts: 'Mes alertes en cours', noMine: 'Aucune alerte en cours.', waiting: 'En attente d’un manager…', coming: '{n} arrive',
    flashSub: 'Caisse {r} · {t}', noStore: 'Ce compte caissier n’a pas de magasin. Demandez à l’administrateur.',
    installApp: 'Installer l’app sur cet appareil', installed: 'Application installée. Ouvrez-la depuis l’écran d’accueil.', iosHint: 'Pour l’installer sur iPhone : touchez Partager, puis « Sur l’écran d’accueil ».', androidMenuHint: 'Pour l’installer : menu ⋮ de Chrome → « Installer l’application » (ou « Ajouter à l’écran d’accueil »).', apkLink: 'Ou télécharger le fichier Android (.apk)', winLink: 'Ou télécharger l’app Windows (.zip)', setApp: 'Application',
    postTitle: 'Poste de caisse', postSub: 'Choisissez le magasin et le numéro de caisse de cet ordinateur. C’est gardé sur cet appareil.', store: 'Magasin', registerNo: 'Numéro de caisse', editPost: 'Modifier le poste', needPost: 'Choisissez le magasin et entrez le numéro de caisse.',
    tabLive: 'Alertes', tabHist: 'Historique', tabSet: 'Réglages',
    onDuty: 'En service · {s}', onDutySub: 'Fin automatique à {t}', offDuty: 'Hors service', offInfo: 'Prenez votre service pour recevoir les alertes.',
    startAt: 'Prendre mon service · {s}', lastHere: 'Dernier magasin utilisé sur cet appareil', otherStore: 'Autre magasin',
    chooseStore: 'Dans quel magasin êtes-vous ?', pickStore: '— Choisir le magasin —', goHere: 'Prendre mon service ici', endDuty: 'Terminer',
    dutyElsewhere: 'Service pris sur un autre appareil. Reprenez-le ici pour que cet appareil sonne.', takeHere: 'Prendre le service sur cet appareil',
    gateT: 'Activez la sonnerie', gateS: 'Le navigateur exige un toucher avant de jouer un son. Gardez ensuite cette page ouverte, écran allumé.', gateB: 'Activer la sonnerie',
    allGood: 'Tout va bien', noAlert: 'Aucune alerte dans votre magasin.',
    till: 'Caisse {n}', ago: 'il y a {m} min', now: 'à l’instant', cashier: 'Caissier : {n}',
    imComing: 'J’arrive', solved: 'Problème résolu', you: 'Vous avez pris en charge', took: '{n} arrive · sonnerie arrêtée',
    already: '{n} a déjà répondu', alarmK: 'Alerte caisse', relance: 'Relance', snooze: 'Pas disponible (1 min)',
    alerts: 'Alertes', avgReaction: 'Réaction moyenne', reaction: 'réaction {d}', solvedIn: 'résolu en {d}', noHist: 'Aucune alerte pour le moment.',
    st: { open: 'En attente', taken: 'En cours', resolved: 'Résolue', cancelled: 'Annulée' },
    setAccount: 'Compte', setRing: 'Sonnerie', setLang: 'Langue', volume: 'Volume', play: 'Écouter',
    importSound: 'Importer un son', customOnly: 'Le son importé reste sur cet appareil.', customNone: 'Importez un fichier audio (MP3, M4A, WAV).',
    customLoaded: 'Fichier : {f}', tooBig: 'Fichier trop lourd (5 Mo maximum).', badAudio: 'Ce fichier audio n’a pas pu être lu.',
    wake: 'L’écran reste allumé tant que la page est ouverte et que vous êtes en service.',
    tones: { sirene: 'Sirène', telephone: 'Téléphone', reveil: 'Réveil', urgence: 'Urgence', carillon: 'Carillon', douce: 'Douce', perso: 'Mon son' },
    toneSub: { sirene: 'Deux tons alternés, très audible', telephone: 'Sonnerie de téléphone classique', reveil: 'Bips rapides', urgence: 'Son qui monte, insistant', carillon: 'Quatre notes, plus doux', douce: 'Deux notes calmes' },
  },
  en: {
    appCaisse: 'Till Alert · Station', appManager: 'Till Alert · Manager', loading: 'Loading…',
    loginId: 'User ID', loginIdPh: 'e.g. meya', password: 'Password', show: 'Show', hide: 'Hide', signIn: 'Sign in', signOut: 'Sign out',
    errFill: 'Enter your user ID and password.', errCred: 'Wrong user ID or password.',
    errLoginFmt: 'Invalid ID: letters, digits, dot or dash, no spaces.', errNet: 'No internet connection. Try again.',
    errMany: 'Too many attempts. Wait a few minutes.', errGeneric: 'Something went wrong. Try again.',
    errRelogin: 'Sign in again, then retry.', errDenied: 'Action refused by the server (account rights).',
    noProfile: 'This account has no profile yet (cashier or manager). Ask the administrator to set it up.',
    wrongCaisse: 'This is a manager account. Open the Manager app on your phone.',
    wrongManager: 'This is a cashier account. Open the Till app on the till computer.',
    openOther: 'Open the other app',
    changePw: 'Change password', currentPw: 'Current password', newPw: 'New password', confirmPw: 'Confirm new password',
    pwRule: 'At least 6 characters.', pwShort: 'The new password must have at least 6 characters.', pwMismatch: 'The two new passwords do not match.',
    pwWrong: 'Current password is wrong.', pwChanged: 'Password changed.', cancel: 'Cancel', save: 'Save',
    register: 'Till {n}', managersOnDuty: 'Managers on duty', noneOnDuty: 'Nobody right now',
    noMgr: 'No manager is on duty in this store: the alert will not ring anyone.',
    whatProblem: 'What’s the problem?', details: 'Details (optional)', detailsPh: 'E.g. item 3, 12 instead of 2',
    send: 'SEND ALERT', sending: 'Sending…', sent: 'Alert sent', sendFail: 'Sending failed. Check the internet connection.',
    hint: 'Shortcuts: keys <kbd>1</kbd> to <kbd>9</kbd> to pick, <kbd>Ctrl</kbd> + <kbd>Enter</kbd> to send.',
    myAlerts: 'My open alerts', noMine: 'No open alerts.', waiting: 'Waiting for a manager…', coming: '{n} is on the way',
    flashSub: 'Till {r} · {t}', noStore: 'This cashier account has no store. Ask the administrator.',
    installApp: 'Install the app on this device', installed: 'App installed. Open it from the home screen.', iosHint: 'To install on iPhone: tap Share, then “Add to Home Screen”.', androidMenuHint: 'To install: Chrome menu ⋮ → “Install app” (or “Add to Home screen”).', apkLink: 'Or download the Android file (.apk)', winLink: 'Or download the Windows app (.zip)', setApp: 'App',
    postTitle: 'Till station', postSub: 'Pick the store and till number of this computer. It is kept on this device.', store: 'Store', registerNo: 'Till number', editPost: 'Edit the station', needPost: 'Pick the store and enter the till number.',
    tabLive: 'Alerts', tabHist: 'History', tabSet: 'Settings',
    onDuty: 'On duty · {s}', onDutySub: 'Ends automatically at {t}', offDuty: 'Off duty', offInfo: 'Go on duty to receive alerts.',
    startAt: 'Go on duty · {s}', lastHere: 'Last store used on this device', otherStore: 'Another store',
    chooseStore: 'Which store are you in?', pickStore: '— Pick the store —', goHere: 'Go on duty here', endDuty: 'End',
    dutyElsewhere: 'Duty was taken on another device. Take it here so this device rings.', takeHere: 'Go on duty on this device',
    gateT: 'Turn the ringing on', gateS: 'The browser needs a tap before playing sound. Then keep this page open with the screen on.', gateB: 'Turn ringing on',
    allGood: 'All good', noAlert: 'No alerts in your store.',
    till: 'Till {n}', ago: '{m} min ago', now: 'just now', cashier: 'Cashier: {n}',
    imComing: 'I’m coming', solved: 'Problem solved', you: 'You are handling this', took: '{n} is on the way · ringing stopped',
    already: '{n} already answered', alarmK: 'Till alert', relance: 'Reminder', snooze: 'Not available (1 min)',
    alerts: 'Alerts', avgReaction: 'Average response', reaction: 'response {d}', solvedIn: 'solved in {d}', noHist: 'No alerts yet.',
    st: { open: 'Waiting', taken: 'In progress', resolved: 'Solved', cancelled: 'Cancelled' },
    setAccount: 'Account', setRing: 'Ringtone', setLang: 'Language', volume: 'Volume', play: 'Play',
    importSound: 'Import a sound', customOnly: 'The imported sound stays on this device.', customNone: 'Import an audio file (MP3, M4A, WAV).',
    customLoaded: 'File: {f}', tooBig: 'File too large (5 MB maximum).', badAudio: 'This audio file could not be read.',
    wake: 'The screen stays on while the page is open and you are on duty.',
    tones: { sirene: 'Siren', telephone: 'Phone ring', reveil: 'Alarm clock', urgence: 'Emergency', carillon: 'Chime', douce: 'Gentle', perso: 'My sound' },
    toneSub: { sirene: 'Two alternating tones, very loud', telephone: 'Classic phone ring', reveil: 'Fast beeps', urgence: 'Rising, insistent', carillon: 'Four notes, softer', douce: 'Two calm notes' },
  },
};

const DEFAULT_TYPES = [
  { key: 'suppression_article', fr: 'Suppression d’article', en: 'Delete item' },
  { key: 'annulation_facture', fr: 'Annulation de facture', en: 'Cancel invoice' },
  { key: 'modification_quantite', fr: 'Modification de quantité', en: 'Change quantity' },
  { key: 'recherche_f1', fr: 'Recherche F1', en: 'F1 search' },
  { key: 'authentification', fr: 'Authentification manager', en: 'Manager authentication' },
  { key: 'reclamation_client', fr: 'Réclamation client', en: 'Customer complaint' },
  { key: 'remboursement', fr: 'Remboursement', en: 'Refund' },
  { key: 'monnaie', fr: 'Besoin de monnaie', en: 'Need change' },
  { key: 'autre', fr: 'Autre', en: 'Other' },
];
const SHIFT_MS = 12 * 3600e3;
const SNOOZE_MS = 60e3;

/* ======================= Utilitaires ======================= */
const local = {
  get(k, d) { try { const v = localStorage.getItem('ac2_' + k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } },
  set(k, v) { try { localStorage.setItem('ac2_' + k, JSON.stringify(v)); } catch (e) { /* stockage indisponible */ } },
  del(k) { try { localStorage.removeItem('ac2_' + k); } catch (e) { /* ignore */ } },
};
let lang = local.get('lang', (navigator.language || 'fr').toLowerCase().startsWith('en') ? 'en' : 'fr');
const t = (k, p = {}) => { let s = (T[lang] && T[lang][k]) ?? T.fr[k] ?? k; if (typeof s !== 'string') return s; for (const x in p) s = s.split('{' + x + '}').join(p[x]); return s; };
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const $ = (id) => document.getElementById(id);
const clock = (ms) => (ms ? new Date(ms).toLocaleTimeString(lang === 'en' ? 'en-GB' : 'fr-FR', { hour: '2-digit', minute: '2-digit' }) : '…');
const dur = (ms) => { if (ms == null || ms < 0) return '—'; const s = Math.round(ms / 1000); return s < 60 ? s + ' s' : Math.floor(s / 60) + ' min ' + (s % 60) + ' s'; };
const typeLabel = (a) => (lang === 'en' ? (a.typeEn || a.typeFr) : a.typeFr) || '—';
const typeLabelOf = (ty) => (lang === 'en' ? ty.en : ty.fr);
function toast(msg) { const el = $('toast'); el.textContent = msg; el.hidden = false; clearTimeout(toast.h); toast.h = setTimeout(() => (el.hidden = true), 3200); }
function errText(e) {
  const c = (e && (e.code || e.message)) || '';
  if (/invalid-login/.test(c)) return t('errLoginFmt');
  if (/user-not-found|wrong-password|invalid-credential|invalid-email|user-disabled/.test(c)) return t('errCred');
  if (/too-many-requests/.test(c)) return t('errMany');
  if (/network|unavailable|offline/.test(c)) return t('errNet');
  if (/requires-recent-login/.test(c)) return t('errRelogin');
  if (/permission-denied/.test(c)) return t('errDenied');
  return t('errGeneric');
}

const ROUTE = (() => {
  const p = location.pathname.toLowerCase();
  const q = new URLSearchParams(location.search).get('app') || location.hash.replace('#', '');
  if (p.includes('manager') || q === 'manager' || q === 'mobile') return 'manager';
  return 'caisse';
})();

/* ======================= Installation (même lien : web ou app) ======================= */
const APK_URL = 'https://github.com/honoremadika/alerte-caisse/releases/latest/download/AlerteCaisse-Manager.apk';
const WIN_URL = 'https://github.com/honoremadika/alerte-caisse/releases/latest/download/AlerteCaisse-Caisse-Windows.zip';
let installEvt = null;
window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); installEvt = e; render(); });
window.addEventListener('appinstalled', () => { installEvt = null; toast(t('installed')); render(); });
const standalone = () => (window.matchMedia && matchMedia('(display-mode: standalone)').matches) || navigator.standalone === true;
const UA = navigator.userAgent || '';
const isIOS = /iphone|ipad|ipod/i.test(UA);
const isAndroid = /android/i.test(UA);
function installHTML() {
  if (standalone()) return '';
  let h = '';
  if (installEvt) h += `<button type="button" class="btn green" data-act="install">${esc(t('installApp'))}</button>`;
  else if (isIOS) h += `<p class="hint">${esc(t('iosHint'))}</p>`;
  else if (isAndroid) h += `<p class="hint">${esc(t('androidMenuHint'))}</p>`;
  if (ROUTE === 'manager' && isAndroid) h += `<p class="hint"><a href="${APK_URL}">${esc(t('apkLink'))}</a></p>`;
  if (ROUTE === 'caisse' && !isIOS && !isAndroid) h += `<p class="hint"><a href="${WIN_URL}">${esc(t('winLink'))}</a></p>`;
  return h ? `<div class="install" id="installBox">${h}</div>` : '';
}
async function doInstall() {
  if (!installEvt) return;
  const ev = installEvt; installEvt = null;
  try { await ev.prompt(); await ev.userChoice; } catch (e) { /* refusé */ }
  render();
}
if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost')) {
  window.addEventListener('load', () => { navigator.serviceWorker.register('/sw.js').catch(() => {}); });
}

/* ======================= Sons ======================= */
let actx = null, master = null, audioOk = false;
const ringPrefs = () => ({ tone: local.get('tone', 'sirene'), volume: local.get('volume', 90) });
function ensureAudio() {
  try {
    if (!actx) { actx = new (window.AudioContext || window.webkitAudioContext)(); master = actx.createGain(); master.connect(actx.destination); }
    if (actx.state === 'suspended') actx.resume();
    master.gain.value = ringPrefs().volume / 100;
    return true;
  } catch (e) { return false; }
}
function note(f, at, len, type = 'square', vol = 0.14, f2) {
  const o = actx.createOscillator(), g = actx.createGain(), t0 = actx.currentTime + at;
  o.type = type; o.frequency.setValueAtTime(f, t0);
  if (f2) o.frequency.linearRampToValueAtTime(f2, t0 + len);
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(vol, t0 + 0.02);
  g.gain.setValueAtTime(vol, t0 + Math.max(0.03, len - 0.05));
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + len);
  o.connect(g).connect(master); o.start(t0); o.stop(t0 + len + 0.02);
}
const TONES = {
  sirene: { cycle: 520, play() { note(1100, 0, 0.24); note(800, 0.26, 0.24); } },
  telephone: { cycle: 2600, play() { for (let i = 0; i < 2; i++) { note(440, i * 0.5, 0.42, 'sine', 0.16); note(480, i * 0.5, 0.42, 'sine', 0.16); } } },
  reveil: { cycle: 1100, play() { for (let i = 0; i < 4; i++) note(1000, i * 0.13, 0.08, 'square', 0.13); } },
  urgence: { cycle: 750, play() { note(600, 0, 0.6, 'sawtooth', 0.1, 1400); } },
  carillon: { cycle: 1900, play() { [523, 659, 784, 1047].forEach((f, i) => note(f, i * 0.18, 0.5, 'sine', 0.2)); } },
  douce: { cycle: 2200, play() { note(660, 0, 0.5, 'sine', 0.18); note(880, 0.55, 0.7, 'sine', 0.18); } },
};
let customBytes = null, customName = '', customBuf = null;
function idb() {
  return new Promise((res, rej) => {
    try { const r = indexedDB.open('alerte-caisse', 1); r.onupgradeneeded = () => r.result.createObjectStore('sons'); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); }
    catch (e) { rej(e); }
  });
}
async function idbPut(key, val) { try { const d = await idb(); await new Promise((res, rej) => { const tx = d.transaction('sons', 'readwrite'); tx.objectStore('sons').put(val, key); tx.oncomplete = res; tx.onerror = () => rej(tx.error); }); } catch (e) { /* ignore */ } }
async function idbGet(key) { try { const d = await idb(); return await new Promise((res) => { const r = d.transaction('sons').objectStore('sons').get(key); r.onsuccess = () => res(r.result); r.onerror = () => res(null); }); } catch (e) { return null; } }
idbGet('perso').then((v) => { if (v && v.bytes) { customBytes = v.bytes; customName = v.name || ''; } });

let ringTimer = null, ringSrc = null, ringStarting = false, previewTimer = null;
async function ringStart(key) {
  if (ringTimer || ringSrc || ringStarting || !ensureAudio()) return;
  key = key || ringPrefs().tone;
  if (key === 'perso' && customBytes) {
    ringStarting = true;
    try { customBuf = customBuf || await actx.decodeAudioData(customBytes.slice(0)); } catch (e) { customBuf = null; }
    ringStarting = false;
    if (customBuf && !ringTimer && !ringSrc) { ringSrc = actx.createBufferSource(); ringSrc.buffer = customBuf; ringSrc.loop = true; ringSrc.connect(master); ringSrc.start(); return; }
  }
  const tone = TONES[key] || TONES.sirene;
  tone.play(); ringTimer = setInterval(() => tone.play(), tone.cycle);
  vibrate([800, 300, 800, 300, 800]);
}
let vibrating = false;
function vibrate(p) { try { if (navigator.vibrate && navigator.userActivation && navigator.userActivation.hasBeenActive) { navigator.vibrate(p); vibrating = p !== 0; } } catch (e) { /* ignore */ } }
function ringStop() {
  const wasRinging = !!(ringTimer || ringSrc);
  if (ringTimer) { clearInterval(ringTimer); ringTimer = null; }
  if (ringSrc) { try { ringSrc.stop(); } catch (e) { /* ignore */ } ringSrc = null; }
  if (wasRinging || vibrating) vibrate(0);
}
function preview(key) { ringStop(); clearTimeout(previewTimer); ringStart(key); previewTimer = setTimeout(() => { previewTimer = null; ringStop(); renderAlarm(); }, 3000); }
function chime() { if (!ensureAudio()) return; note(660, 0, 0.18, 'sine', 0.12); note(990, 0.18, 0.3, 'sine', 0.12); }
function unlockAudio() { if (ensureAudio()) { note(880, 0, 0.1, 'sine', 0.05); audioOk = true; } requestWake(); }
let wake = null;
async function requestWake() { try { if (navigator.wakeLock && !wake) { wake = await navigator.wakeLock.request('screen'); wake.addEventListener('release', () => { wake = null; }); } } catch (e) { /* refusé */ } }
document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible' && dutyHere()) requestWake(); });

/* ======================= État ======================= */
let B = null;            // backend
let user = null;         // { uid, email }
let profile = null;      // users/{uid}
let profileLoaded = false;
let stores = [];         // magasins
let unsubs = [];
let unsubProfile = null;
const S = { // données écoutées
  store: null, mine: [], onDuty: [], active: [], history: [], loadedActive: false,
};
const ui = { selected: 'modification_quantite', sending: false, tab: 'live', picking: false, busy: false };
const seen = {};
const snoozed = {};

function stopWatches() { unsubs.forEach((u) => { try { u(); } catch (e) { /* ignore */ } }); unsubs = []; }
function setLang(l) { lang = l; local.set('lang', l); document.documentElement.lang = l; if (profile && B) B.saveLang(profile.uid, l); render(); }
document.addEventListener('click', (e) => { const b = e.target.closest('[data-lang]'); if (b) setLang(b.dataset.lang); });
const langSwitch = () => `<div class="lang" role="group" aria-label="${esc(t('setLang'))}"><button type="button" data-lang="fr" aria-pressed="${lang === 'fr'}">FR</button><button type="button" data-lang="en" aria-pressed="${lang === 'en'}">EN</button></div>`;
const logoSvg = '<svg viewBox="0 0 24 24"><path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1z"/><path d="M16 8.5a5 5 0 0 1 0 7"/></svg>';
const storeName = (id) => { const s = stores.find((x) => x.id === id); return s ? s.name : (id || '—'); };

/* ======================= Démarrage ======================= */
async function boot() {
  document.documentElement.lang = lang;
  try {
    B = window.__ALERTE_BACKEND__ || (await import('./backend-firebase.js')).backend;
  } catch (e) {
    $('root').innerHTML = `<div class="center"><div class="card"><p class="error">${esc(t('errNet'))}</p><button class="btn" onclick="location.reload()">↻</button></div></div>`;
    return;
  }
  B.onAuth((u) => {
    user = u; profile = null; profileLoaded = false;
    stopWatches(); if (unsubProfile) { unsubProfile(); unsubProfile = null; }
    // Rien ne doit rester de la session précédente (autre caissier, autre manager).
    S.store = null; S.mine = []; S.onDuty = []; S.active = []; S.history = []; S.loadedActive = false;
    watchedStore = null; watchedPost = null; ui.editPost = false; ui.tab = 'live'; ui.picking = false; ui.sending = false;
    Object.keys(seen).forEach((k) => delete seen[k]);
    $('flash').hidden = true; $('alarm').hidden = true; $('modal').hidden = true;
    ringStop();
    if (!u) { render(); return; }
    render();
    unsubProfile = B.watchProfile(u.uid, (p) => {
      const first = !profileLoaded;
      profile = p; profileLoaded = true;
      if (p && p.lang && first && !local.get('lang', null)) { lang = p.lang; }
      if (first) startWatches();
      render();
    }, () => { profileLoaded = true; render(); });
  });
}

async function startWatches() {
  stopWatches();
  if (!profile) return;
  try { stores = await B.listStores(); } catch (e) { stores = []; }
  watchedPost = null;
  if (ROUTE === 'caisse' && profile.role === 'cashier') watchCaisse();
  if (ROUTE === 'manager' && profile.role === 'manager') watchManagerStore();
  render();
}
let watchedStore = null;
function watchManagerStore() {
  const st = currentManagerStore();
  if (st === watchedStore) return;
  stopWatches(); watchedStore = st; S.active = []; S.history = []; S.loadedActive = false;
  if (!st) return;
  unsubs.push(B.watchActive(st, (list) => { S.active = list; S.loadedActive = true; render(); }, onWatchError));
  unsubs.push(B.watchHistory(st, (list) => { S.history = list; render(); }, onWatchError));
}
function onWatchError(e) { console.error(e); toast(errText(e)); }

/* ======================= Rendu général ======================= */
function render() {
  const root = $('root');
  if (!B) return;
  if (user === null) { renderLogin(root); renderAlarm(); return; }
  if (!profileLoaded) { root.innerHTML = `<div class="center"><p class="hint">${esc(t('loading'))}</p></div>`; return; }
  if (!profile) { renderMessage(root, t('noProfile')); return; }
  if (ROUTE === 'caisse' && profile.role !== 'cashier') { renderMessage(root, t('wrongCaisse'), '/manager'); return; }
  if (ROUTE === 'manager' && profile.role !== 'manager') { renderMessage(root, t('wrongManager'), '/caisse'); return; }
  if (ROUTE === 'caisse') renderCaisse(root); else renderManager(root);
  renderAlarm();
}

function renderMessage(root, msg, other) {
  root.innerHTML = `<div class="center"><div class="card">
    <div class="top"><div class="logo"><i>${logoSvg}</i><div><b>Alerte Caisse</b></div></div>${langSwitch()}</div>
    <p>${esc(msg)}</p>
    ${other ? `<a class="btn primary" href="${other}">${esc(t('openOther'))}</a>` : ''}
    <button type="button" class="btn" data-act="logout">${esc(t('signOut'))}</button></div></div>`;
}

/* ======================= Connexion ======================= */
let loginErr = '', loginBusy = false, loginShow = false;
function renderLogin(root) {
  const keepId = $('lgId') ? $('lgId').value : local.get('lastLogin', '');
  const keepPw = $('lgPw') ? $('lgPw').value : '';
  root.innerHTML = `<div class="center"><form class="card" id="loginForm" autocomplete="on" novalidate>
    <div class="top"><div class="logo"><i>${logoSvg}</i><div><b>${esc(ROUTE === 'caisse' ? t('appCaisse') : t('appManager'))}</b></div></div>${langSwitch()}</div>
    <div class="field"><label for="lgId">${esc(t('loginId'))}</label>
      <input id="lgId" name="username" autocomplete="username" autocapitalize="none" autocorrect="off" spellcheck="false" placeholder="${esc(t('loginIdPh'))}" value="${esc(keepId)}"></div>
    <div class="field"><label for="lgPw">${esc(t('password'))}</label>
      <div class="pw"><input id="lgPw" name="password" type="${loginShow ? 'text' : 'password'}" autocomplete="current-password" value="${esc(keepPw)}">
      <button type="button" data-act="togglePw" aria-label="${esc(loginShow ? t('hide') : t('show'))}">${esc(loginShow ? t('hide') : t('show'))}</button></div></div>
    ${loginErr ? `<p class="error" role="alert">${esc(loginErr)}</p>` : ''}
    <button type="submit" class="btn primary big" ${loginBusy ? 'disabled' : ''}>${esc(loginBusy ? t('loading') : t('signIn'))}</button>
    ${installHTML()}
  </form></div>`;
  $('loginForm').addEventListener('submit', onLogin);
}
async function onLogin(e) {
  e.preventDefault();
  const id = $('lgId').value.trim(), pw = $('lgPw').value;
  if (!id || !pw) { loginErr = t('errFill'); render(); return; }
  loginBusy = true; loginErr = ''; render();
  try { await B.signIn(id, pw); local.set('lastLogin', id.toLowerCase()); loginErr = ''; }
  catch (err) { loginErr = errText(err); }
  finally { loginBusy = false; if (!user) render(); }
}

/* ======================= Mot de passe ======================= */
function openPasswordModal() {
  const m = $('modal');
  m.innerHTML = `<form class="modal" id="pwForm" role="dialog" aria-modal="true" aria-labelledby="pwTitle" novalidate>
    <h2 id="pwTitle">${esc(t('changePw'))}</h2>
    <div class="field"><label for="pwCur">${esc(t('currentPw'))}</label><input id="pwCur" type="password" autocomplete="current-password"></div>
    <div class="field"><label for="pwNew">${esc(t('newPw'))}</label><input id="pwNew" type="password" autocomplete="new-password"></div>
    <div class="field"><label for="pwNew2">${esc(t('confirmPw'))}</label><input id="pwNew2" type="password" autocomplete="new-password"></div>
    <p class="hint">${esc(t('pwRule'))}</p>
    <p class="error" id="pwErr" hidden role="alert"></p>
    <div class="row"><button type="button" class="btn" data-act="closeModal">${esc(t('cancel'))}</button><button type="submit" class="btn primary" id="pwSave">${esc(t('save'))}</button></div>
  </form>`;
  m.hidden = false; $('pwCur').focus();
  $('pwForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const cur = $('pwCur').value, n1 = $('pwNew').value, n2 = $('pwNew2').value, er = $('pwErr');
    const fail = (msg) => { er.textContent = msg; er.hidden = false; };
    if (!cur || !n1 || !n2) return fail(t('errFill'));
    if (n1.length < 6) return fail(t('pwShort'));
    if (n1 !== n2) return fail(t('pwMismatch'));
    $('pwSave').disabled = true;
    try { await B.changePassword(cur, n1); m.hidden = true; m.innerHTML = ''; toast(t('pwChanged')); }
    catch (err) { const c = String(err.code || ''); fail(/wrong-password|invalid-credential/.test(c) ? t('pwWrong') : /weak-password/.test(c) ? t('pwShort') : errText(err)); $('pwSave').disabled = false; }
  });
}

/* ======================= CAISSE ======================= */
// Poste = magasin + numéro de caisse de CET ordinateur (liste déroulante des 40 magasins).
function station() {
  if (!profile) return null;
  const st = local.get('station:' + profile.uid, null);
  if (st && st.storeId && st.register) return st;
  if (profile.storeId && profile.register) return { storeId: profile.storeId, register: profile.register };
  return null;
}
const cashierMe = () => { const st = station(); return st ? { ...profile, storeId: st.storeId, register: String(st.register) } : null; };
let watchedPost = null;
function watchCaisse() {
  const me = cashierMe();
  const key = me ? me.storeId + '|' + me.register : null;
  if (key === watchedPost) return;
  stopWatches(); watchedPost = key; S.store = null; S.mine = []; S.onDuty = [];
  if (!me) return;
  unsubs.push(B.watchStore(me.storeId, (x) => { S.store = x; render(); }));
  unsubs.push(B.watchMyAlerts(me, (list) => { S.mine = list; watchTaken(); render(); }, onWatchError));
  unsubs.push(B.watchManagersOnDuty(me.storeId, (list) => { S.onDuty = list; render(); }, onWatchError));
}
function allStoresOptions(sel) {
  return `<option value="" ${sel ? '' : 'selected'} disabled>${esc(t('pickStore'))}</option>` +
    stores.map((x) => `<option value="${esc(x.id)}" ${x.id === sel ? 'selected' : ''}>${esc(x.name || x.id)}</option>`).join('');
}
function renderPost(root) {
  const cur = station() || {};
  root.innerHTML = `<div class="center"><form class="card" id="postForm" novalidate>
    <div class="top"><div class="logo"><i>${logoSvg}</i><div><b>${esc(t('postTitle'))}</b><span>${esc(profile.name)}</span></div></div>${langSwitch()}</div>
    <p class="hint">${esc(t('postSub'))}</p>
    <div class="field"><label for="pStore">${esc(t('store'))}</label><select id="pStore">${allStoresOptions(cur.storeId || '')}</select></div>
    <div class="field"><label for="pReg">${esc(t('registerNo'))}</label><input id="pReg" inputmode="numeric" maxlength="3" value="${esc(cur.register || '')}" placeholder="1"></div>
    <p class="error" id="pErr" hidden role="alert"></p>
    <button type="submit" class="btn primary big">${esc(t('save'))}</button>
    ${station() ? `<button type="button" class="btn" data-act="cancelPost">${esc(t('cancel'))}</button>` : ''}
    <button type="button" class="btn" data-act="logout">${esc(t('signOut'))}</button>
  </form></div>`;
  $('postForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const storeId = $('pStore').value, reg = $('pReg').value.trim();
    if (!storeId || !/^[0-9A-Za-z]{1,3}$/.test(reg)) { const er = $('pErr'); er.textContent = t('needPost'); er.hidden = false; return; }
    local.set('station:' + profile.uid, { storeId, register: reg });
    ui.editPost = false; render();
  });
}
function caisseTypes() {
  const raw = S.store && Array.isArray(S.store.alertTypes) ? S.store.alertTypes.filter((x) => x && x.key) : [];
  return raw.length ? raw.map((x) => ({ key: x.key, fr: x.fr || x.key, en: x.en || x.fr || x.key })) : DEFAULT_TYPES;
}
function renderCaisse(root) {
  if (!station() || ui.editPost) {
    if (!(document.activeElement && document.activeElement.closest && document.activeElement.closest('#postForm'))) renderPost(root);
    return;
  }
  watchCaisse();
  const post = station();
  const types = caisseTypes();
  if (!types.find((x) => x.key === ui.selected)) ui.selected = types[0].key;
  const keepMsg = $('cMsg') ? $('cMsg').value : '';
  const focusMsg = document.activeElement && document.activeElement.id === 'cMsg';
  const onDuty = S.onDuty;
  root.innerHTML = `<div class="desk">
    <aside class="side">
      <div class="logo"><i>${logoSvg}</i><div><b>Alerte Caisse</b><span>${esc(t('appCaisse'))}</span></div></div>
      <div class="who"><span class="muted">${esc(storeName(post.storeId))}</span><span class="big">${esc(t('register', { n: post.register }))}</span><span>${esc(profile.name)}</span></div>
      <div style="display:grid;gap:8px"><h3>${esc(t('managersOnDuty'))}</h3>
        <div class="duty-list">${onDuty.length ? onDuty.map((d) => `<div><span class="dot"></span>${esc(d.name)}</div>`).join('') : `<div class="muted">${esc(t('noneOnDuty'))}</div>`}</div></div>
      <div class="foot">${langSwitch()}
        <button type="button" class="sbtn" data-act="editPost">${esc(t('editPost'))}</button>
        <button type="button" class="sbtn" data-act="password">${esc(t('changePw'))}</button>
        <button type="button" class="sbtn logout" data-act="logout">${esc(t('signOut'))}</button>${installHTML()}</div>
    </aside>
    <main class="desk-main">
      ${onDuty.length ? '' : `<div class="banner">${esc(t('noMgr'))}</div>`}
      <h1>${esc(t('whatProblem'))}</h1>
      <div class="types">${types.map((ty, i) => `<button type="button" class="type" data-type="${esc(ty.key)}" aria-pressed="${ty.key === ui.selected}"><kbd>${i + 1}</kbd><span>${esc(typeLabelOf(ty))}</span></button>`).join('')}</div>
      <div class="send-row">
        <div class="field"><label for="cMsg">${esc(t('details'))}</label><input id="cMsg" maxlength="140" placeholder="${esc(t('detailsPh'))}" value="${esc(keepMsg)}"></div>
        <button type="button" class="big-red" data-act="send" ${ui.sending ? 'disabled' : ''}>${esc(ui.sending ? t('sending') : t('send'))}</button>
      </div>
      <p class="hint">${t('hint')}</p>
      <h2 style="font-size:17px">${esc(t('myAlerts'))}</h2>
      <div class="mine">${S.mine.length ? S.mine.map(mineRow).join('') : `<div class="empty">${esc(t('noMine'))}</div>`}</div>
    </main></div>`;
  if (focusMsg) { const i = $('cMsg'); i.focus(); i.setSelectionRange(i.value.length, i.value.length); }
}
function mineRow(a) {
  const taken = a.status === 'taken';
  return `<div class="mrow ${taken ? 'taken' : 'wait'}">
    <div class="ic">${taken ? '<svg viewBox="0 0 24 24"><circle cx="13" cy="4" r="2"/><path d="m7 21 3-6 3 2v5M6 12l3-4 4 1 3 3 3 1"/></svg>' : '<svg viewBox="0 0 24 24"><path d="M6 2h12M6 22h12M7 2v4l5 6-5 6v4M17 2v4l-5 6 5 6v4"/></svg>'}</div>
    <div><b>${esc(typeLabel(a))} · ${clock(a.createdAt)}</b><span class="sub">${esc(taken ? t('coming', { n: a.takenByName || '—' }) : t('waiting'))}</span></div>
    ${taken ? '' : `<button type="button" class="btn" data-cancel="${esc(a.id)}">${esc(t('cancel'))}</button>`}</div>`;
}
function watchTaken() {
  S.mine.forEach((a) => {
    if (seen[a.id] === 'open' && a.status === 'taken') {
      const f = $('flash');
      f.innerHTML = `<svg viewBox="0 0 24 24"><circle cx="13" cy="4" r="2"/><path d="m7 21 3-6 3 2v5M6 12l3-4 4 1 3 3 3 1"/></svg><div><b>${esc(t('coming', { n: a.takenByName || '—' }))}</b>${esc(t('flashSub', { r: a.register, t: typeLabel(a) }))}</div>`;
      f.hidden = false; clearTimeout(watchTaken.h); watchTaken.h = setTimeout(() => { f.hidden = true; }, 7000);
      chime();
    }
    seen[a.id] = a.status;
  });
}
async function caisseSend() {
  if (ui.sending || !profile || !cashierMe()) return;
  const ty = caisseTypes().find((x) => x.key === ui.selected) || DEFAULT_TYPES[DEFAULT_TYPES.length - 1];
  ensureAudio();
  ui.sending = true; render();
  try { await B.sendAlert(cashierMe(), ty, $('cMsg') ? $('cMsg').value : ''); if ($('cMsg')) $('cMsg').value = ''; toast(t('sent')); }
  catch (e) { console.error(e); toast(/permission/.test(String(e.code)) ? t('errDenied') : t('sendFail')); }
  finally { ui.sending = false; render(); }
}

/* ======================= MANAGER ======================= */
// L'appareil qui a pris le service est le seul à sonner.
function dutyHere() {
  if (!profile) return false;
  const d = local.get('dutyHere:' + profile.uid, null);
  if (!d) return false;
  return profile.onDuty && profile.dutyStoreId === d.store && (profile.dutyUntil || 0) > Date.now();
}
function onDutyAnywhere() { return !!(profile && profile.onDuty && (profile.dutyUntil || 0) > Date.now()); }
function lastStore() { const k = local.get('lastStore', null); return k && profile.storeIds.includes(k) ? k : null; }
function currentManagerStore() {
  if (!profile) return null;
  if (onDutyAnywhere()) return profile.dutyStoreId;
  return lastStore() || null;
}
function myStoresOptions(sel) {
  const ids = profile.storeIds.length ? profile.storeIds : [];
  const list = stores.filter((s) => ids.includes(s.id));
  const fallback = ids.filter((id) => !list.find((s) => s.id === id)).map((id) => ({ id, name: id }));
  return `<option value="" ${sel ? '' : 'selected'} disabled>${esc(t('pickStore'))}</option>` +
    [...list, ...fallback].map((s) => `<option value="${esc(s.id)}" ${s.id === sel ? 'selected' : ''}>${esc(s.name)}</option>`).join('');
}
function ringingAlerts() {
  if (!dutyHere()) return [];
  const now = Date.now();
  return S.active.filter((a) => a.status === 'open' && a.storeId === profile.dutyStoreId && !(snoozed[a.id] > now)).sort((x, y) => x.createdAt - y.createdAt);
}

function renderManager(root) {
  watchManagerStore();
  const typing = document.activeElement && document.activeElement.matches && document.activeElement.matches('#mBody input:not([type=radio]):not([type=range]):not([type=file]), #mBody select, #mDuty select');
  if (typing && $('mApp')) { updateManagerChrome(); return; }
  root.innerHTML = `<div class="mob" id="mApp">
    <header class="mtop"><div><h1>${esc(t('tabLive'))}</h1><div class="me">${esc(profile.name)}</div></div>${langSwitch()}</header>
    <div class="dutybar" id="mDuty"></div>
    <div class="gate" id="mGate" hidden><b>${esc(t('gateT'))}</b><span>${esc(t('gateS'))}</span><button type="button" data-act="unlock">${esc(t('gateB'))}</button></div>
    <div class="mbody" id="mBody"></div>
    <nav class="tabbar"><div role="tablist">
      <button type="button" role="tab" data-tab="live"><svg viewBox="0 0 24 24"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg><span>${esc(t('tabLive'))}</span><i class="count" id="mCount" hidden></i></button>
      <button type="button" role="tab" data-tab="hist"><svg viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 2"/></svg><span>${esc(t('tabHist'))}</span></button>
      <button type="button" role="tab" data-tab="set"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/></svg><span>${esc(t('tabSet'))}</span></button>
    </div></nav></div>`;
  updateManagerChrome();
  const b = $('mBody');
  if (ui.picking) b.innerHTML = pickHTML();
  else if (ui.tab === 'live') b.innerHTML = liveHTML();
  else if (ui.tab === 'hist') b.innerHTML = histHTML();
  else b.innerHTML = setHTML();
}
function updateManagerChrome() {
  const duty = $('mDuty'); if (!duty) return;
  const here = dutyHere(), any = onDutyAnywhere(), last = lastStore();
  const keepSel = $('mFirstSel') ? $('mFirstSel').value : '';
  if (here) {
    duty.className = 'dutybar on';
    duty.innerHTML = `<div><b>${esc(t('onDuty', { s: storeName(profile.dutyStoreId) }))}</b><span>${esc(t('onDutySub', { t: clock(profile.dutyUntil) }))}</span></div>
      <button type="button" class="btn" data-act="endDuty" ${ui.busy ? 'disabled' : ''}>${esc(t('endDuty'))}</button>`;
  } else if (any) {
    duty.className = 'dutybar off';
    duty.innerHTML = `<div><b>${esc(t('onDuty', { s: storeName(profile.dutyStoreId) }))}</b><span>${esc(t('dutyElsewhere'))}</span></div>
      <button type="button" class="btn green big" data-start="${esc(profile.dutyStoreId)}" ${ui.busy ? 'disabled' : ''}>${esc(t('takeHere'))}</button>
      <button type="button" class="btn" data-act="endDuty" ${ui.busy ? 'disabled' : ''}>${esc(t('endDuty'))}</button>`;
  } else if (last) {
    duty.className = 'dutybar off';
    duty.innerHTML = `<div><b>${esc(t('offDuty'))}</b><span>${esc(t('offInfo'))}</span></div>
      <button type="button" class="btn green big" data-start="${esc(last)}" ${ui.busy ? 'disabled' : ''}>${esc(t('startAt', { s: storeName(last) }))}</button>
      <span class="hint" style="text-align:center">${esc(t('lastHere'))}</span>
      <button type="button" class="linkbtn" data-act="other">${esc(t('otherStore'))}</button>`;
  } else {
    duty.className = 'dutybar off';
    duty.innerHTML = `<div><b>${esc(t('offDuty'))}</b><span>${esc(t('offInfo'))}</span></div>
      <div class="field"><label for="mFirstSel">${esc(t('chooseStore'))}</label><select id="mFirstSel">${myStoresOptions(keepSel)}</select></div>
      <button type="button" class="btn green big" data-act="startSel" ${ui.busy ? 'disabled' : ''}>${esc(t('goHere'))}</button>`;
  }
  $('mGate').hidden = !(here && !audioOk);
  const open = S.active.filter((a) => a.status === 'open').length;
  const c = $('mCount'); c.hidden = !open; c.textContent = open;
  document.querySelectorAll('.tabbar [data-tab]').forEach((b) => b.setAttribute('aria-selected', String(b.dataset.tab === ui.tab && !ui.picking)));
}
function pickHTML() {
  return `<h2 style="font-size:18px">${esc(t('chooseStore'))}</h2>
    <div class="field"><label for="mPickSel">${esc(t('chooseStore'))}</label><select id="mPickSel">${myStoresOptions(lastStore())}</select></div>
    <button type="button" class="btn green big" data-act="startPick">${esc(t('goHere'))}</button>
    <button type="button" class="btn" data-act="cancelPick">${esc(t('cancel'))}</button>`;
}
function liveHTML() {
  const st = currentManagerStore();
  if (!onDutyAnywhere() && !st) return `<div class="calm"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 7v5"/><path d="M12 16h.01"/></svg><b>${esc(t('offDuty'))}</b>${esc(t('offInfo'))}</div>`;
  const list = S.active;
  if (!list.length) return `<div class="calm"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="m8 12 3 3 5-6"/></svg><b>${esc(t('allGood'))}</b>${esc(t('noAlert'))}</div>`;
  return list.map((a) => {
    const mine = a.takenBy === profile.uid;
    const m = Math.floor((Date.now() - a.createdAt) / 60e3);
    return `<div class="acard ${a.status}">
      <div class="r1"><span class="reg">${esc(t('till', { n: a.register }))}</span><span class="ago">${m < 1 ? esc(t('now')) : esc(t('ago', { m }))}</span></div>
      <div class="what">${esc(typeLabel(a))}</div>
      ${a.message ? `<div>« ${esc(a.message)} »</div>` : ''}
      <div class="meta">${esc(t('cashier', { n: a.cashierName }))} · ${clock(a.createdAt)}</div>
      ${a.status === 'taken'
        ? `<div class="by">${mine ? esc(t('you')) : esc(t('took', { n: a.takenByName || '—' }))}</div><button type="button" class="btn ${mine ? 'green' : ''}" data-resolve="${esc(a.id)}">${esc(t('solved'))}</button>`
        : `<button type="button" class="btn red" data-take="${esc(a.id)}">${esc(t('imComing'))}</button>`}
    </div>`;
  }).join('');
}
function histHTML() {
  const st = currentManagerStore();
  const list = S.history;
  const re = list.filter((a) => a.takenAt).map((a) => a.takenAt - a.createdAt);
  const avg = re.length ? re.reduce((x, y) => x + y, 0) / re.length : null;
  return `<div class="stats"><div class="stat"><b class="tab-nums">${list.length}</b><span>${esc(t('alerts'))} · ${esc(storeName(st))}</span></div>
    <div class="stat"><b class="tab-nums">${dur(avg)}</b><span>${esc(t('avgReaction'))}</span></div></div>` +
    (list.length ? list.map((a) => `<div class="hrow"><div class="n">${esc(a.register)}</div>
      <div><b>${esc(typeLabel(a))} · ${esc(a.cashierName)}</b><span class="tab-nums">${clock(a.createdAt)}${a.takenByName ? ' · ' + esc(a.takenByName) + ' · ' + esc(t('reaction', { d: dur(a.takenAt - a.createdAt) })) : ''}${a.resolvedAt ? ' · ' + esc(t('solvedIn', { d: dur(a.resolvedAt - a.createdAt) })) : ''}</span></div>
      <span class="st ${a.status}">${esc((T[lang].st || T.fr.st)[a.status] || a.status)}</span></div>`).join('')
    : `<div class="calm">${esc(t('noHist'))}</div>`);
}
function setHTML() {
  const p = ringPrefs();
  const play = '<svg viewBox="0 0 24 24"><path d="M7 4v16l13-8z"/></svg>';
  const keys = [...Object.keys(TONES), 'perso'];
  return `<div class="group"><h2>${esc(t('setRing'))}</h2><div class="tones">${keys.map((k) => {
      const dis = k === 'perso' && !customBytes;
      const sub = k === 'perso' ? (customBytes ? t('customLoaded', { f: customName }) : t('customNone')) : t('toneSub')[k];
      return `<div class="tone ${k === p.tone ? 'sel' : ''}"><input type="radio" name="tone" id="tone-${k}" value="${k}" ${k === p.tone ? 'checked' : ''} ${dis ? 'disabled' : ''}>
        <label for="tone-${k}">${esc(t('tones')[k])}<small>${esc(sub)}</small></label>
        <button type="button" class="play" data-preview="${k}" aria-label="${esc(t('play'))} ${esc(t('tones')[k])}" ${dis ? 'disabled' : ''}>${play}</button></div>`;
    }).join('')}</div>
    <span class="btn file-btn">${esc(t('importSound'))}<input type="file" id="mFile" accept="audio/*" aria-label="${esc(t('importSound'))}"></span>
    <p class="hint">${esc(t('customOnly'))}</p>
    <div class="range"><span>${esc(t('volume'))}</span><input type="range" id="mVol" min="10" max="100" step="5" value="${p.volume}"><span class="tab-nums" id="mVolV">${p.volume} %</span></div></div>
    ${installHTML() ? `<div class="group"><h2>${esc(t('setApp'))}</h2>${installHTML()}</div>` : ''}
    <div class="group"><h2>${esc(t('setAccount'))}</h2><p>${esc(profile.name)}${profile.loginId ? ` · <span class="hint">${esc(profile.loginId)}</span>` : ''}</p>
      <button type="button" class="btn" data-act="password">${esc(t('changePw'))}</button>
      <button type="button" class="btn red" data-act="logout">${esc(t('signOut'))}</button>
      <p class="hint">${esc(t('wake'))}</p></div>`;
}

function renderAlarm() {
  const al = $('alarm');
  if (ROUTE !== 'manager' || !profile || profile.role !== 'manager') { al.hidden = true; if (!previewTimer) ringStop(); return; }
  const ring = ringingAlerts();
  if (!ring.length) { al.hidden = true; if (!previewTimer) ringStop(); return; }
  const a = ring[0];
  const relance = Date.now() - a.createdAt > 60e3;
  al.innerHTML = `<div class="ring"><svg viewBox="0 0 24 24"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg></div>
    <div class="k">${esc(relance ? t('relance') : t('alarmK'))}${ring.length > 1 ? ' · ' + ring.length : ''}</div>
    <h2>${esc(t('till', { n: a.register }))}</h2><div class="w">${esc(typeLabel(a))}</div>
    <div class="who">${esc(a.cashierName)} · ${clock(a.createdAt)}</div>
    ${a.message ? `<div class="msg">« ${esc(a.message)} »</div>` : ''}
    <div class="acts"><button type="button" class="go" data-take="${esc(a.id)}">${esc(t('imComing'))}</button>
    <button type="button" class="later" data-snooze="${esc(a.id)}">${esc(t('snooze'))}</button></div>`;
  al.hidden = false;
  if (audioOk && !previewTimer) ringStart();
}

async function startDuty(storeId) {
  if (!storeId) { toast(t('pickStore')); return; }
  unlockAudio(); ui.picking = false; ui.busy = true; render();
  const until = Date.now() + SHIFT_MS;
  try {
    await B.startDuty(profile.uid, storeId, until);
    local.set('dutyHere:' + profile.uid, { store: storeId });
    local.set('lastStore', storeId);
    ui.tab = 'live';
  } catch (e) { console.error(e); toast(errText(e)); }
  finally { ui.busy = false; render(); }
}
async function endDuty() {
  ui.busy = true; render();
  try { await B.endDuty(profile.uid); local.del('dutyHere:' + profile.uid); ringStop(); }
  catch (e) { console.error(e); toast(errText(e)); }
  finally { ui.busy = false; render(); }
}
async function take(id) {
  ringStop();
  try { const other = await B.takeAlert(id, profile); if (other) toast(t('already', { n: other })); }
  catch (e) { console.error(e); toast(errText(e)); }
  render();
}
async function resolve(id) { try { await B.resolveAlert(id, profile); } catch (e) { console.error(e); toast(errText(e)); } }

/* ======================= Évènements ======================= */
document.addEventListener('click', async (e) => {
  const el = (s) => e.target.closest(s);
  const act = el('[data-act]') && el('[data-act]').dataset.act;
  if (act === 'togglePw') { loginShow = !loginShow; render(); return; }
  if (act === 'logout') {
    $('modal').hidden = true;
    if (ROUTE === 'manager' && profile && dutyHere()) { try { await B.endDuty(profile.uid); } catch (err) { /* ignore */ } local.del('dutyHere:' + profile.uid); }
    ringStop(); await B.signOut(); return;
  }
  if (act === 'password') { openPasswordModal(); return; }
  if (act === 'closeModal') { $('modal').hidden = true; $('modal').innerHTML = ''; return; }
  if (act === 'install') { doInstall(); return; }
  if (act === 'send') { caisseSend(); return; }
  if (act === 'editPost') { ui.editPost = true; render(); return; }
  if (act === 'cancelPost') { ui.editPost = false; render(); return; }
  if (act === 'unlock') { unlockAudio(); render(); return; }
  if (act === 'endDuty') { endDuty(); return; }
  if (act === 'other') { ui.picking = true; render(); return; }
  if (act === 'cancelPick') { ui.picking = false; render(); return; }
  if (act === 'startPick') { startDuty($('mPickSel') && $('mPickSel').value); return; }
  if (act === 'startSel') { startDuty($('mFirstSel') && $('mFirstSel').value); return; }
  const tp = el('[data-type]'); if (tp) { ui.selected = tp.dataset.type; render(); return; }
  const cn = el('[data-cancel]'); if (cn) { try { await B.cancelAlert(cn.dataset.cancel); } catch (err) { toast(errText(err)); } return; }
  const tb = el('[data-tab]'); if (tb) { ui.tab = tb.dataset.tab; ui.picking = false; render(); return; }
  const sd = el('[data-start]'); if (sd) { startDuty(sd.dataset.start); return; }
  const tk = el('[data-take]'); if (tk) { take(tk.dataset.take); return; }
  const rs = el('[data-resolve]'); if (rs) { resolve(rs.dataset.resolve); return; }
  const sz = el('[data-snooze]'); if (sz) { snoozed[sz.dataset.snooze] = Date.now() + SNOOZE_MS; ringStop(); renderAlarm(); return; }
  const pv = el('[data-preview]'); if (pv) { unlockAudio(); preview(pv.dataset.preview); return; }
});
document.addEventListener('change', async (e) => {
  if (e.target.name === 'tone') { local.set('tone', e.target.value); unlockAudio(); preview(e.target.value); render(); }
  if (e.target.id === 'mVol') { local.set('volume', +e.target.value); unlockAudio(); preview(ringPrefs().tone); }
  if (e.target.id === 'mFile') {
    const f = e.target.files && e.target.files[0]; if (!f) return;
    if (f.size > 5 * 1024 * 1024) { toast(t('tooBig')); return; }
    const bytes = await f.arrayBuffer();
    unlockAudio();
    try { await actx.decodeAudioData(bytes.slice(0)); } catch (err) { toast(t('badAudio')); return; }
    customBytes = bytes; customName = f.name; customBuf = null;
    await idbPut('perso', { bytes, name: f.name });
    local.set('tone', 'perso'); preview('perso'); render();
  }
});
document.addEventListener('input', (e) => { if (e.target.id === 'mVol') { $('mVolV').textContent = e.target.value + ' %'; if (master) master.gain.value = e.target.value / 100; } });
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !$('modal').hidden) { $('modal').hidden = true; $('modal').innerHTML = ''; return; }
  if (ROUTE !== 'caisse' || !profile || profile.role !== 'cashier' || !$('modal').hidden) return;
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') { e.preventDefault(); caisseSend(); return; }
  const inField = e.target.matches && e.target.matches('input, select, textarea');
  if (!inField && /^[1-9]$/.test(e.key)) { const ty = caisseTypes()[+e.key - 1]; if (ty) { ui.selected = ty.key; render(); } }
});
// Rafraîchit « il y a X min », relances après « pas disponible », fin de service.
setInterval(() => { if (user && profile && ROUTE === 'manager') render(); }, 15000);

boot();
