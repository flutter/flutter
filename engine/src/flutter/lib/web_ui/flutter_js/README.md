# Flutter Web JavaScript (flutter_js)

This directory contains the JavaScript implementation of the Flutter Web bootstrap process. This library is the first component to run when a Flutter Web application is loaded in a browser. It is responsible for orchestrating the transition from a host HTML page to a running Flutter engine.

## Purpose

The primary goal of `flutter_js` is to provide a robust and configurable loading sequence for Flutter applications. Key responsibilities include environment detection, renderer selection (CanvasKit or Skwasm), asset management, and injecting the compiled Dart entrypoint into the page.

## Subdirectories

- **`src/`**: This directory contains the implementation of the bootstrap process.

## Files

- **`BUILD.gn`**: The GN (Generate Ninja) build file that defines the build targets for the library. It specifies how the source files are bundled using `esbuild` and packaged into the Flutter Web SDK.
- **`sources.gni`**: A GN include file that maintains a centralized list of all JavaScript and TypeScript source files required by the bootstrap library.
