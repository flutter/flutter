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
- [ ] Replace ATK-based implementation with GTK4 `GtkAccessible` (or bridge):
      - `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.cc`
      - `engine/src/flutter/shell/platform/linux/fl_view_accessible.*`
      - `engine/src/flutter/shell/platform/linux/fl_accessible_*`
- [ ] Update ATK-based tests to GTK4 equivalents in
      `engine/src/flutter/shell/platform/linux/*_test.cc`.

## GTK4 test coverage
- [ ] Add GTK4 mocks in `engine/src/flutter/shell/platform/linux/testing/mock_gtk.*`
      for `GdkSurface` and GTK4-only APIs.
- [ ] Add a GTK4 CI shard/build step in `dev/bots/test.dart` for
      `flutter_linux_unittests` with `use_gtk4=true`.

## Plugins & registrant
- [ ] Audit `packages/flutter_tools/templates/plugin/linux-gtk4.tmpl/*`
      for deprecated GTK3 APIs and verify example builds.
- [ ] Validate `flutter_linux` plugin registrar types against GTK4.
