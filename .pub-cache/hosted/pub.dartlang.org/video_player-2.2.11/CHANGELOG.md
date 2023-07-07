## 2.2.11

* Removes dependency on `meta`.

## 2.2.10

* iOS: Updates texture on `seekTo`.

## 2.2.9

* Adds compatibility with `video_player_platform_interface` 5.0, which does not
  include non-dev test dependencies.

## 2.2.8

* Changes the way the `VideoPlayerPlatform` instance is cached in the
  controller, so that it's no longer impossible to change after the first use.
* Updates unit tests to be self-contained.
* Fixes integration tests.
* Updates Android compileSdkVersion to 31.
* Fixes a flaky integration test.
* Integration tests now use WebM on web, to allow running with Chromium.

## 2.2.7

* Fixes a regression where dragging a [VideoProgressIndicator] while playing
  would restart playback from the start of the video.

## 2.2.6

* Initialize player when size and duration become available on iOS

## 2.2.5

* Support to closed caption WebVTT format added.

## 2.2.4

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 2.2.3

* Fixed empty caption text still showing the caption widget.

## 2.2.2

* Fix a disposed `VideoPlayerController` throwing an exception when being replaced in the `VideoPlayer`.

## 2.2.1

* Specify Java 8 for Android build.

## 2.2.0

* Add `contentUri` based VideoPlayerController.

## 2.1.15

* Ensured seekTo isn't called before video player is initialized. Fixes [#89259](https://github.com/flutter/flutter/issues/89259).
* Updated Android lint settings.

## 2.1.14

* Removed dependency on the `flutter_test` package.

## 2.1.13

* Removed obsolete warning about not working in iOS simulators from README.

## 2.1.12

* Update the video url in the readme code sample

## 2.1.11

* Remove references to the Android V1 embedding.

## 2.1.10

* Ensure video pauses correctly when it finishes.

## 2.1.9

* Silenced warnings that may occur during build when using a very
  recent version of Flutter relating to null safety.

## 2.1.8

* Refactor `FLTCMTimeToMillis` to support indefinite streams. Fixes [#48670](https://github.com/flutter/flutter/issues/48670).

## 2.1.7

* Update exoplayer to 2.14.1, removing dependency on Bintray.

## 2.1.6

* Remove obsolete pre-1.0 warning from README.
* Add iOS unit and UI integration test targets.

## 2.1.5

* Update example code in README to fix broken url.

## 2.1.4

* Add an exoplayer URL to the maven repositories to address
  a possible build regression in 2.1.2.

## 2.1.3

* Fix pointer value to boolean conversion analyzer warnings.

## 2.1.2

* Migrate maven repository from jcenter to mavenCentral.

## 2.1.1

* Update example code in README to reflect API changes.

## 2.1.0

* Add `httpHeaders` option to `VideoPlayerController.network`

## 2.0.2

* Fix `VideoPlayerValue` size and aspect ratio documentation

## 2.0.1

* Remove the deprecated API "exoPlayer.setAudioAttributes".

## 2.0.0

* Migrate to null safety.
* Fix an issue where `isBuffering` was not updating on Android.
* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))
* Fix `VideoPlayerValue toString()` test.
* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.
* Migrate from deprecated `defaultBinaryMessenger`.
* Fix an issue where a crash can occur after a closing a video player view on iOS.
* Setting the `mixWithOthers` `VideoPlayerOptions` in web now is silently ignored instead of throwing an exception.

## 1.0.2

* Update Flutter SDK constraint.

## 1.0.1

* Android: Dispose video players when app is closed.

## 1.0.0

* Announce 1.0.0.

## 0.11.1+5

* Update Dart SDK constraint in example.
* Remove `test` dependency.
* Convert disabled driver test to integration_test.

## 0.11.1+4

* Add `toString()` to `Caption`.
* Fix a bug on Android when loading videos from assets would crash.

## 0.11.1+3

* Android: Upgrade ExoPlayer to 2.12.1.

## 0.11.1+2

* Update android compileSdkVersion to 29.

## 0.11.1+1

* Fixed uncanceled timers when calling `play` on the controller multiple times before `pause`, which
  caused value listeners to be called indefinitely (after `pause`) and more often than needed.

## 0.11.1

* Enable TLSv1.1 & TLSv1.2 for API 19 and below.

