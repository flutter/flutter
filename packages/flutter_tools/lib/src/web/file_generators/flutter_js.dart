// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


/// Generates the flutter.js file.
///
/// flutter.js should be completely static, so **do not use any parameter or
/// environment variable to generate this file**.
String generateFlutterJsFile() {
  return r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

if (!_flutter) {
  var _flutter = {};
}
_flutter.loader = null;

(function() {
  "use strict";
  /**
   * Wraps `promise` in a timeout of the given `duration` in ms.
   *
   * Resolves/rejects with whatever the original `promises` does, or rejects
   * if `promise` takes longer to complete than `duration`. In that case,
   * `debugName` is used to compose a legible error message.
   *
   * If `duration` is <= 0, the original `promise` is returned unchanged.
   * @param {Promise} promise
   * @param {number} duration
   * @param {string} debugName
   * @returns {Promise} a wrapped promise.
   */
  async function timeout(promise, duration, debugName) {
    if (duration <= 0) {
      return promise;
    }
    let _timeoutId;
    const _clock = new Promise((_, reject) => {
      _timeoutId = setTimeout(() => {
        reject(new Error(`${debugName} took more than ${duration}ms to resolve. Moving on.`, {
          cause: timeout,
        }));
      }, duration);
    });

    return Promise.race([promise, _clock]).finally(() => {
      clearTimeout(_timeoutId);
    });
  }

  /**
   * Handles loading/reloading Flutter's service worker, if configured.
   *
   * @see: https://developers.google.com/web/fundamentals/primers/service-workers
   */
  class FlutterServiceWorkerLoader {
    /**
     * Returns a Promise that resolves when the latest Flutter service worker,
     * configured by `settings` has been loaded and activated.
     *
     * Otherwise, the promise is rejected with an error message.
     * @param {*} settings Service worker settings
     * @returns {Promise} that resolves when the latest serviceWorker is ready.
     */
    loadServiceWorker(settings) {
      if (!("serviceWorker" in navigator) || settings == null) {
        // In the future, settings = null -> uninstall service worker?
        return Promise.reject(new Error("Service worker not supported (or configured)."));
      }
      const {
        serviceWorkerVersion,
        serviceWorkerUrl = "flutter_service_worker.js?v=" + serviceWorkerVersion,
        timeoutMillis = 4000,
      } = settings;

      const serviceWorkerActivation = navigator.serviceWorker.register(serviceWorkerUrl)
        .then(this._getNewServiceWorker)
        .then(this._waitForServiceWorkerActivation);

        // Timeout race promise
      return timeout(serviceWorkerActivation, timeoutMillis, "prepareServiceWorker");
    }

    /**
     * Returns the latest service worker for the given `serviceWorkerRegistrationPromise`.
     *
     * This might return the current service worker, if there's no new service worker
     * awaiting to be installed/updated.
     *
     * @param {Promise<ServiceWorkerRegistration>} serviceWorkerRegistrationPromise
     * @returns {Promise<ServiceWorker?>}
     */
    async _getNewServiceWorker(serviceWorkerRegistrationPromise) {
      const reg = await serviceWorkerRegistrationPromise;

      if (!reg.active && (reg.installing || reg.waiting)) {
        // No active web worker and we have installed or are installing
        // one for the first time. Simply wait for it to activate.
        console.debug("Installing/Activating first service worker.");
        return reg.installing || reg.waiting;
      } else if (!reg.active.scriptURL.endsWith(serviceWorkerVersion)) {
        // When the app updates the serviceWorkerVersion changes, so we
        // need to ask the service worker to update.
        return reg.update().then((newReg) => {
          console.debug("Updating service worker.");
          return newReg.installing || newReg.waiting || newReg.active;
        });
      } else {
        console.debug("Loading from existing service worker.");
        return reg.active;
      }
    }

    /**
     * Returns a Promise that resolves when the `latestServiceWorker` changes its
     * state to "activated".
     *
     * @param {Promise<ServiceWorker>} latestServiceWorkerPromise
     * @returns {Promise<void>}
     */
    async _waitForServiceWorkerActivation(latestServiceWorkerPromise) {
      const serviceWorker = await latestServiceWorkerPromise;

      if (!serviceWorker || serviceWorker.state == "activated") {
        if (!serviceWorker) {
          return Promise.reject(new Error("Cannot activate a null service worker!"));
        } else {
          console.debug("Service worker already active.");
          return Promise.resolve();
        }
      }
      return new Promise((resolve, _) => {
        serviceWorker.addEventListener("statechange", () => {
          if (serviceWorker.state == "activated") {
            console.debug("Activated new service worker.");
            resolve();
          }
        });
      });
    }
  }

  class FlutterLoader {
    /**
     * Creates a FlutterLoader, and initializes its instance methods.
     */
    constructor() {
      // TODO: Move the below methods to "#private" once supported by all the browsers
      // we support. In the meantime, we use the "revealing module" pattern.

      // Watchdog to prevent injecting the main entrypoint multiple times.
      this._scriptLoaded = null;

      // Resolver for the pending promise returned by loadEntrypoint.
      this._didCreateEngineInitializerResolve = null;

      // TODO: Make FlutterLoader extend EventTarget once Safari is mature enough
      // to support EventTarget() constructor.
      // @see: https://caniuse.com/mdn-api_eventtarget_eventtarget
      this._eventTarget = document.createElement("custom-event-target");

      // The event of the synthetic CustomEvent that we use to signal that the
      // entrypoint is loaded.
      this._eventName = "flutter:entrypoint-loaded";

      // Called by Flutter web.
      // Bound to `this` now, so "this" is preserved across JS <-> Flutter jumps.
      this.didCreateEngineInitializer = this._didCreateEngineInitializer.bind(this);
    }

    /**
     * Initializes the main.dart.js with/without serviceWorker.
     * @param {*} options
     * @returns a Promise that will eventually resolve with an EngineInitializer,
     * or will be rejected with the error caused by the loader.
     */
    async loadEntrypoint(options) {
      const {
        entrypointUrl = "main.dart.js",
        serviceWorker,
      } = (options || {});

      try {
        // This method could be injected as loadEntrypoint config instead, also
        // dynamically imported when this becomes a ESModule.
        await new FlutterServiceWorkerLoader().loadServiceWorker(serviceWorker);
      } catch (e) {
        // Regardless of what happens with the injection of the SW, the show must go on
        console.warn(e);
      }
      // This method could also be configurable, to attach new load techniques
      return this._loadEntrypoint(entrypointUrl);
    }

    /**
     * Registers a listener for the entrypoint-loaded events fired from this loader.
     *
     * @param {Function} entrypointLoadedCallback
     * @returns {undefined}
     */
    onEntrypointLoaded(entrypointLoadedCallback) {
      this._eventTarget.addEventListener(this._eventName, entrypointLoadedCallback);
      // Disable the promise resolution
      this._didCreateEngineInitializerResolve = null;
    }

    /**
     * Resolves the promise created by loadEntrypoint once, and dispatches an
     * `this._eventName` event.
     *
     * Called by Flutter through the public `didCreateEngineInitializer` method,
     * which is bound to the correct instance of the FlutterLoader on the page.
     * @param {Function} engineInitializer
     */
    _didCreateEngineInitializer(engineInitializer) {
      if (typeof this._didCreateEngineInitializerResolve == "function") {
        this._didCreateEngineInitializerResolve(engineInitializer);
        // Remove the resolver after the first time, so Flutter Web can hot restart.
        this._didCreateEngineInitializerResolve = null;
      }
      this._eventTarget.dispatchEvent(new CustomEvent(this._eventName, {
        detail: engineInitializer
      }));
    }

    _loadEntrypoint(entrypointUrl) {
      if (!this._scriptLoaded) {
        console.debug("Injecting <script> tag.");
        this._scriptLoaded = new Promise((resolve, reject) => {
          let scriptTag = document.createElement("script");
          scriptTag.src = entrypointUrl;
          scriptTag.type = "application/javascript";
          // Cache the resolve, so it can be called from Flutter.
          // Note: Flutter hot restart doesn't re-create this promise, so this
          // can only be called once. Use onEngineInitialized for a stream of
          // engineInitialized events, that handle hot restart better!
          this._didCreateEngineInitializerResolve = resolve;
          scriptTag.addEventListener("error", reject);
          document.body.append(scriptTag);
        });
      }

      return this._scriptLoaded;
    }
  }

  _flutter.loader = new FlutterLoader();
}());
''';
}
