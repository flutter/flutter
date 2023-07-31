// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test_api/hooks.dart';

import 'async_matcher.dart';
import 'util/pretty_print.dart';

/// This function is deprecated.
///
/// Use [throwsA] instead. We strongly recommend that you add assertions about
/// at least the type of the error, but you can write `throwsA(anything)` to
/// mimic the behavior of this matcher.
@Deprecated('Will be removed in 0.13.0')
const Matcher throws = Throws();

/// This can be used to match three kinds of objects:
///
/// * A [Function] that throws an exception when called. The function cannot
///   take any arguments. If you want to test that a function expecting
///   arguments throws, wrap it in another zero-argument function that calls
///   the one you want to test.
///
/// * A [Future] that completes with an exception. Note that this creates an
///   asynchronous expectation. The call to `expect()` that includes this will
///   return immediately and execution will continue. Later, when the future
///   completes, the actual expectation will run.
///
/// * A [Function] that returns a [Future] that completes with an exception.
///
/// In all three cases, when an exception is thrown, this will test that the
/// exception object matches [matcher]. If [matcher] is not an instance of
/// [Matcher], it will implicitly be treated as `equals(matcher)`.
///
/// Examples:
/// ```dart
/// void functionThatThrows() => throw SomeException();
///
/// void functionWithArgument(bool shouldThrow) {
///   if (shouldThrow) {
///     throw SomeException();
///   }
/// }
///
/// Future<void> asyncFunctionThatThrows() async => throw SomeException();
///
/// expect(functionThatThrows, throwsA(isA<SomeException>()));
///
/// expect(() => functionWithArgument(true), throwsA(isA<SomeException>()));
///
/// var future = asyncFunctionThatThrows();
/// await expectLater(future, throwsA(isA<SomeException>()));
///
/// await expectLater(
///     asyncFunctionThatThrows, throwsA(isA<SomeException>()));
/// ```
Matcher throwsA(matcher) => Throws(wrapMatcher(matcher));

/// Use the [throwsA] function instead.
@Deprecated('Will be removed in 0.13.0')
class Throws extends AsyncMatcher {
  final Matcher? _matcher;

  const Throws([Matcher? matcher]) : _matcher = matcher;

  // Avoid async/await so we synchronously fail if we match a synchronous
  // function.
  @override
  dynamic /*FutureOr<String>*/ matchAsync(item) {
    if (item is! Function && item is! Future) {
      return 'was not a Function or Future';
    }

    if (item is Future) {
      return _matchFuture(item, 'emitted ');
    }

    try {
      var value = item();
      if (value is Future) {
        return _matchFuture(value, 'returned a Future that emitted ');
      }

      return indent(prettyPrint(value), first: 'returned ');
    } catch (error, trace) {
      return _check(error, trace);
    }
  }

  /// Matches [future], using try/catch since `onError` doesn't seem to work
  /// properly in nnbd.
  Future<String?> _matchFuture(
      Future<dynamic> future, String messagePrefix) async {
    try {
      var value = await future;
      return indent(prettyPrint(value), first: messagePrefix);
    } catch (error, trace) {
      return _check(error, trace);
    }
  }

  @override
  Description describe(Description description) {
    if (_matcher == null) {
      return description.add('throws');
    } else {
      return description.add('throws ').addDescriptionOf(_matcher);
    }
  }

  /// Verifies that [error] matches [_matcher] and returns a [String]
  /// description of the failure if it doesn't.
  String? _check(error, StackTrace? trace) {
    if (_matcher == null) return null;

    var matchState = {};
    if (_matcher!.matches(error, matchState)) return null;

    var result = _matcher!
        .describeMismatch(error, StringDescription(), matchState, false)
        .toString();

    var buffer = StringBuffer();
    buffer.writeln(indent(prettyPrint(error), first: 'threw '));
    if (trace != null) {
      buffer.writeln(indent(
          TestHandle.current.formatStackTrace(trace).toString(),
          first: 'stack '));
    }
    if (result.isNotEmpty) buffer.writeln(indent(result, first: 'which '));
    return buffer.toString().trimRight();
  }
}
