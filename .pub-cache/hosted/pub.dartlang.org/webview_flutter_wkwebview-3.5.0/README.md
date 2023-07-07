# webview\_flutter\_wkwebview

The Apple WKWebView implementation of [`webview_flutter`][1].

## Usage

This package is [endorsed][2], which means you can simply use `webview_flutter`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

### External Native API

The plugin also provides a native API accessible by the native code of iOS applications or packages.
This API follows the convention of breaking changes of the Dart API, which means that any changes to
the class that are not backwards compatible will only be made with a major version change of the
plugin. Native code other than this external API does not follow breaking change conventions, so
app or plugin clients should not use any other native APIs.

The API can be accessed by importing the native plugin `webview_flutter_wkwebview`:

Objective-C:

```objectivec
@import webview_flutter_wkwebview;
```

Then you will have access to the native class `FWFWebViewFlutterWKWebViewExternalAPI`.

## Contributing

This package uses [pigeon][3] to generate the communication layer between Flutter and the host
platform (iOS). The communication interface is defined in the `pigeons/web_kit.dart`
file. After editing the communication interface regenerate the communication layer by running
`dart run pigeon --input pigeons/web_kit.dart`.

Besides [pigeon][3] this package also uses [mockito][4] to generate mock objects for testing
purposes. To generate the mock objects run the following command:
```bash
dart run build_runner build --delete-conflicting-outputs
```

If you would like to contribute to the plugin, check out our [contribution guide][5].

[1]: https://pub.dev/packages/webview_flutter
[2]: https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin
[3]: https://pub.dev/packages/pigeon
[4]: https://pub.dev/packages/mockito
[5]: https://github.com/flutter/packages/blob/main/CONTRIBUTING.md
