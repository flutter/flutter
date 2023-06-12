<?code-excerpt path-base="excerpts/packages/image_picker_example"?>

# image\_picker\_android

The Android implementation of [`image_picker`][1].

## Usage

This package is [endorsed][2], which means you can simply use `image_picker`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

## Photo Picker

This package has optional Android Photo Picker functionality.

To use this feature, add the following code to your app before calling any `image_picker` APIs:

<?code-excerpt "main.dart (photo-picker-example)"?>
```dart
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
// ···
  final ImagePickerPlatform imagePickerImplementation =
      ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
```

[1]: https://pub.dev/packages/image_picker
[2]: https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin
