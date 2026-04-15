# Mouse Engine Tests

This directory contains unit tests for mouse-related functionality in the Flutter Web Engine. These tests ensure that the engine correctly handles mouse interactions, such as managing the browser's context menu and updating the system mouse cursor.

## Files

- **`context_menu_test.dart`**: Verifies the behavior of the `ContextMenu` class. It tests the ability to enable and disable the browser's default context menu on the root view element, ensuring that `contextmenu` events are appropriately prevented or allowed.
- **`cursor_test.dart`**: Tests the `MouseCursor` class to ensure it correctly maps Flutter's system cursors to the corresponding CSS `cursor` properties and applies them to the appropriate DOM element.
