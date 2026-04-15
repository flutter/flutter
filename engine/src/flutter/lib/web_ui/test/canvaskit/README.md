# CanvasKit Web Engine Tests

This directory contains unit and golden tests for the CanvasKit-based implementation of the Flutter web engine. CanvasKit is a WebAssembly build of Skia that provides a consistent rendering path across browsers.

## Subdirectories

- **`initialization/`**: Contains tests specifically for the engine's initialization process, ensuring services and UI layers are set up correctly and that global scope is not polluted with module exports.

## Files

- **`bitmap_less_rendering_test.dart`**: Tests rendering scenarios that do not rely on intermediate bitmaps, specifically verifying behavior when `createImageBitmap` is unsupported.
- **`canvaskit_api_test.dart`**: A comprehensive test suite for the low-level JavaScript bindings to the CanvasKit WebAssembly module, covering mappings for enums (BlendMode, PaintStyle, etc.) and core Skia objects (Canvas, Paint, Path, Paragraph).
- **`canvaskit_api_tt_on_test.dart`**: Runs the standard CanvasKit API tests with Trusted Types enabled to ensure security compliance and verifies the `createTrustedScriptUrl` utility.
- **`common.dart`**: Provides shared testing infrastructure, including `setUpCanvasKitTest` for environment initialization and `matchPictureGolden` for screenshot-based verification.
- **`configuration_canvaskit_variant_test.dart`**: Ensures that the CanvasKit variant selection (e.g., `chromium` or `full`) is deterministic during testing and that configuration overrides work correctly.
- **`filter_test.dart`**: Tests the implementation and lifecycle of `CkColorFilter` and `CkImageFilter`, ensuring that temporary Skia objects are correctly managed.
- **`flutter_tester_emulation_golden_test.dart`**: Golden tests that emulate the `flutter_tester` environment, specifically verifying font fallback behavior to the `FlutterTest` and `Ahem` font families.
- **`fragment_program_test.dart`**: Tests the `CkFragmentProgram` and `CkFragmentShader` APIs, including creation from JSON IPLR bundles and the handling of complex uniforms like arrays and matrices.
- **`hot_restart_test.dart`**: Verifies that the CanvasKit engine correctly handles multiple initializations by reusing the existing Wasm instance, simulating a hot restart.
- **`image_golden_test.dart`**: Golden tests verifying that images (including animated GIFs) can be correctly decoded and converted back to byte data in various formats.
- **`image_test.dart`**: Unit tests for `CkImage` and image fetching logic, covering chunked loading, resource management, and clone/dispose semantics.
- **`native_memory_test.dart`**: Tests the engine's native memory management system (`CkUniqueRef` and `CkCountedRef`), ensuring that Skia objects are properly finalized, leaked objects are tracked, and reference counting works as expected.
- **`no_create_image_bitmap_test.dart`**: Verifies that the engine remains functional and can render complex primitives (like gradients) on browsers where `createImageBitmap` is unavailable.
- **`painting_test.dart`**: Verifies the basic conversion of a `CkPaint` object into a native CanvasKit `SkPaint`.
- **`picture_test.dart`**: Tests the `CkPicture` implementation, including manual disposal, synchronous image conversion (`toImageSync`), and the calculation of tight cull rectangles.
- **`platform_dispatcher_test.dart`**: Tests the handling of Skia-specific platform messages, such as setting the resource cache limit.
- **`rasterizer_test.dart`**: Verifies the logic for selecting the appropriate rasterizer (e.g., `OffscreenCanvasRasterizer` vs. `MultiSurfaceRasterizer`) based on the browser and configuration.
- **`renderer_test.dart`**: Tests the `CanvasKitRenderer`'s frame scheduling logic, including frame skipping during heavy bursts and rendering into multiple independent views.
- **`shader_test.dart`**: Tests all gradient types (`Sweep`, `Linear`, `Radial`, `Conical`) and `CkImageShader`, ensuring that Skia shaders are correctly regenerated when quality settings change.
- **`skia_font_collection_test.dart`**: Comprehensive tests for font management, covering asset loading from the manifest, handling of broken or missing font files, and test font prioritization.
- **`surface_test.dart`**: Tests the `CkOnscreenSurface` and `CkOffscreenSurface`, covering resizing logic, device pixel ratio integration, and the fallback to software rendering.
- **`text_test.dart`**: Verifies that text styling and font selection behave correctly when running in the `flutterTester` emulation environment.
