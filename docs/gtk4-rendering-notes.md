# GTK4 Rendering Notes (Linux Embedder)

## Overview: current rendering pipeline
- `FlEngine` selects the renderer (`kOpenGL` or `kSoftware`) and wires the embedder callbacks in `engine/src/flutter/shell/platform/linux/fl_engine.cc`.
- `FlView` owns the GTK widget tree, creates the GL context (or software path), and dispatches frames to the compositor in `engine/src/flutter/shell/platform/linux/fl_view.cc`.
- `FlCompositor` abstracts composition. Implementations:
  - OpenGL path: `engine/src/flutter/shell/platform/linux/fl_compositor_opengl.cc`
  - Software path: `engine/src/flutter/shell/platform/linux/fl_compositor_software.cc`
- Frame storage and interop live in:
  - `engine/src/flutter/shell/platform/linux/fl_framebuffer.*`
  - `engine/src/flutter/shell/platform/linux/fl_renderable.*`
  - `engine/src/flutter/shell/platform/linux/fl_texture_gl.*`
- GL context lifecycle/sharing lives in `engine/src/flutter/shell/platform/linux/fl_opengl_manager.*`.

## Files that are rendering-critical
- `engine/src/flutter/shell/platform/linux/fl_engine.cc`: renderer selection, embedder config, compositor callbacks.
- `engine/src/flutter/shell/platform/linux/fl_view.cc`: widget tree, GL context creation, render callbacks, window metrics, input/event plumbing.
- `engine/src/flutter/shell/platform/linux/fl_compositor.h`: compositor API (currently uses `GdkWindow*` in render path).
- `engine/src/flutter/shell/platform/linux/fl_compositor_opengl.cc`: GL shader setup, framebuffer compositing, EGL/GLX sharing decisions.
- `engine/src/flutter/shell/platform/linux/fl_compositor_software.cc`: Cairo-based software rendering.
- `engine/src/flutter/shell/platform/linux/fl_framebuffer.*`: OpenGL FBO/texture management.
- `engine/src/flutter/shell/platform/linux/fl_texture_gl.*`: GL texture interop with GTK contexts.
- `engine/src/flutter/shell/platform/linux/fl_window_state_monitor.*`: window state and scale factor (uses `GdkWindow*`).
- `engine/src/flutter/shell/platform/linux/fl_text_input_handler.cc`: IME integration uses `gtk_widget_get_window`.

## GTK4 adaptation points (API shifts to address)
These are the main GTK3 -> GTK4 deltas that touch rendering and windowing:

1) Window/surface APIs
- GTK3 uses `GdkWindow*` from `gtk_widget_get_window`. GTK4 replaces this with `GdkSurface*` accessed via `GtkNative`.
- Update compositor render signatures to use `GdkSurface*` (or an abstracted surface type) and replace calls like:
  - `gdk_window_get_width/height/scale_factor/display` -> GTK4 surface equivalents.

2) Child attachment and containers
- GTK4 removes `GtkContainer` APIs. Replace `gtk_container_add` with widget-specific APIs (e.g., `gtk_window_set_child`, `gtk_box_append`).
- In the embedder, this affects `fl_application.cc` and `fl_view.cc` widget trees.

3) Event handling
- `GtkEventBox` is removed in GTK4. Replace with `GtkEventController*` and attach controllers to the widget that should receive input.
- Update input plumbing in `fl_view.cc` (motion, button, scroll, touch) to use GTK4 event controllers and gestures.

4) GL/Vulkan context creation
- GTK3 uses `gdk_window_create_gl_context`. GTK4 uses surface-native context creation APIs.
- Update `fl_view.cc` and any GL interop helpers to use GTK4 context creation and to fetch the correct drawable/surface handle.

5) Cursor + monitor queries
- Cursor setting and monitor lookup currently use `GdkWindow*`. Switch to surface-based APIs in `fl_view.cc` and `fl_window_state_monitor.cc`.

## Rendering options (is there more than one?)
Yes. There are at least three viable rendering paths:

1) **GTK4 + OpenGL (EGL/GLX)**
- Keep the existing OpenGL renderer and compositor but replace GTK3 APIs with GTK4 equivalents.
- Lowest risk, reuses current embedder code. Still benefits from GTK4 event/input improvements.

2) **GTK4 + Vulkan (Impeller/Vulkan)**
- Requires adding Vulkan support to the Linux embedder. Today `fl_engine.cc` rejects `kVulkan`.
- GTK4 exposes Vulkan-capable surfaces; the embedder would need:
  - Vulkan device/swapchain setup per surface.
  - A Vulkan-backed compositor path (similar to `fl_compositor_opengl` but for Vulkan).
  - Impeller/Vulkan integration in the embedder config.
- Highest upside if Vulkan stability/perf are a goal, but also the largest change.

3) **Software (Cairo)**
- Already supported via `fl_compositor_software.cc` and remains a fallback for unsupported GPU paths.
- Useful for headless or minimal environments, but not performance-competitive.

## Recommended approach order
- Start with **GTK4 + OpenGL** to land GTK4 without destabilizing rendering.
- Parallel-plan a **Vulkan/Impeller** track: add renderer selection, Vulkan context creation, and compositor.
- Keep **software** as a fallback path during transition.

## Test scope (rendering-specific)
- `engine/src/flutter/shell/platform/linux/*_test.cc` for compositor, framebuffer, and view lifecycle.
- Add GTK4-only test runs by building `flutter_linux_unittests` with `use_gtk4=true`.
- Add GTK4 integration tests for window metrics, input, and first-frame behavior using `dev/integration_tests/`.
