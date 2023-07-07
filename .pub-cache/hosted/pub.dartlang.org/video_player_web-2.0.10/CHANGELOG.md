## 2.0.10

* Minor fixes for new analysis options.

## 2.0.9

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.8

* Ensures `buffering` state is only removed when the browser reports enough data
  has been buffered so that the video can likely play through without stopping
  (`onCanPlayThrough`). Issue [#94630](https://github.com/flutter/flutter/issues/94630).
* Improves testability of the `_VideoPlayer` private class.
* Ensures that tests that listen to a Stream fail "fast" (1 second max timeout).

## 2.0.7

* Internal code cleanup for stricter analysis options.

## 2.0.6

* Removes dependency on `meta`.

## 2.0.5

* Adds compatibility with `video_player_platform_interface` 5.0, which does not
  include non-dev test dependencies.

## 2.0.4

* Adopt `video_player_platform_interface` 4.2 and opt out of `contentUri` data source.

## 2.0.3

* Add `implements` to pubspec.

## 2.0.2

* Updated installation instructions in README.

## 2.0.1

* Fix videos not playing in Safari/Chrome on iOS by setting autoplay to false
* Change sizing code of `Video` widget's `HtmlElementView` so it works well when slotted.
* Move tests to `example` directory, so they run as integration_tests with `flutter drive`.

## 2.0.0

* Migrate to null safety.
* Calling `setMixWithOthers()` now is silently ignored instead of throwing an exception.
* Fixed an issue where `isBuffering` was not updating on Web.

## 0.1.4+2

* Update Flutter SDK constraint.

## 0.1.4+1

* Substitute `undefined_prefixed_name: ignore` analyzer setting by a `dart:ui` shim with conditional exports. [Issue](https://github.com/flutter/flutter/issues/69309).

## 0.1.4

* Added option to set the video playback speed on the video controller.

## 0.1.3+2

* Allow users to set the 'muted' attribute on video elements by setting their volume to 0.
* Do not parse URIs on 'network' videos to not break blobs (Safari).

## 0.1.3+1

* Remove Android folder from `video_player_web`.

## 0.1.3

* Updated video_player_platform_interface, bumped minimum Dart version to 2.1.0.

## 0.1.2+3

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.1.2+2

* Add `analysis_options.yaml` to the package, so we can ignore `undefined_prefixed_name` errors. Works around https://github.com/flutter/flutter/issues/41563.

## 0.1.2+1

* Make the pedantic dev_dependency explicit.

## 0.1.2

* Add a `PlatformException` to the player's `eventController` when there's a `videoElement.onError`. Fixes https://github.com/flutter/flutter/issues/48884.
* Handle DomExceptions on videoElement.play() and turn them into `PlatformException` as well, so we don't end up with unhandled Futures.
* Update setup instructions in the README.

## 0.1.1+1

* Add an android/ folder with no-op implementation to workaround https://github.com/flutter/flutter/issues/46898.

## 0.1.1

* Support videos from assets.

## 0.1.0+1

* Remove the deprecated `author:` field from pubspec.yaml
* Require Flutter SDK 1.10.0 or greater.

## 0.1.0

* Initial release
