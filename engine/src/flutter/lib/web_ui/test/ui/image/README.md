# Image Tests

This directory contains unit tests for image decoding and codec functionality in the Flutter Web Engine. These tests verify the implementation of image-related APIs in `dart:ui` and `dart:ui_web`, particularly focusing on how images are loaded and decoded using HTML elements and other web-specific mechanisms.

## Files

- **`html_image_element_codec_test.dart`**: Contains tests for `HtmlImageElementCodec`. It verifies:
    - Decoding of raw image pixels in various formats (RGBA8888, BGRA8888).
    - Loading of images from assets and URLs.
    - Proper image disposal and resource management.
    - Progress reporting during image loading.
    - Correct handling of image dimensions, including regression tests for specific browser issues.
- **`sample_image1.png`**: A sample image asset (100x100 PNG) used by the tests to verify successful image loading and decoding.
