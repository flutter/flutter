# Web Paragraph Tests

This directory contains the unit and integration tests for `web_paragraph`, a browser-based implementation of the Flutter `ui.Paragraph` API.

## Purpose

`web_paragraph` is an alternative text layout engine in the Flutter Web Engine. Unlike the default Skia-based text layout used by CanvasKit and Skwasm (which requires shipping ICU data and complex layout logic), `web_paragraph` leverages native browser APIs (such as `measureText` and the Enhanced TextMetrics API) to perform line breaking, bidi reordering, and glyph measurement. This helps reduce the size of the compiled WASM binary.

The tests in this directory ensure that this browser-based implementation correctly handles:
- **Construction**: Building paragraphs with complex nested styles and spans.
- **Layout**: Accurate line breaking, text wrapping, and alignment (including RTL support).
- **Styling**: Application of fonts, colors, shadows, decorations, and font variations.
- **Interactivity**: Mapping between visual coordinates (offsets) and logical text positions.
- **Metadata**: Extraction of grapheme boundaries, word breaks, and line metrics.
- **Rendering**: Visual correctness through screenshot-based golden tests.

## Files

- **`font_collection_test.dart`**: Tests the registration and loading of asset fonts, ensuring font family names (including those with special characters or whitespaces) are handled correctly by the browser.
- **`paragraph_bidi_test.dart`**: Verifies bidirectional (BIDI) text support, ensuring that mixed LTR and RTL text is correctly segmented into runs for layout.
- **`paragraph_builder_test.dart`**: Tests the `WebParagraphBuilder` to ensure it correctly manages the style stack, handles nested spans, and merges styles as expected.
- **`paragraph_codepoint_info_test.dart`**: Validates the extraction of codepoint-level metadata, such as grapheme clusters, soft/hard line breaks, word boundaries, and whitespace.
- **`paragraph_get_boxes_test.dart`**: Tests the `getBoxesForRange` API, verifying that the bounding boxes for text ranges are correctly calculated for various height and width styles.
- **`paragraph_get_position_test.dart`**: Tests hit-testing logic via `getPositionForOffset`, mapping visual coordinates back to logical text positions.
- **`paragraph_multi_style_test.dart`**: Specifically exercises paragraphs containing multiple mixed styles to ensure proper layout and styling.
- **`paragraph_performance_test.dart`**: Contains performance benchmarks and profiling for the build, layout, and paint cycles of paragraphs.
- **`paragraph_placeholders_test.dart`**: Tests the positioning, scaling, and alignment of inline placeholders (e.g., widgets converted to text spans).
- **`paragraph_queries_test.dart`**: Tests paragraph-level queries including word boundaries, line metrics, line numbers, and glyph information.
- **`paragraph_test.dart`**: High-level functional tests and golden (screenshot) tests covering a wide range of rendering scenarios like LTR/RTL mixed text, shadows, decorations, and font features.
- **`paragraph_wrapper_test.dart`**: Tests the text wrapping (line breaking) algorithm, ensuring text is split correctly across lines while respecting whitespace and hard breaks.
