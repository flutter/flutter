## 0.9.8+1

* Ignores deprecation warnings for upcoming styleFrom button API changes.

## 0.9.8

* Moves Android and iOS implementations to federated packages.
* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/104231).

## 0.9.7+1

* Moves streaming implementation to the platform interface package.

## 0.9.7

* Returns all the available cameras on iOS.

## 0.9.6

* Adds audio access permission handling logic on iOS to fix an issue with `prepareForVideoRecording` not awaiting for the audio permission request result.

## 0.9.5+1

* Suppresses warnings for pre-iOS-11 codepaths.

## 0.9.5

* Adds camera access permission handling logic on iOS to fix a related crash when using the camera for the first time.

## 0.9.4+24

* Fixes preview orientation when pausing preview with locked orientation.

## 0.9.4+23

* Minor fixes for new analysis options.

## 0.9.4+22

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 0.9.4+21

* Fixes README code samples.

## 0.9.4+20

* Fixes an issue with the orientation of videos recorded in landscape on Android.

## 0.9.4+19

* Migrate deprecated Scaffold SnackBar methods to ScaffoldMessenger.

## 0.9.4+18

* Fixes a crash in iOS when streaming on low-performance devices.

## 0.9.4+17

* Removes obsolete information from README, and adds OS support table.

## 0.9.4+16

* Fixes a bug resulting in a `CameraAccessException` that prevents image
  capture on some Android devices.

## 0.9.4+15

* Uses dispatch queue for pixel buffer synchronization on iOS.
* Minor iOS internal code cleanup related to queue helper functions.

## 0.9.4+14

* Restores compatibility with Flutter 2.5 and 2.8.

## 0.9.4+13

* Updates iOS camera's photo capture delegate reference on a background queue to prevent potential race conditions, and some related internal code cleanup.

## 0.9.4+12

* Skips unnecessary AppDelegate setup for unit tests on iOS.
* Internal code cleanup for stricter analysis options.

## 0.9.4+11

* Manages iOS camera's orientation-related states on a background queue to prevent potential race conditions.

## 0.9.4+10

* iOS performance improvement by moving file writing from the main queue to a background IO queue.

## 0.9.4+9

* iOS performance improvement by moving sample buffer handling from the main queue to a background session queue.
* Minor iOS internal code cleanup related to camera class and its delegate.
* Minor iOS internal code cleanup related to resolution preset, video format, focus mode, exposure mode and device orientation.
* Minor iOS internal code cleanup related to flash mode.

## 0.9.4+8

* Fixes a bug where ImageFormatGroup was ignored in `startImageStream` on iOS.

## 0.9.4+7

* Fixes a crash in iOS when passing null queue pointer into AVFoundation API due to race condition.
* Minor iOS internal code cleanup related to dispatch queue.

## 0.9.4+6

* Fixes a crash in iOS when using image stream due to calling Flutter engine API on non-main thread.

## 0.9.4+5

* Fixes bug where calling a method after the camera was closed resulted in a Java `IllegalStateException` exception.
* Fixes integration tests.

## 0.9.4+4

* Change Android compileSdkVersion to 31.
* Remove usages of deprecated Android API `CamcorderProfile`.
* Update gradle version to 7.0.2 on Android.

## 0.9.4+3

* Fix registerTexture and result being called on background thread on iOS.

## 0.9.4+2

* Updated package description;
* Refactor unit test on iOS to make it compatible with new restrictions in Xcode 13 which only supports the use of the `XCUIDevice` in Xcode UI tests.

## 0.9.4+1

* Fixed Android implementation throwing IllegalStateException when switching to a different activity.

## 0.9.4

* Add web support by endorsing `package:camera_web`.

## 0.9.3+1

* Remove iOS 9 availability check around ultra high capture sessions.

## 0.9.3

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 0.9.2+2

* Ensure that setting the exposure offset returns the new offset value on Android.

## 0.9.2+1

* Fixed camera controller throwing an exception when being replaced in the preview widget.

## 0.9.2

* Added functions to pause and resume the camera preview.

## 0.9.1+1

* Replace `device_info` reference with `device_info_plus` in the [README.md](README.md)

## 0.9.1

* Added `lensAperture`, `sensorExposureTime` and `sensorSensitivity` properties to the `CameraImage` dto.

## 0.9.0

