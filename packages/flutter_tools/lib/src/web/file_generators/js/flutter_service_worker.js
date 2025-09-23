'use strict';

const OLD_CACHE_NAMES = [
  'flutter-app-cache',
  'flutter-temp-cache',
  'flutter-app-manifest',
];

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        const deletePromises = OLD_CACHE_NAMES.map((key) => self.caches.delete(key));
        await Promise.all(deletePromises);
      } catch (e) {
        console.warn('Failed to delete old caches:', e);
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

        for (const client of clients) {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        }
      } catch (e) {
        console.warn('Failed to navigate clients:', e);
      }
    })()
  );
});
