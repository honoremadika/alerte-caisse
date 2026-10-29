// Test de bout en bout : un onglet « caisse » et un onglet « manager » en même temps.
// node tools/webtest/e2e.mjs <dossier playwright-core> <url de base> <dossier captures>
import path from 'node:path';
import fs from 'node:fs';
const [pwDir, BASE, SHOTS] = process.argv.slice(2);
const { chromium } = await import(path.join(pwDir, 'node_modules/playwright-core/index.mjs'));
fs.mkdirSync(SHOTS, { recursive: true });

const results = [];
const ok = (name, cond, extra = '') => { results.push({ name, ok: !!cond, extra }); console.log((cond ? 'OK   ' : 'FAIL ') + name + (extra ? '  — ' + extra : '')); };
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell', args: ['--autoplay-policy=no-user-gesture-required'] });
const ctx = await browser.newContext({ locale: 'fr-FR' });
await ctx.addInitScript({ path: path.join(path.dirname(new URL(import.meta.url).pathname), 'mock-backend.js') });
const consoleErrors = [];
const watchConsole = (p, label) => { p.on('pageerror', (e) => consoleErrors.push(label + ': ' + e.message)); p.on('console', (m) => { if (m.type() === 'error' && !/ERR_TUNNEL_CONNECTION_FAILED|fonts\.g/.test(m.text())) consoleErrors.push(label + ': ' + m.text()); }); };
const text = (p) => p.evaluate(() => document.body.innerText);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
async function login(p, id, pw) { await p.fill('#lgId', id); await p.fill('#lgPw', pw); await p.click('#loginForm button[type=submit]'); await wait(300); }

// ---------- CAISSE (ordinateur) ----------
const caisse = await ctx.newPage(); watchConsole(caisse, 'caisse');
await caisse.setViewportSize({ width: 1280, height: 800 });
await caisse.goto(BASE + '/app.html?app=caisse');
await caisse.waitForSelector('#loginForm');
ok('Caisse : écran de connexion avec « Identifiant »', (await text(caisse)).includes('Identifiant'));
await caisse.click('#loginForm button[type=submit]'); await wait(150);
ok('Champs vides → message clair', (await text(caisse)).includes('Remplissez l’identifiant et le mot de passe.'));
await login(caisse, 'meya', 'mauvais');
ok('Mauvais mot de passe → refusé', (await text(caisse)).includes('Identifiant ou mot de passe incorrect.'));
await login(caisse, 'inconnu', 'caisse123');
ok('Identifiant inconnu → refusé', (await text(caisse)).includes('Identifiant ou mot de passe incorrect.'));
await login(caisse, 'me ya', 'caisse123');
ok('Identifiant avec espace → format expliqué', (await text(caisse)).includes('Identifiant invalide'));
await login(caisse, 'Meya', 'caisse123');
await caisse.waitForSelector('#postForm', { timeout: 3000 }).catch(() => {});
const nOpts = await caisse.evaluate(() => document.querySelectorAll('#pStore option:not([disabled])').length);
const optTxt = await caisse.evaluate(() => [...document.querySelectorAll('#pStore option')].map((o) => o.textContent).join('|'));
ok('Poste : liste déroulante des 40 magasins', nOpts === 40 && optTxt.includes('KM 01 · Gombe') && optTxt.includes('KM 81 · UPN') && optTxt.includes('KM 06 · Limete'), nOpts + ' magasins');
await caisse.click('#postForm button[type=submit]'); await wait(100);
ok('Poste : magasin obligatoire', (await text(caisse)).includes('Choisissez le magasin'));
await caisse.selectOption('#pStore', 'km06'); await caisse.fill('#pReg', '1');
await caisse.click('#postForm button[type=submit]');
await caisse.waitForSelector('.desk', { timeout: 3000 }).catch(() => {});
let tc = await text(caisse);
ok('Connexion par identifiant (majuscule tolérée)', tc.includes('Caisse 1') && tc.includes('KM 06 · Limete') && tc.includes('Meya'));
ok('Caisse : avertit qu’aucun manager n’est en service', tc.includes('Aucun manager n’est en service'));
ok('Caisse : « Recherche F1 » dans la liste', tc.includes('Recherche F1'));
await caisse.screenshot({ path: SHOTS + '/1-caisse.png' });

