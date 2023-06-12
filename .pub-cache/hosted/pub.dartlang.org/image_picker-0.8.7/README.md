# Image Picker plugin for Flutter

[![pub package](https://img.shields.io/pub/v/image_picker.svg)](https://pub.dev/packages/image_picker)

A Flutter plugin for iOS and Android for picking images from the image library,
and taking new pictures with the camera.

|             | Android | iOS     | Web                             |
|-------------|---------|---------|---------------------------------|
| **Support** | SDK 21+ | iOS 11+ | [See `image_picker_for_web`][1] |

## Installation

First, add `image_picker` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### iOS

Starting with version **0.8.1** the iOS implementation uses PHPicker to pick (multiple) images on iOS 14 or higher.
As a result of implementing PHPicker it becomes impossible to pick HEIC images on the iOS simulator in iOS 14+. This is a known issue. Please test this on a real device, or test with non-HEIC images until Apple solves this issue. [63426347 - Apple known issue](https://www.google.com/search?q=63426347+apple&sxsrf=ALeKk01YnTMid5S0PYvhL8GbgXJ40ZS[…]t=gws-wiz&ved=0ahUKEwjKh8XH_5HwAhWL_rsIHUmHDN8Q4dUDCA8&uact=5)

Add the following keys to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.
  * This permission will not be requested if you always pass `false` for `requestFullMetadata`, but App Store policy requires including the plist entry.
* `NSCameraUsageDescription` - describe why your app needs access to the camera. This is called _Privacy - Camera Usage Description_ in the visual editor.
* `NSMicrophoneUsageDescription` - describe why your app needs access to the microphone, if you intend to record videos. This is called _Privacy - Microphone Usage Description_ in the visual editor.

### Android

Starting with version **0.8.1** the Android implementation support to pick (multiple) images on Android 4.3 or higher.

No configuration required - the plugin should work out of the box. It is
however highly recommended to prepare for Android killing the application when
low on memory. How to prepare for this is discussed in the [Handling
MainActivity destruction on Android](#handling-mainactivity-destruction-on-android)
section.

It is no longer required to add `android:requestLegacyExternalStorage="true"` as an attribute to the `<application>` tag in AndroidManifest.xml, as `image_picker` has been updated to make use of scoped storage.

**Note:** Images and videos picked using the camera are saved to your application's local cache, and should therefore be expected to only be around temporarily.
If you require your picked image to be stored permanently, it is your responsibility to move it to a more permanent location.

### Example

``` dart
import 'package:image_picker/image_picker.dart';

    ...
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // Capture a photo
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    // Pick a video
    final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);
    // Capture a video
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    // Pick multiple images
    final List<XFile>? images = await _picker.pickMultiImage();
    ...
```

### Handling MainActivity destruction on Android

When under high memory pressure the Android system may kill the MainActivity of
the application using the image_picker. On Android the image_picker makes use
of the default `Intent.ACTION_GET_CONTENT` or `MediaStore.ACTION_IMAGE_CAPTURE`
intents. This means that while the intent is executing the source application
is moved to the background and becomes eligable for cleanup when the system is
low on memory. When the intent finishes executing, Android will restart the
application. Since the data is never returned to the original call use the
`ImagePicker.retrieveLostData()` method to retrieve the lost data. For example:

```dart
Future<void> getLostData() async {
  final LostDataResponse response =
      await picker.retrieveLostData();
  if (response.isEmpty) {
    return;
  }
  if (response.files != null) {
    for (final XFile file in response.files) {
      _handleFile(file);
    }
  } else {
    _handleError(response.exception);
  }
}
```

This check should always be run at startup in order to detect and handle this
case. Please refer to the
[example app](https://pub.dev/packages/image_picker/example) for a more
complete example of handling this flow.

### Android Photo Picker

This package has optional [Android Photo Picker](https://developer.android.com/training/data-storage/shared/photopicker) functionality. 
[Learn how to use it](https://pub.dev/packages/image_picker_android).

## Migrating to 0.8.2+

Starting with version **0.8.2** of the image_picker plugin, new methods have been added for picking files that return `XFile` instances (from the [cross_file](https://pub.dev/packages/cross_file) package) rather than the plugin's own `PickedFile` instances. While the previous methods still exist, it is already recommended to start migrating over to their new equivalents. Eventually, `PickedFile` and the methods that return instances of it will be deprecated and removed.

#### Call the new methods

| Old API | New API |
|---------|---------|
| `PickedFile image = await _picker.getImage(...)` | `XFile image = await _picker.pickImage(...)` |
| `List<PickedFile> images = await _picker.getMultiImage(...)` | `List<XFile> images = await _picker.pickMultiImage(...)` |
| `PickedFile video = await _picker.getVideo(...)` | `XFile video = await _picker.pickVideo(...)` |
| `LostData response = await _picker.getLostData()` | `LostDataResponse response = await _picker.retrieveLostData()` |

[1]: https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform
