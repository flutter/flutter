// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_api/hooks.dart';

import 'util/placeholder.dart';

// Function types returned by expectAsync# methods.

typedef Func0<T> = T Function();
typedef Func1<T, A> = T Function([A a]);
typedef Func2<T, A, B> = T Function([A a, B b]);
typedef Func3<T, A, B, C> = T Function([A a, B b, C c]);
typedef Func4<T, A, B, C, D> = T Function([A a, B b, C c, D d]);
typedef Func5<T, A, B, C, D, E> = T Function([A a, B b, C c, D d, E e]);
typedef Func6<T, A, B, C, D, E, F> = T Function([A a, B b, C c, D d, E e, F f]);

/// A wrapper for a function that ensures that it's called the appropriate
/// number of times.
///
/// The containing test won't be considered to have completed successfully until
/// this function has been called the appropriate number of times.
///
/// The wrapper function is accessible via [func]. It supports up to six
/// optional and/or required positional arguments, but no named arguments.
class _ExpectedFunction<T> {
  /// The wrapped callback.
  final Function _callback;

  /// The minimum number of calls that are expected to be made to the function.
  ///
  /// If fewer calls than this are made, the test will fail.
  final int _minExpectedCalls;

  /// The maximum number of calls that are expected to be made to the function.
  ///
  /// If more calls than this are made, the test will fail.
  final int _maxExpectedCalls;

  /// A callback that should return whether the function is not expected to have
  /// any more calls.
  ///
  /// This will be called after every time the function is run. The test case
  /// won't be allowed to terminate until it returns `true`.
  ///
  /// This may be `null`. If so, the function is considered to be done after
  /// it's been run once.
  final bool Function()? _isDone;

  /// A descriptive name for the function.
  final String _id;

  /// An optional description of why the function is expected to be called.
  ///
  /// If not passed, this will be an empty string.
  final String _reason;

  /// The number of times the function has been called.
  int _actualCalls = 0;

  /// The test in which this function was wrapped.
  late final TestHandle _test;

  /// Whether this function has been called the requisite number of times.
  late bool _complete;

  OutstandingWork? _outstandingWork;

  /// Wraps [callback] in a function that asserts that it's called at least
  /// [minExpected] times and no more than [maxExpected] times.
  ///
  /// If passed, [id] is used as a descriptive name fo the function and [reason]
  /// as a reason it's expected to be called. If [isDone] is passed, the test
  /// won't be allowed to complete until it returns `true`.
  _ExpectedFunction(Function callback, int minExpected, int maxExpected,
      {String? id, String? reason, bool Function()? isDone})
      : _callback = callback,
        _minExpectedCalls = minExpected,
        _maxExpectedCalls =
            (maxExpected == 0 && minExpected > 0) ? minExpected : maxExpected,
        _isDone = isDone,
        _reason = reason == null ? '' : '\n$reason',
        _id = _makeCallbackId(id, callback) {
    try {
      _test = TestHandle.current;
    } on OutsideTestException {
      throw StateError('`expectAsync` must be called within a test.');
    }

    if (maxExpected > 0 && minExpected > maxExpected) {
      throw ArgumentError('max ($maxExpected) may not be less than count '
          '($minExpected).');
    }

    if (isDone != null || minExpected > 0) {
      _outstandingWork = _test.markPending();
      _complete = false;
    } else {
      _complete = true;
    }
  }

  /// Tries to find a reasonable name for [callback].
  ///
  /// If [id] is passed, uses that. Otherwise, tries to determine a name from
  /// calling `toString`. If no name can be found, returns the empty string.
  static String _makeCallbackId(String? id, Function callback) {
    if (id != null) return '$id ';

    // If the callback is not an anonymous closure, try to get the
    // name.
    var toString = callback.toString();
    var prefix = "Function '";
    var start = toString.indexOf(prefix);
    if (start == -1) return '';

    start += prefix.length;
    var end = toString.indexOf("'", start);
    if (end == -1) return '';
    return '${toString.substring(start, end)} ';
  }

  /// Returns a function that has the same number of positional arguments as the
  /// wrapped function (up to a total of 6).
  Function get func {
    if (_callback is Function(Never, Never, Never, Never, Never, Never)) {
      return max6;
    }
    if (_callback is Function(Never, Never, Never, Never, Never)) return max5;
    if (_callback is Function(Never, Never, Never, Never)) return max4;
    if (_callback is Function(Never, Never, Never)) return max3;
    if (_callback is Function(Never, Never)) return max2;
    if (_callback is Function(Never)) return max1;
    if (_callback is Function()) return max0;

    _outstandingWork?.complete();
    throw ArgumentError(
        'The wrapped function has more than 6 required arguments');
  }

  // This indirection is critical. It ensures the returned function has an
  // argument count of zero.
  T max0() => max6();

  T max1([Object? a0 = placeholder]) => max6(a0);

  T max2([Object? a0 = placeholder, Object? a1 = placeholder]) => max6(a0, a1);

  T max3(
          [Object? a0 = placeholder,
          Object? a1 = placeholder,
          Object? a2 = placeholder]) =>
      max6(a0, a1, a2);

  T max4(
          [Object? a0 = placeholder,
          Object? a1 = placeholder,
          Object? a2 = placeholder,
          Object? a3 = placeholder]) =>
      max6(a0, a1, a2, a3);

  T max5(
          [Object? a0 = placeholder,
          Object? a1 = placeholder,
          Object? a2 = placeholder,
          Object? a3 = placeholder,
          Object? a4 = placeholder]) =>
      max6(a0, a1, a2, a3, a4);

  T max6(
          [Object? a0 = placeholder,
          Object? a1 = placeholder,
          Object? a2 = placeholder,
          Object? a3 = placeholder,
          Object? a4 = placeholder,
          Object? a5 = placeholder]) =>
      _run([a0, a1, a2, a3, a4, a5].where((a) => a != placeholder));

  /// Runs the wrapped function with [args] and returns its return value.
  T _run(Iterable args) {
    // Note that in the old test, this returned `null` if it encountered an
    // error, where now it just re-throws that error because Zone machinery will
    // pass it to the invoker anyway.
    try {
      _actualCalls++;
      if (_test.shouldBeDone) {
        throw 'Callback ${_id}called ($_actualCalls) after test case '
            '${_test.name} had already completed.$_reason';
      } else if (_maxExpectedCalls >= 0 && _actualCalls > _maxExpectedCalls) {
        throw TestFailure('Callback ${_id}called more times than expected '
            '($_maxExpectedCalls).$_reason');
      }

      return Function.apply(_callback, args.toList()) as T;
    } finally {
      _afterRun();
    }
  }

  /// After each time the function is run, check to see if it's complete.
  void _afterRun() {
    if (_complete) return;
    if (_minExpectedCalls > 0 && _actualCalls < _minExpectedCalls) return;
    if (_isDone != null && !_isDone!()) return;

    // Mark this callback as complete and remove it from the test case's
    // outstanding callback count; if that hits zero the test is done.
    _complete = true;
    _outstandingWork?.complete();
  }
}

/// This function is deprecated because it doesn't work well with strong mode.
/// Use [expectAsync0], [expectAsync1],
/// [expectAsync2], [expectAsync3], [expectAsync4], [expectAsync5], or
/// [expectAsync6] instead.
@Deprecated('Will be removed in 0.13.0')
Function expectAsync(Function callback,
        {int count = 1, int max = 0, String? id, String? reason}) =>
    _ExpectedFunction(callback, count, max, id: id, reason: reason).func;

