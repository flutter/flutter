[![Dart CI](https://github.com/dart-lang/string_scanner/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/string_scanner/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/string_scanner.svg)](https://pub.dev/packages/string_scanner)
[![package publisher](https://img.shields.io/pub/publisher/string_scanner.svg)](https://pub.dev/packages/string_scanner/publisher)

This package exposes a `StringScanner` type that makes it easy to parse a string
using a series of `Pattern`s. For example:

```dart
import 'dart:math' as math;

import 'package:string_scanner/string_scanner.dart';

num parseNumber(String source) {
  // Scan a number ("1", "1.5", "-3").
  final scanner = StringScanner(source);

  // [Scanner.scan] tries to consume a [Pattern] and returns whether or not it
  // succeeded. It will move the scan pointer past the end of the pattern.
  final negative = scanner.scan('-');

  // [Scanner.expect] consumes a [Pattern] and throws a [FormatError] if it
  // fails. Like [Scanner.scan], it will move the scan pointer forward.
  scanner.expect(RegExp(r'\d+'));

  // [Scanner.lastMatch] holds the [MatchData] for the most recent call to
  // [Scanner.scan], [Scanner.expect], or [Scanner.matches].
  var number = num.parse(scanner.lastMatch[0]);

  if (scanner.scan('.')) {
    scanner.expect(RegExp(r'\d+'));
    final decimal = scanner.lastMatch[0];
    number += int.parse(decimal) / math.pow(10, decimal.length);
  }

  // [Scanner.expectDone] will throw a [FormatError] if there's any input that
  // hasn't yet been consumed.
  scanner.expectDone();

  return (negative ? -1 : 1) * number;
}
```
