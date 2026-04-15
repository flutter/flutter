# CanvasKit Engine Initialization Tests

This directory contains tests for the initialization process of the CanvasKit-based web engine. These tests ensure that the engine services and UI layers are initialized correctly, both independently and in sequence.

## Files

- **`does_not_mock_module_exports_test.dart`**: Verifies that the engine initialization process does not inadvertently define `window.exports` or `window.module` on the global scope, ensuring compatibility with various JavaScript module loaders.
- **`services_vs_ui_test.dart`**: Confirms that engine services (like the CanvasKit module itself) can be initialized separately from the UI layer (like the `flt-glass-pane` and keyboard bindings), and that the UI layer only becomes active after `initializeEngineUi` is called.
- **`stores_config_test.dart`**: Ensures that the `JsFlutterConfiguration` passed to `initializeEngineServices` is correctly stored and accessible via the internal engine configuration.
