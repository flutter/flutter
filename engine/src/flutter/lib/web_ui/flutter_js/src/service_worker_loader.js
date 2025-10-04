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
   * default Flutter service worker. It will do nothing and resolve immediately.
   * @param {import("./types").ServiceWorkerSettings} settings Service worker settings
   * @returns {Promise<void>} A promise that resolves immediately.
   */
  loadServiceWorker(settings) {
    // We will no longer register, update, or wait for any service worker.
    // We simply log a warning for developers and return a resolved promise.

    if (settings) {
      // This warning will appear in the developer console if the app tries
      // to call the loader with any service worker configuration.
      console.warn(
        `[Flutter] Service worker registration has been disabled in flutter.js.
        The 'serviceWorkerSettings' option is no longer used.
        To install a service worker, you must now do so manually in your index.html.
        For more information, see: https://flutter.dev/go/web-cleanup-service-worker`
      );
    }

    return Promise.resolve();
  }
}