// ---------- MANAGER (téléphone) ----------
const mgr = await ctx.newPage(); watchConsole(mgr, 'manager');
await mgr.setViewportSize({ width: 390, height: 844 });
await mgr.goto(BASE + '/app.html?app=manager');
await mgr.waitForSelector('#loginForm');
await login(mgr, 'meya', 'caisse123');
ok('Mauvais rôle : un caissier ne peut pas ouvrir l’app Manager', (await text(mgr)).includes('Ce compte est un compte caissier'));
await mgr.click('[data-act=logout]'); await mgr.waitForSelector('#loginForm');
await login(mgr, 'honey', 'manager123');
await mgr.waitForSelector('#mDuty', { timeout: 3000 }).catch(() => {});
let tm = await text(mgr);
ok('Manager connecté, hors service, liste des magasins', tm.includes('Hors service') && (await mgr.$('#mFirstSel')) !== null);
await mgr.selectOption('#mFirstSel', 'km06');
await mgr.click('[data-act=startSel]'); await wait(400);
tm = await text(mgr);
ok('Prise de service à KM 06', tm.includes('En service · KM 06 · Limete'));
const noOverflow = await mgr.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1);
ok('Manager : pas de débordement horizontal sur téléphone', noOverflow);
await mgr.screenshot({ path: SHOTS + '/2-manager-service.png' });

await wait(300);
tc = await text(caisse);
ok('Caisse voit « Honey » en service en direct', tc.includes('Honey') && !tc.includes('Aucun manager n’est en service'));

// ---------- ALERTE ----------
await caisse.keyboard.press('4');
await caisse.fill('#cMsg', 'Client attend, article 3');
await caisse.click('body', { position: { x: 5, y: 5 } }).catch(() => {});
await caisse.keyboard.press('Control+Enter'); await wait(500);
tc = await text(caisse);
ok('Alerte envoyée (Ctrl+Entrée), en attente', tc.includes('Recherche F1') && tc.includes('En attente d’un manager'));
await mgr.waitForSelector('#alarm:not([hidden])', { timeout: 3000 }).catch(() => {});
const alarmTxt = await mgr.evaluate(() => (document.getElementById('alarm').hidden ? '' : document.getElementById('alarm').innerText));
ok('Le téléphone du manager affiche l’alarme', alarmTxt.includes('Caisse 1') && alarmTxt.includes('Recherche F1') && alarmTxt.includes('Client attend'));
await mgr.screenshot({ path: SHOTS + '/3-manager-alarme.png' });

// Un 2e manager du même magasin, sur un autre appareil
const mgr2 = await ctx.newPage(); watchConsole(mgr2, 'manager2');
await mgr2.setViewportSize({ width: 390, height: 844 });
await mgr2.goto(BASE + '/app.html?app=manager');
await mgr2.evaluate(() => localStorage.removeItem('ac2_lastStore'));
await login(mgr2, 'ceda', 'manager456');
await mgr2.waitForSelector('#mDuty');
await mgr2.selectOption('#mFirstSel', 'km06').catch(() => {});
await mgr2.click('[data-act=startSel]').catch(() => {}); await wait(500);
const a2 = await mgr2.evaluate(() => (document.getElementById('alarm').hidden ? '' : document.getElementById('alarm').innerText));
ok('Le 2e manager (Ceda) sonne aussi', a2.includes('Caisse 1'));

