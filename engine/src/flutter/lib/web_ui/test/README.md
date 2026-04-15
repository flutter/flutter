# Flutter Web Engine Tests

This directory is the central location for the Flutter Web Engine's test suite. It contains unit tests, golden (screenshot) tests, and performance benchmarks designed to verify the correctness and performance of the engine across various browsers, renderers, and compilation targets.

Tests in this directory are typically managed and executed using the `felt` (Flutter Engine Local Tester) tool, which uses the configurations defined in `felt_config.yaml` to handle complex test permutations (e.g., combinations of `dart2js`/`dart2wasm` compilers and `canvaskit`/`skwasm` renderers).

## Subdirectories

- **`canvaskit/`**: Contains tests specifically for the CanvasKit-based implementation of the engine, including Skia bindings, native memory management, and rendering correctness.
- **`common/`**: Provides shared testing infrastructure, such as mock asset managers, keyboard simulators, and custom matchers used across the entire test suite.
- **`engine/`**: Focuses on core engine logic, including browser detection, platform channels, initialization, semantics (accessibility), and pointer event handling.
- **`fallbacks/`**: Verifies the logic for falling back between different renderers (e.g., Wasm/Skwasm to CanvasKit) depending on browser capabilities.
- **`skwasm/`**: Contains low-level tests for the Skwasm renderer, specifically focusing on the interface between Dart and the underlying WebAssembly/Skia implementation.
- **`ui/`**: Contains renderer-agnostic tests for the `dart:ui` and `dart:ui_web` APIs, covering graphics, text, and basic platform integration.
- **`webparagraph/`**: Tests for the experimental browser-native text layout engine that leverages native browser APIs (like `measureText`) instead of Skia.

## Files

- **`felt_config.yaml`**: The main configuration file for the `felt` tool. It specifies compile configurations, test sets, test bundles, and run configurations for the test suite.
- **`FELT_CONFIG.md`**: Documentation explaining the structure and usage of the `felt_config.yaml` file.
