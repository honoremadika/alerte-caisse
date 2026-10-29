// Accès à Firebase pour la web app — MÊMES collections et MÊMES requêtes que
// l'app Windows/Android (lib/services/*.dart), donc les deux se parlent.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut as fbSignOut,
  EmailAuthProvider, reauthenticateWithCredential, updatePassword,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js';
import {
  initializeFirestore, persistentLocalCache, doc, getDoc, getDocs, onSnapshot, collection, query, where,
  orderBy, limit, addDoc, updateDoc, serverTimestamp, runTransaction, Timestamp, deleteField,
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';
import config from './firebase-config.js';

const app = initializeApp(config);
const auth = getAuth(app);
let db;
try { db = initializeFirestore(app, { localCache: persistentLocalCache() }); }
catch (e) { db = initializeFirestore(app, {}); }

const ms = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : (typeof v === 'number' ? v : null));
const ID_RE = /^[a-z0-9._-]{2,40}$/;

function err(code) { const e = new Error(code); e.code = code; return e; }

function alertFrom(d) {
  const x = d.data() || {};
  return {
    id: d.id, storeId: x.storeId || '', type: x.type || 'autre',
    typeFr: x.typeFr || 'Alerte', typeEn: x.typeEn || x.typeFr || 'Alert',
    message: x.message || '', register: String(x.register ?? ''),
    cashierId: x.cashierId || '', cashierName: x.cashierName || '',
    status: x.status || 'open', createdAt: ms(x.createdAt) ?? Date.now(),
    takenAt: ms(x.takenAt), takenBy: x.takenBy || null, takenByName: x.takenByName || null,
    resolvedAt: ms(x.resolvedAt),
  };
}
function profileFrom(d) {
  const x = d.data() || {};
  return {
    uid: d.id, name: x.name || '—', role: x.role || 'cashier', register: String(x.register ?? ''),
    storeId: x.storeId || '', storeIds: Array.isArray(x.storeIds) ? x.storeIds : [],
    onDuty: x.onDuty === true, dutyStoreId: x.dutyStoreId || null, dutyUntil: ms(x.dutyUntil),
    lang: x.lang || null, loginId: x.loginId || null,
  };
}

export const backend = {
  kind: 'firebase',

  onAuth(cb) { return onAuthStateChanged(auth, (u) => cb(u ? { uid: u.uid, email: u.email } : null)); },

  async signIn(login, password) {
    const l = String(login || '').trim().toLowerCase();
    let email = l;
    if (!l.includes('@')) {
      if (!ID_RE.test(l)) throw err('invalid-login');
      const snap = await getDoc(doc(db, 'logins', l));
      email = snap.exists() ? snap.data().email : null;
      if (!email) throw err('user-not-found');
    }
    try { await signInWithEmailAndPassword(auth, email, password); }
    catch (e) { throw err(String(e.code || '').replace('auth/', '') || 'unknown'); }
  },

  async signOut() { await fbSignOut(auth); },

  async changePassword(current, next) {
    const u = auth.currentUser;
    if (!u || !u.email) throw err('requires-recent-login');
    try {
      await reauthenticateWithCredential(u, EmailAuthProvider.credential(u.email, current));
      await updatePassword(u, next);
    } catch (e) { throw err(String(e.code || '').replace('auth/', '') || 'unknown'); }
  },

  watchProfile(uid, cb, onError) {
    return onSnapshot(doc(db, 'users', uid), (d) => cb(d.exists() ? profileFrom(d) : null), onError);
  },

  async listStores() {
    const snap = await getDocs(collection(db, 'stores'));
    return snap.docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => a.id.localeCompare(b.id));
  },

  watchStore(id, cb) { return onSnapshot(doc(db, 'stores', id), (d) => cb(d.exists() ? { id: d.id, ...d.data() } : null)); },

  async sendAlert(me, type, message) {
    await addDoc(collection(db, 'alerts'), {
      storeId: me.storeId, type: type.key, typeFr: type.fr, typeEn: type.en,
      message: String(message || '').trim().slice(0, 140), register: me.register,
      cashierId: me.uid, cashierName: me.name, status: 'open', createdAt: serverTimestamp(),
    });
  },

  watchMyAlerts(me, cb, onError) {
    const q = query(collection(db, 'alerts'), where('storeId', '==', me.storeId), where('cashierId', '==', me.uid),
      where('status', 'in', ['open', 'taken']), orderBy('createdAt', 'desc'));
    return onSnapshot(q, (s) => cb(s.docs.map(alertFrom)), onError);
  },

  watchActive(storeId, cb, onError) {
    const q = query(collection(db, 'alerts'), where('storeId', '==', storeId),
      where('status', 'in', ['open', 'taken']), orderBy('createdAt', 'desc'));
    return onSnapshot(q, (s) => cb(s.docs.map(alertFrom)), onError);
  },

  watchHistory(storeId, cb, onError) {
    const q = query(collection(db, 'alerts'), where('storeId', '==', storeId), orderBy('createdAt', 'desc'), limit(100));
    return onSnapshot(q, (s) => cb(s.docs.map(alertFrom)), onError);
  },

  watchManagersOnDuty(storeId, cb, onError) {
    const q = query(collection(db, 'users'), where('role', '==', 'manager'), where('onDuty', '==', true),
      where('dutyStoreId', '==', storeId));
    return onSnapshot(q, (s) => cb(s.docs.map(profileFrom).filter((u) => (u.dutyUntil || 0) > Date.now())), onError);
  },

  /** « J'arrive » : null si OK, sinon le nom de celui qui a déjà répondu. */
  async takeAlert(alertId, me) {
    const ref = doc(db, 'alerts', alertId);
    return runTransaction(db, async (tx) => {
      const s = await tx.get(ref);
      if (!s.exists()) return '—';
      const x = s.data();
      if (x.status !== 'open') return x.takenByName || '—';
      tx.update(ref, { status: 'taken', takenAt: serverTimestamp(), takenBy: me.uid, takenByName: me.name });
      return null;
    });
  },

  async resolveAlert(alertId, me) {
    await updateDoc(doc(db, 'alerts', alertId), { status: 'resolved', resolvedAt: serverTimestamp(), resolvedBy: me.uid, resolvedByName: me.name });
  },

  async cancelAlert(alertId) {
    await updateDoc(doc(db, 'alerts', alertId), { status: 'cancelled', cancelledAt: serverTimestamp() });
  },

  async startDuty(uid, storeId, untilMs) {
    await updateDoc(doc(db, 'users', uid), { onDuty: true, dutyStoreId: storeId, dutyUntil: Timestamp.fromMillis(untilMs) });
  },

  async endDuty(uid) { await updateDoc(doc(db, 'users', uid), { onDuty: false, dutyUntil: deleteField() }); },

  async saveLang(uid, lang) { try { await updateDoc(doc(db, 'users', uid), { lang }); } catch (e) { /* non bloquant */ } },
};
