// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * Wraps `promise` in a timeout of the given `duration` in ms.
 *
 * Resolves/rejects with whatever the original `promises` does, or rejects
 * if `promise` takes longer to complete than `duration`. In that case,
 * `debugName` is used to compose a legible error message.
 *
 * If `duration` is < 0, the original `promise` is returned unchanged.
 * @param {Promise} promise
 * @param {number} duration
 * @param {string} debugName
 * @returns {Promise} a wrapped promise.
 */
async function timeout(promise, duration, debugName) {
  if (duration < 0) {
    return promise;
  }
  let timeoutId;
  const _clock = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      reject(
        new Error(
          `${debugName} took more than ${duration}ms to resolve. Moving on.`,
          {
            cause: timeout,
          }
        )
      );
    }, duration);
  });
  return Promise.race([promise, _clock]).finally(() => {
    clearTimeout(timeoutId);
  });
}

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

  /**
   * This method is no longer called by loadServiceWorker.
   */
  async _getNewServiceWorker(serviceWorkerRegistration, serviceWorkerVersion) {
    if (!serviceWorkerRegistration.active && (serviceWorkerRegistration.installing || serviceWorkerRegistration.waiting)) {
      // No active web worker and we have installed or are installing
      // one for the first time. Simply wait for it to activate.
      console.debug("Installing/Activating first service worker.");
      return serviceWorkerRegistration.installing || serviceWorkerRegistration.waiting;
    } else if (!serviceWorkerRegistration.active.scriptURL.endsWith(serviceWorkerVersion)) {
      // When the app updates the serviceWorkerVersion changes, so we
      // need to ask the service worker to update.
      const newRegistration = await serviceWorkerRegistration.update();
      console.debug("Updating service worker.");
      return newRegistration.installing || newRegistration.waiting || newRegistration.active;
    } else {
      console.debug("Loading from existing service worker.");
      return serviceWorkerRegistration.active;
    }
  }

  async _waitForServiceWorkerActivation(serviceWorker) {
    if (!serviceWorker || serviceWorker.state === "activated") {
      if (!serviceWorker) {
        throw new Error("Cannot activate a null service worker!");
      } else {
        console.debug("Service worker already active.");
        return;
      }
    }
    return new Promise((resolve, _) => {
      serviceWorker.addEventListener("statechange", () => {
        if (serviceWorker.state === "activated") {
          console.debug("Activated new service worker.");
          resolve();
        }
      });
    });
  }
}
