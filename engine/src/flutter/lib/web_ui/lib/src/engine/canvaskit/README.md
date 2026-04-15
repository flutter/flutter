# CanvasKit Engine Implementation

This directory contains the CanvasKit-based implementation of the Flutter web engine. CanvasKit is a WebAssembly (Wasm) build of the Skia graphics library, which is the same rendering engine used by Flutter on mobile and desktop platforms. Using CanvasKit on the web provides high-performance rendering and ensures visual consistency with other Flutter platforms.

The files in this directory wrap the CanvasKit JavaScript/Wasm API and provide implementations for the core `dart:ui` interfaces used by the Flutter framework.

## Architecture and Naming Conventions

The implementation involves multiple layers of wrapping:

1.  **Skia C++**: The underlying graphics engine written in C++.
2.  **CanvasKit (JS/Wasm)**: A JavaScript wrapper around the Skia C++ classes, delivered as a WebAssembly module.
3.  **JS-Interop Bindings (`Sk*` prefixes)**: In `canvaskit_api.dart`, we define Dart types that map to the CanvasKit JavaScript classes using `dart:js_interop`. We typically use the `Sk` prefix for these (e.g., `SkPath` is a binding for the JavaScript `CanvasKit.Path` class).
4.  **Engine Implementation (`Ck*` prefixes)**: These are the high-level Dart classes (e.g., `CkPath`) that implement Flutter's `engine.dart` interfaces. They wrap the `Sk*` interop types and manage their lifecycle (e.g., reference counting and deletion of Wasm memory).

## Files

- **`canvas.dart`**: Implements `CkCanvas`, the CanvasKit-specific wrapper for Skia's `SkCanvas` which executes drawing commands.
- **`canvaskit_api.dart`**: Provides the low-level `dart:js_interop` bindings for the CanvasKit JavaScript API.
- **`color_filter.dart`**: Implements color filters (`CkColorFilter`) and manages the lifecycle of the underlying `SkColorFilter` objects.
- **`fonts.dart`**: Manages `SkiaFontCollection`, handling font registration for use with CanvasKit. It implements the necessary platform-specific APIs (via `SkiaFallbackRegistry`) to integrate with the engine's font fallback logic.
- **`image.dart`**: Implements `CkImage` (wrapping `SkImage`) and provides logic for image decoding, scaling, and conversion to byte data.
- **`image_filter.dart`**: Implements image filters (`CkImageFilter`) such as blur, matrix transforms, and filter composition.
- **`image_wasm_codecs.dart`**: Implements image codecs using the decoders provided directly within the CanvasKit Wasm bundle.
- **`image_web_codecs.dart`**: Implements image codecs that leverage the browser's native `ImageDecoder` API for better performance when available.
- **`mask_filter.dart`**: Provides utilities for creating Skia mask filters, primarily used for blur effects on paints.
- **`native_memory.dart`**: Implements reference counting and lifecycle management (`CkUniqueRef`, `CkCountedRef`) for native Wasm objects to prevent memory leaks.
- **`painting.dart`**: Implements `CkPaint`, wrapping Skia's `SkPaint` to manage drawing attributes like colors, styles, and shaders.
- **`path.dart`**: Implements `CkPath`, the CanvasKit wrapper for Skia's `SkPath` used for defining vector shapes.
- **`path_metrics.dart`**: Implements `CkPathMetrics` and related classes for measuring paths and extracting segments.
- **`picture.dart`**: Implements `CkPicture`, wrapping Skia's `SkPicture` which stores recorded drawing operations.
- **`picture_recorder.dart`**: Implements `CkPictureRecorder` used to capture drawing commands into a `CkPicture`.
- **`renderer.dart`**: Implements `CanvasKitRenderer`, the CanvasKit implementation of the engine's `Renderer` abstraction (defined in `lib/src/engine/renderer.dart`). It coordinates the initialization and operation of the CanvasKit backend.
- **`shader.dart`**: Implements various gradient and image shaders (`CkShader`) wrapping Skia's `SkShader` API.
- **`surface.dart`**: Manages the rendering surface (`CkSurface`), including WebGL context acquisition, resizing, and software rendering fallbacks.
- **`text.dart`**: Implements the text layout and styling engine, including `CkParagraph`, `CkTextStyle`, and `CkParagraphBuilder`.
- **`util.dart`**: Contains general utility functions for CanvasKit, such as color conversions and shadow drawing logic.
- **`vertices.dart`**: Implements `CkVertices` for rendering triangle meshes and custom vertex data.
