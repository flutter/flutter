# Skwasm Raw FFI Bindings

This directory contains the low-level Dart FFI (Foreign Function Interface) bindings to the Skwasm module, which is a Skia-based rendering engine compiled to WebAssembly. These files define the `Opaque` handles and `external` functions that map directly to the C++ implementation in the Skwasm WASM module.

## Purpose

The bindings in this directory provide a direct, low-level bridge between the Flutter Web engine's Dart code and the Skia-based C++ rendering engine. This allows the engine to perform high-performance 2D graphics, complex text layout, and image manipulation by leveraging Skia's capabilities directly within the browser via WebAssembly.

## Subdirectories

- **`text/`**: Contains specialized FFI bindings for the text layout engine, including paragraph building, styling, and line metrics.

## Files

- **`raw_animated_image.dart`**: Bindings for managing animated images, including frame decoding, repetition count, and frame duration management.
- **`raw_canvas.dart`**: Bindings for the `SkCanvas` API, providing a wide range of drawing operations such as drawing lines, shapes, images, paths, and paragraphs, as well as transformation and clipping operations.
- **`raw_filters.dart`**: Bindings for creating and managing image filters (blur, dilate, erode), color filters (matrix, mode, SRGB/linear conversion), and mask filters (blur).
- **`raw_fonts.dart`**: Bindings for font management, including creating font collections, registering typefaces from raw data, and filtering code points.
- **`raw_geometry.dart`**: Defines type aliases for raw pointers to geometric data structures like rects, rrects, matrices, and point arrays.
- **`raw_image.dart`**: Bindings for `SkImage`, allowing for image creation from pictures, raw pixels, or WebGL textures.
- **`raw_memory.dart`**: Provides utilities for managing WebAssembly memory, including stack allocation and helper methods to convert between Dart types (like `ui.Rect`, `ui.RRect`, and `Float64List`) and their native representations.
- **`raw_paint.dart`**: Bindings for `SkPaint`, used to define the style, color, and filters for drawing operations.
- **`raw_path.dart`**: Bindings for `SkPath`, providing comprehensive tools for creating and manipulating vector paths (lines, quads, cubics, conics, arcs, etc.).
- **`raw_path_metrics.dart`**: Bindings for measuring path contours, calculating length, and extracting segments from existing paths.
- **`raw_picture.dart`**: Bindings for `SkPicture` and `SkPictureRecorder`, used to record sequences of drawing commands for later playback or conversion to images.
- **`raw_shaders.dart`**: Bindings for creating shaders, including linear, radial, conical, and sweep gradients, as well as runtime effects (custom Shaders) and uniform data management.
- **`raw_skdata.dart`**: Bindings for `SkData`, representing immutable data buffers used throughout the Skia API.
- **`raw_skstring.dart`**: Bindings for `SkString` (UTF-8) and `SkString16` (UTF-16), used for efficient string passing between Dart and the WASM module.
- **`raw_surface.dart`**: Bindings for `SkSurface` and the underlying GPU context, managing the rendering target and synchronization with the browser's HTML canvas.
- **`raw_vertices.dart`**: Bindings for `SkVertices`, enabling the rendering of custom meshes with positions, colors, and texture coordinates.
- **`skwasm_module.dart`**: Core bindings for interacting with the Skwasm WebAssembly instance, memory, and module-level configuration (e.g., multi-threading status).
