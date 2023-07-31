// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A class for running an asynchronous function exactly once and caching its
/// result.
///
/// An `AsyncMemoizer` is used when some function may be run multiple times in
/// order to get its result, but it only actually needs to be run once for its
/// effect. To memoize the result of an async function, you can create a
/// memoizer outside the function (for example as an instance field if you want
/// to memoize the result of a method), and then wrap the function's body in a
/// call to [runOnce].
///
/// This is useful for methods like `close()` and getters that need to do
/// asynchronous work. For example:
///
/// ```dart
/// class SomeResource {
///   final _closeMemo = AsyncMemoizer();
///
///   Future close() => _closeMemo.runOnce(() {
///     // ...
///   });
/// }
/// ```
class AsyncMemoizer<T> {
  /// The future containing the method's result.
  ///
  /// This can be accessed at any time, and will fire once [runOnce] is called.
  Future<T> get future => _completer.future;
  final _completer = Completer<T>();

  /// Whether [runOnce] has been called yet.
  bool get hasRun => _completer.isCompleted;

  /// Runs the function, [computation], if it hasn't been run before.
  ///
  /// If [runOnce] has already been called, this returns the original result.
  Future<T> runOnce(FutureOr<T> Function() computation) {
    if (!hasRun) _completer.complete(Future.sync(computation));
    return future;
  }
}
