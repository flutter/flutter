Welcome to the Flutter API reference documentation.

Flutter is Google’s mobile UI framework for crafting high-quality native
interfaces on iOS and Android in record time. Flutter works with existing code,
is used by developers and organizations around the world, and is free and open
source.

The API reference herein covers all libraries that are exported by the Flutter
SDK.

### More Documentation

This site hosts Flutter's API documentation. Other documentation can be found at
the following locations:

* [flutter.io](https://flutter.io/) (main site)
* [Installation](https://flutter.io/docs/get-started/install)
* [Codelabs](https://flutter.io/docs/codelabs)
* [Contributing to Flutter](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)

### Importing a Library

#### Framework Libraries

Libraries in the "Libraries" section below (or in the left navigation) are part
of the core Flutter framework and are imported using
`'package:flutter/<library>.dart'`, like so:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
```

#### Dart Libraries

Libraries in the "Dart" section exist in the `'dart:'` namespace and are imported
using `'dart:<library>'`, like so:

```dart
import 'dart:async';
import 'dart:ui';
```

Except for `'dart:core'`, you must import a Dart library before you can use it.

#### Other Libraries

Libraries in other sections are supporting libraries that ship with Flutter.
They are organized by package and are imported using
`'package:<package>/<library>.dart'`, like so:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:file/local.dart';
```

### Finding Other Libraries

Flutter has a rich community of packages that have been contributed by the
open-source community. You can browse those packages at
[pub.dartlang.org](http://pub.dartlang.org/flutter)
