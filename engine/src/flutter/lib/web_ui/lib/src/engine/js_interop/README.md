# JavaScript Interop for Flutter Web Engine

This directory contains the Dart interop layer for communicating between the Flutter Web Engine and JavaScript. It provides bindings for the public JS API that allows developers to initialize and control Flutter Web applications from their own JavaScript code.

## Files

- **`js_app.dart`**: Defines the JS bindings for a running Flutter Web App (`FlutterApp`). It includes configurations for adding views (`JsFlutterViewOptions`) and defining view constraints (`JsViewConstraints`).
- **`js_loader.dart`**: Handles the engine's initialization process. It provides JS bindings for the Flutter loader, engine initializer (`FlutterEngineInitializer`), and app runner (`FlutterAppRunner`), enabling the "multi-app" and "custom initialization" features.
- **`js_promise.dart`**: Provides a custom utility to convert Dart `Future`s to JS `Promise`s. It includes improved error reporting by appending Dart stack traces to the JS Error object.
- **`js_typed_data.dart`**: Contains extensions for `JSTypedArray` to expose methods like `slice` and `set` that are not yet available in the standard Dart SDK.
