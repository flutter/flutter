*For information on using platform views in a Flutter app, see the documentation for
[Android](https://docs.flutter.dev/platform-integration/android/platform-views),
[iOS](https://docs.flutter.dev/platform-integration/ios/platform-views), and
[macOS](https://docs.flutter.dev/platform-integration/macos/platform-views).*

## Background

Hybrid Composition (HC) refers to a method of composing native views (for example, a native webview) alongside Flutter widgets.
On Android, it is one of several modes for displaying platform views; see [Android Platform Views](Android-Platform-Views.md) for an overview of modes.
On iOS and macOS, it is the only mode used for displaying platform views.

## Approach

HC creates multiple layers of native views that are composited by the standard platform
UI toolkit rather than by Flutter. This requires separating the Flutter rendering into
separate views, one containing the things that are behind the native view, and another
things above the native view, so that everything looks correct when composited by the
system.

Because it involves coordinating multiple native views, it adds complexity to the
rendering pipeline (requiring synchronization between OS rendering and Flutter
rendering to avoid tearing) and event handling such as gesture resolution.

## Limitations

- **Thread performance.** Normally, the Flutter UI is composed
  on a dedicated raster thread. This allows Flutter apps to be fast,
  as the main platform thread is rarely blocked. While a platform view
  is rendered with Hybrid Composition, the Flutter UI is composed from
  the platform thread, which competes with other tasks like
  handling OS or plugin messages.
- **Gesture handling.** Coordinating gesture resolution between Flutter's
  gesture arena and the native gesture system sometimes results in
  unexpected behaviors, such as specific gestures not working correctly
  over native views.

### Android

- Prior to Android 10 (API 29), Hybrid Composition copies each Flutter frame
  out of the graphic memory into main memory and then copied back to
  a GPU texture. As this copy happens per frame, the performance of
  the entire Flutter UI may be impacted.

To see all known issues specific to this mode on Android, search for the [`platform-views: hc` label](https://github.com/flutter/flutter/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22platform-views%3A%20hc%22).
