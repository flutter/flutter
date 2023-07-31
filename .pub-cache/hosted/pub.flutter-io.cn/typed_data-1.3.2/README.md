[![Dart CI](https://github.com/dart-lang/typed_data/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/typed_data/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/typed_data.svg)](https://pub.dev/packages/typed_data)
[![package publisher](https://img.shields.io/pub/publisher/typed_data.svg)](https://pub.dev/packages/typed_data/publisher)

Helper libraries for working with typed data lists.

The `typed_data` package contains utility functions and classes that makes working with typed data lists easier.

## Using

The `typed_data` package can be imported using:

```dart
import 'package:typed_data/typed_data.dart';
```

## Typed buffers

Typed buffers are growable lists backed by typed arrays. These are similar to
the growable lists created by `<int>[]` or `<double>[]`, but store typed data
like a typed data list.
