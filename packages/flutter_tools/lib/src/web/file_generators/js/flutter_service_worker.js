'use strict';

const OLD_CACHE_NAMES = ['flutter-app-manifest', 'flutter-app-cache', 'flutter-temp-cache'];

self.addEventListener('install', () => {
  self.skipWaiting();
  console.log('Deprecated service worker installed. It will not be used.');
});

// remove old caches and unregister the service worker
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        const deletePromises = OLD_CACHE_NAMES.map((key) => self.caches.delete(key));
        await Promise.all(deletePromises);
      } catch (e) {
        console.warn('Failed to delete old service worker caches:', e);
      }

      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('Failed to unregister service worker:', e);
      }

      try {
        const clients = await self.clients.matchAll({
          type: 'window',
          includeUncontrolled: true,
        });
        // Reload clients to ensure they are not using the old service worker.
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {
        console.warn('Failed to navigate service worker clients:', e);
      }
    })()
  );
});
