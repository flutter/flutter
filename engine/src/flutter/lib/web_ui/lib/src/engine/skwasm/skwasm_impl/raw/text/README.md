# Skwasm Raw Text Bindings

This directory contains the low-level Dart FFI (Foreign Function Interface) bindings to the Skia-based text engine implemented in Skwasm. These files define the `Opaque` handles and `external` functions that map to the C++ implementation in the Skwasm WASM module.

## Files

- **`raw_line_metrics.dart`**: Defines bindings for line metrics, providing information about individual lines within a laid-out paragraph, such as ascent, descent, width, and height.
- **`raw_paragraph.dart`**: Defines bindings for the `Paragraph` object, which represents a block of text with associated styles. It includes functions for performing layout and, once laid out, retrieving metrics, finding glyph positions, and getting bounding boxes for text ranges.
- **`raw_paragraph_builder.dart`**: Defines bindings for the `ParagraphBuilder` object, used to incrementally construct a paragraph by adding text, pushing/popping styles, and adding placeholders.
- **`raw_paragraph_style.dart`**: Defines bindings for paragraph-wide styling options such as text alignment, direction, and maximum lines.
- **`raw_strut_style.dart`**: Defines bindings for strut styling, which controls the minimum line height and vertical alignment within a paragraph.
- **`raw_text_style.dart`**: Defines bindings for individual text styles, including properties like color, font size, decorations, shadows, and font features.
