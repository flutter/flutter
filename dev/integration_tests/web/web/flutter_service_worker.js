'use strict';
const OLD_CACHE_PREFIX = 'flutter-';
self.addEventListener('install', (event) => {
  self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        const cacheKeys = await self.caches.keys();
        const oldCacheKeys = cacheKeys.filter(key => key.startsWith(OLD_CACHE_PREFIX));
        const deletePromises = oldCacheKeys.map(key => self.caches.delete(key));
        await Promise.all(deletePromises);
      } catch (e) {
        // Ignore errors.
      }
      try {
        await self.registration.unregister();
      } catch (e) {
        // Ignore errors.
      }
      try {
        const clients = await self.clients.matchAll({
          type: 'window',
          includeUncontrolled: true,
        });
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {
        // Ignore errors.
      }
    })()
  );
});
