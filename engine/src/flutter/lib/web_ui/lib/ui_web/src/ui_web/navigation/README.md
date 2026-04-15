# Navigation

This directory contains the implementation of browser navigation and URL strategies for Flutter Web. It provides an abstraction layer over the browser's History and Location APIs, allowing the engine to manage the URL and history stack in a platform-agnostic and testable manner.

## Files

- **`platform_location.dart`**: Defines the `PlatformLocation` interface and its default implementation, `BrowserPlatformLocation`. This file encapsulates direct calls to DOM APIs (such as `window.history` and `window.location`), enabling other components to interact with the browser's location and history without being tightly coupled to the DOM.
- **`url_strategy.dart`**: Defines the `UrlStrategy` interface, which represents how the application's route state is read from and written to the browser's URL. It includes the `HashUrlStrategy` implementation, which uses URL hash fragments to represent the application's state, and provides mechanisms for setting a custom URL strategy.
