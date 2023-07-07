[![Dart CI](https://github.com/dart-lang/clock/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/clock/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/clock.svg)](https://pub.dev/packages/clock)
[![package publisher](https://img.shields.io/pub/publisher/clock.svg)](https://pub.dev/packages/clock/publisher)

This package provides a [`Clock`][] class which encapsulates the notion of the
"current time" and provides easy access to points relative to the current time.
Different `Clock`s can have a different notion of the current time, and the
default top-level [`clock`][]'s notion can be swapped out to reliably test
timing-dependent code.

[`Clock`]: https://pub.dev/documentation/clock/latest/clock/Clock-class.html
[`clock`]: https://pub.dev/documentation/clock/latest/clock/clock.html

For example, you can use `clock` in your libraries like this:

```dart
// run_with_timing.dart
import 'package:clock/clock.dart';

/// Runs [callback] and prints how long it took.
T runWithTiming<T>(T Function() callback) {
  var stopwatch = clock.stopwatch()..start();
  var result = callback();
  print('It took ${stopwatch.elapsed}!');
  return result;
}
```

...and then test your code using the [`fake_async`][] package, which
automatically overrides the current clock:

[`fake_async`]: https://pub.dartlang.org/packages/fake_async

```dart
// run_with_timing_test.dart
import 'run_with_timing.dart';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  test('runWithTiming() prints the elapsed time', () {
    FakeAsync().run((async) {
      expect(() {
        runWithTiming(() {
          async.elapse(Duration(seconds: 10));
        });
      }, prints('It took 0:00:10.000000!'));
    });
  });
}
```