// Honey répond
await mgr.click('#alarm [data-take]'); await wait(600);
const alarmGone = await mgr.evaluate(() => document.getElementById('alarm').hidden);
ok('« J’arrive » arrête l’alarme chez Honey', alarmGone);
const alarmGone2 = await mgr2.evaluate(() => document.getElementById('alarm').hidden);
ok('… et chez Ceda (l’autre manager)', alarmGone2);
const t2 = await text(mgr2);
ok('Ceda voit « Honey arrive »', t2.includes('Honey arrive'));
tc = await text(caisse);
ok('La caisse voit « Honey arrive »', tc.includes('Honey arrive'));
const flash = await caisse.evaluate(() => !document.getElementById('flash').hidden);
ok('La caisse affiche le bandeau vert', flash);
await caisse.screenshot({ path: SHOTS + '/4-caisse-honey-arrive.png' });

// Résolution + historique
await mgr.click('[data-resolve]'); await wait(500);
tm = await text(mgr);
ok('Problème résolu → plus d’alerte en cours', tm.includes('Tout va bien'));
await mgr.click('[data-tab=hist]'); await wait(200);
tm = await text(mgr);
ok('Historique : 1 alerte résolue avec temps de réaction', tm.includes('Résolue') && tm.includes('réaction'));

// Réglages : sonneries
await mgr.click('[data-tab=set]'); await wait(200);
tm = await text(mgr);
ok('Réglages : 6 sonneries + mon son + volume + mot de passe', ['Sirène', 'Téléphone', 'Réveil', 'Urgence', 'Carillon', 'Douce', 'Mon son', 'Volume', 'Changer le mot de passe'].every((w) => tm.includes(w)));
await mgr.check('#tone-carillon'); await wait(200);
ok('Choix de la sonnerie mémorisé', await mgr.evaluate(() => localStorage.getItem('ac2_tone') === '"carillon"'));
await mgr.screenshot({ path: SHOTS + '/5-manager-reglages.png' });

// Changement de poste : une alerte de KM 14 ne fait PAS sonner un manager de KM 06
await caisse.click('[data-act=editPost]'); await caisse.waitForSelector('#postForm');
await caisse.selectOption('#pStore', 'km14'); await caisse.fill('#pReg', '2');
await caisse.click('#postForm button[type=submit]'); await caisse.waitForSelector('.desk');
tc = await text(caisse);
ok('Poste modifié : KM 14 · Lemba, caisse 2', tc.includes('KM 14 · Lemba') && tc.includes('Caisse 2'));
await caisse.keyboard.press('1'); await caisse.click('[data-act=send]'); await wait(600);
const km14ring = await mgr.evaluate(() => !document.getElementById('alarm').hidden);
ok('Alerte de KM 14 : le manager de KM 06 ne sonne pas', !km14ring);
await caisse.click('[data-cancel]'); await wait(400);
await caisse.click('[data-act=editPost]'); await caisse.waitForSelector('#postForm');
await caisse.selectOption('#pStore', 'km06'); await caisse.fill('#pReg', '1');
await caisse.click('#postForm button[type=submit]'); await caisse.waitForSelector('.desk');

// Annulation côté caisse
await caisse.keyboard.press('1'); await caisse.click('[data-act=send]'); await wait(500);
await caisse.click('[data-cancel]'); await wait(500);
tc = await text(caisse);
ok('La caisse peut annuler une alerte envoyée par erreur', tc.includes('Aucune alerte en cours.'));

// ---------- MOT DE PASSE ----------
await caisse.click('[data-act=password]');
await caisse.fill('#pwCur', 'faux'); await caisse.fill('#pwNew', 'nouveau1'); await caisse.fill('#pwNew2', 'nouveau1');
await caisse.click('#pwSave'); await wait(300);
ok('Mot de passe actuel faux → refusé', (await caisse.textContent('#pwErr')).includes('incorrect'));
await caisse.fill('#pwCur', 'caisse123'); await caisse.fill('#pwNew', 'abc'); await caisse.fill('#pwNew2', 'abc');
await caisse.click('#pwSave'); await wait(150);
ok('Nouveau mot de passe trop court → refusé', (await caisse.textContent('#pwErr')).includes('6 caractères'));
await caisse.fill('#pwNew', 'nouveau1'); await caisse.fill('#pwNew2', 'nouveau2');
await caisse.click('#pwSave'); await wait(150);
ok('Confirmation différente → refusée', (await caisse.textContent('#pwErr')).includes('pas identiques'));
await caisse.fill('#pwNew2', 'nouveau1');
await caisse.click('#pwSave'); await wait(400);
ok('Mot de passe changé', (await text(caisse)).includes('Mot de passe modifié.'));
await caisse.click('[data-act=logout]'); await caisse.waitForSelector('#loginForm');
await login(caisse, 'meya', 'caisse123');
ok('Ancien mot de passe ne marche plus', (await text(caisse)).includes('incorrect'));
await login(caisse, 'meya', 'nouveau1');
await caisse.waitForSelector('.desk', { timeout: 3000 }).catch(() => {});
ok('Nouveau mot de passe fonctionne', (await text(caisse)).includes('Caisse 1'));

