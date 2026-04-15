# Flutter Web Engine

This directory contains the source code for the **Flutter Web Engine**. It is responsible for implementing the `dart:ui` library for the web platform, providing the bridge between the Flutter framework and the browser's low-level APIs (DOM, Canvas, WebGL, and WebAssembly).

## Purpose

The Flutter Web Engine handles rendering, text layout, accessibility, and platform integration for Flutter applications running in a web browser. It currently supports two primary rendering backends:

*   **CanvasKit Renderer:** Uses Skia compiled to WebAssembly via Emscripten to provide a more consistent rendering experience with Flutter mobile and desktop.
*   **Skwasm Renderer:** A high-performance renderer that leverages WebAssembly and Skia's newer Wasm-native bindings.

Development and testing in this directory are primarily managed using the `felt` (Flutter Engine Local Tester) tool, located in the `dev/` directory.

## Directory Structure

*   **`dev/`**: Contains the `felt` tool and other developer utilities for building and testing the engine.
*   **`flutter_js/`**: The JavaScript bootstrap logic that initializes and loads the Flutter engine in the browser.
*   **`lib/`**: The Dart implementation of the `dart:ui` and `dart:ui_web` libraries.
*   **`test/`**: A comprehensive suite of unit, golden (screenshot), and integration tests.

## Root Files

- **`analysis_options.yaml`**: Defines the static analysis rules and lints applied to the Dart code in this project to ensure code quality and consistency.
- **`CODE_CONVENTIONS.md`**: Documents the specific naming and structural conventions used within the web engine (e.g., prefixing CanvasKit wrappers with `Ck`).
- **`CONTRIBUTING.md`**: Provides guidance for developers looking to contribute to the web engine, including environment setup and how to use `felt`.
- **`dart_test_{chrome,edge,firefox,safari}.yaml`**: Browser-specific configuration files for running Dart tests in their respective browser environments.
- **`pubspec.yaml`**: The standard Dart package manifest that defines the project's dependencies, environment constraints, and metadata.
