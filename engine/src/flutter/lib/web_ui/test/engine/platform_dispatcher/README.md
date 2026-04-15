# Platform Dispatcher Tests

This directory contains unit tests for the Flutter Web Engine's implementation of the `PlatformDispatcher`. The `PlatformDispatcher` serves as the primary interface between the Flutter framework and the host platform (the web browser), handling lifecycle events, system settings, and multi-view management.

## Files

- **`app_lifecycle_state_test.dart`**: Tests the `AppLifecycleState` management, specifically how it responds to the registration and unregistration of views in the `FlutterViewManager` to determine if the app is resumed or detached.
- **`application_switcher_description_test.dart`**: Verifies that the `SystemChrome.setApplicationSwitcherDescription` platform message correctly updates the browser tab's title and the `theme-color` meta tag.
- **`media_query_manager_test.dart`**: Tests the `MediaQueryManager`, which encapsulates browser media query listeners (e.g., for dark mode, reduced motion, or high contrast) and notifies the engine of changes.
- **`platform_dispatcher_test.dart`**: Provides comprehensive tests for `EnginePlatformDispatcher`, covering display reporting, lifecycle state transitions, handling of various platform messages (`flutter/skia`, `flutter/platform`, etc.), locale settings, text scaling, and accessibility features.
- **`system_color_palette_detector_test.dart`**: Tests the detection and parsing of CSS system colors (like `CanvasText` or `ButtonFace`), ensuring the engine can correctly identify the browser's system color palette for high-contrast modes.
- **`system_ui_overlay_style_test.dart`**: Verifies that `SystemChrome.setSystemUIOverlayStyle` updates the browser's theme color through the appropriate meta tags.
- **`view_focus_binding_test.dart`**: Tests the `ViewFocusBinding`, which manages focus and tab navigation between multiple Flutter views, ensuring correct focus events are dispatched when the user navigates between views.
