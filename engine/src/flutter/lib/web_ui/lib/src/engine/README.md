# Flutter Web Engine (`lib/src/engine`)

This directory contains the core implementation of the Flutter web engine. It bridges the gap between the `dart:ui` API expected by the Flutter framework and the web browser environment (DOM, WebGL, WebAssembly, etc.).

## Subdirectories

- **`canvaskit/`**: CanvasKit-based implementation of the web engine, wrapping the Skia WebAssembly module for high-performance rendering.
- **`compositing/`**: Logic for compositing and rasterizing a Flutter scene into HTML `<canvas>` elements, including interleaving Platform Views.
- **`js_interop/`**: Dart interop layer for communicating with JavaScript, providing bindings for public JS APIs (like the engine initializer).
- **`layer/`**: Implementations of the layer-based rendering system, used to build, optimize, and render scenes using a tree of `Layer` objects.
- **`mouse/`**: Utilities for managing mouse-related behaviors, including custom context menus and mapping Flutter cursors to CSS styles.
- **`navigation/`**: Manages integration between Flutter's routing system and the browser's History API, supporting back/forward buttons.
- **`platform_dispatcher/`**: Components bridging browser-level events (lifecycle, media queries, focus) to the engine's `PlatformDispatcher`.
- **`platform_views/`**: Core logic for managing and rendering Platform Views (native HTML elements embedded within Flutter scenes).
- **`pointer_binding/`**: Normalizes and binds browser pointer, mouse, and touch events to Flutter's internal event system.
- **`semantics/`**: Translates Flutter's semantics tree into an accessible DOM structure using ARIA roles and attributes.
- **`services/`**: Serialization and messaging infrastructure, including message codecs and binary data buffers.
- **`skwasm/`**: A high-performance 2D graphics renderer leveraging Skia compiled to WebAssembly, heavily optimized for `dart2wasm`.
- **`text/`**: Core text layout and rendering logic, mapping Flutter's text types to CSS or using browser APIs for text metrics.
- **`text_editing/`**: Bridges the Flutter text input model with the browser's native text editing capabilities via hidden input/textarea elements.
- **`view_embedder/`**: Manages the logic for embedding Flutter views into the web page's DOM, including dimensions, styles, and embedding strategies.
- **`web_paragraph/`**: Implementation of text layout that utilizes browser APIs (like `measureText`) as a lightweight alternative to full ICU/Skia text layout.

## Files

