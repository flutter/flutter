# Image Decoding in Flutter Web

## Overview

The image decoding system in the Flutter Web engine is designed to provide high-performance, memory-efficient image loading and rendering across a wide variety of browsers. Its primary purpose is to bridge the gap between Flutter's `dart:ui` API and the various image decoding capabilities provided by modern web browsers.

### Implementation Sketch

The system is built on a pluggable architecture that adapts to the active rendering backend (**CanvasKit** or **Skwasm**) and the capabilities of the host browser.

1.  **Backend Abstraction**: The `Renderer` class serves as the entry point. It delegates image codec instantiation to backend-specific implementations, ensuring that the resulting `ui.Image` objects (e.g., `CkImage` or `SkwasmImage`) are compatible with the current rendering pipeline.
2.  **Multi-Path Decoding**:
    *   **WebCodecs (`ImageDecoder` API)**: The primary, high-performance path. It uses hardware-accelerated decoding to produce `VideoFrame` objects, supporting both static and animated images.
    *   **HTML `<img>` Element**: A robust fallback for static images. It utilizes the browser's native `HTMLImageElement.decode()` API to decode images asynchronously.
    *   **WASM-based Decoders**: Fallback decoders implemented in WebAssembly (e.g., Skia's built-in codecs) are used for animated images when the `ImageDecoder` API is not available.
3.  **Source Preservation**: `ui.Image` implementations often maintain a reference to their original browser-native source (like an `ImageBitmap` or `HTMLImageElement`). This allows for efficient pixel read-back and avoids slow GPU-to-CPU memory transfers.
4.  **Transformation and Optimization**:
    *   **Resizing Codecs**: Images can be resized immediately after decoding to minimize memory usage.
    *   **Iterative Downscaling**: To maintain high visual quality, the engine performs multi-step downscaling for large scale factors, bypassing limitations in browser-side mipmap generation.

## Entrypoints

The Flutter framework interacts with the web engine through a set of APIs defined in `dart:ui`. These APIs are the starting point for any image loading operation.

### Codec Instantiation

The most common way images are loaded is by creating a `ui.Codec`, which manages the decoding and frame-by-frame access of an image.

*   **`instantiateImageCodec(Uint8List list, ...)`**: The primary entrypoint for decoding encoded image bytes (JPEG, PNG, GIF, etc.).
*   **`instantiateImageCodecFromBuffer(ImmutableBuffer buffer, ...)`**: Similar to the above, but uses an `ImmutableBuffer` for memory efficiency.
*   **`instantiateImageCodecWithSize(ImmutableBuffer buffer, ...)`**: Allows the framework to request a specific target size during the decoding process.
*   **`ImageDescriptor.instantiateCodec(...)`**: Decodes an image based on a descriptor that provides metadata like width, height, and pixel format.

On the framework side, these are typically invoked by an `ImageProvider` (like `NetworkImage` or `AssetImage`) during the image resolution process.

### Direct Decoding

For simpler use cases or raw pixel data, the following APIs are used:

*   **`decodeImageFromList(Uint8List list, ...)`**: A convenience wrapper that decodes an image and returns a single `ui.Image` via a callback.
*   **`decodeImageFromPixels(Uint8List pixels, ...)`**: Creates a `ui.Image` directly from a buffer of raw pixel data.

### Rendering Entrypoints

Once an image is decoded into a `ui.Image` object, it is displayed using the `Canvas` API:

*   **`Canvas.drawImage(ui.Image image, Offset p, Paint paint)`**: Draws the entire image at a specific point.
*   **`Canvas.drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint)`**: Draws a sub-region of the image into a target rectangle on the canvas. This is where the engine's **Iterative Downscaling** logic is often triggered if the destination rectangle is significantly smaller than the source.

## Memory Management

Memory management for images in Flutter Web is a multi-layered process involving the Dart VM, the browser's JavaScript/DOM environment, and the WebAssembly (WASM) heap used by the renderers.

### Reference Counting and Disposal

Because the rendering backends (CanvasKit and Skwasm) store image data in a private WASM heap, the Dart garbage collector cannot automatically reclaim that memory.

*   **`CountedRef`**: The engine uses a reference-counting mechanism (`CkCountedRef` in CanvasKit) to track how many Dart-side proxies are pointing to a single WASM-side image object.
*   **Explicit Disposal**: It is critical that the Flutter framework calls `image.dispose()` when an image is no longer needed. This decrements the reference count and, when it reaches zero, triggers the actual deletion of the object from the WASM heap.

### Preservation of Original Image Source

In addition to the WASM-side representation, the engine typically retains a reference to the **original browser-native source** (e.g., an `HTMLImageElement`, `ImageBitmap`, or `VideoFrame`).

*   **Workaround for CanvasKit Bug**: This is primarily done to work around a bug in CanvasKit where calling `readPixels` on a texture-backed `SkImage` can fail and return entirely black pixels. By keeping the DOM source, the engine can reliably extract pixel data for `toByteData()`.
*   **Ref-Counting of the Source**: The `ImageSource` object itself is ref-counted separately from the WASM handle. When a `ui.Image` is cloned, the new instance increments the `refCount` on the same `ImageSource`. This ensures that the browser-native resource (like an `ImageBitmap`) is only closed/released when all clones that depend on it have been disposed.

### Lazy Texture Uploads

The CanvasKit backend makes extensive use of Skia's **Lazy Images** (e.g., `MakeLazyImageFromImageBitmap`).

*   **On-Demand Upload**: Instead of immediately copying the image pixels into a GPU texture, the engine creates a "lazy" wrapper. The actual texture upload to the WebGL/WebGPU context happens at the last possible moment—right before the image is drawn to a surface.
*   **Multi-Surface Support**: This lazy behavior is what enables the **`MultiSurfaceRasterizer`** to work. Since the texture isn't tied to a specific context until draw time, it can be uploaded to different canvases or handled correctly if a WebGL context is lost and needs to be recovered.
*   **Skwasm Note**: While Skwasm also uses texture sources, its current implementation is more tightly coupled to the active surface, and it does not yet support the `MultiSurfaceRasterizer`.

### Resource Copies and Footprint

At any given time, an active image might have several representations in memory:
1.  **Encoded Bytes**: Present briefly during the initial fetch/load phase.
2.  **Browser-Native Source**: The decoded `ImageBitmap` or `HTMLImageElement` managed by the browser.
3.  **WASM Wrapper**: A small handle in the WASM heap representing the Skia/Skwasm image object.
4.  **GPU Texture(s)**: One or more actual textures in GPU memory, potentially duplicated if the image is being drawn across multiple independent WebGL contexts (in `MultiSurfaceRasterizer` mode).

## Relevant Files

The following files constitute the core of the image decoding and rendering system in the Flutter Web engine.

### Core Abstractions and Shared Logic

*   **`lib/painting.dart`**: Defines the `ui.Image`, `ui.Codec`, and `ui.ImmutableBuffer` interfaces as part of the `dart:ui` library. It also contains utility methods for image decoding like `decodeImageFromList`.
*   **`lib/src/engine/renderer.dart`**: Contains the `Renderer` base class, which defines the interface for creating image codecs and images across different backends.
*   **`lib/src/engine/image_decoder.dart`**: Implements `BrowserImageDecoder`, the base class for decoders using the browser's `ImageDecoder` (WebCodecs) API. It also contains `ResizingCodec` and the general `scaleImageIfNeeded` logic.
*   **`lib/src/engine/html_image_element_codec.dart`**: Provides the base `HtmlImageElementCodec` which uses an off-screen HTML `<img>` tag to decode static images asynchronously.

### CanvasKit Backend (Skia-WASM)

*   **`lib/src/engine/canvaskit/renderer.dart`**: Implements `CanvasKitRenderer`, delegating image operations to `skiaInstantiateImageCodec` and backend-specific image creation methods.
*   **`lib/src/engine/canvaskit/image.dart`**: The "brain" of CanvasKit image logic. It manages the selection between WebCodecs, `<img>` tags, and Skia's own decoders. It also defines `CkImage`, which wraps a Skia `SkImage` while optionally retaining a reference to the original DOM source.
*   **`lib/src/engine/canvaskit/canvas.dart`**: Implements the drawing commands for CanvasKit. It includes the `shouldIterativelyDownscale` check and calls into `getOrCreateDownscaledImage` to ensure high-quality rendering of large images.

### Skwasm Backend (FFI-WASM)

*   **`lib/src/engine/skwasm/skwasm_impl/renderer.dart`**: Implements `SkwasmRenderer`, managing the lifecycle of `SkwasmImage` objects and choosing between `SkwasmBrowserImageDecoder` and other fallback strategies.
*   **`lib/src/engine/skwasm/skwasm_impl/codecs.dart`**: Contains Skwasm-specific implementations of the decoding paths, including `SkwasmBrowserImageDecoder` and a WASM-based `SkwasmAnimatedImageDecoder`.
*   **`lib/src/engine/skwasm/skwasm_impl/canvas.dart`**: Implements drawing logic for the Skwasm backend, mirroring the iterative downscaling optimizations found in CanvasKit.
