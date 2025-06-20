'use strict';

// This list of all possible cache names created by the old service worker.
const OLD_CACHE_NAMES = [
  'flutter-app-cache',
  'flutter-temp-cache',
  'flutter-app-manifest'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

// The `activate` event cleans up old caches and unregisters the service worker.
self.addEventListener('activate', (event) => {
  console.log('[Cleanup Service Worker] Activating to remove old caches and unregister.');

  event.waitUntil(
    (async () => {
      try {
        const deletePromises = OLD_CACHE_NAMES.map(key => self.caches.delete(key));

        await Promise.all(deletePromises);
        console.log('[Cleanup Service Worker] Successfully deleted old caches.');
      } catch (e) {
        console.error('[Cleanup Service Worker] Error while deleting caches:', e);
      }

      try {
        const unregistered = await self.registration.unregister();
        if (unregistered) {
          console.log('[Cleanup Service Worker] Successfully unregistered itself.');
        } else {
          console.log('[Cleanup Service Worker] Unregistration failed.');
        }
      } catch (e) {
        console.error('[Cleanup Service Worker] Error while unregistering:', e);
      }

      // Instruct all open tabs to reload, so they can start using the new service worker.
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
        console.log('[Cleanup Service Worker] Instructed all open tabs to reload.');
      } catch (e) {
        console.error('[Cleanup Service Worker] Error while reloading clients:', e);
      }
    })()
  );
});