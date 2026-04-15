# View Embedder

This directory contains the logic for embedding Flutter views into the web page's DOM. It manages the DOM structure, styling, dimensions, and integration strategies for both full-page applications and those embedded within specific HTML elements.

## Purpose

The `view_embedder` package encapsulates the complexity of managing the browser environment for Flutter. Its primary responsibilities include:
- Defining and maintaining the DOM hierarchy for each `FlutterView`.
- Providing different embedding strategies (e.g., full-page vs. custom element).
- Managing global CSS styles and browser-specific style overrides.
- Tracking viewport dimensions and device pixel ratio changes.
- Handling lifecycle events like hot restarts and view disposal.
- Managing focus and blur across the Flutter view boundaries.

## Subdirectories

- **`dimensions_provider/`**: Logic for providing viewport dimensions, such as physical size and keyboard insets, tailored to the current embedding mode.
- **`embedding_strategy/`**: Implementation of different ways a Flutter app can be placed and sized within the browser's DOM.

## Files

- **`display_dpr_stream.dart`**: Provides a broadcast stream that emits the current `devicePixelRatio` and notifies listeners when it changes.
- **`dom_manager.dart`**: Manages the internal DOM structure of a `FlutterView`. It creates and organizes the root element, glass pane, shadow root, scene host, text editing host, and semantics host.
- **`flutter_view_manager.dart`**: Acts as a registry and lifecycle manager for all `EngineFlutterView` instances. It handles view registration, disposal, and utilities for finding views and managing focus.
- **`global_html_attributes.dart`**: Sets global HTML attributes on the root and host elements of a Flutter view, such as `flt-renderer`, `flt-build-mode`, and `flt-view-id`, primarily for debugging and interop.
- **`hot_restart_cache_handler.dart`**: Manages the cleanup of DOM elements across hot restarts to prevent element accumulation and ensure a clean state for the new app instance.
- **`style_manager.dart`**: Manages the application of global CSS styles. It handles default font settings and applies browser-specific CSS rules to ensure consistent behavior across Safari, Firefox, and Edge.
