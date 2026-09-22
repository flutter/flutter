# Flutter App-Level Find-in-Page (`Cmd+F` / `Ctrl+F`) Example

Interactive demonstration of generic, app-level Find-in-Page ([flutter/flutter#65504](https://github.com/flutter/flutter/issues/65504)) powered by `SelectionArea`, `SelectableRegion`, `FindInPageController`, and `_SelectableFragment` highlight painting.

## Features Demonstrated

* **Find-Only Mode (`SelectionArea(enableSelection: false, enableFind: true)`)**:
  Registers all descendant `Text`, `RichText`, button labels, `Chip`s, and `DataTable` cells with `SelectionRegistrar` without overriding mouse cursors (`MouseCursor.defer`) or attaching drag-selection gesture recognizers.
* **Pluggable Invocation (`CallbackShortcuts` / `Shortcuts` / AppBar Actions)**:
  Bind `Cmd+F` / `Ctrl+F`, `Cmd+K`, `/`, or toolbar buttons to `FindInPageController.open()` with standard `FocusAndSelectAll` (`0..length`) semantics on repeated invocations.
* **Pluggable Find Bar UI (`findBarBuilder` & Headless Controller)**:
  Switch dynamically between:
  1. Default floating `SelectableRegionFindBar`
  2. Custom bottom-docked pill via `SelectionArea.findBarBuilder`
  3. Headless `AppBar` input driving `FindInPageController` directly
* **Multi-Widget Highlight Painting & Auto-Scroll (`showRangeOnScreen`)**:
  Paints passive yellow (`#66FFEB3B`) and active orange (`#CCFF9800`) match highlights across `Text`, `RichText` with inline `WidgetSpan` badges, interactive buttons, `DataTable` cells, and off-screen scrollable `ListView` items.

## Running

```bash
../../bin/flutter run -d chrome
```