- **`alarm_clock.dart`**: Provides an `AlarmClock` utility for scheduling and notifying callbacks at specific target times, backed by `Timer`.
- **`app_bootstrap.dart`**: Controls the coarse lifecycle of a Flutter app, containing the logic for initializing (`initEngine`) and running (`runApp`) the engine, as well as managing the multi-view lifecycle (`addView` / `removeView`).
- **`arena.dart`**: Implements a simple garbage collection `Arena` for managing a list of `Collectable` objects, ensuring they can be collected in batch.
- **`browser_detection.dart`**: Utilities for detecting the current browser engine (Chrome, Safari, Firefox), environment (desktop vs. mobile), and features (e.g. WebGL support and CanvasKit variants).
- **`clipboard.dart`**: Handles clipboard-related platform messages and interacts directly with the browser's native Clipboard API to read and write text.
- **`color_filter.dart`**: Implements `EngineColorFilter`, converting various color filters (blend modes, matrices, sRGB gammas) into formats used during compositing.
- **`configuration.dart`**: Defines the `FlutterConfiguration` mechanism for passing initialization parameters (like CanvasKit URLs or web renderers) via environment variables or from JavaScript to the engine.
- **`display.dart`**: Implements `EngineFlutterDisplay`, representing the physical browser display (dimensions, refresh rate, pixel ratio), and `ScreenOrientation` for managing device orientation.
- **`dom.dart`**: Contains extensive `dart:js_interop` bindings for interacting with the browser's Document Object Model (Window, Document, Elements, Events), as well as abstractions for fetching (`httpFetch`) and other web APIs.
- **`font_change_util.dart`**: Provides utilities to batch and asynchronously send font change messages to the framework via platform channels.
- **`font_fallback_data.dart`**: Contains the generated list of fallback fonts, primarily Noto fonts, used for missing glyphs.
- **`font_fallbacks.dart`**: Manages global font fallback logic (`FontFallbackManager`), determining when fallback fonts (like Noto) are required to cover missing code points, and efficiently dispatching font download requests.
- **`fonts.dart`**: Provides mechanisms to fetch the `FontManifest.json`, parsing `FontFamily` and `FontAsset` data, and interfaces (`FlutterFontCollection`) for loading and managing custom asset fonts.
- **`frame_service.dart`**: Provides the core `FrameService` singleton for scheduling application frames using `requestAnimationFrame`. Manages frame lifecycle states and integrates with `EnginePlatformDispatcher` to dispatch `onBeginFrame` and `onDrawFrame`.
- **`frame_timing_recorder.dart`**: Collects performance metrics (`ui.FrameTiming`) during the frame lifecycle (vsync, build, and raster times) and periodically submits them to the framework for profiling.
- **`html_image_element_codec.dart`**: Implements an image codec (`HtmlImageElementCodec` and `HtmlBlobCodec`) backed by the standard browser HTML `<img>` element.
- **`image_decoder.dart`**: Implements an image decoder (`BrowserImageDecoder`) backed by the browser's native `ImageDecoder` API, supporting animated frames. Also includes `ResizingCodec`.
- **`image_format_detector.dart`**: Analyzes raw byte data to detect image file formats (PNG, GIF, JPEG, WebP, BMP, AVIF) and whether they are animated by parsing their header signatures.
- **`initialization.dart`**: Contains utilities and global constants related to engine initialization (`initializeEngineServices`, `initializeEngineUi`), build modes (release, profile, debug), and lifecycle hooks (`registerHotRestartListener`).
- **`key_map.g.dart`**: Auto-generated map of web DOM `KeyboardEvent.code` and `KeyboardEvent.key` values to Flutter's `LogicalKeyboardKey` IDs.
- **`keyboard_binding.dart`**: Binds browser DOM keyboard events (`keydown`, `keyup`), translates them into `ui.KeyData` using `KeyboardConverter` and OS-specific keymaps, and handles macOS key guards and modifier synthesis.
- **`lazy_path.dart`**: Defines `LazyPath`, which lazily records path drawing commands (`MoveToCommand`, `LineToCommand`, etc.) to defer `DisposablePath` construction, as well as metrics abstractions.
- **`native_memory.dart`**: Implements a `Finalizer` to attach cleanup functions when native/WASM objects are garbage collected, along with `UniqueRef` and `CountedRef` for lifecycle management of native object references.
- **`noto_font_encoding.dart`**: Constants defining Noto font encoding boundaries, digit offsets, and radices used for fallback font indices.
- **`noto_font.dart`**: Defines the `NotoFont` and `FallbackFontComponent` classes used to track and manage fallback font coverage for missing code points.
- **`occlusion_map.dart`**: Implements `OcclusionMap`, a 2D bounding volume hierarchy (tree of `ui.Rect`s) used to efficiently track and query overlapping rectangular regions.
- **`onscreen_logging.dart`**: Provides `printOnScreen` for displaying a fixed-position logging UI in the browser DOM, along with stack trace filtering and debugging utilities.
- **`platform_dispatcher.dart`**: Central `EnginePlatformDispatcher` that bridges the framework's `ui.PlatformDispatcher` to the web environment, handling configuration, multiple views, frame scheduling, and routing platform messages.
- **`plugins.dart`**: Defines the global `pluginMessageCallHandler` used by the platform dispatcher for routing platform channel messages.
- **`pointer_binding.dart`**: Adapts browser DOM pointer, touch, and wheel events into Flutter pointer data, including click debouncing and button state sanitization.
- **`pointer_converter.dart`**: Implements `PointerDataConverter`, which translates raw pointer metrics into a sequence of `ui.PointerData` by calculating deltas and synthesizing missing state-transition events (e.g., hover before down).
- **`profiler.dart`**: Provides performance profiling (`Profiler`, `timeAction`) and execution counting (`Instrumentation`) utilities, conditionally enabled via environment variables.
- **`raw_keyboard.dart`**: The `RawKeyboard` singleton that receives DOM keyboard events, tracks modifier states, synthesizes missing keyup events on macOS, and dispatches them over the `flutter/keyevent` channel.
- **`renderer.dart`**: Defines the abstract `Renderer` interface (implemented by CanvasKit or Skwasm), providing core rendering primitives and managing view rasterizers and frame scheduling queues for multi-view support.
- **`safe_browser_api.dart`**: Safe JavaScript API bindings and utilities (like `parseFloat` and `vibrate`), as well as interop wrappers for the browser's native `ImageDecoder`, `VideoFrame`, and `ImageTrack` APIs.
- **`semantics.dart`**: A barrel file that exports the extensive accessibility and semantics system classes from the `semantics/` subdirectory (e.g., alerts, focusable, live regions).
- **`services.dart`**: A barrel file that exports the messaging and serialization utilities from the `services/` subdirectory (e.g., buffers, message codecs, serialization routines).
- **`shader_data.dart`**: Defines `ShaderData` and `UniformData` to parse and manage custom fragment shader metadata (SkSL source, uniforms, float offsets, texture counts) from JSON payloads.
- **`shadow.dart`**: Computes physical shadow approximations based on light source constants to estimate penumbra bounds and provides utilities (`applyCssShadow`) to render these shadows using CSS `box-shadow`.
- **`svg.dart`**: Strongly-typed `dart:js_interop` bindings for creating and manipulating scalable vector graphics elements (e.g., `SVGSVGElement`, `SVGPathElement`, filters, clips) directly in the DOM.
- **`test_embedding.dart`**: Provides `TestUrlStrategy`, an in-memory mock of the browser's History API used for rigorous routing and navigation testing without affecting the actual browser URL.
- **`text_fragmenter.dart`**: Segments text into words, graphemes, and line breaks using browser APIs (`Intl.Segmenter`, V8 break iterator) and caches the results using multi-tiered LRU caches (`segmentationCache`) to optimize text layout.
- **`util.dart`**: General utility functions, including logic for detecting transform types and converting `Matrix4` to 2D/3D CSS transform strings (`matrix4ToCssTransform`), parsing colors, DOM manipulation helpers, and a generic `LruCache` implementation.
- **`validators.dart`**: Assertion helpers to validate geometric primitives (like `ui.Rect`, `ui.RRect`, `ui.Offset`, `ui.Radius`, `Matrix4`) for `NaN` values and to ensure valid color stops for gradients.
- **`vector_math.dart`**: Implements the `Matrix4` and `Vector3` classes for 3D transformations (translation, rotation, scaling, matrix inversion) used throughout the rendering pipeline, along with efficient Float32/Float64 conversion utilities.
- **`window.dart`**: Defines `EngineFlutterView` (and `EngineFlutterWindow`), which represents a Flutter view on the web, managing its DOM structure (`rootElement`), layout constraints, pointers, semantics, browser history integration, and lifecycle within the browser.