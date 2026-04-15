# Flutter Web Engine Internal Implementation (`lib/src`)

This directory contains the internal implementation of the Flutter web engine. It houses the core logic that bridges the gap between the `dart:ui` API (used by the Flutter framework) and the web browser environment (DOM, WebGL, WebAssembly, etc.).

The code in this directory is not intended to be used directly by Flutter developers. Instead, it is transformed during the build process into the `dart:_engine` library, which provides the low-level primitives that the web-specific implementation of `dart:ui` relies on.

## Purpose

The primary purpose of this directory is to provide a comprehensive, high-performance, and accessible implementation of the Flutter engine for the web. This includes:

*   **Rendering Backends**: High-performance rendering strategies including CanvasKit (Skia-based WASM) and Skwasm (optimized for `dart2wasm`).
*   **Platform Integration**: Bridging browser-level events (lifecycle, media queries, focus, pointer/keyboard/touch) to Flutter's internal systems.
*   **Text Layout and Editing**: Implementing complex text layout either through browser APIs or Skia-based engines, and managing native-like text editing via hidden DOM elements.
*   **Accessibility**: Translating Flutter's semantics tree into a fully accessible ARIA-compliant DOM structure.
*   **Platform Views**: Enabling the seamless embedding of native HTML elements (like maps and videos) within the Flutter scene.
*   **Navigation**: Synchronizing Flutter's routing with the browser's History API.

## Subdirectories

- **`engine/`**: Contains the bulk of the engine implementation, organized into specialized modules:
    - **`canvaskit/`**: Skia-based rendering using WebAssembly.
    - **`compositing/`**: Logic for grouping and rasterizing scenes.
    - **`js_interop/`**: Dart-to-JavaScript communication layer.
    - **`layer/`**: The layer-based rendering system (Clip, Opacity, Transform, etc.).
    - **`mouse/`**, **`navigation/`**, **`pointer_binding/`**: Platform event handling and integration.
    - **`platform_dispatcher/`**: Bridges browser events to the `PlatformDispatcher`.
    - **`platform_views/`**: Support for embedding HTML elements.
    - **`semantics/`**: ARIA-based accessibility system.
    - **`services/`**: Messaging and serialization infrastructure.
    - **`skwasm/`**: High-performance WASM-based renderer for `dart2wasm`.
    - **`text/`**, **`text_editing/`**, **`web_paragraph/`**: Comprehensive text support.
    - **`view_embedder/`**: DOM management and embedding strategies.

## Files

- **`engine.dart`**: The main entry point for the internal web engine library. It exports all the internal engine components from the `engine/` subdirectory. During the build process, this file is transformed into a single library with part files (`dart:_engine`) by the `sdk_rewriter.dart` tool. It handles the mapping of internal engine classes to the names expected by the framework.