* Complete rewrite of Android plugin to fix many capture, focus, flash, orientation and exposure issues.
* Fixed crash when opening front-facing cameras on some legacy android devices like Sony XZ.
* Android Flash mode works with full precapture sequence.
* Updated Android lint settings.

## 0.8.1+7

* Fix device orientation sometimes not affecting the camera preview orientation.

## 0.8.1+6

* Remove references to the Android V1 embedding.

## 0.8.1+5

* Make sure the `setFocusPoint` and `setExposurePoint` coordinates work correctly in all orientations on iOS (instead of only in portrait mode).

## 0.8.1+4

* Silenced warnings that may occur during build when using a very
  recent version of Flutter relating to null safety.

## 0.8.1+3

* Do not change camera orientation when iOS device is flat.

## 0.8.1+2

* Fix iOS crash when selecting an unsupported FocusMode.

## 0.8.1+1

* Migrate maven repository from jcenter to mavenCentral.

## 0.8.1

* Solved a rotation issue on iOS which caused the default preview to be displayed as landscape right instead of portrait.

## 0.8.0

* Stable null safety release.
* Solved delay when using the zoom feature on iOS.
* Added a timeout to the pre-capture sequence on Android to prevent crashes when the camera cannot get a focus.
* Updates the example code listed in the [README.md](README.md), so it runs without errors when you simply copy/ paste it into a Flutter App.

## 0.7.0+4

* Fix crash when taking picture with orientation lock

## 0.7.0+3

* Clockwise rotation of focus point in android

## 0.7.0+2

* Fix example reference in README.
* Revert compileSdkVersion back to 29 (from 30) as this is causing problems with add-to-app configurations.

## 0.7.0+1

* Ensure communication from JAVA to Dart is done on the main UI thread.

## 0.7.0

