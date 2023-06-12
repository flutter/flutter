# 0.3.3
* Re-apply Flutter framework bindings' null safety calls but set SDK
  constraints correctly to 2.12.0 instead.

# 0.3.2
* Reverts change from 0.3.0 where the Flutter version constraint should have
  been set to 2.12.0 instead of 2.10.5.

# 0.3.1-dev
* Populate the pubspec `repository` field.

# 0.3.0
* Move to Flutter version 2.10.5 and update dependencies' null safety calls.

# 0.2.2

* Minor internal changes to maintain forward-compatibility with [flutter#91753](https://github.com/flutter/flutter/pull/91753).

# 0.2.1

* Bug fix for using VisibilityDetector with FittedBox and Transform.scale [issue #285](https://github.com/google/flutter.widgets/issues/285).

# 0.2.0

* Added `SliverVisibilityDetector` to report visibility of `RenderSliver`-based
  widgets.  Fixes [issue #174](https://github.com/google/flutter.widgets/issues/174).

# 0.2.0-nullsafety.1

* Revert change to add `VisibilityDetectorController.scheduleNotification`,
  which introduced unexpected memory usage.

# 0.2.0-nullsafety.0

* Update to null safety.

* Try to fix the link to the example on pub.dev.

* Revert tests to again use `RenderView` instead of `TestWindow`.

* Add `VisibilityDetectorController.scheduleNotification` to force firing a
  visibility callback.

# 0.1.5

* Compatibility fixes to `demo.dart` for Flutter 1.13.8.

* Moved `demo.dart` to an `examples/` directory, renamed it, and added
  instructions to `README.md`.

* Adjusted tests to use `TestWindow` instead of `RenderView`.

* Added a "Known limitations" section to `README.md`.

# 0.1.4

* Style and comment adjustments.

* Fix a potential infinite loop in the demo app and add tests for it.

# 0.1.3

* Fixed positioning of text selection handles for `EditableText`-based
  widgets (e.g. `TextField`, `CupertinoTextField`) when used within a
  `VisibilityDetector`.

* Added `VisibilityDetectorController.widgetBoundsFor`.

# 0.1.2

* Compatibility fixes for Flutter 1.3.0.

# 0.1.1

* Added `VisibilityDetectorController.forget`.
