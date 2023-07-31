// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names

import 'package:async/async.dart';
import 'package:test/test.dart';

final someStack = StackTrace.current;
Result<T> res<T>(T n) => Result<T>.value(n);
Result<T> err<T>(int n) => ErrorResult('$n', someStack);

/// Helper function creating an iterable of results.
Iterable<Result<int>> results(int count,
    {bool Function(int index)? throwWhen}) sync* {
  for (var i = 0; i < count; i++) {
    if (throwWhen != null && throwWhen(i)) {
      yield err(i);
    } else {
      yield res(i);
    }
  }
}

void main() {
  void expectAll<T>(Result<T> result, Result<T> expectation) {
    if (expectation.isError) {
      expect(result, expectation);
    } else {
      expect(result.isValue, true);
      expect(result.asValue!.value, expectation.asValue!.value);
    }
  }

  test('empty', () {
    expectAll(Result.flattenAll<int>(results(0)), res([]));
  });
  test('single value', () {
    expectAll(Result.flattenAll<int>(results(1)), res([0]));
  });
  test('single error', () {
    expectAll(
        Result.flattenAll<int>(results(1, throwWhen: (_) => true)), err(0));
  });
  test('multiple values', () {
    expectAll(Result.flattenAll<int>(results(5)), res([0, 1, 2, 3, 4]));
  });
  test('multiple errors', () {
    expectAll(Result.flattenAll<int>(results(5, throwWhen: (x) => x.isOdd)),
        err(1)); // First error is result.
  });
  test('error last', () {
    expectAll(
        Result.flattenAll<int>(results(5, throwWhen: (x) => x == 4)), err(4));
  });
}
