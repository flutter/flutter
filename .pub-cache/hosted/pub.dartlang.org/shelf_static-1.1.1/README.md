[![pub package](https://img.shields.io/pub/v/shelf_static.svg)](https://pub.dev/packages/shelf_static)
[![package publisher](https://img.shields.io/pub/publisher/shelf_static.svg)](https://pub.dev/packages/shelf_static/publisher)

`shelf_static` is a `Handler` for the Dart `shelf` package.

### Example
```dart
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main() {
  var handler = createStaticHandler('example/files',
      defaultDocument: 'index.html');

  io.serve(handler, 'localhost', 8080);
}
```
