A Dart [CSS](https://developer.mozilla.org/en-US/docs/Web/CSS) parser.

## Usage

Parsing CSS is easy!

```dart
import 'package:csslib/parser.dart';

main() {
  var stylesheet = parse(
      '.foo { color: red; left: 20px; top: 20px; width: 100px; height:200px }');
  print(stylesheet.toDebugString());
}
```

You can pass a `String` or `List<int>` to `parse`.
