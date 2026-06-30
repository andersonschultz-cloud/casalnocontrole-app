// Service Worker — cacheia apenas a casca estática do app (HTML/CSS/JS/ícones).
// Os dados financeiros vêm sempre do Supabase pela rede, nunca do cache,
// para garantir que o casal sempre veja a informação mais atual.
const CACHE = 'patrimonio-v10-burn-logo-toast-fix';
const SHELL = ['./', './index.html', './config.js', './manifest.json', './icon.svg', './icon-192.png', './icon-512.png', './logoburn.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Nunca interceptar chamadas ao Supabase — sempre rede, sempre dado fresco.
  if (url.hostname.endsWith('supabase.co') || url.hostname.endsWith('supabase.in')) return;
  // Shell estático: cache-first com fallback de rede.
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request).catch(() => caches.match('./index.html')))
  );
});
