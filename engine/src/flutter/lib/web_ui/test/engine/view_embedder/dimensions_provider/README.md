# Dimensions Provider Tests

This directory contains unit tests for the `DimensionsProvider` implementations, which are responsible for providing the dimensions (physical size and keyboard insets) of the Flutter view on the web.

These tests ensure that the dimension providers correctly report values and react to changes in the browser environment, such as window resizing, host element resizing, and device pixel ratio (DPR) changes.

## Files

- **`dimensions_provider_test.dart`**: Tests the `DimensionsProvider` factory, ensuring the correct implementation (`FullPageDimensionsProvider` or `CustomElementDimensionsProvider`) is instantiated based on the presence of a host element.
- **`custom_element_dimensions_provider_test.dart`**: Tests the `CustomElementDimensionsProvider` implementation, verifying it correctly calculates the physical size of a host element and handles resizing via `ResizeObserver`.
- **`full_page_dimensions_provider_test.dart`**: Tests the `FullPageDimensionsProvider` implementation, verifying it correctly calculates the physical size of the browser's visual viewport and handles keyboard insets on mobile.
