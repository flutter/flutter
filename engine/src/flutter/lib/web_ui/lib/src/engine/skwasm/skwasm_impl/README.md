# Skwasm Implementation

This directory contains the Dart implementation of the Flutter Web engine's `dart:ui` layer using the Skwasm renderer. Skwasm is a Skia-based rendering engine compiled to WebAssembly (WASM).

## Purpose

The files in this directory bridge the high-level Flutter framework APIs (defined in `dart:ui`) with the low-level Skia graphics library running in WebAssembly. This implementation leverages Dart FFI (Foreign Function Interface) to call directly into the Skwasm WASM module, providing high-performance 2D graphics, complex text layout, and advanced rendering features like custom shaders and filters.

## Subdirectories

- **`raw/`**: Contains the low-level Dart FFI bindings and opaque handles that map directly to the Skwasm WASM module's C++ API.

## Files

- **`canvas.dart`**: Implements `SkwasmCanvas`, which translates Flutter's `Canvas` API calls into Skia drawing commands via FFI.
- **`codecs.dart`**: Provides image decoding functionality, including `SkwasmAnimatedImageDecoder` and decoders that leverage browser APIs for Skwasm.
- **`filters.dart`**: Implements various image, color, and mask filters (e.g., blur, matrix, color mode) by wrapping Skia's native filter objects.
- **`font_collection.dart`**: Manages fonts and typefaces for the Skwasm renderer, including font registration, asset loading, and fallback logic.
- **`image.dart`**: Implements `SkwasmImage`, a reference-counted wrapper around a native Skia image (`SkImage`).
- **`memory.dart`**: Defines `SkwasmObjectWrapper`, a base class for managing the lifecycle and finalization of native Skia objects and their FFI handles.
- **`paint.dart`**: Implements `SkwasmPaint`, which stores drawing style information and converts it to a native Skia paint object (`SkPaint`) for drawing operations.
- **`paragraph.dart`**: Contains the implementation of text layout and styling (Paragraph, ParagraphBuilder, TextStyle, etc.), combining FFI bindings with browser-based text segmentation.
- **`path.dart`**: Implements `SkwasmPath`, providing comprehensive vector graphics operations by wrapping Skia's `SkPath`.
- **`path_metrics.dart`**: Provides utilities for measuring path contours and extracting segments from `SkwasmPath` objects.
- **`picture.dart`**: Implements `SkwasmPicture` and `SkwasmPictureRecorder` for recording and playing back sequences of drawing commands.
- **`renderer.dart`**: The central entry point for the Skwasm renderer, implementing the `Renderer` interface and providing factory methods for all Skwasm-based UI objects.
- **`shaders.dart`**: Implements gradients (linear, radial, sweep, conical), image shaders, and custom fragment programs using Skia's runtime effects (SkSL).
- **`surface.dart`**: Manages the rendering target (HTML `OffscreenCanvas`) and coordinates the rasterization process between Dart and the WASM module, including handling context loss.
- **`vertices.dart`**: Implements `SkwasmVertices` for rendering custom triangle meshes with positions, colors, and texture coordinates.
