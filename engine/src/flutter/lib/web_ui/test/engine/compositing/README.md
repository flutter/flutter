# Engine Compositing Tests

This directory contains unit tests for the engine's compositing layer, which handles how scenes are rasterized and rendered onto the browser's display surfaces (canvases).

## Files

- **`display_canvas_factory_test.dart`**: Tests for the `DisplayCanvasFactory` class. It ensures that the factory correctly manages the lifecycle and recycling of `DisplayCanvas` objects, including behavior during hot restarts.
- **`rasterizer_test.dart`**: Tests for the `Rasterizer` and `ViewRasterizer` classes. These tests verify the logic for rendering scenes into multiple views and confirm that intermediate frames are correctly skipped when rendering multiple pictures.
- **`render_canvas_test.dart`**: Tests for the `RenderCanvas` class. It validates that the canvas handles device-pixel ratio changes correctly and that physical sizes are rounded as expected.
