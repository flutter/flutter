[![Dart CI](https://github.com/dart-lang/term_glyph/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/term_glyph/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/term_glyph.svg)](https://pub.dev/packages/term_glyph)
[![package publisher](https://img.shields.io/pub/publisher/term_glyph.svg)](https://pub.dev/packages/term_glyph/publisher)

This library contains getters for useful Unicode glyphs as well as plain ASCII
alternatives. It's intended to be used in command-line applications that may run
in places where Unicode isn't well-supported and libraries that may be used by
those applications.

We recommend that you import this library with the prefix "glyph". For example:

```dart
import 'package:term_glyph/term_glyph.dart' as glyph;

/// Formats [items] into a bulleted list, with one item per line.
String bulletedList(List<String> items) =>
    items.map((item) => "${glyph.bullet} $item").join("\n");
```

## ASCII Mode

Some shells are unable to display Unicode characters, so this package is able to
transparently switch its glyphs to ASCII alternatives by setting [the `ascii`
attribute][ascii]. When this attribute is `true`, all glyphs use ASCII
characters instead. It currently defaults to `false`, although in the future it
may default to `true` for applications running on the Dart VM on Windows. For
example:

[ascii]: https://pub.dev/documentation/term_glyph/latest/term_glyph/ascii.html

```dart
import 'dart:io';

import 'package:term_glyph/term_glyph.dart' as glyph;

void main() {
  glyph.ascii = Platform.isWindows;

  // Prints "Unicode => ASCII" on Windows, "Unicode ━▶ ASCII" everywhere else.
  print("Unicode ${glyph.rightArrow} ASCII");
}
```

All ASCII glyphs are guaranteed to be the same number of characters as the
corresponding Unicode glyphs, so that they line up properly when printed on a
terminal. The specific ASCII text for a given Unicode glyph may change over
time; this is not considered a breaking change.
