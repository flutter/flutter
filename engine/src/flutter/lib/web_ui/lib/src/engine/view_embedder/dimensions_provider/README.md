# Dimensions Provider

This directory contains the logic for providing the dimensions of the "viewport" in which the Flutter app is rendered on the web.

Depending on how Flutter is embedded in the web page, the source of these dimensions can vary. This package abstracts those differences, providing a unified interface for the engine to retrieve physical size and keyboard insets.

## Files

- **`dimensions_provider.dart`**: Defines the abstract `DimensionsProvider` class, which serves as the base interface for all dimension providers. It includes a factory constructor `DimensionsProvider.create` that automatically selects the appropriate implementation based on whether a `hostElement` is provided.
- **`custom_element_dimensions_provider.dart`**: An implementation of `DimensionsProvider` used when Flutter is hosted within a specific HTML element. It uses the `ResizeObserver` API to monitor size changes and the `DisplayDprStream` to respond to device pixel ratio changes.
- **`full_page_dimensions_provider.dart`**: An implementation of `DimensionsProvider` used for "full-page" Flutter apps. it primarily uses the `VisualViewport` API to measure the browser window and detect changes, including adjustments for keyboard insets on mobile browsers.
