# Flutter Web Bootstrap (flutter_js/src)

This directory contains the JavaScript implementation of the Flutter Web bootstrap process. Its primary purpose is to orchestrate the loading of a Flutter application in the browser, including environment detection, renderer selection, and engine initialization.

## Overview

The code here is responsible for:
1.  **Environment Detection:** Identifying the browser engine and supported features (e.g., Wasm GC, WebGL).
2.  **Configuration Handling:** Processing user-provided and build-time configurations.
3.  **Asset Loading:** Fetching and initializing the necessary engine assets (CanvasKit or Skwasm).
4.  **Entrypoint Injection:** Loading the compiled Dart code (either as JavaScript or WebAssembly).
5.  **Lifecycle Management:** Coordinating the transition from page load to a running Flutter app.

## Files

- **`browser_environment.js`**: Detects browser-specific capabilities such as the rendering engine (Blink, Gecko, Webkit), Wasm GC support, and available WebGL versions.
- **`canvaskit_loader.js`**: Logic for loading the CanvasKit renderer's JavaScript and WebAssembly components, including variant selection (e.g., Chromium-optimized).
- **`entrypoint_loader.js`**: Handles the injection of the main Flutter entrypoint script or Wasm module into the document.
- **`flutter.js`**: The main entry point for the `flutter.js` library; it initializes the global `window._flutter.loader` object.
- **`instantiate_wasm.js`**: A utility helper for fetching and compilation of WebAssembly modules in parallel with their supporting scripts.
- **`loader.js`**: The core `FlutterLoader` class that coordinates the entire bootstrap sequence, build selection, and dependency management.
- **`service_worker_loader.js`**: (Deprecated) Manages the registration, update, and activation of the Flutter service worker.
- **`skwasm_loader.js`**: Specialized loader for the Skwasm renderer, handling multi-threading configuration and worker bootstrapping.
- **`trusted_types.js`**: Implements a Trusted Types policy to validate and secure the URLs used for script and worker injection.
- **`types.d.ts`**: TypeScript type definitions for the internal bootstrap logic and public APIs.
- **`utils.js`**: Common utility functions for URL resolution, path manipulation, and asset base URL calculation.
