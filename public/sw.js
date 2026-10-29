// Service worker : rend la web app installable (« Installer l'app ») et
// utilisable si le réseau coupe un instant. Toujours la version en ligne d'abord.
const CACHE = 'alerte-caisse-v2';
const SHELL = ['/app.html', '/js/app.js', '/js/backend-firebase.js', '/js/firebase-config.js',
  '/icons/manager-192.png', '/icons/caisse-192.png'];
self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).catch(() => {}).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', (e) => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;
  e.respondWith(
    fetch(req).then((res) => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
      return res;
    }).catch(() => caches.match(req).then((m) => m || (req.mode === 'navigate' ? caches.match('/app.html') : Response.error()))),
  );
});
