const CACHE_NAME = 'nabra-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      // Gracefully fetch and pre-cache essential pages
      return cache.addAll(urlsToCache).catch(() => {});
    })
  );
});

self.addEventListener('fetch', (event) => {
  // Simple network-first state fallback
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
});
