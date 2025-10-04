// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * Handles loading/reloading Flutter's service worker, if configured.
 *
 * @see: https://developers.google.com/web/fundamentals/primers/service-workers
 */
export class FlutterServiceWorkerLoader {
  /**
   * Injects a TrustedTypesPolicy (or undefined if the feature is not supported).
   * @param {TrustedTypesPolicy | undefined} policy
   */
  setTrustedTypesPolicy(policy) {
    this._ttPolicy = policy;
  }
  /**
   * Disables service worker registration from flutter.js. This is now a no-op,
   * and a warning will be logged if any `settings` are provided.
   * @param {import("./types").ServiceWorkerSettings} settings Service worker settings
   * @returns {Promise<void>} that resolves immediately
   */
  loadServiceWorker(settings) {
    if (settings) {
      console.warn(`Service worker registration has been disabled in flutter.js.
        The 'serviceWorkerSettings' option is no longer used.
        To install a service worker, you must now do so manually in your index.html.
        For more information, see: https://flutter.dev/go/web-cleanup-service-worker`);
    }
    return Promise.resolve();
  }
}
