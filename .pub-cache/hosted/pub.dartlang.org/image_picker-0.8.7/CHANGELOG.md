## 0.8.7

* Adds `usePhotoPickerAndroid` options.
* Aligns Dart and Flutter SDK constraints.

## 0.8.6+4

* Updates iOS minimum version in README.

## 0.8.6+3

* Updates links for the merge of flutter/plugins into flutter/packages.

## 0.8.6+2

* Updates `NSPhotoLibraryUsageDescription` description in README.

* Updates minimum Flutter version to 3.0.

## 0.8.6+1

* Updates code for stricter lint checks.

## 0.8.6

* Updates minimum Flutter version to 2.10.
* Fixes avoid_redundant_argument_values lint warnings and minor typos.
* Adds `requestFullMetadata` option to `pickImage`, so images on iOS can be picked without `Photo Library Usage` permission.

## 0.8.5+3

* Adds argument error assertions to the app-facing package, to ensure
  consistency across platform implementations.
* Updates tests to use a mock platform instead of relying on default
  method channel implementation internals.

## 0.8.5+2

* Minor fixes for new analysis options.

## 0.8.5+1

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 0.8.5

* Moves Android and iOS implementations to federated packages.
* Adds OS version support information to README.

## 0.8.4+11

* Fixes Activity leak.

## 0.8.4+10

* iOS: allows picking images with WebP format.

## 0.8.4+9

* Internal code cleanup for stricter analysis options.

## 0.8.4+8

* Configures the `UIImagePicker` to default to gallery instead of camera when
picking multiple images on pre-iOS 14 devices.

## 0.8.4+7

* Refactors unit test to expose private interface via a separate test header instead of the inline declaration.

## 0.8.4+6

* Fixes minor type issues in iOS implementation.

## 0.8.4+5

* Improves the documentation on handling MainActivity being killed by the Android OS.
* Updates Android compileSdkVersion to 31.
* Fix iOS RunnerUITests search paths.

## 0.8.4+4

* Fix typos in README.md.

## 0.8.4+3

* Suppress a unchecked cast build warning.

## 0.8.4+2

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 0.8.4+1

* Fix README Example for `ImagePickerCache` to cache multiple files.

## 0.8.4

* Update `ImagePickerCache` to cache multiple files.

## 0.8.3+3

* Fix pickImage not returning a value on iOS when dismissing PHPicker sheet by swiping.
* Updated Android lint settings.

## 0.8.3+2

* Fix using Camera as image source on Android 11+

## 0.8.3+1

* Fixed README Example.

## 0.8.3

* Move `ImagePickerFromLimitedGalleryUITests` to `RunnerUITests` target.
* Improved handling of bad image data when applying metadata changes on iOS.

## 0.8.2

