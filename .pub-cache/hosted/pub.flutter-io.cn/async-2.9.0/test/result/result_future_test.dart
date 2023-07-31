// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  late Completer completer;
  late ResultFuture future;
  setUp(() {
    completer = Completer();
    future = ResultFuture(completer.future);
  });

  test('before completion, result is null', () {
    expect(future.result, isNull);
  });

  test('after successful completion, result is the value of the future', () {
    completer.complete(12);

    // The completer calls its listeners asynchronously. We have to wait
    // before we can access the result.
    expect(future.then((_) => future.result!.asValue!.value),
        completion(equals(12)));
  });

  test("after an error completion, result is the future's error", () {
    var trace = Trace.current();
    completer.completeError('error', trace);

    // The completer calls its listeners asynchronously. We have to wait
    // before we can access the result.
    return future.catchError((_) {}).then((_) {
      var error = future.result!.asError!;
      expect(error.error, equals('error'));
      expect(error.stackTrace, equals(trace));
    });
  });
}
