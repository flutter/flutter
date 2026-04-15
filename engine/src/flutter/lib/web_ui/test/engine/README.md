# Flutter Web Engine - Core Tests

This directory contains unit tests for the core logic of the Flutter Web Engine. These tests ensure the reliability of fundamental engine components, including browser detection, initialization, event handling, rendering coordination, and platform integration.

## Subdirectories

- **`compositing/`**: Tests for the engine's compositing layer, covering rasterization, rendering canvases, and the lifecycle of display surfaces.
- **`mouse/`**: Tests for mouse-related functionality, such as system cursor management and browser context menu control.
- **`platform_dispatcher/`**: Tests for the `PlatformDispatcher`, which manages the interface between the Flutter framework and the browser (lifecycle, system settings, multi-view).
- **`platform_views/`**: Tests for the platform views implementation, ensuring correct embedding and management of HTML content within Flutter.
- **`pointer_binding/`**: Tests for the `PointerBinding` class, focusing on the conversion of DOM events to Flutter pointer data and coordinate transformations.
- **`semantics/`**: Comprehensive tests for the engine's accessibility implementation, verifying the mapping of Flutter's semantic tree to ARIA-enabled DOM elements.
- **`services/`**: Tests for binary serialization and messaging infrastructure used for communication between the engine and the framework.
- **`surface/`**: Tests for rendering surfaces, including image filters and their properties.
- **`view/`**: Tests for view-level logic, such as sizing constraints and interaction with JavaScript.
- **`view_embedder/`**: Tests for the view embedding logic, managing how Flutter views are integrated into the web page's DOM (including dimensions and embedding strategies).

## Files

