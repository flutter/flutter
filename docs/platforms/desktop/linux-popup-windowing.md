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

## GTK4 Unsupported Windowing APIs

The experimental Dart windowing API includes a few GTK3 operations whose GTK
implementation was removed in GTK4. On GTK4, the following methods throw
`UnsupportedError` rather than resolving a GTK3-only symbol from the GTK4
library:

| Dart operation | GTK3 implementation | GTK4 status |
| --- | --- | --- |
| `setAppPaintable` | `gtk_widget_set_app_paintable` | Unsupported. GTK4 does not expose app-paintable windows. |
| `beginMoveDrag` | `gtk_window_begin_move_drag` | Unsupported. GTK4 removed this direct interactive-move entry point. |
| `beginResizeDrag` | `gtk_window_begin_resize_drag` | Unsupported. GTK4 removed this direct interactive-resize entry point. |

These are intentional fail-closed checks. Calling a removed GTK3 symbol from a
GTK4 process would make the API unreliable and can fail during native-symbol
resolution. Code that uses these operations must retain a GTK3-specific path
or provide a GTK4-native interaction model. Do not infer GTK capability from
the Linux platform alone; select behavior using the configured GTK variant.

Regular GTK4 top-level windows continue to support title, decoration, modal
parenting, presentation, size requests, maximize, and fullscreen through their
GTK4 equivalents. GTK4 tooltip and popup controllers use `GtkPopover` for
parent-relative placement instead of GTK3 `GdkWindow` positioning.

### Upstream API Recommendations

These limitations are candidates for improving the experimental windowing API
rather than adding GTK4-specific workarounds to application code:

- Expose windowing capabilities or feature-specific availability checks. A
  Linux platform check does not say whether the selected runner is GTK3 or
  GTK4, and a GTK major version alone does not guarantee a Wayland compositor
  grants a particular operation.
- Keep interactive move and resize semantic APIs, but route them through the
  embedder while it has the native input event and its compositor serial. GTK3
  can accept the older timestamp-based calls; GTK4 and Wayland require a
  different native interaction path.
- Model transparent or app-painted content as a cross-platform window visual
  capability. `gtk_widget_set_app_paintable` is a GTK3 implementation detail,
  not a portable windowing primitive.
- Keep parent-relative transient surfaces separate from top-level windows.
  GTK4 `GtkPopover` provides correct Wayland placement but deliberately does
  not offer arbitrary global placement or all `GtkWindow` operations.

Until such APIs exist, applications should treat these as optional features
and provide a normal in-content interaction when unavailable.

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