// ---------- DERNIER MAGASIN + DÉCONNEXION MANAGER ----------
await mgr.click('[data-tab=set]'); await wait(150);
await mgr.click('.group [data-act=logout]'); await mgr.waitForSelector('#loginForm');
await wait(300);
tc = await text(caisse);
ok('Déconnexion du manager → il n’est plus en service', !tc.match(/Managers en service\s*\n\s*Honey/));
await login(mgr, 'honey', 'manager123');
await mgr.waitForSelector('#mDuty');
tm = await text(mgr);
ok('Le téléphone propose le dernier magasin utilisé (KM 06)', tm.includes('Prendre mon service · KM 06 · Limete') && tm.includes('Dernier magasin utilisé'));

// ---------- LANGUE ----------
await caisse.click('[data-lang=en]'); await wait(150);
tc = await text(caisse);
ok('Caisse en anglais', tc.includes('SEND ALERT') && tc.includes('Till 1'));
await caisse.click('[data-lang=fr]');

// ---------- Petit écran caisse ----------
await caisse.setViewportSize({ width: 700, height: 700 }); await wait(150);
ok('Caisse : pas de débordement horizontal en petite fenêtre', await caisse.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1));

// ---------- Même lien : version web + installation (téléphone Android) ----------
const android = await browser.newContext({ locale: 'fr-FR', userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-A145P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36', viewport: { width: 390, height: 844 } });
await android.addInitScript({ path: path.join(path.dirname(new URL(import.meta.url).pathname), 'mock-backend.js') });
const ap = await android.newPage(); watchConsole(ap, 'android');
await ap.goto(BASE + '/app.html?app=manager'); await ap.waitForSelector('#loginForm');
let ta = await text(ap);
ok('Téléphone Android : même page web, lien APK proposé', ta.includes('télécharger le fichier Android (.apk)') && ta.includes('Installer l’application'));
const manifest = await ap.evaluate(() => (document.querySelector('link[rel=manifest]') || {}).href || '');
ok('Manifest de l’app Manager (installable)', manifest.endsWith('/manifest-manager.json'));
await ap.evaluate(() => { const e = new Event('beforeinstallprompt'); e.prompt = async () => { window.__prompted = true; }; e.userChoice = Promise.resolve({ outcome: 'accepted' }); window.dispatchEvent(e); });
await wait(150);
ok('Bouton « Installer l’app sur cet appareil » quand le téléphone le permet', (await text(ap)).includes('Installer l’app sur cet appareil'));
await ap.click('[data-act=install]'); await wait(150);
ok('Le bouton lance l’installation', await ap.evaluate(() => window.__prompted === true));
const mres = await ap.evaluate(async () => { const r = await fetch('/manifest-manager.json'); const j = await r.json(); return j.start_url + '|' + j.display + '|' + j.icons.length; });
ok('Manifest valide (start_url /manager, plein écran, 3 icônes)', mres === '/manager|standalone|3', mres);
await android.close();

ok('Aucune erreur JavaScript', consoleErrors.length === 0, consoleErrors.slice(0, 5).join(' | '));
await browser.close();
const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length}/${results.length} vérifications réussies`);
process.exit(failed.length ? 1 : 0);
