# [![Flutter logo][]][flutter.dev]

[![Build Status - Cirrus][]][Build status]
[![Gitter Channel][]][Gitter badge]

Flutter is Google's mobile app SDK for crafting high-quality native interfaces
on iOS and Android in record time. Flutter works with existing code, is used by
developers and organizations around the world, and is free and open source.

## Documentation

* [Install Flutter](https://flutter.dev/get-started/)
* [Flutter documentation](https://flutter.dev/docs)
* [Development wiki](https://github.com/flutter/flutter/wiki)
* [Contributing to Flutter](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)

For announcements about new releases and breaking changes, follow the
[flutter-announce@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-announce)
mailing list.

## About Flutter

We think Flutter will help you create beautiful, fast apps, with a productive,
extensible and open development model.

### Beautiful apps

We want to enable designers to deliver their full creative vision without being
forced to water it down due to limitations of the underlying framework.
Flutter's [layered architecture] gives you control over every pixel on the
screen, and its powerful compositing capabilities let you overlay and animate
graphics, video, text and controls without limitation. Flutter includes a full
[set of widgets][widget catalog] that deliver pixel-perfect experiences on both
iOS and Android.

![Reflectly hero image][Reflectly hero image]

### Fast apps

Flutter is fast. It's powered by the same hardware-accelerated [Skia] 2D
graphics library that underpins Chrome and Android. We architected Flutter to
support glitch-free, jank-free graphics at the native speed of your device.
Flutter code is powered by the world-class [Dart platform], which enables
compilation to native 32-bit and 64-bit ARM code for iOS and Android.

### Productive development

Flutter offers stateful hot reload, allowing you to make changes to your code
and see the results instantly without restarting your app or losing its state.

[![Hot reload animation][]][Hot reload]

### Extensible and open model

Flutter works with any development tool, but includes editor plug-ins for both
[Visual Studio Code] and [IntelliJ / Android Studio]. Flutter provides
[thousands of packages][Flutter packages] to speed your development, regardless
of your target platform. And accessing platform features is easy. Here is a
snippet from our [interop example]:

```dart
Future<void> getBatteryLevel() async {
  var batteryLevel = 'unknown';
  try {
    int result = await methodChannel.invokeMethod('getBatteryLevel');
    batteryLevel = 'Battery level: $result%';
  } on PlatformException {
    batteryLevel = 'Failed to get battery level.';
  }
  setState(() {
    _batteryLevel = batteryLevel;
  });
}
```

Flutter is a fully open source project, and we welcome contributions.
Information on how to get started can be found at our
[contributor guide](CONTRIBUTING.md).

[Flutter logo]: https://flutter.dev/assets/flutter-lockup-4cb0ee072ab312e59784d9fbf4fb7ad42688a7fdaea1270ccf6bbf4f34b7e03f.svg
[flutter.dev]: https://flutter.dev
[Build Status - Cirrus]: https://api.cirrus-ci.com/github/flutter/flutter.svg
[Build status]: https://cirrus-ci.com/github/flutter/flutter/master
[Gitter Channel]: https://badges.gitter.im/flutter/flutter.svg
[Gitter badge]: https://gitter.im/flutter/flutter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[layered architecture]: https://flutter.dev/docs/resources/inside-flutter
[widget catalog]: https://flutter.dev/widgets/
[Reflectly hero image]: https://github.com/flutter/website/blob/master/src/images/homepage/reflectly-hero-600px.png
[Skia]: https://skia.org/
[Dart platform]: https://dart.dev/
[Hot reload animation]: https://raw.githubusercontent.com/flutter/website/master/src/_assets/image/tools/android-studio/hot-reload.gif
[Hot reload]: https://flutter.dev/docs/development/tools/hot-reload
[Visual Studio Code]: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
[IntelliJ / Android Studio]: https://plugins.jetbrains.com/plugin/9212-flutter
[Flutter packages]: https://pub.dev/flutter
[interop example]: https://github.com/flutter/flutter/tree/master/examples/platform_channel