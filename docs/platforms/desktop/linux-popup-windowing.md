# Linux Native Popup And Multi-Window API

This document describes the native Linux windowing entrypoints that a sample
app such as `flutter_multi_window_ffi_test` can use to create regular windows
and popup-style dialog windows with Flutter content.

## What The Engine Exposes

The Linux embedder exports a small native windowing API from the engine:

- `fl_linux_windowing_get_gtk_major_version()`
- `fl_linux_windowing_create_regular_window(...)`
- `fl_linux_windowing_create_dialog_window(...)`

The returned `FlLinuxWindowingWindow` contains:

- `GtkWindow* window`
- `FlView* view`
- `gint64 view_id`

That makes the view identity available to the host app without going back
through Dart.

## GTK3 Versus GTK4

The windowing API is the same from the sample app’s point of view, but the
engine backend differs:

- GTK3 uses the older GTK3 runner path
- GTK4 uses the GTK4 runner path and native GTK4 windowing APIs

The sample app should not hardcode GTK assumptions into its Dart code unless
it needs a UI-specific branch. Prefer the engine-exported GTK major version for
native code and the `FLUTTER_LINUX_GTK` define for Dart-side branching.

## Recommended Sample-App Flow

For a sample app that wants to prove popup windows work:

1. Create the main Flutter window through the normal application path.
2. Use the native windowing API to create a second dialog-style window when the
   user presses a button.
3. Keep the popup backed by its own `FlView`.
4. Present the window once the first frame is ready.

The GTK4 application helper already follows that pattern:

- `fl_application_gtk4_create_window(...)` creates a `GtkApplicationWindow`
- `fl_application_gtk4_first_frame_cb(...)` calls `gtk_window_present(...)`

For the sample app, that means the native popup behavior is already validated
at the engine layer. The sample mostly needs to call into the exported window
creation functions and keep the window alive.

## Window Monitoring

`FlWindowMonitor` is the native hook for observing popup and secondary window
lifecycle changes. It can report:

- configure/resize changes
- state changes
- active-state changes
- title changes
- popup movement
- close requests
- destroy notifications

That is the right place to connect a native sample to Flutter-side window
behavior, especially if the sample needs to verify GTK4 dialog behavior against
GTK3.

## Practical Notes For The Sample App

- Use `fl_linux_windowing_get_gtk_major_version()` if the native code needs to
  branch on GTK3 versus GTK4 behavior.
- Keep popup creation in the native layer rather than trying to infer GTK
  details from Dart.
- Use a separate `FlView` for each popup or secondary window.
- Keep the Dart-side GTK selection in `FLUTTER_LINUX_GTK` aligned with the
  engine build and the project template.

## Why This Exists

The goal is to keep the popup and multi-window demo focused on engine behavior:

- the engine creates the windows
- the engine owns the Flutter views
- the sample app only drives the API

That makes it easier to test GTK3 and GTK4 side by side without baking
implementation details into the demo.
