# Compositing and Rasterization

This directory contains the logic for compositing and rasterizing a Flutter scene on the web. It handles the process of taking a scene description (composed of pictures and platform views) and rendering it into one or more HTML `<canvas>` elements.

## Purpose

The primary goal of this directory is to manage the complex task of interleaving Flutter's high-performance graphics (rendered via WebGL/Skia) with native browser elements (Platform Views). 

It provides abstractions for:
* Composition: Deciding how to group pictures and where to insert platform views to minimize the number of rendering surfaces while maintaining correct layering.
* Rasterization: Converting drawing commands (Pictures) into actual pixels on a surface.
* Surface Management: Managing the lifecycle and pooling of both onscreen and offscreen `<canvas>` elements, including WebGL context management.

## Files

- **`canvas_provider.dart`**: Manages the lifecycle of raw HTML canvas elements. It abstracts the differences between onscreen and offscreen canvases and handles tasks like acquisition, resizing, and responding to WebGL context loss.
- **`composition.dart`**: Defines the `Composition` structure, which is a sequence of canvases (containing pictures) and platform views. It includes the logic for creating an "optimized" composition that balances rendering performance with correct z-ordering.
- **`display_canvas_factory.dart`**: Implements a factory and cache for `DisplayCanvas` objects. This allows the engine to reuse canvas elements across frames, reducing the overhead of creating and destroying DOM elements.
- **`multi_surface_rasterizer.dart`**: A `Rasterizer` implementation that uses multiple onscreen WebGL contexts. This is used on browsers where transferring bitmaps from offscreen canvases is slow (e.g., Safari and Firefox).
- **`offscreen_canvas_rasterizer.dart`**: A `Rasterizer` implementation that uses a single `OffscreenCanvas` for all rendering and then transfers the resulting bitmaps to one or more `RenderCanvas` elements for display.
- **`rasterizer.dart`**: Contains the base abstractions for the rasterization pipeline, including `Rasterizer` (the entry point for rendering into a view) and `ViewRasterizer` (which manages the per-view rendering state).
- **`render_canvas.dart`**: A specialized `DisplayCanvas` that is optimized for displaying bitmaps transferred from an `OffscreenCanvas`.
- **`surface.dart`**: Defines the `Surface` and `SurfaceProvider` interfaces. These represent the Skia-backed rendering surfaces (either onscreen or offscreen) and manage their underlying graphics contexts.
