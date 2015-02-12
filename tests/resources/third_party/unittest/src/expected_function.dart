// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.expected_function;

import '../unittest.dart';

import 'internal_test_case.dart';

/// An object used to detect unpassed arguments.
const _PLACEHOLDER = const Object();

// Functions used to check how many arguments a callback takes.
typedef _Func0();
typedef _Func1(a);
typedef _Func2(a, b);
typedef _Func3(a, b, c);
typedef _Func4(a, b, c, d);
typedef _Func5(a, b, c, d, e);
typedef _Func6(a, b, c, d, e, f);

typedef bool _IsDoneCallback();

/// A wrapper for a function that ensures that it's called the appropriate
/// number of times.
///
/// The containing test won't be considered to have completed successfully until
/// this function has been called the appropriate number of times.
///
/// The wrapper function is accessible via [func]. It supports up to six
/// optional and/or required positional arguments, but no named arguments.
class ExpectedFunction {
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
  final _IsDoneCallback _isDone;

  /// A descriptive name for the function.
  final String _id;

  /// An optional description of why the function is expected to be called.
  ///
  /// If not passed, this will be an empty string.
  final String _reason;

  /// The number of times the function has been called.
  int _actualCalls = 0;

  /// The test case in which this function was wrapped.
  final InternalTestCase _testCase;

  /// Whether this function has been called the requisite number of times.
  bool _complete;

  /// Wraps [callback] in a function that asserts that it's called at least
  /// [minExpected] times and no more than [maxExpected] times.
  ///
  /// If passed, [id] is used as a descriptive name fo the function and [reason]
  /// as a reason it's expected to be called. If [isDone] is passed, the test
  /// won't be allowed to complete until it returns `true`.
  ExpectedFunction(Function callback, int minExpected, int maxExpected,
      {String id, String reason, bool isDone()})
      : this._callback = callback,
        _minExpectedCalls = minExpected,
        _maxExpectedCalls = (maxExpected == 0 && minExpected > 0)
            ? minExpected
            : maxExpected,
        this._isDone = isDone,
        this._reason = reason == null ? '' : '\n$reason',
        this._testCase = currentTestCase as InternalTestCase,
        this._id = _makeCallbackId(id, callback) {
    ensureInitialized();
    if (_testCase == null) {
      throw new StateError("No valid test. Did you forget to run your test "
          "inside a call to test()?");
    }

    if (isDone != null || minExpected > 0) {
      _testCase.callbackFunctionsOutstanding++;
      _complete = false;
    } else {
      _complete = true;
    }
  }

  /// Tries to find a reasonable name for [callback].
  ///
  /// If [id] is passed, uses that. Otherwise, tries to determine a name from
  /// calling `toString`. If no name can be found, returns the empty string.
  static String _makeCallbackId(String id, Function callback) {
    if (id != null) return "$id ";

    // If the callback is not an anonymous closure, try to get the
    // name.
    var toString = callback.toString();
    var prefix = "Function '";
    var start = toString.indexOf(prefix);
    if (start == -1) return '';

    start += prefix.length;
    var end = toString.indexOf("'", start);
    if (end == -1) return '';
    return "${toString.substring(start, end)} ";
  }

  /// Returns a function that has the same number of positional arguments as the
  /// wrapped function (up to a total of 6).
  Function get func {
    if (_callback is _Func6) return _max6;
    if (_callback is _Func5) return _max5;
    if (_callback is _Func4) return _max4;
    if (_callback is _Func3) return _max3;
    if (_callback is _Func2) return _max2;
    if (_callback is _Func1) return _max1;
    if (_callback is _Func0) return _max0;

    throw new ArgumentError(
        'The wrapped function has more than 6 required arguments');
  }

  // This indirection is critical. It ensures the returned function has an
  // argument count of zero.
  _max0() => _max6();

  _max1([a0 = _PLACEHOLDER]) => _max6(a0);

  _max2([a0 = _PLACEHOLDER, a1 = _PLACEHOLDER]) => _max6(a0, a1);

  _max3([a0 = _PLACEHOLDER, a1 = _PLACEHOLDER, a2 = _PLACEHOLDER]) =>
      _max6(a0, a1, a2);

  _max4([a0 = _PLACEHOLDER, a1 = _PLACEHOLDER, a2 = _PLACEHOLDER,
      a3 = _PLACEHOLDER]) => _max6(a0, a1, a2, a3);

  _max5([a0 = _PLACEHOLDER, a1 = _PLACEHOLDER, a2 = _PLACEHOLDER,
      a3 = _PLACEHOLDER, a4 = _PLACEHOLDER]) => _max6(a0, a1, a2, a3, a4);

  _max6([a0 = _PLACEHOLDER, a1 = _PLACEHOLDER, a2 = _PLACEHOLDER,
      a3 = _PLACEHOLDER, a4 = _PLACEHOLDER, a5 = _PLACEHOLDER]) =>
      _run([a0, a1, a2, a3, a4, a5].where((a) => a != _PLACEHOLDER));

  /// Runs the wrapped function with [args] and returns its return value.
  ///
  /// This will pass any errors on to [_testCase] and return `null`.
  _run(Iterable args) {
    try {
      _actualCalls++;
      if (_testCase.isComplete) {
        // Don't run the callback if the test is done. We don't throw here as
        // this is not the current test, but we do mark the old test as having
        // an error if it previously passed.
        if (_testCase.result == PASS) {
          _testCase.error(
              'Callback ${_id}called ($_actualCalls) after test case '
              '${_testCase.description} had already been marked as '
              '${_testCase.result}.$_reason');
        }
        return null;
      } else if (_maxExpectedCalls >= 0 && _actualCalls > _maxExpectedCalls) {
        throw new TestFailure('Callback ${_id}called more times than expected '
                              '($_maxExpectedCalls).$_reason');
      }

      return Function.apply(_callback, args.toList());
    } catch (error, stackTrace) {
      _testCase.registerException(error, stackTrace);
      return null;
    } finally {
      _afterRun();
    }
  }

  /// After each time the function is run, check to see if it's complete.
  void _afterRun() {
    if (_complete) return;
    if (_minExpectedCalls > 0 && _actualCalls < _minExpectedCalls) return;
    if (_isDone != null && !_isDone()) return;

    // Mark this callback as complete and remove it from the test case's
    // oustanding callback count; if that hits zero the test is done.
    _complete = true;
    _testCase.markCallbackComplete();
  }
}
