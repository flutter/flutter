# UI Tests

This directory contains tests for the `dart:ui` and `dart:ui_web` APIs. These tests are intended to be renderer-agnostic, meaning they should run correctly on any renderer. They primarily focus on the core graphics, text, and platform integration layers of the Flutter Web Engine.

## Subdirectories

- **`image/`**: Contains unit tests for image decoding and codec functionality, focusing on `HtmlImageElementCodec` and web-specific image loading mechanisms.

## Files

- **`async_rendering_test.dart`**: Tests asynchronous rendering behaviors, specifically focusing on the disposal of platform views during different stages of the rasterization process.
- **`backdrop_filter_golden_test.dart`**: Golden tests for `BackdropFilter` layer rendering, including blur effects and interactions with platform views.
- **`canvas_curves_golden_test.dart`**: Golden tests for drawing curved shapes like arcs, circles, and ovals on the `Canvas`.
- **`canvas_draw_points_golden_test.dart`**: Golden tests for the `drawPoints` and `drawRawPoints` APIs on `Canvas` in various modes.
- **`canvas_golden_test.dart`**: General golden tests for various `Canvas` drawing operations, including text style isolation, frame clearing, and resource management across surfaces.
- **`canvas_lines_golden_test.dart`**: Golden tests for drawing lines on the `Canvas`, verifying thickness, offsets, and stroke caps.
- **`canvas_test.dart`**: Unit tests for the `Canvas` API, focusing on transformation, clipping, and save/restore state management.
- **`codecs_test.dart`**: Comprehensive tests for image codecs and frame decoding across various formats (PNG, JPEG, GIF, WebP, BMP, AVIF) and loading methods.
- **`color_filter_golden_test.dart`**: Golden tests for applying `ColorFilter` to drawing operations, including matrix filters and blend modes.
- **`color_test.dart`**: Tests for the `Color` class, including accessors, equality, interpolation (`lerp`), and luminance calculations.
- **`draw_atlas_golden_test.dart`**: Golden tests for the `drawAtlas` and `drawRawAtlas` APIs, verifying sprite transformations, rect mapping, and color blending.
- **`fallback_fonts_golden_test.dart`**: Golden tests verifying font fallback behavior for various scripts (Arabic, Japanese, Emojis) and language-specific font prioritization (SC, TC, HK, JP, KR).
- **`filters_test.dart`**: Comprehensive tests for `ImageFilter` (blur, dilate, erode, matrix, compose) and `ColorFilter` effects, including extensive verification of `TileMode` behaviors.
- **`font_collection_test.dart`**: Tests for the `FlutterFontCollection`, covering font loading from memory or assets, manifest parsing, and error handling for missing or invalid font data.
- **`fragment_shader_test.dart`**: Extensive tests for `FragmentShader`, covering SkSL-based shaders, all uniform types (float, vec, mat, and arrays), sampler filter quality, and shader reuse.
- **`frame_timings_test.dart`**: Tests for collecting and reporting `FrameTiming` data, ensuring build and raster durations are correctly captured over multiple frames.
- **`gradient_golden_test.dart`**: Golden tests for linear, radial, conical, and sweep gradients applied to canvas paints.
- **`gradient_test.dart`**: Unit tests for `Gradient` constructors, focusing on focal point configurations and validation of color stop distributions.
- **`image_cpu_only_test.dart`**: Tests for image decoding and rendering specifically when the engine is forced into CPU-only mode (e.g., `canvasKitForceCpuOnly`).
- **`image_decoder_test.dart`**: Unit tests for image decoding, specifically verifying the `ResizingCodec` and repetition counts for animated formats like GIF.
- **`image_filter_golden_test.dart`**: Golden tests for `ImageFilter.blur` with `TileMode.clamp`.
- **`image_filter_non_invertible_matrix_test.dart`**: Ensures that using a non-invertible matrix (e.g., all zeros or zero scale) with `ImageFilter` in a scene or `Paint` doesn't crash the engine.
- **`image_golden_test.dart`**: Extensive golden tests for image rendering including `drawImage`, `drawImageRect`, `drawImageNine`, `ImageShader`, `FragmentShader` (glitch shader), and `drawVertices` with image shader. Covers various image sources like `picture.toImage`, `decodeImageFromPixels` (unscaled/scaled), `instantiateImageCodecFromUrl`, and animated GIFs/WebP.
- **`image_test.dart`**: Unit tests for `ui.Image` lifecycle hooks (`onCreate`, `onDispose`), `scaledImageSize` utility, and ensuring that `instantiateImageCodecFromBuffer` and `instantiateImageCodecWithSize` properly dispose of buffers and temporary images.
- **`image_texture_source_test.dart`**: Tests `createImageFromTextureSource` with `HTMLImageElement` and `ImageBitmap`, specifically checking the `transferOwnership` flag.
- **`layer_test.dart`**: Tests for `LayerScene` and `LayerSceneBuilder`, including regression tests for `TransformLayer` preroll with perspective transforms, pushing leaf layers, `PlatformView` rendering in `LayerScene.toImage`, and `ImageFilter` matrix application in preroll.
- **`line_metrics_test.dart`**: Tests for text line metrics including `getLineMetricsAt`, `numberOfLines`, `getLineNumberAt`, `getGlyphInfoAt`, and hit-testing with `getClosestGlyphInfoForOffset`. Includes verification of `TestEnvironment` font emulation (overriding with `FlutterTest` font).
- **`multi_view_test.dart`**: Tests for rendering into multiple `EngineFlutterView` instances, registration/unregistration of views, and ensuring platform view factories are not reset when a view is disposed.
- **`native_resource_test.dart`**: Verifies that `onCreate` and `onDispose` hooks are balanced correctly when cloning `ui.Image` and `ui.Picture` (specifically `LayerPicture`).
- **`paint_test.dart`**: Unit tests for `ui.Paint`, verifying default values, `toString()` output, and that `Paint.from` copies all fields correctly.
- **`paragraph_builder_test.dart`**: Tests `ParagraphBuilder` and `Paragraph` functionality, including basic layout, foreground style support, `getWordBoundary` with affinity, and `kTextHeightNone` behavior.
- **`paragraph_performance_test.dart`**: Benchmarks for building, laying out, and painting paragraphs of different sizes to measure engine text performance.
- **`paragraph_style_test.dart`**: Exhaustive equality and hashCode tests for `ParagraphStyle`, ensuring every property (textAlign, fontStyle, etc.) is correctly accounted for.
- **`path_metrics_test.dart`**: Tests `Path.computeMetrics()` for various path types (lines, curves, RRects, arcs) to verify accurate length computation.
- **`path_test.dart`**: Comprehensive tests for the `Path` API, covering bounds, path combination operations, transformations, and detailed `PathMetrics` iterator/tangent behavior.
- **`performance_overlay_test.dart`**: Verifies that `SceneBuilder.addPerformanceOverlay` provides a one-time warning about being unsupported on Flutter Web without crashing.
- **`picture_test.dart`**: Tests for `Picture` and `PictureRecorder` lifecycle, ensuring proper disposal, interaction with `PictureLayer`, and `onCreate`/`onDispose` hook execution.
- **`platform_view_position_test.dart`**: Specifically tests that the onscreen canvas in multi-surface mode maintains `position: absolute` when platform views are present.
- **`platform_view_test.dart`**: Extensive tests for platform view integration, including sandwiching with pictures, transformations, various clipping types, pointer event slotting, and overlay optimization.
- **`rasterizer_order_test.dart`**: Verifies the execution order of `ViewRasterizer` lifecycle methods, ensuring frame sizes are updated and optimizations occur at the correct stage.
- **`rasterizer_resize_golden_test.dart`**: Golden test verifying that the rasterizer correctly handles view resizing and that subsequent frames use updated dimensions for centering and clipping.
- **`rect_test.dart`**: Unit tests for `Rect`, `Size`, and `RRect` basic accessors and geometric operations like `intersect` and `expandToInclude`.
- **`renderer_test.dart`**: Tests for multi-view rendering, ensuring the engine can render different scenes into multiple independent `EngineFlutterView` instances simultaneously.
- **`rrect_test.dart`**: Unit tests for `RRect.contains()` across various point locations and corner radius configurations.
- **`rsuperellipse_contains_test.dart`**: Exhaustive hit-testing for `RSuperellipse`, covering various corner radii and non-centered or diagonal shapes.
- **`scene_builder_test.dart`**: Extensive tests for all `SceneBuilder` layers (offset, transform, clips, opacity, filters) including retained layer support and regression tests.
- **`shader_mask_golden_test.dart`**: Golden tests for `pushShaderMask` using sweep gradients and color blend modes, including translated and clipped cases.
- **`shadow_test.dart`**: Golden tests for `Canvas.drawShadow`, verifying rendering for both opaque and translucent objects with elevation.
- **`strut_style_test.dart`**: Exhaustive equality and hashCode tests for `StrutStyle`, ensuring all properties are correctly handled.
- **`surface_context_lost_test.dart`**: Tests for handling WebGL context loss and recovery in `OffscreenSurface`, ensuring the engine can re-initialize and continue rendering.
- **`sweep_gradient_golden_test.dart`**: Golden tests for `SweepGradient`, verifying rendering of multi-color conical gradients with custom start and end angles.
- **`text_golden_test.dart`**: Exhaustive golden tests for text styling (alignment, weight, decorations, shadows, font features) and multi-language samples including Arabic, Chinese, and Emojis.
- **`text_style_test.dart`**: Exhaustive equality and hashCode tests for `TextStyle`, ensuring all properties (decoration, shadows, font features/variations) are correctly accounted for.
- **`text_style_test_env_test.dart`**: Verifies that `TextStyle` and `ParagraphStyle` correctly remember their original `fontFamily` value in `toString()` output.
- **`text_test.dart`**: Unit tests for general text functionality, including shadow stability, RTL-paragraph LTR-span behavior, and tab-to-space rendering.
- **`url_strategy_test.dart`**: Tests for `ui_web` URL strategy management, covering default strategies, custom strategy assignment, and prevention rules.
- **`utils.dart`**: Common utility functions and helpers for UI tests, including renderer detection and platform view management.
- **`vertices_test.dart`**: Tests for the `Vertices` API (construction, drawing, disposal) and verifying that custom meshes are not anti-aliased by default.

## Notes

These tests should call `setUpUnitTests()` at the top level to initialize the renderer they are expected to run. They are designed to be run using the `felt` tool.
