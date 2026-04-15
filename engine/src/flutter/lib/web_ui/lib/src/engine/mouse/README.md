# Mouse Management

This directory contains utilities and classes for managing mouse-related behaviors and interactions in the Flutter Web Engine.

## Purpose

The primary goal of this directory is to bridge Flutter's mouse interaction model with the browser's DOM and CSS capabilities. This includes controlling the visibility and behavior of the native context menu, mapping Flutter's mouse cursor types to CSS cursor styles, and providing utility listeners to prevent default browser event handling.

## Files

- **`context_menu.dart`**: Provides the `ContextMenu` class, which allows enabling or disabling the browser's native context menu for a specific DOM element.
- **`cursor.dart`**: Contains the `MouseCursor` class, which maps Flutter's abstract mouse cursor kinds (e.g., `click`, `text`, `grab`) to their corresponding CSS `cursor` values.
- **`prevent_default.dart`**: Defines a shared `DomEventListener` that calls `preventDefault()` on events, used to suppress default browser behaviors that might conflict with Flutter's own gesture or interaction handling.
