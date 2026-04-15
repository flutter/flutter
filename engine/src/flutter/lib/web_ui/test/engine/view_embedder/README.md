# View Embedder Tests

This directory contains unit tests for the view embedding logic of the Flutter Web engine. This logic is responsible for managing how Flutter views are integrated into the web page's DOM, including handling dimensions, embedding strategies, and global styles.

## Subdirectories

- **`dimensions_provider/`**: Tests for `DimensionsProvider` implementations, which provide the physical size and keyboard insets of the Flutter view.
- **`embedding_strategy/`**: Tests for `EmbeddingStrategy` implementations, which determine how the Flutter application is attached to the DOM (e.g., full page vs. custom element).

## Files

- **`display_dpr_stream_test.dart`**: Tests the `DisplayDprStream` class, ensuring it correctly emits Device Pixel Ratio (DPR) changes by listening to media query "change" events on the display.
- **`dom_manager_test.dart`**: Verifies the functionality of the `DomManager`, including the correct structure of the created DOM tree, shadow root initialization, and the management of the scene host.
- **`flutter_view_manager_test.dart`**: Tests the `FlutterViewManager`, which tracks all active `EngineFlutterView` instances. It covers view registration, disposal, event notification, and the ability to find a view given a DOM element.
- **`flutter_views_proxy_test.dart`**: Tests the `FlutterViewManagerProxy`, which provides a JS-interop interface for accessing information about Flutter views, such as their host elements and initial data.
- **`global_html_attributes_test.dart`**: Ensures that `GlobalHtmlAttributes` correctly applies engine-specific HTML attributes (like `flt-view-id`, `flt-renderer`, and `flt-build-mode`) to the root and host elements of a view.
- **`hot_restart_cache_handler_test.dart`**: Verifies the `HotRestartCacheHandler`, which ensures that DOM elements created by the engine are properly cleaned up and removed from the document during a hot restart.
- **`style_manager_test.dart`**: Tests the `StyleManager`, which handles the application of CSS styles to various engine-managed elements, such as the global styles for the Flutter view and specific positioning/scaling for the semantics host.
