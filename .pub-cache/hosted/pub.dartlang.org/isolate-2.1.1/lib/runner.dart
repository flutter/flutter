// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A [Runner] runs a function, potentially in a different scope
/// or even isolate.
library isolate.runner;

import 'dart:async' show FutureOr;

/// Calls a function with an argument.
///
/// The function can be run in a different place from where the `Runner`
/// resides, e.g., in a different isolate.
class Runner {
  /// Request that [function] be called with the provided arguments.
  ///
  /// The arguments will be applied to the function in the same way as by
  /// [Function.apply], but it may happen in a different isolate or setting.
  ///
  /// It's necessary that the function can be sent through a [SendPort]
  /// if the call is performed in another isolate.
  /// That means the other isolate should be created using [Isolate.spawn]
  /// so that it is running the same code as the sending isolate,
  /// and the function must be a static or top-level function.
  ///
  /// Waits for the result of the call, and completes the returned future
  /// with the result, whether it's a value or an error.
  ///
  /// If [timeout] is provided, and the returned future does not complete
  /// before that duration has passed,
  /// the [onTimeout] action is executed instead, and its result (whether it
  /// returns or throws) is used as the result of the returned future.
  /// If [onTimeout] is omitted, it defaults to throwing a[TimeoutException].
  ///
  /// The default implementation runs the function in the current isolate.
  Future<R> run<R, P>(FutureOr<R> Function(P argument) function, P argument,
      {Duration? timeout, FutureOr<R> Function()? onTimeout}) {
    var result = Future.sync(() => function(argument));
    if (timeout != null) {
      result = result.timeout(timeout, onTimeout: onTimeout);
    }
    return result;
  }

  /// Stop the runner.
  ///
  /// If the runner has allocated resources, e.g., an isolate, it should
  /// be released. No further calls to [run] should be made after calling
  /// stop.
  Future<void> close() => Future.value();
}
