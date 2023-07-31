[![Dart CI](https://github.com/dart-lang/matcher/actions/workflows/ci.yml/badge.svg)](https://github.com/dart-lang/matcher/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/matcher.svg)](https://pub.dev/packages/matcher)
[![package publisher](https://img.shields.io/pub/publisher/matcher.svg)](https://pub.dev/packages/matcher/publisher)

Support for specifying test expectations, such as for unit tests.

The matcher library provides a third-generation assertion mechanism, drawing
inspiration from [Hamcrest](https://code.google.com/p/hamcrest/).

For more information on testing, see
[Unit Testing with Dart](https://github.com/dart-lang/test/blob/master/pkgs/test/README.md#writing-tests).

## Using matcher

Expectations start with a call to [`expect()`] or [`expectAsync()`].

[`expect()`]: https://pub.dev/documentation/matcher/latest/expect/expect.html
[`expectAsync()`]: https://pub.dev/documentation/matcher/latest/expect/expectAsync.html

Any matchers package can be used with `expect()` to do
complex validations:

[`matcher`]: https://pub.dev/documentation/matcher/latest/matcher/matcher-library.html

```dart
import 'package:test/test.dart';

void main() {
  test('.split() splits the string on the delimiter', () {
    expect('foo,bar,baz', allOf([
      contains('foo'),
      isNot(startsWith('bar')),
      endsWith('baz')
    ]));
  });
}
```

If a non-matcher value is passed, it will be wrapped with [`equals()`].

[`equals()`]: https://pub.dev/documentation/matcher/latest/expect/equals.html

## Exception matchers

You can also test exceptions with the [`throwsA()`] function or a matcher such
as [`throwsFormatException`]:

[`throwsA()`]: https://pub.dev/documentation/matcher/latest/expect/throwsA.html
[`throwsFormatException`]: https://pub.dev/documentation/matcher/latest/expect/throwsFormatException-constant.html

```dart
import 'package:test/test.dart';

void main() {
  test('.parse() fails on invalid input', () {
    expect(() => int.parse('X'), throwsFormatException);
  });
}
```

### Future Matchers

There are a number of useful functions and matchers for more advanced
asynchrony. The [`completion()`] matcher can be used to test `Futures`; it
ensures that the test doesn't finish until the `Future` completes, and runs a
matcher against that `Future`'s value.

[`completion()`]: https://pub.dev/documentation/matcher/latest/expect/completion.html

```dart
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Future.value() returns the value', () {
    expect(Future.value(10), completion(equals(10)));
  });
}
```

The [`throwsA()`] matcher and the various [`throwsExceptionType`] matchers work
with both synchronous callbacks and asynchronous `Future`s. They ensure that a
particular type of exception is thrown:

[`throwsExceptionType`]: https://pub.dev/documentation/matcher/latest/expect/throwsException-constant.html

```dart
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Future.error() throws the error', () {
    expect(Future.error('oh no'), throwsA(equals('oh no')));
    expect(Future.error(StateError('bad state')), throwsStateError);
  });
}
```

The [`expectAsync()`] function wraps another function and has two jobs. First,
it asserts that the wrapped function is called a certain number of times, and
will cause the test to fail if it's called too often; second, it keeps the test
from finishing until the function is called the requisite number of times.

```dart
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Stream.fromIterable() emits the values in the iterable', () {
    var stream = Stream.fromIterable([1, 2, 3]);

    stream.listen(expectAsync1((number) {
      expect(number, inInclusiveRange(1, 3));
    }, count: 3));
  });
}
```

[`expectAsync()`]: https://pub.dev/documentation/matcher/latest/expect/expectAsync.html

### Stream Matchers

The `test` package provides a suite of powerful matchers for dealing with
[asynchronous streams][Stream]. They're expressive and composable, and make it
easy to write complex expectations about the values emitted by a stream. For
example:

[Stream]: https://api.dart.dev/stable/dart-async/Stream-class.html

```dart
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('process emits status messages', () {
    // Dummy data to mimic something that might be emitted by a process.
    var stdoutLines = Stream.fromIterable([
      'Ready.',
      'Loading took 150ms.',
      'Succeeded!'
    ]);

    expect(stdoutLines, emitsInOrder([
      // Values match individual events.
      'Ready.',

      // Matchers also run against individual events.
      startsWith('Loading took'),

      // Stream matchers can be nested. This asserts that one of two events are
      // emitted after the "Loading took" line.
      emitsAnyOf(['Succeeded!', 'Failed!']),

      // By default, more events are allowed after the matcher finishes
      // matching. This asserts instead that the stream emits a done event and
      // nothing else.
      emitsDone
    ]));
  });
}
```

A stream matcher can also match the [`async`] package's [`StreamQueue`] class,
which allows events to be requested from a stream rather than pushed to the
consumer. The matcher will consume the matched events, but leave the rest of the
queue alone so that it can still be used by the test, unlike a normal `Stream`
which can only have one subscriber. For example:

[`async`]: https://pub.dev/packages/async
[`StreamQueue`]: https://pub.dev/documentation/async/latest/async/StreamQueue-class.html

```dart
import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  test('process emits a WebSocket URL', () async {
    // Wrap the Stream in a StreamQueue so that we can request events.
    var stdout = StreamQueue(Stream.fromIterable([
      'WebSocket URL:',
      'ws://localhost:1234/',
      'Waiting for connection...'
    ]));

    // Ignore lines from the process until it's about to emit the URL.
    await expectLater(stdout, emitsThrough('WebSocket URL:'));

    // Parse the next line as a URL.
    var url = Uri.parse(await stdout.next);
    expect(url.host, equals('localhost'));

    // You can match against the same StreamQueue multiple times.
    await expectLater(stdout, emits('Waiting for connection...'));
  });
}
```

The following built-in stream matchers are available:

*   [`emits()`] matches a single data event.
*   [`emitsError()`] matches a single error event.
*   [`emitsDone`] matches a single done event.
*   [`mayEmit()`] consumes events if they match an inner matcher, without
    requiring them to match.
*   [`mayEmitMultiple()`] works like `mayEmit()`, but it matches events against
    the matcher as many times as possible.
*   [`emitsAnyOf()`] consumes events matching one (or more) of several possible
    matchers.
*   [`emitsInOrder()`] consumes events matching multiple matchers in a row.
*   [`emitsInAnyOrder()`] works like `emitsInOrder()`, but it allows the
    matchers to match in any order.
*   [`neverEmits()`] matches a stream that finishes *without* matching an inner
    matcher.

You can also define your own custom stream matchers with [`StreamMatcher()`].

[`emits()`]: https://pub.dev/documentation/matcher/latest/expect/emits.html
[`emitsError()`]: https://pub.dev/documentation/matcher/latest/expect/emitsError.html
[`emitsDone`]: https://pub.dev/documentation/matcher/latest/expect/emitsDone.html
[`mayEmit()`]: https://pub.dev/documentation/matcher/latest/expect/mayEmit.html
[`mayEmitMultiple()`]: https://pub.dev/documentation/matcher/latest/expect/mayEmitMultiple.html
[`emitsAnyOf()`]: https://pub.dev/documentation/matcher/latest/expect/emitsAnyOf.html
[`emitsInOrder()`]: https://pub.dev/documentation/matcher/latest/expect/emitsInOrder.html
[`emitsInAnyOrder()`]: https://pub.dev/documentation/matcher/latest/expect/emitsInAnyOrder.html
[`neverEmits()`]: https://pub.dev/documentation/matcher/latest/expect/neverEmits.html
[`StreamMatcher()`]: https://pub.dev/documentation/matcher/latest/expect/StreamMatcher-class.html

## Best Practices

### Prefer semantically meaningful matchers to comparing derived values

Matchers which have knowledge of the semantics that are tested are able to emit
more meaningful messages which don't require reading test source to understand
why the test failed. For instance compare the failures between
`expect(someList.length, 1)`, and `expect(someList, hasLength(1))`:

```
// expect(someList.length, 1);
  Expected: <1>
    Actual: <2>
```

```
// expect(someList, hasLength(1));
  Expected: an object with length of <1>
    Actual: ['expected value', 'unexpected value']
     Which: has length of <2>

```
