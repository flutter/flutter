<p align="center">
  <img src="https://github.com/aloisdeniel/flutter_device_preview/raw/master/logo.png" alt="Device Preview for Flutter" />
</p>

<h4 align="center">Approximate how your app looks and performs on another device.</h4>

<p align="center">
  <a href="https://pub.dartlang.org/packages/device_preview"><img src="https://img.shields.io/pub/v/device_preview.svg"></a>
  <a href="https://www.buymeacoffee.com/aloisdeniel">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat">
  </a>
</p>

<p align="center">
  <img src="https://github.com/aloisdeniel/flutter_device_preview/raw/master/device_preview.gif" alt="Device Preview for Flutter" />
</p>

## Main features

* Preview any device from any device
* Change the device orientation
* Dynamic system configuration (*language, dark mode, text scaling factor, ...)*
* Freeform device with adjustable resolution and safe areas
* Keep the application state
* Plugin system (*Screenshot, File explorer, ...*)
* Customizable plugins

## Quickstart

### Add dependency to your pubspec file

Since Device Preview is a simple Dart package, you have to declare it as any other dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  device_preview: <latest version>
```

### Add DevicePreview

Wrap your app's root widget in a `DevicePreview` and make sure to :

* Set your app's `useInheritedMediaQuery` to `true`.
* Set your app's `builder` to `DevicePreview.appBuilder`.
* Set your app's `locale` to `DevicePreview.locale(context)`.

> Make sure to override the previous properties as described. If not defined, `MediaQuery` won't be simulated for the selected device.

```dart
import 'package:device_preview/device_preview.dart';

void main() => runApp(
  DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => MyApp(), // Wrap your app
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
```

## Documentation

<a href='https://aloisdeniel.github.io/flutter_device_preview/' target='_blank'>Open the website</a>

## Demo

<a href='https://flutter-device-preview.firebaseapp.com/' target='_blank'>Open the demo</a>

## Limitations

Think of Device Preview as a first-order approximation of how your app looks and feels on a mobile device. With Device Mode you don't actually run your code on a mobile device. You simulate the mobile user experience from your laptop, desktop or tablet.

> There are some aspects of mobile devices that Device Preview will never be able to simulate. When in doubt, your best bet is to actually run your app on a real device.