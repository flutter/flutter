# GTK4 Porting TODOs

This checklist maps remaining work to GTK4 migration guide changes and to
specific files in this repo.

## Window lifecycle/state (GdkToplevel)
- Replace GTK3 `window-state-event`/`GdkWindowState` with GTK4 `GdkToplevelState`
  updates in `engine/src/flutter/shell/platform/linux/fl_window_state_monitor.cc`.
- Ensure lifecycle mapping:
  - visible + focused => `AppLifecycleState.resumed`
  - visible + not focused => `AppLifecycleState.inactive`
  - not visible/minimized => `AppLifecycleState.hidden`

## Window configure/state notifications (GTK4 signals)
- Replace GTK3 `configure-event` and `window-state-event` in
  `engine/src/flutter/shell/platform/linux/fl_window_monitor.cc` with GTK4
  equivalents (toplevel state or surface size/notify signals).

## Accessibility (ATK removal)
- Replace ATK-based implementation with GTK4 `GtkAccessible` API or
  compatible bridge:
  - `engine/src/flutter/shell/platform/linux/fl_view.cc`
  - `engine/src/flutter/shell/platform/linux/fl_accessibility_handler.cc`
  - `engine/src/flutter/shell/platform/linux/fl_view_accessible.*` and
    related ATK types

## GTK4 test coverage
- GTK3-specific tests are disabled under `use_gtk4`. Create GTK4 tests/mocks:
  - `engine/src/flutter/shell/platform/linux/fl_window_state_monitor_test.cc`
  - `engine/src/flutter/shell/platform/linux/testing/mock_gtk.*`

## Runner templates (already updated)
- GTK4 runner templates now use GTK4 APIs and pkg-config:
  - `packages/flutter_tools/templates/app/linux-gtk4.tmpl/*`

## Plugin templates (GTK4)
- Plugin templates use GTK4 but may still need review for deprecated APIs:
  - `packages/flutter_tools/templates/plugin/linux-gtk4.tmpl/*`
