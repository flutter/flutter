# WebView for Flutter

[![pub package](https://img.shields.io/pub/v/webview_flutter.svg)](https://pub.dev/packages/webview_flutter)

A Flutter plugin that provides a WebView widget.

On iOS the WebView widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview);
On Android the WebView widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).

## Usage
Add `webview_flutter` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels). If you are targeting Android, make sure to read the *Android Platform Views* section below to choose the platform view mode that best suits your needs.

You can now include a WebView widget in your widget tree. See the
[WebView](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebView-class.html)
widget's Dartdoc for more details on how to use the widget.

## Android Platform Views
The WebView is relying on
[Platform Views](https://flutter.dev/docs/development/platform-integration/platform-views) to embed
the Android’s webview within the Flutter app. It supports two modes: *Virtual displays* (the current default) and *Hybrid composition*.

Here are some points to consider when choosing between the two:

* *Hybrid composition* mode has a built-in keyboard support while *Virtual displays* mode has multiple
[keyboard issues](https://github.com/flutter/flutter/issues?q=is%3Aopen+label%3Avd-only+label%3A%22p%3A+webview-keyboard%22)
* *Hybrid composition* mode requires Android SDK 19+ while *Virtual displays* mode requires Android SDK 20+
* *Hybrid composition* mode has [performance limitations](https://flutter.dev/docs/development/platform-integration/platform-views#performance) when working on Android versions prior to Android 10 while *Virtual displays* is performant on all supported Android versions 

|                             | Hybrid composition  | Virtual displays |
| --------------------------- | ------------------- | ---------------- |
| **Full keyboard supoport**  | yes                 | no               |
| **Android SDK support**     | 19+                 | 20+              |
| **Full performance**        | Android 10+         | always           |
| **The default**             | no                  | yes              |

### Using Virtual displays

The mode is currently enabled by default. You should however make sure to set the correct `minSdkVersion` in `android/app/build.gradle` (if it was previously lower than 20):

```groovy
android {
    defaultConfig {
        minSdkVersion 20
    }
}
```


### Using Hybrid Composition

1. Set the correct `minSdkVersion` in `android/app/build.gradle` (if it was previously lower than 19):

    ```groovy
    android {
        defaultConfig {
            minSdkVersion 19
        }
    }
    ```

2. Set `WebView.platform = SurfaceAndroidWebView();` in `initState()`.
    For example:
    
    ```dart
    import 'dart:io';
    
    import 'package:webview_flutter/webview_flutter.dart';

    class WebViewExample extends StatefulWidget {
      @override
      WebViewExampleState createState() => WebViewExampleState();
    }
    
    class WebViewExampleState extends State<WebViewExample> {
      @override
      void initState() {
        super.initState();
            // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
      }

      @override
      Widget build(BuildContext context) {
        return WebView(
          initialUrl: 'https://flutter.dev',
        );
      }
    }
    ```

### Enable Material Components for Android

To use Material Components when the user interacts with input elements in the WebView,
follow the steps described in the [Enabling Material Components instructions](https://flutter.dev/docs/deployment/android#enabling-material-components).

### Setting custom headers on POST requests

Currently, setting custom headers when making a post request with the WebViewController's `loadRequest` method is not supported on Android.
If you require this functionality, a workaround is to make the request manually, and then load the response data using `loadHTMLString` instead. 