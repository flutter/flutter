# Platform Views Tests

This directory contains unit tests for the Flutter Web Engine's platform views implementation. Platform views allow embedding HTML content from the browser into a Flutter web application.

## Files

- **`content_manager_test.dart`**: Tests the `PlatformViewManager` class, ensuring it correctly manages platform view factories, renders view content, handles view caching, and updates accessibility attributes (like `aria-hidden`) for platform views.
- **`message_handler_test.dart`**: Tests the `PlatformViewMessageHandler` class, which processes platform channel messages for creating and disposing of platform views. It verifies correct behavior for both successful operations and error cases like unregistered view types or duplicate view IDs.
- **`slots_test.dart`**: Tests utility functions for managing the HTML slots used to host platform views in the DOM, including `createPlatformViewSlot`, `getPlatformViewSlotName`, and `getPlatformViewDomId`.
