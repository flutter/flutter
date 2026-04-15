# Platform Dispatcher Helpers

This directory contains specialized components that support the `EnginePlatformDispatcher` by bridging the gap between the web browser environment and the Flutter engine's platform-level logic.

## Purpose

The components in this directory are responsible for monitoring and reacting to various browser-level events and properties. They translate these platform-specific signals into the standard Flutter concepts used by the `PlatformDispatcher`, such as application lifecycle states, media query changes, and focus management across views.

## Files

- **`app_lifecycle_state.dart`**: Tracks the application's lifecycle (e.g., resumed, inactive, hidden, detached) by monitoring browser events like `focus`, `blur`, and `visibilitychange`.
- **`media_query_manager.dart`**: Manages media query listeners for detecting system-level preferences such as dark mode, forced colors (high contrast), and reduced motion.
- **`system_color_palette_detector.dart`**: Detects system colors (like `AccentColor`, `Canvas`, and `LinkText`) by creating temporary DOM elements and reading their computed styles for both light and dark mode schemes.
- **`view_focus_binding.dart`**: Handles focus changes across multiple `FlutterView`s, managing keyboard navigation (like Tab/Shift+Tab) and ensuring proper focus behavior between the browser and the Flutter application.
