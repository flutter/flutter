// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { browserEnvironment, defaultWasmSupport } from './browser_environment.js';
import { FlutterEntrypointLoader } from './entrypoint_loader.js';
import { FlutterServiceWorkerLoader } from './service_worker_loader.js';
import { FlutterTrustedTypesPolicy } from './trusted_types.js';
import { loadCanvasKit } from './canvaskit_loader.js';
import { loadSkwasm } from './skwasm_loader.js';
import { getCanvaskitBaseUrl } from './utils.js';

const supportsDart2Wasm = browserEnvironment.supportsWasmGC;

/**
 * The public interface of _flutter.loader. Exposes two methods:
 * * loadEntrypoint (which coordinates the default Flutter web loading procedure)
 * * didCreateEngineInitializer (which is called by Flutter to notify that its
 *                              Engine is ready to be initialized)
 */
export class FlutterLoader {
  /**
   * @deprecated Use `load` instead.
   * Initializes the Flutter web app.
   * @param {*} options
   * @returns {Promise?} a (Deprecated) Promise that will eventually resolve
   *                     with an EngineInitializer, or will be rejected with
   *                     any error caused by the loader. Or Null, if the user
   *                     supplies an `onEntrypointLoaded` Function as an option.
   */
  async loadEntrypoint(options) {
    const { serviceWorker, ...entrypoint } = options || {};
    // A Trusted Types policy that is going to be used by the loader.
    const flutterTT = new FlutterTrustedTypesPolicy();
    // The FlutterServiceWorkerLoader instance could be injected as a dependency
    // (and dynamically imported from a module if not present).
    const serviceWorkerLoader = new FlutterServiceWorkerLoader();
    serviceWorkerLoader.setTrustedTypesPolicy(flutterTT.policy);
    await serviceWorkerLoader.loadServiceWorker(serviceWorker).catch(e => {
      // Regardless of what happens with the injection of the SW, the show must go on
      console.warn("Exception while loading service worker:", e);
    });
    // The FlutterEntrypointLoader instance could be injected as a dependency
    // (and dynamically imported from a module if not present).
    const entrypointLoader = new FlutterEntrypointLoader();
    entrypointLoader.setTrustedTypesPolicy(flutterTT.policy);
    // Install the `didCreateEngineInitializer` listener where Flutter web expects it to be.
    this.didCreateEngineInitializer =
      entrypointLoader.didCreateEngineInitializer.bind(entrypointLoader);
    return entrypointLoader.loadEntrypoint(entrypoint);
  }