* Added new methods that return `package:cross_file` `XFile` instances. [Docs](https://pub.dev/documentation/cross_file/latest/index.html).
* Deprecate methods that return `PickedFile` instances:
  * `getImage`: use **`pickImage`** instead.
  * `getVideo`: use **`pickVideo`** instead.
  * `getMultiImage`: use **`pickMultiImage`** instead.
  * `getLostData`: use **`retrieveLostData`** instead.

## 0.8.1+4

* Fixes an issue where `preferredCameraDevice` option is not working for `getVideo` method.
* Refactor unit tests that were device-only before.

## 0.8.1+3

* Fix image picker causing a crash when the cache directory is deleted.

## 0.8.1+2

* Update the example app to support the multi-image feature.

## 0.8.1+1

* Expose errors thrown in `pickImage` and `pickVideo` docs.

## 0.8.1

* Add a new method `getMultiImage` to allow picking multiple images on iOS 14 or higher
and Android 4.3 or higher. Returns only 1 image for lower versions of iOS and Android.
* Known issue: On Android, `getLostData` will only get the last picked image when picking multiple images,
see: [#84634](https://github.com/flutter/flutter/issues/84634).

## 0.8.0+4

* Cleaned up the README example

## 0.8.0+3

* Readded request for camera permissions.

## 0.8.0+2

* Fix a rotation problem where when camera is chosen as a source and additional parameters are added.

## 0.8.0+1

* Removed redundant request for camera permissions.

## 0.8.0

* BREAKING CHANGE: Changed storage location for captured images and videos to internal cache on Android,
to comply with new Google Play storage requirements. This means developers are responsible for moving
the image or video to a different location in case more permanent storage is required. Other applications
will no longer be able to access images or videos captured unless they are moved to a publicly accessible location.
* Updated Mockito to fix Android tests.

## 0.7.5+4
* Migrate maven repo from jcenter to mavenCentral.

## 0.7.5+3
* Localize `UIAlertController` strings.

## 0.7.5+2
* Implement `UIAlertController` with a preferredStyle of `UIAlertControllerStyleAlert` since `UIAlertView` is deprecated.

## 0.7.5+1

* Fixes a rotation problem where Select Photos limited access is chosen but the image that is picked
is not included selected photos and image is scaled.

## 0.7.5

* Fixes an issue where image rotation is wrong when Select Photos chose and image is scaled.
* Migrate to PHPicker for iOS 14 and higher versions to pick image from the photo library.
* Implement the limited permission to pick photo from the photo library when Select Photo is chosen.

## 0.7.4

* Update flutter_plugin_android_lifecycle dependency to 2.0.1 to fix an R8 issue
  on some versions.

## 0.7.3

* Endorse image_picker_for_web.

## 0.7.2+1

* Android: fixes an issue where videos could be wrongly picked with `.jpg` extension.

## 0.7.2

* Run CocoaPods iOS tests in RunnerUITests target.

## 0.7.1

* Update platform_plugin_interface version requirement.

## 0.7.0

* Migrate to nullsafety
* Breaking Changes:
    * Removed the deprecated methods: `ImagePicker.pickImage`, `ImagePicker.pickVideo`,
`ImagePicker.retrieveLostData`

## 0.6.7+22

* iOS: update XCUITests to separate each test session.

## 0.6.7+21

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 0.6.7+20

* Updated README.md to show the new Android API requirements.

## 0.6.7+19

* Do not copy static field to another static field.

## 0.6.7+18

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 0.6.7+17

* iOS: fix `User-facing text should use localized string macro` warning.

## 0.6.7+16

* Update Flutter SDK constraint.

## 0.6.7+15

* Fix element type in XCUITests to look for staticText type when searching for texts.
  * See https://github.com/flutter/flutter/issues/71927
* Minor update in XCUITests to search for different elements on iOS 14 and above.

## 0.6.7+14

* Set up XCUITests.

## 0.6.7+13

* Update documentation of `getImage()` about HEIC images.

## 0.6.7+12

* Update android compileSdkVersion to 29.

## 0.6.7+11

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.6.7+10

* Updated documentation with code that does not throw an error when image is not picked.

## 0.6.7+9

* Updated the ExifInterface to the AndroidX version to support more file formats;
* Update documentation of `getImage()` regarding compression support for specific image types.

## 0.6.7+8

* Update documentation of getImage() about Android's disability to preference front/rear camera.

## 0.6.7+7

* Updating documentation to use isEmpty check.

## 0.6.7+6

* Update package:e2e -> package:integration_test

## 0.6.7+5

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.


## 0.6.7+4

* Support iOS simulator x86_64 architecture.

## 0.6.7+3

* Fixes to the example app:
  * Make videos in web start muted. This allows auto-play across browsers.
  * Prevent the app from disposing of video controllers too early.

## 0.6.7+2

* iOS: Fixes unpresentable album/image picker if window's root view controller is already presenting other view controller.

## 0.6.7+1

* Add web support to the example app.

## 0.6.7

* Utilize the new platform_interface package.
* **This change marks old methods as `deprecated`. Please check the README for migration instructions to the new API.**

## 0.6.6+5

* Pin the version of the platform interface to 1.0.0 until the plugin refactor
is ready to go.

## 0.6.6+4

* Fix bug, sometimes double click cancel button will crash.

## 0.6.6+3

* Update README

## 0.6.6+2

* Update lower bound of dart dependency to 2.1.0.

## 0.6.6+1

* Android: always use URI to get image/video data.

## 0.6.6

* Use the new platform_interface package.

## 0.6.5+3

* Move core plugin to a subdirectory to allow for federation.

## 0.6.5+2

* iOS: Fixes crash when an image in the gallery is tapped more than once.

## 0.6.5+1

* Fix CocoaPods podspec lint warnings.

## 0.6.5

* Set maximum duration for video recording.
* Fix some existing XCTests.

## 0.6.4

* Add a new parameter to select preferred camera device.

## 0.6.3+4

* Make the pedantic dev_dependency explicit.

## 0.6.3+3

* Android: Fix a crash when `externalFilesDirectory` does not exist.

## 0.6.3+2

* Bump RoboElectric dependency to 4.3.1 and update resource usage.

## 0.6.3+1

* Fix an issue that the example app won't launch the image picker after Android V2 embedding migration.

## 0.6.3

* Support Android V2 embedding.
* Migrate to using the new e2e test binding.

## 0.6.2+3

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.6.2+2

* Android: Revert the image file return logic when the image doesn't have to be scaled. Fix a rotation regression caused by 0.6.2+1
* Example App: Add a dialog to enter `maxWidth`, `maxHeight` or `quality` when picking image.

## 0.6.2+1

* Android: Fix a crash when a non-image file is picked.
* Android: Fix unwanted bitmap scaling.

## 0.6.2

* iOS: Fixes an issue where picking content from Gallery would result in a crash on iOS 13.

## 0.6.1+11

* Stability and Maintainability: update documentations, add unit tests.

## 0.6.1+10

* iOS: Fix image orientation problems when scaling images.

## 0.6.1+9

* Remove AndroidX warning.

## 0.6.1+8

* Fix iOS build and analyzer warnings.

## 0.6.1+7

* Android: Fix ImagePickerPlugin#onCreate casting context which causes exception.

## 0.6.1+6

* Define clang module for iOS

## 0.6.1+5

* Update and migrate iOS example project.

## 0.6.1+4

* Android: Fix a regression where the `retrieveLostImage` does not work anymore.
* Set up Android unit test to test `ImagePickerCache` and added image quality caching tests.

## 0.6.1+3

* Bugfix iOS: Fix orientation of the picked image after scaling.
* Remove unnecessary code that tried to normalize the orientation.
* Trivial XCTest code fix.

## 0.6.1+2

* Replace dependency on `androidx.legacy:legacy-support-v4:1.0.0` with `androidx.core:core:1.0.2`

## 0.6.1+1

* Add dependency on `androidx.annotation:annotation:1.0.0`.

## 0.6.1

* New feature : Get images with custom quality. While picking images, user can pass `imageQuality`
parameter to compress image.

## 0.6.0+20

* Android: Migrated information cache methods to use instance methods.

## 0.6.0+19

* Android: Fix memory leak due not unregistering ActivityLifecycleCallbacks.

## 0.6.0+18

* Fix video play in example and update video_player plugin dependency.

## 0.6.0+17

* iOS: Fix a crash when user captures image from the camera with devices under iOS 11.

## 0.6.0+16

* iOS Simulator: fix hang after trying to take an image from the non-existent camera.

## 0.6.0+15

* Android: throws an exception when permissions denied instead of ignoring.

## 0.6.0+14

* Fix typo in README.

## 0.6.0+13

* Bugfix Android: Fix a crash occurs in some scenarios when user picks up image from gallery.

## 0.6.0+12

* Use class instead of struct for `GIFInfo` in iOS implementation.

## 0.6.0+11

* Don't use module imports.

## 0.6.0+10

* iOS: support picking GIF from gallery.

## 0.6.0+9

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.6.0+8

* Bugfix: Add missed return statement into the image_picker example.

## 0.6.0+7

* iOS: Rename objects to follow Objective-C naming convention to avoid conflicts with other iOS library/frameworks.

## 0.6.0+6

* iOS: Picked image now has all the correct meta data from the original image, includes GPS, orientation and etc.

## 0.6.0+5

* iOS: Add missing import.

## 0.6.0+4

* iOS: Using first byte to determine original image type.
* iOS: Added XCTest target.
* iOS: The picked image now has the correct EXIF data copied from the original image.

## 0.6.0+3

* Android: fixed assertion failures due to reply messages that were sent on the wrong thread.

## 0.6.0+2

* Android: images are saved with their real extension instead of always using `.jpg`.

## 0.6.0+1

* Android: Using correct suffix syntax when picking image from remote url.

## 0.6.0

* Breaking change iOS: Returned `File` objects when picking videos now always holds the correct path. Before this change, the path returned could have `file://` prepended to it.

## 0.5.4+3

* Fix the example app failing to load picked video.

## 0.5.4+2

* Request Camera permission if it present in Manifest on Android >= M.

## 0.5.4+1

* Bugfix iOS: Cancel button not visible in gallery, if camera was accessed first.

## 0.5.4

* Add `retrieveLostData` to retrieve lost data after MainActivity is killed.

## 0.5.3+2

* Android: fix a crash when the MainActivity is destroyed after selecting the image/video.

## 0.5.3+1

* Update minimum deploy iOS version to 8.0.

## 0.5.3

* Fixed incorrect path being returned from Google Photos on Android.

## 0.5.2

* Check iOS camera authorizationStatus and return an error, if the access was
  denied.

## 0.5.1

* Android: Do not delete original image after scaling if the image is from gallery.

## 0.5.0+9

* Remove unnecessary temp video file path.

## 0.5.0+8

* Fixed wrong GooglePhotos authority of image Uri.

## 0.5.0+7

* Fix a crash when selecting images from yandex.disk and dropbox.

## 0.5.0+6

* Delete the original image if it was scaled.

## 0.5.0+5

* Remove unnecessary camera permission.

## 0.5.0+4

* Preserve transparency when saving images.

## 0.5.0+3

* Fixed an Android crash when Image Picker is registered without an activity.

## 0.5.0+2

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.5.0+1

* Fix a crash when user calls the plugin in quick succession on Android.

## 0.5.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.4.12+1

* Fix a crash when selecting downloaded images from image picker on certain devices.

## 0.4.12

* Fix a crash when user tap the image mutiple times.

## 0.4.11

* Use `api` to define `support-v4` dependency to allow automatic version resolution.

## 0.4.10

* Depend on full `support-v4` library for ease of use (fixes conflicts with Firebase and libraries)

## 0.4.9

* Bugfix: on iOS prevent to appear one pixel white line on resized image.

## 0.4.8

* Replace the full `com.android.support:appcompat-v7` dependency with `com.android.support:support-core-utils`, which results in smaller APK sizes.
* Upgrade support library to 27.1.1

## 0.4.7

* Added missing video_player package dev dependency.

## 0.4.6

* Added support for picking remote images.

## 0.4.5

* Bugfixes, code cleanup, more test coverage.

## 0.4.4

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.4.3

* Bugfix: on iOS the `pickVideo` method will now return null when the user cancels picking a video.

## 0.4.2

* Added support for picking videos.
* Updated example app to show video preview.

## 0.4.1

* Bugfix: the `pickImage` method will now return null when the user cancels picking the image, instead of hanging indefinitely.
* Removed the third party library dependency for taking pictures with the camera.

## 0.4.0

* **Breaking change**. The `source` parameter for the `pickImage` is now required. Also, the `ImageSource.any` option doesn't exist anymore.
* Use the native Android image gallery for picking images instead of a custom UI.

## 0.3.1

* Bugfix: Android version correctly asks for runtime camera permission when using `ImageSource.camera`.

## 0.3.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.2.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.2.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.1.5

* Added FLT prefix to iOS types

## 0.1.4

* Bugfix: canceling image picking threw exception.
* Bugfix: errors in plugin state management.

## 0.1.3

* Added optional source argument to pickImage for controlling where the image comes from.

## 0.1.2

* Added optional maxWidth and maxHeight arguments to pickImage.

## 0.1.1

* Updated Gradle repositories declaration to avoid the need for manual configuration
  in the consuming app.

## 0.1.0+1

* Updated readme and description in pubspec.yaml

## 0.1.0

* Updated dependencies
* **Breaking Change**: You need to add a maven section with the "https://maven.google.com" endpoint to the repository section of your `android/build.gradle`. For example:
```gradle
allprojects {
    repositories {
        jcenter()
        maven {                              // NEW
            url "https://maven.google.com"   // NEW
        }                                    // NEW
    }
}
```

## 0.0.3

* Fix for crash on iPad when showing the Camera/Gallery selection dialog

## 0.0.2+2

* Updated README

## 0.0.2+1

* Updated README

## 0.0.2

* Fix crash when trying to access camera on a device without camera (e.g. the Simulator)

## 0.0.1

* Initial Release