/// Informs the framework that the given [callback] of arity 0 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with zero arguments. See also
/// [expectAsync1], [expectAsync2], [expectAsync3], [expectAsync4],
/// [expectAsync5], and [expectAsync6] for callbacks with different arity.
Func0<T> expectAsync0<T>(T Function() callback,
        {int count = 1, int max = 0, String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max0;

/// Informs the framework that the given [callback] of arity 1 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with one argument. See also
/// [expectAsync0], [expectAsync2], [expectAsync3], [expectAsync4],
/// [expectAsync5], and [expectAsync6] for callbacks with different arity.
Func1<T, A> expectAsync1<T, A>(T Function(A) callback,
        {int count = 1, int max = 0, String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max1;

/// Informs the framework that the given [callback] of arity 2 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with two arguments. See also
/// [expectAsync0], [expectAsync1], [expectAsync3], [expectAsync4],
/// [expectAsync5], and [expectAsync6] for callbacks with different arity.
Func2<T, A, B> expectAsync2<T, A, B>(T Function(A, B) callback,
        {int count = 1, int max = 0, String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max2;

/// Informs the framework that the given [callback] of arity 3 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with three arguments. See also
/// [expectAsync0], [expectAsync1], [expectAsync2], [expectAsync4],
/// [expectAsync5], and [expectAsync6] for callbacks with different arity.
Func3<T, A, B, C> expectAsync3<T, A, B, C>(T Function(A, B, C) callback,
        {int count = 1, int max = 0, String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max3;

/// Informs the framework that the given [callback] of arity 4 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with four arguments. See also
/// [expectAsync0], [expectAsync1], [expectAsync2], [expectAsync3],
/// [expectAsync5], and [expectAsync6] for callbacks with different arity.
Func4<T, A, B, C, D> expectAsync4<T, A, B, C, D>(
        T Function(A, B, C, D) callback,
        {int count = 1,
        int max = 0,
        String? id,
        String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max4;

/// Informs the framework that the given [callback] of arity 5 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with five arguments. See also
/// [expectAsync0], [expectAsync1], [expectAsync2], [expectAsync3],
/// [expectAsync4], and [expectAsync6] for callbacks with different arity.
Func5<T, A, B, C, D, E> expectAsync5<T, A, B, C, D, E>(
        T Function(A, B, C, D, E) callback,
        {int count = 1,
        int max = 0,
        String? id,
        String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max5;

/// Informs the framework that the given [callback] of arity 6 is expected to be
/// called [count] number of times (by default 1).
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// The test framework will wait for the callback to run the [count] times
/// before it considers the current test to be complete.
///
/// [max] can be used to specify an upper bound on the number of calls; if this
/// is exceeded the test will fail. If [max] is `0` (the default), the callback
/// is expected to be called exactly [count] times. If [max] is `-1`, the
/// callback is allowed to be called any number of times greater than [count].
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with six arguments. See also
/// [expectAsync0], [expectAsync1], [expectAsync2], [expectAsync3],
/// [expectAsync4], and [expectAsync5] for callbacks with different arity.
Func6<T, A, B, C, D, E, F> expectAsync6<T, A, B, C, D, E, F>(
        T Function(A, B, C, D, E, F) callback,
        {int count = 1,
        int max = 0,
        String? id,
        String? reason}) =>
    _ExpectedFunction<T>(callback, count, max, id: id, reason: reason).max6;

/// This function is deprecated because it doesn't work well with strong mode.
/// Use [expectAsyncUntil0], [expectAsyncUntil1],
/// [expectAsyncUntil2], [expectAsyncUntil3], [expectAsyncUntil4],
/// [expectAsyncUntil5], or [expectAsyncUntil6] instead.
@Deprecated('Will be removed in 0.13.0')
Function expectAsyncUntil(Function callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction(callback, 0, -1, id: id, reason: reason, isDone: isDone)
        .func;

/// Informs the framework that the given [callback] of arity 0 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with zero arguments. See also
/// [expectAsyncUntil1], [expectAsyncUntil2], [expectAsyncUntil3],
/// [expectAsyncUntil4], [expectAsyncUntil5], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func0<T> expectAsyncUntil0<T>(T Function() callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max0;

/// Informs the framework that the given [callback] of arity 1 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with one argument. See also
/// [expectAsyncUntil0], [expectAsyncUntil2], [expectAsyncUntil3],
/// [expectAsyncUntil4], [expectAsyncUntil5], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func1<T, A> expectAsyncUntil1<T, A>(
        T Function(A) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max1;

/// Informs the framework that the given [callback] of arity 2 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with two arguments. See also
/// [expectAsyncUntil0], [expectAsyncUntil1], [expectAsyncUntil3],
/// [expectAsyncUntil4], [expectAsyncUntil5], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func2<T, A, B> expectAsyncUntil2<T, A, B>(
        T Function(A, B) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max2;

/// Informs the framework that the given [callback] of arity 3 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with three arguments. See also
/// [expectAsyncUntil0], [expectAsyncUntil1], [expectAsyncUntil2],
/// [expectAsyncUntil4], [expectAsyncUntil5], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func3<T, A, B, C> expectAsyncUntil3<T, A, B, C>(
        T Function(A, B, C) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max3;

/// Informs the framework that the given [callback] of arity 4 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with four arguments. See also
/// [expectAsyncUntil0], [expectAsyncUntil1], [expectAsyncUntil2],
/// [expectAsyncUntil3], [expectAsyncUntil5], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func4<T, A, B, C, D> expectAsyncUntil4<T, A, B, C, D>(
        T Function(A, B, C, D) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max4;

/// Informs the framework that the given [callback] of arity 5 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with five arguments. See also
/// [expectAsyncUntil0], [expectAsyncUntil1], [expectAsyncUntil2],
/// [expectAsyncUntil3], [expectAsyncUntil4], and [expectAsyncUntil6] for
/// callbacks with different arity.
Func5<T, A, B, C, D, E> expectAsyncUntil5<T, A, B, C, D, E>(
        T Function(A, B, C, D, E) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max5;

/// Informs the framework that the given [callback] of arity 6 is expected to be
/// called until [isDone] returns true.
///
/// Returns a wrapped function that should be used as a replacement of the
/// original callback.
///
/// [isDone] is called after each time the function is run. Only when it returns
/// true will the callback be considered complete.
///
/// Both [id] and [reason] are optional and provide extra information about the
/// callback when debugging. [id] should be the name of the callback, while
/// [reason] should be the reason the callback is expected to be called.
///
/// This method takes callbacks with six arguments. See also
/// [expectAsyncUntil0], [expectAsyncUntil1], [expectAsyncUntil2],
/// [expectAsyncUntil3], [expectAsyncUntil4], and [expectAsyncUntil5] for
/// callbacks with different arity.
Func6<T, A, B, C, D, E, F> expectAsyncUntil6<T, A, B, C, D, E, F>(
        T Function(A, B, C, D, E, F) callback, bool Function() isDone,
        {String? id, String? reason}) =>
    _ExpectedFunction<T>(callback, 0, -1,
            id: id, reason: reason, isDone: isDone)
        .max6;
