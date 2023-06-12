# Share plugin

[![Flutter Community: share_plus](https://fluttercommunity.dev/_github/header/share_plus)](https://github.com/fluttercommunity/community)

[![share_plus](https://github.com/fluttercommunity/plus_plugins/actions/workflows/share_plus.yaml/badge.svg)](https://github.com/fluttercommunity/plus_plugins/actions/workflows/share_plus.yaml)
[![pub points](https://img.shields.io/pub/points/share_plus?color=2E8B57&label=pub%20points)](https://pub.dev/packages/share_plus/score)
[![pub package](https://img.shields.io/pub/v/share_plus.svg)](https://pub.dev/packages/share_plus)

<a href="https://flutter.dev/docs/development/packages-and-plugins/favorites" target="_blank" rel="noreferrer noopener"><img src="../../../website/static/img/flutter-favorite-badge.png" width="100" alt="build"></a>

A Flutter plugin to share content from your Flutter app via the platform's
share dialog.

Wraps the `ACTION_SEND` Intent on Android and `UIActivityViewController`
on iOS.

## Platform Support

| Android | iOS | MacOS | Web | Linux | Windows |
| :-----: | :-: | :---: | :-: | :---: | :----: |
|   ✔️    | ✔️  |  ✔️   | ✔️  |  ✔️   |   ✔️   |

Also compatible with Windows and Linux by using "mailto" to share text via Email.

Sharing files is not supported on Windows and Linux.

## Usage

To use this plugin, add `share_plus` as a [dependency in your pubspec.yaml file](https://plus.fluttercommunity.dev/docs/overview).

## Example

Import the library.

```dart
import 'package:share_plus/share_plus.dart';
```

Then invoke the static `share` method anywhere in your Dart code.

```dart
Share.share('check out my website https://example.com');
```

The `share` method also takes an optional `subject` that will be used when
sharing to email.

```dart
Share.share('check out my website https://example.com', subject: 'Look what I made!');
```

To share one or multiple files invoke the static `shareFiles` method anywhere in your Dart code. Optionally you can also pass in `text` and `subject`.

```dart
Share.shareFiles(['${directory.path}/image.jpg'], text: 'Great picture');
Share.shareFiles(['${directory.path}/image1.jpg', '${directory.path}/image2.jpg']);
```

On web you can use `SharePlus.shareXFiles()`. This uses the [Web Share API](https://web.dev/web-share/)
if it's available. Otherwise it falls back to downloading the shared files.
See [Can I Use - Web Share API](https://caniuse.com/web-share) to understand
which browsers are supported. This builds on the [`cross_file`](https://pub.dev/packages/cross_file)
package.


```dart
Share.shareXFiles([XFile('assets/hello.txt')], text: 'Great picture');
```

Check out our documentation website to learn more. [Plus plugins documentation](https://plus.fluttercommunity.dev/docs/overview)

## Known Issues

### Sharing data created with XFile.fromData

When sharing data created with `XFile.fromData`, the plugin will write a temporal file inside the cache directory of the app, so it can be shared.

Althouth the OS should take care of deleting those files, it is advised, that you clean up this data once in a while (e.g. on app start).

You can access this directory using [path_provider](https://pub.dev/packages/path_provider) [getTemporaryDirectory](https://pub.dev/documentation/path_provider/latest/path_provider/getTemporaryDirectory.html).

Alternatively, don't use `XFile.fromData` and instead write the data down to a `File` with a path before sharing it, so you control when to delete it.

### Mobile platforms (Android and iOS)

#### Facebook limitations (WhatsApp, Instagram, Facebook Messenger)

Due to restrictions set up by Facebook this plugin isn't capable of sharing data reliably to Facebook related apps on Android and iOS. This includes eg. sharing text to the Facebook Messenger. If you require this functionality please check the native Facebook Sharing SDK ([https://developers.facebook.com/docs/sharing](https://developers.facebook.com/docs/sharing)) or search for other Flutter plugins implementing this SDK. More information can be found in [this issue](https://github.com/fluttercommunity/plus_plugins/issues/413).

#### iPad

`share_plus` requires iPad users to provide the `sharePositionOrigin` parameter.

Without it, `share_plus` will not work on iPads and may cause a crash or
letting the UI not responding.

To avoid that problem, provide the `sharePositionOrigin`.

For example:

```dart
// Use Builder to get the widget context
Builder(
  builder: (BuildContext context) {
    return ElevatedButton(
      onPressed: () => _onShare(context),
          child: const Text('Share'),
     );
  },
),

// _onShare method:
final box = context.findRenderObject() as RenderBox?;

await Share.share(
  text,
  subject: subject,
  sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
);
```

See the `main.dart` in the `example` for a complete example.

