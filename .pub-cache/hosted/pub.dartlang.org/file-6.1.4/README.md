[![pub package](https://img.shields.io/pub/v/file.svg)](https://pub.dev/packages/file)
[![package publisher](https://img.shields.io/pub/publisher/file.svg)](https://pub.dev/packages/file/publisher)

A generic file system abstraction for Dart.

## Features

Like `dart:io`, `package:file` supplies a rich Dart-idiomatic API for accessing
a file system.

Unlike `dart:io`, `package:file`:

- Can be used to implement custom file systems.
- Comes with an in-memory implementation out-of-the-box, making it super-easy to
  test code that works with the file system.
- Allows using multiple file systems simultaneously. A file system is a
  first-class object. Instantiate however many you want and use them all.

## Usage

Implement your own custom file system:

```dart
import 'package:file/file.dart';

class FooBarFileSystem implements FileSystem { ... }
```

Use the in-memory file system:

```dart
import 'package:file/memory.dart';

var fs = MemoryFileSystem();
```

Use the local file system (requires dart:io access):

```dart
import 'package:file/local.dart';

var fs = const LocalFileSystem();
```
