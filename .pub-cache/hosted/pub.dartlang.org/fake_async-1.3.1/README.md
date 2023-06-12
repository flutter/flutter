[![Dart CI](https://github.com/dart-lang/fake_async/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/fake_async/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/fake_async.svg)](https://pub.dev/packages/fake_async)
[![package publisher](https://img.shields.io/pub/publisher/fake_async.svg)](https://pub.dev/packages/fake_async/publisher)

This package provides a [`FakeAsync`][] class, which makes it easy to
deterministically test code that uses asynchronous features like `Future`s,
`Stream`s, `Timer`s, and microtasks. It creates an environment in which the user
can explicitly control Dart's notion of the "current time". When the time is
advanced, `FakeAsync` fires all asynchronous events that are scheduled for that
time period without actually needing the test to wait for real time to elapse.

[`FakeAsync`]: https://www.dartdocs.org/documentation/fake_async/latest/fake_async/FakeAsync-class.html

For example:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  test("Future.timeout() throws an error once the timeout is up", () {
    // Any code run within [fakeAsync] is run within the context of the
    // [FakeAsync] object passed to the callback.
    fakeAsync((async) {
      // All asynchronous features that rely on timing are automatically
      // controlled by [fakeAsync].
      expect(Completer().future.timeout(Duration(seconds: 5)),
          throwsA(isA<TimeoutException>()));

      // This will cause the timeout above to fire immediately, without waiting
      // 5 seconds of real time.
      async.elapse(Duration(seconds: 5));
    });
  });
}
```

## Integration With `clock`

`FakeAsync` can't control the time reported by [`DateTime.now()`][] or by
the [`Stopwatch`][] class, since they're not part of `dart:async`. However, if
you create them using the [`clock`][] package's [`clock.now()`][] or
[`clock.stopwatch()`][] functions, `FakeAsync` will automatically override
them to use the same notion of time as `dart:async` classes.

[`DateTime.now()`]: https://api.dart.dev/stable/dart-core/DateTime/DateTime.now.html
[`Stopwatch`]: https://api.dart.dev/stable/dart-core/Stopwatch-class.html
[`clock`]: https://pub.dev/packages/clock
[`clock.now()`]: https://pub.dev/documentation/clock/latest/clock/Clock/now.html
[`clock.stopwatch()`]: https://pub.dev/documentation/clock/latest/clock/Clock/stopwatch.html
