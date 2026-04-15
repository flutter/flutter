# ui_web

This directory contains the web-specific implementation of the `dart:ui_web` library. It provides APIs and utilities that are unique to the Flutter Web engine, enabling interaction with browser-specific features like the DOM, asset loading over HTTP, and browser-based navigation.

## Subdirectories

- **`navigation/`**: Implements browser navigation and URL strategies. It abstracts the browser's History and Location APIs to support different routing styles (e.g., hash-based vs. path-based) in a testable way.

## Files

- **`asset_manager.dart`**: Manages downloading and resolving assets over the network. It handles URL encoding to ensure compatibility between Flutter's asset keys and web server requests.
- **`benchmarks.dart`**: Provides a callback mechanism (`benchmarkValueCallback`) to receive and process performance benchmark data from the engine.
- **`browser_detection.dart`**: Implements detection for browser engines (Blink, WebKit, Firefox) and operating systems. This is used throughout the engine to apply platform-specific fixes and behaviors.
- **`flutter_views_proxy.dart`**: Exposes web-only attributes for `FlutterView` objects in multi-view applications, such as accessing the host HTML element and initial data passed during view creation.
- **`images.dart`**: Contains utilities for creating `ui.Codec` and `ui.Image` objects from web-specific sources, including URLs, `ImageBitmap` objects, and other HTML texture sources like `<canvas>` or `<video>`.
- **`initialization.dart`**: Handles the bootstrapping process for the Flutter Web engine and application. It coordinates engine service initialization, plugin registration, and application startup.
- **`platform_view_registry.dart`**: Defines the registry for platform view factories. These factories are responsible for creating the HTML elements that represent platform-integrated views in a Flutter app.
- **`plugins.dart`**: Provides a mechanism to set a handler for platform messages, allowing web-based plugins (which are implemented in Dart) to communicate with the engine.
- **`semantics.dart`**: Manages web-specific accessibility settings, such as the customizable label for the placeholder element used to trigger accessibility mode.
- **`testing.dart`**: Offers utilities for testing Flutter Web, including environment configurations (`TestEnvironment`) and overrides for physical size and device pixel ratio.