## 0.11.0

* Added option to set the video playback speed on the video controller.
* **Minor breaking change**: fixed `VideoPlayerValue.toString` to insert a comma after `isBuffering`.

## 0.10.12+5

* Depend on `video_player_platform_interface` version that contains the new `TestHostVideoPlayerApi`
  in order for tests to pass using the latest dependency.

## 0.10.12+4

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.10.12+3

* Avoiding uses or overrides a deprecated API in `VideoPlayerPlugin` class.

## 0.10.12+2

* Fix `setMixWithOthers` test.

## 0.10.12+1

* Depend on the version of `video_player_platform_interface` that contains the new `VideoPlayerOptions` class.

## 0.10.12

* Introduce VideoPlayerOptions to set the audio mix mode.

## 0.10.11+2

* Fix aspectRatio calculation when size.width or size.height are zero.

## 0.10.11+1

* Post-v2 Android embedding cleanups.

## 0.10.11

* iOS: Fixed crash when detaching from a dying engine.
* Android: Fixed exception when detaching from any engine.

## 0.10.10

* Migrated to [pigeon](https://pub.dev/packages/pigeon).

## 0.10.9+2

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.10.9+1

* Readme updated to include web support and details on how to use for web

## 0.10.9

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.
* Fix CocoaPods podspec lint warnings.

## 0.10.8+2

* Replace deprecated `getFlutterEngine` call on Android.

## 0.10.8+1

* Make the pedantic dev_dependency explicit.

## 0.10.8

* Added support for cleaning up the plugin if used for add-to-app (Flutter
  v1.15.3 is required for that feature).


## 0.10.7

* `VideoPlayerController` support for reading closed caption files.
* `VideoPlayerValue` has a `caption` field for reading the current closed caption at any given time.

## 0.10.6

* `ClosedCaptionFile` and `SubRipCaptionFile` classes added to read
  [SubRip](https://en.wikipedia.org/wiki/SubRip) files into dart objects.

## 0.10.5+3

* Add integration instructions for the `web` platform.

## 0.10.5+2

* Make sure the plugin is correctly initialized

## 0.10.5+1

* Fixes issue where `initialize()` `Future` stalls when failing to load source
  data and does not throw an error.

## 0.10.5

* Support `web` by default.
* Require Flutter SDK 1.12.13+hotfix.4 or greater.

## 0.10.4+2

* Remove the deprecated `author:` field form pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.10.4+1

* Fix pedantic lints. This fixes some potential race conditions in cases where
  futures within some video_player methods weren't being awaited correctly.

## 0.10.4

* Port plugin code to use the federated Platform Interface, instead of a MethodChannel directly.

## 0.10.3+3

* Add DartDocs and unit tests.

## 0.10.3+2

* Update the homepage to point to the new plugin location

## 0.10.3+1

* Dispose `FLTVideoPlayer` in `onTextureUnregistered` callback on iOS.
* Add a temporary fix to dispose the `FLTVideoPlayer` with a delay to avoid race condition.
* Updated the example app to include a new page that pop back after video is done playing.

## 0.10.3

* Add support for the v2 Android embedding. This shouldn't impact existing
  functionality.

## 0.10.2+6

* Remove AndroidX warnings.

## 0.10.2+5

* Update unit test for compatibility with Flutter stable branch.

## 0.10.2+4

* Define clang module for iOS.

## 0.10.2+3

* Fix bug where formatHint was not being pass down to network sources.

## 0.10.2+2

* Update and migrate iOS example project.

## 0.10.2+1

* Use DefaultHttpDataSourceFactory only when network schemas and use
DefaultHttpDataSourceFactory by default.

## 0.10.2

* **Android Only** Adds optional VideoFormat used to signal what format the plugin should try.

## 0.10.1+7

* Fix tests by ignoring deprecated member use.

## 0.10.1+6

* [iOS] Fixed a memory leak with notification observing.

## 0.10.1+5

* Fix race condition while disposing the VideoController.

## 0.10.1+4

* Fixed syntax error in README.md.

## 0.10.1+3

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.10.1+2

* Example: Fixed tab display and added scroll view

## 0.10.1+1

* iOS: Avoid deprecated `seekToTime` API

## 0.10.1

* iOS: Consider a player only `initialized` once duration is determined.

## 0.10.0+8

* iOS: Fix an issue where the player sends initialization message incorrectly.

* Fix a few other IDE warnings.


## 0.10.0+7

* Android: Fix issue where buffering status in percentage instead of milliseconds

* Android: Update buffering status everytime we notify for position change

## 0.10.0+6

* Android: Fix missing call to `event.put("event", "completed");` which makes it possible to detect when the video is over.

## 0.10.0+5

* Fixed iOS build warnings about implicit retains.

## 0.10.0+4

* Android: Upgrade ExoPlayer to 2.9.6.

## 0.10.0+3

* Fix divide by zero bug on iOS.

## 0.10.0+2

* Added supported format documentation in README.

## 0.10.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.10.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.9.0

* Fixed the aspect ratio and orientation of videos. Videos are now properly displayed when recorded
 in portrait mode both in iOS and Android.

## 0.8.0

* Android: Upgrade ExoPlayer to 2.9.1
* Android: Use current gradle dependencies
* Android 9 compatibility fixes for Demo App

## 0.7.2

* Updated to use factories on exoplayer `MediaSource`s for Android instead of the now-deprecated constructors.

## 0.7.1

* Fixed null exception on Android when the video has a width or height of 0.

## 0.7.0

* Add a unit test for controller and texture changes. This is a breaking change since the interface
  had to be cleaned up to facilitate faking.

## 0.6.6

* Fix the condition where the player doesn't update when attached controller is changed.

## 0.6.5

* Eliminate race conditions around initialization: now initialization events are queued and guaranteed
  to be delivered to the Dart side. VideoPlayer widget is rebuilt upon completion of initialization.

## 0.6.4

* Android: add support for hls, dash and ss video formats.

## 0.6.3

* iOS: Allow audio playback in silent mode.

## 0.6.2

* `VideoPlayerController.seekTo()` is now frame accurate on both platforms.

## 0.6.1

* iOS: add missing observer removals to prevent crashes on deallocation.

## 0.6.0

* Android: use ExoPlayer instead of MediaPlayer for better video format support.

## 0.5.5

* **Breaking change** `VideoPlayerController.initialize()` now only completes after the controller is initialized.
* Updated example in README.md.

## 0.5.4

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.5.3

* Added video buffering status.

## 0.5.2

* Fixed a bug on iOS that could lead to missing initialization.
* Added support for HLS video on iOS.

## 0.5.1

* Fixed bug on video loop feature for iOS.

## 0.5.0

* Added the constructor `VideoPlayerController.file`.
* **Breaking change**. Changed `VideoPlayerController.isNetwork` to
  an enum `VideoPlayerController.dataSourceType`.

## 0.4.1

* Updated Flutter SDK constraint to reflect the changes in v0.4.0.

## 0.4.0

* **Breaking change**. Removed the `VideoPlayerController` constructor
* Added two new factory constructors `VideoPlayerController.asset` and
  `VideoPlayerController.network` to respectively play a video from the
  Flutter assets and from a network uri.

## 0.3.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.2.1

* Fixed some signatures to account for strong mode runtime errors.
* Fixed spelling mistake in toString output.

## 0.2.0

* **Breaking change**. Renamed `VideoPlayerController.isErroneous` to `VideoPlayerController.hasError`.
* Updated documentation of when fields are available on `VideoPlayerController`.
* Updated links in README.md.

## 0.1.1

* Simplified and upgraded Android project template to Android SDK 27.
* Moved Android package to io.flutter.plugins.
* Fixed warnings from the Dart 2.0 analyzer.

## 0.1.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.0.7

* Added access to the video size.
* Made the VideoProgressIndicator render using a LinearProgressIndicator.

## 0.0.6

* Fixed a bug related to hot restart on Android.

## 0.0.5

* Added VideoPlayerValue.toString().
* Added FLT prefix to iOS types.

## 0.0.4

* The player will now pause on app pause, and resume on app resume.
* Implemented scrubbing on the progress bar.

## 0.0.3

* Made creating a VideoPlayerController a synchronous operation. Must be followed by a call to initialize().
* Added VideoPlayerController.setVolume().
* Moved the package to flutter/plugins github repo.

## 0.0.2

* Fix meta dependency version.

## 0.0.1

* Initial release
