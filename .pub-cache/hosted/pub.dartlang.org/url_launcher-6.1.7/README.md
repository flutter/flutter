<?code-excerpt path-base="excerpts/packages/url_launcher_example"?>

# url_launcher

[![pub package](https://img.shields.io/pub/v/url_launcher.svg)](https://pub.dev/packages/url_launcher)

A Flutter plugin for launching a URL.

|             | Android | iOS  | Linux | macOS  | Web | Windows     |
|-------------|---------|------|-------|--------|-----|-------------|
| **Support** | SDK 16+ | 9.0+ | Any   | 10.11+ | Any | Windows 10+ |

## Usage

To use this plugin, add `url_launcher` as a [dependency in your pubspec.yaml file](https://flutter.dev/platform-plugins/).

### Example

<?code-excerpt "basic.dart (basic-example)"?>
``` dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _url = Uri.parse('https://flutter.dev');

void main() => runApp(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: _launchUrl,
              child: Text('Show Flutter homepage'),
            ),
          ),
        ),
      ),
    );

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}
```

See the example app for more complex examples.

## Configuration

### iOS
Add any URL schemes passed to `canLaunchUrl` as `LSApplicationQueriesSchemes`
entries in your Info.plist file, otherwise it will return false.

Example:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>sms</string>
  <string>tel</string>
</array>
```

See [`-[UIApplication canOpenURL:]`](https://developer.apple.com/documentation/uikit/uiapplication/1622952-canopenurl) for more details.

### Android

Add any URL schemes passed to `canLaunchUrl` as `<queries>` entries in your
`AndroidManifest.xml`, otherwise it will return false in most cases starting
on Android 11 (API 30) or higher. A `<queries>`
element must be added to your manifest as a child of the root element.

Example:

<?code-excerpt "../../android/app/src/main/AndroidManifest.xml (android-queries)" plaster="none"?>
``` xml
<!-- Provide required visibility configuration for API level 30 and above -->
<queries>
  <!-- If your app checks for SMS support -->
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="sms" />
  </intent>
  <!-- If your app checks for call support -->
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="tel" />
  </intent>
</queries>
```

See
[the Android documentation](https://developer.android.com/training/package-visibility/use-cases)
for examples of other queries.

## Supported URL schemes

The provided URL is passed directly to the host platform for handling. The
supported URL schemes therefore depend on the platform and installed apps.

Commonly used schemes include:

| Scheme | Example | Action |
|:---|:---|:---|
| `https:<URL>` | `https://flutter.dev` | Open `<URL>` in the default browser |
| `mailto:<email address>?subject=<subject>&body=<body>` | `mailto:smith@example.org?subject=News&body=New%20plugin` | Create email to `<email address>` in the default email app |
| `tel:<phone number>` | `tel:+1-555-010-999` | Make a phone call to `<phone number>` using the default phone app |
| `sms:<phone number>` | `sms:5550101234` | Send an SMS message to `<phone number>` using the default messaging app |
| `file:<path>` | `file:/home` | Open file or folder using default app association, supported on desktop platforms |

More details can be found here for [iOS](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html)
and [Android](https://developer.android.com/guide/components/intents-common.html)

URL schemes are only supported if there are apps installed on the device that can
support them. For example, iOS simulators don't have a default email or phone
apps installed, so can't open `tel:` or `mailto:` links.

### Checking supported schemes

If you need to know at runtime whether a scheme is guaranteed to work before
using it (for instance, to adjust your UI based on what is available), you can
check with [`canLaunchUrl`](https://pub.dev/documentation/url_launcher/latest/url_launcher/canLaunchUrl.html).

However, `canLaunchUrl` can return false even if `launchUrl` would work in
some circumstances (in web applications, on mobile without the necessary
configuration as described above, etc.), so in cases where you can provide
fallback behavior it is better to use `launchUrl` directly and handle failure.
For example, a UI button that would have sent feedback email using a `mailto` URL
might instead open a web-based feedback form using an `https` URL on failure,
rather than disabling the button if `canLaunchUrl` returns false for `mailto`.

### Encoding URLs

URLs must be properly encoded, especially when including spaces or other special
characters. In general this is handled automatically by the
[`Uri` class](https://api.dart.dev/dart-core/Uri-class.html).

**However**, for any scheme other than `http` or `https`, you should use the
`query` parameter and the `encodeQueryParameters` function shown below rather
than `Uri`'s `queryParameters` constructor argument for any query parameters,
due to [a bug](https://github.com/dart-lang/sdk/issues/43838) in the way `Uri`
encodes query parameters. Using `queryParameters` will result in spaces being
converted to `+` in many cases.

<?code-excerpt "encoding.dart (encode-query-parameters)"?>
```dart
String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
// ···
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'smith@example.com',
    query: encodeQueryParameters(<String, String>{
      'subject': 'Example Subject & Symbols are allowed!',
    }),
  );

  launchUrl(emailLaunchUri);
```

Encoding for `sms` is slightly different:

<?code-excerpt "encoding.dart (sms)"?>
```dart
final Uri smsLaunchUri = Uri(
  scheme: 'sms',
  path: '0118 999 881 999 119 7253',
  queryParameters: <String, String>{
    'body': Uri.encodeComponent('Example Subject & Symbols are allowed!'),
  },
);
```

### URLs not handled by `Uri`

In rare cases, you may need to launch a URL that the host system considers
valid, but cannot be expressed by `Uri`. For those cases, alternate APIs using
strings are available by importing `url_launcher_string.dart`.

Using these APIs in any other cases is **strongly discouraged**, as providing
invalid URL strings was a very common source of errors with this plugin's
original APIs.

### File scheme handling

`file:` scheme can be used on desktop platforms: Windows, macOS, and Linux.

We recommend checking first whether the directory or file exists before calling `launchUrl`.

Example:

<?code-excerpt "files.dart (file)"?>
```dart
final String filePath = testFile.absolute.path;
final Uri uri = Uri.file(filePath);

if (!File(uri.toFilePath()).existsSync()) {
  throw '$uri does not exist!';
}
if (!await launchUrl(uri)) {
  throw 'Could not launch $uri';
}
```

#### macOS file access configuration

If you need to access files outside of your application's sandbox, you will need to have the necessary
[entitlements](https://docs.flutter.dev/desktop#entitlements-and-the-app-sandbox).

## Browser vs in-app Handling

On some platforms, web URLs can be launched either in an in-app web view, or
in the default browser. The default behavior depends on the platform (see
[`launchUrl`](https://pub.dev/documentation/url_launcher/latest/url_launcher/launchUrl.html)
for details), but a specific mode can be used on supported platforms by
passing a `LaunchMode`.