- **`alarm_clock_test.dart`**: Tests the `AlarmClock` utility for scheduling and managing asynchronous callbacks using `FakeAsync`.
- **`app_bootstrap_test.dart`**: Verifies the engine's bootstrapping process, including `AppBootstrap` and the initialization of the JS-based loader.
- **`assets_test.dart`**: Tests the `AssetManager` for correctly resolving asset URLs, including support for base paths and `<meta name=assetBase>` tags.
- **`browser_detect_test.dart`**: Tests the detection of browser engines (Blink, WebKit, Firefox) and operating systems (iOS, Android, macOS, Windows, Linux).
- **`channel_buffers_test.dart`**: Tests the `ChannelBuffers` system for managing platform channel messages, including buffering, draining, resizing, and overflow handling.
- **`clipboard_test.dart`**: Tests the `ClipboardMessageHandler` for reading from and writing to the system clipboard, including error handling for unavailable contexts.
- **`composition_test.dart`**: Tests the `CompositionAwareMixin` for handling browser text composition events (IME) and the `TextEditingDeltaModel`.
- **`configuration_test.dart`**: Tests the `FlutterConfiguration` for managing engine settings, including initialization from JavaScript and default values.
- **`culling_test.dart`**: Verifies the logic for culling pictures that are outside the viewport or clipped out by engine layers.
- **`display_test.dart`**: Tests the `EngineFlutterDisplay` for managing display properties, including device pixel ratio calculations and overrides.
- **`dom_http_fetch_test.dart`**: Tests the `httpFetch` utility and its variants for performing HTTP requests using the browser's `fetch` API, covering successful payloads, error codes, and network errors.
- **`engine_browser_detect_test.dart`**: Tests the `browserSupportsCanvaskitChromium` logic, verifying detection based on features like `v8BreakIterator` and `Intl.Segmenter`.
- **`frame_service_test.dart`**: Tests the `FrameService` for scheduling and managing frames, including support for warm-up frames and handling hot restarts.
- **`frame_timing_recorder_test.dart`**: Tests the `FrameTimingRecorder` for capturing and reporting performance metrics like build and raster durations.
- **`geometry_test.dart`**: Tests for geometric primitives like `Offset`, `Size`, `Radius`, and `RRect`, covering calculations like direction, aspect ratio, and clamping.
- **`gesture_settings_test.dart`**: Tests the `GestureSettings` class for correct equality, `toString` representation, and `copyWith` behavior.
- **`global_styles_test.dart`**: Verifies the application of global CSS rules to the document, including browser-specific styles for Edge and autofill overlays.
- **`history_test.dart`**: Extensive tests for `BrowserHistory` (Single and Multi-entry), `UrlStrategy` (Hash and Path), and integration with the `flutter/navigation` platform channel.
- **`image_format_detector_test.dart`**: Tests the `detectImageType` utility for identifying image formats (JPEG, PNG, GIF, WebP, AVIF, BMP) and detecting animated GIFs/WebPs.
- **`image_to_byte_data_test.dart`**: Tests the conversion of `ui.Image` objects to `ByteData` in various formats, including RGBA and PNG.
- **`initialization_test.dart`**: Verifies the `bootstrapEngine` process and its interaction with the `_flutter.loader` JS API for engine initialization and auto-starting.
- **`keyboard_converter_test.dart`**: Extensive tests for the `KeyboardConverter`, verifying the mapping of browser keyboard events to Flutter `KeyData`, including modifiers, dead keys, and OS-specific behaviors (like CapsLock on macOS).
- **`lazy_path_test.dart`**: Tests the `LazyPath` utility for deferred path construction and its lifecycle management within the `frameArena`.
- **`lerp_test.dart`**: Verifies the `lerpDouble` linear interpolation utility, ensuring it correctly handles nulls, NaNs, infinities, and edge cases.
- **`locale_test.dart`**: Tests the `Locale` class and `DomLocale` utility for parsing, comparison, and subtag handling.
- **`lru_cache_test.dart`**: Verifies the `LruCache` implementation, testing item promotion, updating, and maximum capacity enforcement.
- **`matchers_test.dart`**: Tests for the `hasHtml` and `expectDom` matchers, ensuring they correctly identify DOM structural, attribute, and style mismatches.
- **`native_memory_test.dart`**: Verifies the `UniqueRef` and `CountedRef` utilities for managing the lifecycle of native-backed objects and integration with `Finalizer`.
- **`navigation_test.dart`**: Tests for the `flutter/navigation` platform channel, verifying route tracking and handling navigation messages both with and without an implicit view.
- **`platform_view_registry_test.dart`**: Verifies the ability to override and restore the `PlatformViewRegistry` for testing purposes.
- **`pointer_binding_test.dart`**: Comprehensive tests for converting browser pointer events (mouse, touch, wheel) to Flutter's `PointerData`, including coordinate transformation, button mapping, and scroll delta scaling.
- **`profiler_test.dart`**: Tests the `Profiler` and `Instrumentation` systems for benchmarking and engine event counting.
- **`raw_keyboard_test.dart`**: Tests for the legacy `flutter/keyevent` platform channel, verifying correct dispatching of `keyup` and `keydown` events with appropriate meta states.
- **`routing_test.dart`**: Verifies the `UrlStrategy` and its integration with `EngineFlutterWindow`, covering route tracking, history mode switching, and complex state handling.
- **`text_editing_test.dart`**: Extensive tests for `HybridTextEditing` and positioning strategies, covering focus management, input actions, autocorrect, and autofill group handling.
- **`text_fragmenter_test.dart`**: Tests for text segmentation into words, graphemes, and line breaks using browser-native APIs (`Intl.Segmenter`, `v8BreakIterator`).
- **`util_test.dart`**: Tests for various internal utilities, including matrix kind identification, font family canonicalization (with iOS 15 specifics), and list equality.
- **`vector_math_test.dart`**: Verifies `FastMatrix32` transformation logic and matrix conversion utilities.
- **`window_test.dart`**: Tests for `EngineFlutterWindow` event callbacks (metrics, locale, brightness) and platform messages like screen orientation lock.
