# Text Engine

This directory contains the core text layout and rendering logic for the Flutter Web Engine. It handles line breaking, text metrics, and conversion of Flutter's text-related types into their CSS equivalents for use in the DOM.

This implementation leverages browser APIs (like `V8BreakIterator`) to implement Flutter text measurement and layout. These APIs are currently only supported in Chromium-based browsers.

This browser-based implementation is primarily used as an optimization in the CanvasKit renderer to reduce the size of the compiled WASM bundle. By offloading text measurement and layout to the browser, we avoid the need to include large ICU (International Components for Unicode) data and complex layout code in the WASM binary.

When this browser-based optimization is not used, both the CanvasKit and Skwasm renderers rely on the underlying Skia implementation for text layout and measurement.

## Files

- **`line_breaker.dart`**: Implements line-breaking logic according to the Unicode spec. It provides mechanisms for identifying mandatory breaks and opportunities for soft breaks using the browser's `V8BreakIterator`.
- **`paragraph.dart`**: Provides engine-specific implementations of text metrics (`EngineLineMetrics`) and utility extensions for mapping Flutter's `ui.TextStyle` properties (like font weight, style, and features) to CSS strings.
