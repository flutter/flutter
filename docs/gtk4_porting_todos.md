# GTK4 Porting TODOs

This checklist tracks remaining GTK4 work and notes what’s already landed in
this branch. Keep it short and focused on actionable items.

## Done (GTK4 baseline in this branch)
- [x] GTK4 close-request wiring in `engine/src/flutter/shell/platform/linux/fl_window_monitor.cc`.
- [x] GTK4 lifecycle monitoring via `GdkToplevelState` + `GdkSurface::mapped` in
      `engine/src/flutter/shell/platform/linux/fl_window_state_monitor.cc`.
- [x] GTK4 drawing area resize handling in `engine/src/flutter/shell/platform/linux/fl_view.cc`.
- [x] GTK4 input controllers/gestures wired in `engine/src/flutter/shell/platform/linux/fl_view.cc`.
- [x] GTK4 compositor sizing/orientation + output flip fixes in
      `engine/src/flutter/shell/platform/linux/fl_compositor_*`.
- [x] GTK4 runner template updates in
      `packages/flutter_tools/templates/app/linux-gtk4.tmpl/*`.

## Window configure/state notifications (GTK4 signals)
- [ ] Replace GTK3 `configure-event`/`window-state-event` in
      `engine/src/flutter/shell/platform/linux/fl_window_monitor.cc` with GTK4
      equivalents:
      - `GdkSurface::notify::width` / `notify::height` for size.
      - `GdkSurface::notify::state` for minimize/maximize/fullscreen.
- [ ] Verify callbacks on Wayland and X11 (`on_configure`, `on_state_changed`).

## Defaults, compatibility, and tooling
- [ ] Make GTK4 the default for new Linux apps (`flutter create --platforms=linux`).
- [ ] Keep GTK3 opt-in (flag/env) and document the selection mechanism.
- [ ] Decide how to keep/rename GTK3 runner templates (`linux-gtk3.tmpl`) so
      they’re available but not default.

## Accessibility (ATK removal)
- [ ] Follow the dedicated plan in `docs/gtk4-accessibility-plan.md`.
- [ ] Near-term priority 1: remove GTK4 dependency on the GTK3 accessibility
      stack in:
      - `engine/src/flutter/shell/platform/linux/fl_engine.cc`
      - `engine/src/flutter/shell/platform/linux/fl_view.cc`
      - `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.*`
      - `engine/src/flutter/shell/platform/linux/fl_view_accessible.*`
      - `engine/src/flutter/shell/platform/linux/fl_accessible_*`
- [ ] Near-term priority 2: add a minimal GTK4 accessibility bridge that
      preserves semantics updates, even before full GTK4 accessibility parity.
- [ ] Keep ATK-backed sources and mocks out of the GTK4 compile graph; the GTK4
      sysroot does not provide `atk/atk.h`.
- [ ] Update ATK-based tests to GTK4-safe coverage only after the GTK4 bridge
      exists.

## GTK4 test coverage
- [ ] Add GTK4 mocks in `engine/src/flutter/shell/platform/linux/testing/mock_gtk.*`
      for `GdkSurface`, event controllers, and other GTK4-only APIs.
- [ ] Split Linux engine test coverage into:
      - GTK3-only tests that still depend on ATK / `GtkSocket` / GTK3 GDK APIs.
      - GTK4-safe tests that can build with `use_gtk4=true`.
- [ ] Add a GTK4 CI build step in `dev/bots/test.dart` that at minimum verifies
      GN generation and `libflutter_linux_gtk.so` build with `use_gtk4=true`.
- [ ] Do not require the existing `flutter_linux_unittests` executable to build
      under GTK4 until GTK4-compatible mocks and accessibility coverage exist.

## Plugins & registrant
- [ ] Audit `packages/flutter_tools/templates/plugin/linux-gtk4.tmpl/*`
      for deprecated GTK3 APIs and verify example builds.
- [ ] Validate `flutter_linux` plugin registrar types against GTK4.

## Current blockers surfaced by build validation
- [ ] GTK4 engine compile/link must no longer depend on:
      - `fl_accessibility_handler_new`
      - `fl_view_accessible.*`
      - `fl_accessible_*`
      unless they have a real GTK4 implementation.
- [ ] GTK4 test targets must no longer include headers that hard-require:
      - `atk/atk.h`
      - GTK3 `GdkWindow` APIs
      - `gdk/gdkwayland.h`
- [ ] Re-run `ninja -C engine/src/out/host_debug_unopt build.ninja.stamp` and
      a focused `libflutter_linux_gtk.so` build after each GTK4 accessibility /
      test-graph change.
