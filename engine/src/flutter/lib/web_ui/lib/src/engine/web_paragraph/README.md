# Web Paragraph

This directory contains an implementation of the Flutter `ui.Paragraph` API that leverages browser APIs (such as `measureText` and the new Enhanced TextMetrics API) to perform text layout and measurement.

## Browser-Based Optimization

While CanvasKit and Skwasm renderers can use their own built-in Skia-based text layout (which includes ICU data), this implementation provides a browser-based alternative. Using this version allows the engine to offload complex layout tasks—such as line breaking, bidi reordering, and glyph measurement—to the browser's native engine. This can significantly reduce the size of the compiled WASM binary by avoiding the need to ship a full copy of ICU and complex text layout code.

## Current Status

Note that this implementation is a work in progress. While the core layout and measurement logic is present, several painting features (such as text decorations, shadows, and certain cluster-based painting methods) are currently unimplemented and will throw `UnimplementedError` if used.

## Files

- **`bidi.dart`**: Handles bidirectional (bidi) text support. It defines `BidiRun` and provides utilities to reorder text runs into visual order, leveraging CanvasKit for bidi reordering.
- **`code_unit_flags.dart`**: Extracts and stores flags for each code unit in a string. These flags identify whitespaces, grapheme boundaries, and different types of line breaks (soft and hard).
- **`debug.dart`**: Contains debugging and profiling utilities for the web paragraph implementation, including logging and benchmark value registration.
- **`font_collection.dart`**: Responsible for registering and loading fonts. It handles asset fonts declared in the manifest as well as fonts loaded from byte lists.
- **`layout.dart`**: The core text layout engine. It manages the conversion of text into clusters, extracts bidi runs, performs line wrapping, and provides querying APIs like `getBoxesForRange` and `getPositionForOffset`.
- **`paint.dart`**: Provides an abstract base class `TextPaint` for painting paragraphs. It includes shared logic for calculating source and target rectangles for clusters, blocks, and the entire paragraph.
- **`paint_clusters.dart`**: A specialized `TextPaint` implementation that renders the paragraph by painting individual text clusters.
- **`paint_paragraph.dart`**: A specialized `TextPaint` implementation that renders the entire paragraph, often by caching the output as a single image to improve performance.
- **`painter.dart`**: Defines the `Painter` interface and its CanvasKit-specific implementation. It abstracts the actual drawing operations (drawing images, rectangles, etc.) onto the underlying canvas. Many methods in `CanvasKitPainter` are currently unimplemented.
- **`paragraph.dart`**: Contains the primary public-facing classes for the web paragraph implementation, including `WebParagraph`, `WebParagraphBuilder`, `WebParagraphStyle`, and `WebTextStyle`.
- **`wrapper.dart`**: Implements the `TextWrapper` class, which handles the line-breaking logic to wrap text according to a specified maximum width while respecting constraints like `maxLines` and `ellipsis`.