  /**
   * Loads and initializes a flutter application.
   * @param {Object} options
   * @param {import("/.types".ServiceWorkerSettings?)} options.serviceWorkerSettings
   *   DEPRECATED: Settings for the service worker to be loaded. Can pass `undefined` or
   *   `null` to not launch a service worker at all.
   * @param {import("/.types".OnEntryPointLoadedCallback)} options.onEntrypointLoaded
   *   An optional callback to invoke
   * @param {string} options.nonce
   *   A nonce to be applied to the main JS script when loading it, which may
   *   be required by the sites Content-Security-Policy.
   *   For more details, see {@link https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src here}.
   * @param {import("./types".FlutterConfiguration)} arg.config
   */
  async load({
    serviceWorkerSettings,
    onEntrypointLoaded,
    nonce,
    config,
  } = {}) {
    config ??= {};

    /** @type {import("./types").BuildConfig} */
    const buildConfig = _flutter.buildConfig;
    if (!buildConfig) {
      throw "FlutterLoader.load requires _flutter.buildConfig to be set";
    }

    const enableWasm = config.wasmAllowList?.[browserEnvironment.browserEngine] ?? defaultWasmSupport[browserEnvironment.browserEngine];

    /**
     * Returns null if [renderer] is compatible, or a human-readable string
     * explaining why it isn't.
     */
    const rendererIncompatibilityReason = (renderer) => {
      switch (renderer) {
        case "skwasm":
          if (!supportsDart2Wasm) {
            return "Skwasm requires WasmGC support; this browser does not implement it yet.";
          }
          if (!(browserEnvironment.webGLVersion > 0)) {
            return "Skwasm requires WebGL support; this browser does not provide it.";
          }
          if (!enableWasm) {
            return `Skwasm is disabled by your wasmAllowList configuration for browser engine "${browserEnvironment.browserEngine}".`;
          }
          return null;
        default:
          return null;
      }
    };

    /**
     * Returns null if [build] is compatible, or a human-readable string
     * explaining why it isn't. Used both to filter candidate builds and to
     * log a useful explanation when the loader has to fall back.
     */
    const buildIncompatibilityReason = (build) => {
      if (build.compileTarget === "dart2wasm" && !supportsDart2Wasm) {
        return "dart2wasm requires WasmGC support; this browser does not implement it yet.";
      }
      if (config.renderer && config.renderer != build.renderer) {
        return `The application is configured to use the "${config.renderer}" renderer; this build targets "${build.renderer}".`;
      }
      return rendererIncompatibilityReason(build.renderer);
    };

    let build;
    const skippedBuilds = [];
    for (const candidate of buildConfig.builds) {
      const reason = buildIncompatibilityReason(candidate);
      if (reason === null) {
        build = candidate;
        break;
      }
      skippedBuilds.push({ candidate, reason });
    }

    // Verbose mode: print why each candidate was skipped, regardless of
    // whether a compatible build was eventually found. Useful for debugging
    // "why does it keep falling back to X instead of Y" without staring at
    // a blank screen. Off by default to keep the console quiet for typical
    // production users.
    if (config.verboseBuildSelection && skippedBuilds.length > 0) {
      for (const skipped of skippedBuilds) {
        console.warn(
          `Flutter Web: build ${skipped.candidate.compileTarget}/${skipped.candidate.renderer} was skipped: ${skipped.reason}`
        );
      }
    }

    if (!build) {
      // Failure case: always warn (the page would otherwise be silently blank)
      // and hint at the verbose flag if it isn't already on.
      console.warn(
        "Flutter Web: no compatible build found for this browser." +
        (config.verboseBuildSelection ? "" :
          " Set `verboseBuildSelection: true` in your Flutter configuration to see why each candidate was rejected.")
      );
      throw new Error("FlutterLoader could not find a build compatible with configuration and environment.");
    }

    const deps = {};
    deps.flutterTT = new FlutterTrustedTypesPolicy();
    if (serviceWorkerSettings) {
      deps.serviceWorkerLoader = new FlutterServiceWorkerLoader();
      deps.serviceWorkerLoader.setTrustedTypesPolicy(deps.flutterTT.policy);
      await deps.serviceWorkerLoader.loadServiceWorker(serviceWorkerSettings).catch(e => {
        // Regardless of what happens with the injection of the SW, the show must go on
        console.warn("Exception while loading service worker:", e);
      });
    }

    const canvasKitBaseUrl = getCanvaskitBaseUrl(config, buildConfig);
    if (build.renderer === "canvaskit") {
      deps.canvasKit = loadCanvasKit(deps, config, browserEnvironment, canvasKitBaseUrl);
    } else if (build.renderer === "skwasm") {
      deps.skwasm = loadSkwasm(deps, config, browserEnvironment, canvasKitBaseUrl);
    }

    // The FlutterEntrypointLoader instance could be injected as a dependency
    // (and dynamically imported from a module if not present).
    const entrypointLoader = new FlutterEntrypointLoader();
    entrypointLoader.setTrustedTypesPolicy(deps.flutterTT.policy);
    // Install the `didCreateEngineInitializer` listener where Flutter web expects it to be.
    this.didCreateEngineInitializer =
      entrypointLoader.didCreateEngineInitializer.bind(entrypointLoader);
    return entrypointLoader.load(build, deps, config, nonce, onEntrypointLoaded);
  }
}
