# Linux Native Windowing Helpers

This document describes the Linux embedder's internal window-creation helpers
for native and FFI integrations. They are exported symbols, but their header
is not part of the public `flutter_linux` header set. Treat them as an internal
engine interface, not a stable plugin API.

See [fl_linux_windowing.h](../../../engine/src/flutter/shell/platform/linux/fl_linux_windowing.h)
for declarations and
[fl_linux_windowing.cc](../../../engine/src/flutter/shell/platform/linux/fl_linux_windowing.cc)
for implementation.

## Available Operations

- `fl_linux_windowing_get_gtk_major_version()` returns the GTK major selected
  when the engine library was compiled. It does not return the loaded GTK
  minor version or report optional capabilities.
- `fl_linux_windowing_create_regular_window(...)` creates a top-level window
  containing a new `FlView` for an existing engine.
- `fl_linux_windowing_create_dialog_window(...)` creates the same kind of
  window and, when given a parent, makes it transient for that parent and modal.

When the default application is a `GtkApplication`, the window is associated
with it. Otherwise the helper creates an unassociated `GtkWindow`.

Both creation functions return a `FlLinuxWindowingWindow` containing the
window, view, and Flutter view ID. They return null for an invalid engine.
Creating a native view does not supply Dart content: the framework side must
render into that view ID.

## Presentation and Lifetime

The helpers attach and show the child view but do not present the top-level
window. The caller must arrange presentation and rendering. Do not assume that
creating the window starts a first-frame presentation callback.

The returned record is allocated with GLib's allocator. Free the record with
`g_free()` when no longer needed; it is not a GObject. Freeing it does not close
the window or release its child view. The record stores pointers without taking
additional references. The window contains the view; neither pointer remains
valid merely because the record is retained.

Manage window closure and any additional references through the selected GTK
version's lifecycle APIs. Disconnect callbacks before their target state is
destroyed. Test repeated creation, parent closure, and dismissal while frames
are still being produced.

## GTK Differences

The helper signatures are shared by GTK3 and GTK4, but not all constraints
have the same implementation:

| Setting | GTK3 | GTK4 |
| --- | --- | --- |
| Preferred size | Window default size | Window default size |
| Minimum size | Geometry hints | Widget size request |
| Maximum size | Geometry hints | Not applied |
| Dialog with parent | Dialog type hint, transient parent, modal | Transient parent, modal |

These requests are not guarantees about the final size chosen by the window
system. A dialog-style top-level is also not a `GtkPopover` or tooltip.
The creation helpers provide no position parameter. Do not build an integration
that requires arbitrary global top-level positioning on Wayland.

## Monitoring

[FlWindowMonitor](../../../engine/src/flutter/shell/platform/linux/fl_window_monitor.h)
is another internal FFI helper. It observes window configuration, state,
activation, title, close, and destruction events. Popup movement reporting
depends on the GTK/backend implementation; GTK3 event signals must not be
connected directly to GTK4 objects.

GTK4 popovers use the separate `FlPopoverMonitor` dismissal helper.
Callbacks, view routing, first-frame content, and parent teardown need testing
with each supported GTK and display backend.

## Related Documentation

- [Linux GTK Variant Selection](linux-gtk-variant.md)
- [Linux GTK Rendering Paths](linux-gtk-rendering.md)
