'use strict';

// This file is a vestigial self-unregistering cleanup stub.
// Flutter stopped generating an offline caching service worker in
// Flutter 3.41.0 (2026-02-10) and no longer registers or uses a service worker
// by default.
//
// This stub is emitted only so returning browsers that previously visited a
// deployment built with Flutter <= 3.38 (2025-11-11, which registered an
// offline-first caching service worker) can fetch an updated script at
// `/flutter_service_worker.js`, unregister the legacy worker, and purge its
// caches instead of getting stuck serving cached assets when
// `/flutter_service_worker.js` returns 404.
//
// You can safely delete or exclude this file from your deployment unless you
// have returning end-users upgrading from a Flutter <= 3.38 deployment.
// To provide your own service worker, place a custom `flutter_service_worker.js`
// in your project's `web/` directory.
// See https://github.com/flutter/flutter/issues/156910 for more details.

const CACHE_NAMES = [
  'flutter-app-manifest',
  'flutter-temp-cache',
  'flutter-app-cache',
];

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      try {
        await self.registration.unregister();
      } catch (e) {
        console.warn('Failed to unregister the service worker:', e);
      }

      try {
        await Promise.all(
          CACHE_NAMES.map((cacheName) => caches.delete(cacheName)),
        );
      } catch (e) {
        console.warn('Failed to delete legacy service worker caches:', e);
      }

      try {
        const clients = await self.clients.matchAll({
          type: 'window',
        });
        // Reload clients to ensure they are not using the old service worker.
        clients.forEach((client) => {
          if (client.url && 'navigate' in client) {
            client.navigate(client.url);
          }
        });
      } catch (e) {
        console.warn('Failed to navigate some service worker clients:', e);
      }
    })()
  );
});
