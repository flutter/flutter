# Welcome to the Flutter API reference documentation!

Flutter is Google's SDK for crafting beautiful, fast user experiences for
mobile, web, and desktop from a single codebase. Flutter works with existing
code, is used by developers and organizations around the world, and is free
and open source.

This API reference covers all libraries that are exported by the Flutter
SDK.

## More Documentation

This site hosts Flutter's API documentation. Other documentation can be found at
the following locations:

* [flutter.dev](https://flutter.dev) (main Flutter site)
* [Stable channel API Docs](https://api.flutter.dev)
* [Main channel API Docs](https://master-api.flutter.dev)
* Engine Embedder API documentation:
  * [Android Embedder](../javadoc/index.html)
  * [iOS Embedder](../ios-embedder/index.html)
  * [macOS Embedder](../macos-embedder/index.html)
  * [Linux Embedder](../linux-embedder/index.html)
  * [Windows Embedder](../windows-embedder/index.html)
  * [Web Embedder](dart-ui_web/dart-ui_web-library.html)
* [Installation](https://flutter.dev/docs/get-started/install)
* [Codelabs](https://flutter.dev/docs/codelabs)
* [Contributing to Flutter](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)

## Offline Documentation

In addition to the online sites above, Flutter's documentation can be downloaded
as an HTML documentation ZIP file for use when offline or when you have a poor
internet connection.

**Warning: the offline documentation files are quite large, approximately 700 MB
to 900 MB.**

Offline HTML documentation ZIP bundles:

 * [Stable channel](https://api.flutter.dev/offline/flutter.docs.zip)
 * [Master channel](https://master-api.flutter.dev/offline/flutter.docs.zip)

Or, you can add Flutter to the open-source [Zeal](https://zealdocs.org/) app
using the following XML configurations. Follow the instructions in the
application for adding a feed.

 * Stable channel Zeal XML configuration URL:
   <https://api.flutter.dev/offline/flutter.xml>
 * Master channel Zeal XML configuration URL:
   <https://master-api.flutter.dev/offline/flutter.xml>

## Importing a Library

### Framework Libraries

Libraries in the "Libraries" section below (or in the left navigation) are part
of the core Flutter framework and are imported using
`'package:flutter/<library>.dart'`, like so:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
```

### Dart Libraries

Libraries in the "Dart" section exist in the `dart:` namespace and are imported
using `'dart:<library>'`, like so:

```dart
import 'dart:async';
import 'dart:ui';
```

Except for `'dart:core'`, you must import a Dart library before you can use it.

### Supporting Libraries

Libraries in other sections are supporting libraries that ship with Flutter.
They are organized by package and are imported using
`'package:<package>/<library>.dart'`, like so:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:file/local.dart';
```

## Packages on pub.dev

Flutter has a rich ecosystem of packages that have been contributed by the
Flutter team and the broader open source community to a central repository.
Among the thousands of packages, you'll find support for Firebase, Google
Fonts, hardware services like Bluetooth and camera, new widgets and
animations, and integration with other popular web services. You can browse
those packages at [pub.dev](https://pub.dev).