* BREAKING CHANGE: `CameraValue.aspectRatio` now returns `width / height` rather than `height / width`. [(commit)](https://github.com/flutter/plugins/commit/100c7470d4066b1d0f8f7e4ec6d7c943e736f970)
  * Added support for capture orientation locking on Android and iOS.
  * Fixed camera preview not rotating correctly on Android and iOS.
  * Fixed camera preview sometimes appearing stretched on Android and iOS.
  * Fixed videos & photos saving with the incorrect rotation on iOS.
* New Features:
  * Adds auto focus support for Android and iOS implementations. [(commmit)](https://github.com/flutter/plugins/commit/71a831790220f898bf8120c8a23840ac6e742db5)
  * Adds ImageFormat selection for ImageStream and Video(iOS only). [(commit)](https://github.com/flutter/plugins/commit/da1b4638b750a5ff832d7be86a42831c42c6d6c0)
* Bug Fixes:
  * Fixes crash when taking a picture on iOS devices without flash. [(commit)](https://github.com/flutter/plugins/commit/831344490984b1feec007afc9c8595d80b6c13f4)
  * Make sure the configured zoom scale is copied over to the final capture builder on Android. Fixes the issue where the preview is zoomed but the final picture is not. [(commit)](https://github.com/flutter/plugins/commit/5916f55664e1772a4c3f0c02c5c71fc11e491b76)
  * Fixes crash with using inner camera on some Android devices. [(commit)](https://github.com/flutter/plugins/commit/980b674cb4020c1927917426211a87e275346d5e)
  * Improved error feedback by differentiating between uninitialized and disposed camera controllers. [(commit)](https://github.com/flutter/plugins/commit/d0b7109f6b00a0eda03506fed2c74cc123ffc6f3)
  * Fixes picture captures causing a crash on some Huawei devices. [(commit)](https://github.com/flutter/plugins/commit/6d18db83f00f4861ffe485aba2d1f8aa08845ce6)

## 0.6.4+5

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 0.6.4+4

* Set camera auto focus enabled by default.

## 0.6.4+3

* Detect if selected camera supports auto focus and act accordingly on Android. This solves a problem where front facing cameras are not capturing the picture because auto focus is not supported.

## 0.6.4+2

* Set ImageStreamReader listener to null to prevent stale images when streaming images.

## 0.6.4+1

* Added closeCaptureSession() to stopVideoRecording in Camera.java to fix an Android 6 crash.

## 0.6.4

* Adds auto exposure support for Android and iOS implementations.

## 0.6.3+4

* Revert previous dependency update: Changed dependency on camera_platform_interface to >=1.04 <1.1.0.

## 0.6.3+3

* Updated dependency on camera_platform_interface to ^1.2.0.

## 0.6.3+2

* Fixes crash on Android which occurs after video recording has stopped just before taking a picture.

## 0.6.3+1

* Fixes flash & torch modes not working on some Android devices.

## 0.6.3

* Adds torch mode as a flash mode for Android and iOS implementations.

## 0.6.2+1

* Fix the API documentation for the `CameraController.takePicture` method.

## 0.6.2

* Add zoom support for Android and iOS implementations.

## 0.6.1+1

* Added implementation of the `didFinishProcessingPhoto` on iOS which allows saving image metadata (EXIF) on iOS 11 and up.

## 0.6.1

* Add flash support for Android and iOS implementations.

## 0.6.0+2

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 0.6.0+1

Updated README to inform users that iOS 10.0+ is needed for use

## 0.6.0

As part of implementing federated architecture and making the interface compatible with the web this version contains the following **breaking changes**:

Method changes in `CameraController`:
- The `takePicture` method no longer accepts the `path` parameter, but instead returns the captured image as an instance of the `XFile` class;
- The `startVideoRecording` method no longer accepts the `filePath`. Instead the recorded video is now returned as a `XFile` instance when the `stopVideoRecording` method completes;
- The `stopVideoRecording` method now returns the captured video when it completes;
- Added the `buildPreview` method which is now used to implement the CameraPreview widget.

## 0.5.8+19

* Update Flutter SDK constraint.

## 0.5.8+18

* Suppress unchecked warning in Android tests which prevented the tests to compile.

## 0.5.8+17

* Added Android 30 support.

## 0.5.8+16

* Moved package to camera/camera subdir, to allow for federated implementations.

## 0.5.8+15

* Added the `debugCheckIsDisposed` method which can be used in debug mode to validate if the `CameraController` class has been disposed.

## 0.5.8+14

* Changed the order of the setters for `mediaRecorder` in `MediaRecorderBuilder.java` to make it more readable.

## 0.5.8+13

* Added Dartdocs for all public APIs.

## 0.5.8+12

* Added information of video not working correctly on Android emulators to `README.md`.

## 0.5.8+11

* Fix rare nullptr exception on Android.
* Updated README.md with information about handling App lifecycle changes.

## 0.5.8+10

* Suppress the `deprecated_member_use` warning in the example app for `ScaffoldMessenger.showSnackBar`.

## 0.5.8+9

* Update android compileSdkVersion to 29.

## 0.5.8+8

* Fixed garbled audio (in video) by setting audio encoding bitrate.

## 0.5.8+7

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.5.8+6

* Avoiding uses or overrides a deprecated API in CameraPlugin.java.

## 0.5.8+5

* Fix compilation/availability issues on iOS.

## 0.5.8+4

* Fixed bug caused by casting a `CameraAccessException` on Android.

## 0.5.8+3

* Fix bug in usage example in README.md

## 0.5.8+2

* Post-v2 embedding cleanups.

## 0.5.8+1

* Update lower bound of dart dependency to 2.1.0.

## 0.5.8

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.

## 0.5.7+5

* Replace deprecated `getFlutterEngine` call on Android.

## 0.5.7+4

* Add `pedantic` to dev_dependency.

## 0.5.7+3

* Fix an Android crash when permissions are requested multiple times.

## 0.5.7+2

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.5.7+1

* Fix example null exception.

## 0.5.7

* Fix unawaited futures.

## 0.5.6+4

* Android: Use CameraDevice.TEMPLATE_RECORD to improve image streaming.

## 0.5.6+3

* Remove AndroidX warning.

## 0.5.6+2

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.5.6+1

* Android: Use android.arch.lifecycle instead of androidx.lifecycle:lifecycle in `build.gradle` to support apps that has not been migrated to AndroidX.

## 0.5.6

* Add support for the v2 Android embedding. This shouldn't affect existing
  functionality.

## 0.5.5+1

* Fix event type check

## 0.5.5

* Define clang modules for iOS.

## 0.5.4+3

* Update and migrate iOS example project.

## 0.5.4+2

* Fix Android NullPointerException on devices with only front-facing camera.

## 0.5.4+1

* Fix Android pause and resume video crash when executing in APIs below 24.

## 0.5.4

* Add feature to pause and resume video recording.

## 0.5.3+1

* Fix too large request code for FragmentActivity users.

## 0.5.3

* Added new quality presets.
* Now all quality presets can be used to control image capture quality.

## 0.5.2+2

* Fix memory leak related to not unregistering stream handler in FlutterEventChannel when disposing camera.

## 0.5.2+1

* Fix bug that prevented video recording with audio.

## 0.5.2

* Added capability to disable audio for the `CameraController`. (e.g. `CameraController(_, _,
 enableAudio: false);`)

## 0.5.1

* Can now be compiled with earlier Android sdks below 21 when
`<uses-sdk tools:overrideLibrary="io.flutter.plugins.camera"/>` has been added to the project
`AndroidManifest.xml`. For sdks below 21, the plugin won't be registered and calls to it will throw
a `MissingPluginException.`

## 0.5.0

* **Breaking Change** This plugin no longer handles closing and opening the camera on Android
  lifecycle changes. Please use `WidgetsBindingObserver` to control camera resources on lifecycle
  changes. See example project for example using `WidgetsBindingObserver`.

## 0.4.3+2

* Bump the minimum Flutter version to 1.2.0.
* Add template type parameter to `invokeMethod` calls.

## 0.4.3+1

* Catch additional `Exception`s from Android and throw as `CameraException`s.

## 0.4.3

* Add capability to prepare the capture session for video recording on iOS.

## 0.4.2

* Add sensor orientation value to `CameraDescription`.

## 0.4.1

* Camera methods are ran in a background thread on iOS.

## 0.4.0+3

* Fixed a crash when the plugin is registered by a background FlutterView.

## 0.4.0+2

* Fix orientation of captured photos when camera is used for the first time on Android.

## 0.4.0+1

* Remove categories.

## 0.4.0

* **Breaking Change** Change iOS image stream format to `ImageFormatGroup.bgra8888` from
  `ImageFormatGroup.yuv420`.

## 0.3.0+4

* Fixed bug causing black screen on some Android devices.

## 0.3.0+3

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.3.0+2

* Fix issue with calculating iOS image orientation in certain edge cases.

## 0.3.0+1

* Remove initial method call invocation from static camera method.

## 0.3.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.2.9+1

* Fix a crash when failing to start preview.

## 0.2.9

* Save photo orientation data on iOS.

## 0.2.8

* Add access to the image stream from Dart.
* Use `cameraController.startImageStream(listener)` to process the images.

## 0.2.7

* Fix issue with crash when the physical device's orientation is unknown.

## 0.2.6

* Update the camera to use the physical device's orientation instead of the UI
  orientation on Android.

## 0.2.5

* Fix preview and video size with satisfying conditions of multiple outputs.

## 0.2.4

* Unregister the activity lifecycle callbacks when disposing the camera.

## 0.2.3

* Added path_provider and video_player as dev dependencies because the example uses them.
* Updated example path_provider version to get Dart 2 support.

## 0.2.2

* iOS image capture is done in high quality (full camera size)

## 0.2.1

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.2.0

* Added support for video recording.
* Changed the example app to add video recording.

A lot of **breaking changes** in this version:

Getter changes:
 - Removed `isStarted`
 - Renamed `initialized` to `isInitialized`
 - Added `isRecordingVideo`

Method changes:
 - Renamed `capture` to `takePicture`
 - Removed `start` (the preview starts automatically when `initialize` is called)
 - Added `startVideoRecording(String filePath)`
 - Removed `stop` (the preview stops automatically when `dispose` is called)
 - Added `stopVideoRecording`

## 0.1.2

* Fix Dart 2 runtime errors.

## 0.1.1

* Fix Dart 2 runtime error.

## 0.1.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.0.4

* Revert regression of `CameraController.capture()` introduced in v. 0.0.3.

## 0.0.3

* Improved resource cleanup on Android. Avoids crash on Activity restart.
* Made the Future returned by `CameraController.dispose()` and `CameraController.capture()` actually complete on
  Android.

## 0.0.2

* Simplified and upgraded Android project template to Android SDK 27.
* Moved Android package to io.flutter.plugins.
* Fixed warnings from the Dart 2.0 analyzer.

## 0.0.1

* Initial release
