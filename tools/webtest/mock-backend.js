// Base simulée pour tester la web app (même interface que public/js/backend-firebase.js).
// Partagée entre onglets via localStorage, avec les mêmes contrôles que les règles Firestore.
(function () {
  const KEY = 'mockdb';
  const now = () => Date.now();
  const seed = () => ({
    accounts: {
      'u-meya': { email: 'meya@gmail.com', pw: 'caisse123' },
      'u-honey': { email: 'honey@gmail.com', pw: 'manager123' },
      'u-ceda': { email: 'ceda@test.app', pw: 'manager456' },
    },
    logins: { meya: 'meya@gmail.com', honey: 'honey@gmail.com', ceda: 'ceda@test.app' },
    users: {
      'u-meya': { name: 'Meya', role: 'cashier', loginId: 'meya' },
      'u-honey': { name: 'Honey', role: 'manager', storeIds: ['km01', 'km06', 'km14'], lang: 'fr', loginId: 'honey' },
      'u-ceda': { name: 'Ceda', role: 'manager', storeIds: ['km06'], loginId: 'ceda' },
    },
    stores: Object.fromEntries([[1,'Gombe'],[3,'Kabambare'],[4,'Bandalungwa'],[5,'Ngaliema'],[6,'Limete'],[7,'Kitambo'],[8,'Victoire'],[9,'Ozone'],[10,'Masina'],[11,'Matadi'],[13,'Triangle'],[14,'Lemba'],[15,'City Moderne'],[16,'Boulevard'],[17,'Mimosa'],[18,'Kapela'],[20,'Cell Point'],[21,'Bon Marché'],[22,'Boma'],[23,'Kingasani'],[24,'Tata Raphel'],[28,'Bibwa'],[29,'Debonhomme'],[32,'Righini'],[35,'Mont-Ngafula'],[36,'Selembao'],[39,'La Promenade'],[40,'Matate'],[45,'Coca Matadi'],[46,'Kasa Vubu'],[48,'Pompage'],[67,'Lingwala'],[68,'Kim Pese'],[70,'Super Lemba'],[74,'Aqua Splash'],[75,'Kabambare'],[76,'Mariano'],[77,'Entrée Plaza'],[78,'Terre Jaune'],[81,'UPN']].map(([n,x]) => { const c = String(n).padStart(2,'0'); return ['km'+c, { name: 'KM '+c+' · '+x }]; })),
    alerts: {},
    seq: 1,
  });
  const load = () => { try { return JSON.parse(localStorage.getItem(KEY)) || seed(); } catch (e) { return seed(); } };
  let db = load();
  const listeners = new Set();
  const save = () => { localStorage.setItem(KEY, JSON.stringify(db)); listeners.forEach((f) => { try { f(); } catch (e) { console.error(e); } }); };
  window.addEventListener('storage', (e) => { if (e.key === KEY) { db = load(); listeners.forEach((f) => f()); } });
  const watch = (fn) => { const f = () => fn(); listeners.add(f); setTimeout(f, 10); return () => listeners.delete(f); };
  const err = (code) => { const e = new Error(code); e.code = code; return e; };
  const delay = (v) => new Promise((r) => setTimeout(() => r(v), 30));
  const prof = (uid) => { const u = db.users[uid]; if (!u) return null; return { uid, name: u.name, role: u.role, register: String(u.register || ''), storeId: u.storeId || '', storeIds: u.storeIds || [], onDuty: !!u.onDuty, dutyStoreId: u.dutyStoreId || null, dutyUntil: u.dutyUntil || null, lang: u.lang || null, loginId: u.loginId || null }; };
  let authCb = null;
  const session = () => sessionStorage.getItem('mockuid');
  const emitAuth = () => { const uid = session(); authCb && authCb(uid ? { uid, email: db.accounts[uid].email } : null); };
  const me = () => { const uid = session(); if (!uid) throw err('permission-denied'); return uid; };
  const alerts = () => Object.entries(db.alerts).map(([id, a]) => ({ id, ...a }));

  window.__ALERTE_BACKEND__ = {
    kind: 'mock',
    onAuth(cb) { authCb = cb; setTimeout(emitAuth, 10); return () => { authCb = null; }; },
    async signIn(login, pw) {
      await delay();
      const l = String(login).trim().toLowerCase();
      let email = l;
      if (!l.includes('@')) { if (!/^[a-z0-9._-]{2,40}$/.test(l)) throw err('invalid-login'); email = db.logins[l]; if (!email) throw err('user-not-found'); }
      const uid = Object.keys(db.accounts).find((k) => db.accounts[k].email === email);
      if (!uid || db.accounts[uid].pw !== pw) throw err('invalid-credential');
      sessionStorage.setItem('mockuid', uid); emitAuth();
    },
    async signOut() { sessionStorage.removeItem('mockuid'); emitAuth(); },
    async changePassword(cur, next) {
      await delay(); const uid = me();
      if (db.accounts[uid].pw !== cur) throw err('invalid-credential');
      if (String(next).length < 6) throw err('weak-password');
      db.accounts[uid].pw = next; save();
    },
    watchProfile(uid, cb) { return watch(() => cb(prof(uid))); },
    async listStores() { return Object.entries(db.stores).map(([id, s]) => ({ id, ...s })).sort((a, b) => a.id.localeCompare(b.id)); },
    watchStore(id, cb) { return watch(() => cb(db.stores[id] ? { id, ...db.stores[id] } : null)); },
    async sendAlert(p, type, message) {
      await delay(); const uid = me(); const u = db.users[uid];
      if (u.role !== 'cashier' || !db.stores[p.storeId]) throw err('permission-denied');
      const id = 'a' + db.seq++;
      db.alerts[id] = { storeId: p.storeId, type: type.key, typeFr: type.fr, typeEn: type.en, message: String(message || '').trim().slice(0, 140), register: String(p.register), cashierId: uid, cashierName: u.name, status: 'open', createdAt: now() };
      save();
    },
    watchMyAlerts(p, cb) { return watch(() => cb(alerts().filter((a) => a.storeId === p.storeId && a.cashierId === p.uid && ['open', 'taken'].includes(a.status)).sort((x, y) => y.createdAt - x.createdAt))); },
    watchActive(storeId, cb) {
      return watch(() => { const u = db.users[session()]; if (!u || !(u.storeIds || []).includes(storeId)) return cb([]); cb(alerts().filter((a) => a.storeId === storeId && ['open', 'taken'].includes(a.status)).sort((x, y) => y.createdAt - x.createdAt)); });
    },
    watchHistory(storeId, cb) { return watch(() => cb(alerts().filter((a) => a.storeId === storeId).sort((x, y) => y.createdAt - x.createdAt).slice(0, 100))); },
    watchManagersOnDuty(storeId, cb) { return watch(() => cb(Object.keys(db.users).map(prof).filter((u) => u.role === 'manager' && u.onDuty && u.dutyStoreId === storeId && (u.dutyUntil || 0) > now()))); },
    async takeAlert(id, p) {
      await delay(); const uid = me(); const u = db.users[uid]; const a = db.alerts[id];
      if (!a) return '—';
      if (u.role !== 'manager' || !(u.storeIds || []).includes(a.storeId)) throw err('permission-denied');
      if (a.status !== 'open') return a.takenByName || '—';
      Object.assign(a, { status: 'taken', takenAt: now(), takenBy: uid, takenByName: u.name }); save(); return null;
    },
    async resolveAlert(id) { await delay(); const uid = me(); const a = db.alerts[id]; if (!(db.users[uid].storeIds || []).includes(a.storeId)) throw err('permission-denied'); Object.assign(a, { status: 'resolved', resolvedAt: now(), resolvedBy: uid }); save(); },
    async cancelAlert(id) { await delay(); const uid = me(); const a = db.alerts[id]; if (a.cashierId !== uid || a.status !== 'open') throw err('permission-denied'); a.status = 'cancelled'; save(); },
    async startDuty(uid, storeId, until) {
      await delay(); if (me() !== uid) throw err('permission-denied');
      const u = db.users[uid];
      if (!(u.storeIds || []).includes(storeId) || until > now() + 13 * 3600e3) throw err('permission-denied');
      Object.assign(u, { onDuty: true, dutyStoreId: storeId, dutyUntil: until }); save();
    },
    async endDuty(uid) { await delay(); if (me() !== uid) throw err('permission-denied'); const u = db.users[uid]; u.onDuty = false; delete u.dutyUntil; save(); },
    async saveLang(uid, l) { if (session() === uid) { db.users[uid].lang = l; save(); } },
  };
})();
