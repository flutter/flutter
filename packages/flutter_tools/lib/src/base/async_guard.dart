// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Runs [fn] with special handling of asynchronous errors.
///
/// If the execution of [fn] does not throw a synchronous exception, and if the
/// [Future] returned by [fn] is completed with a value, then the [Future]
/// returned by [asyncGuard] is completed with that value if it has not already
/// been completed with an error.
///
/// If the execution of [fn] throws a synchronous exception, then the [Future]
/// returned by [asyncGuard] is completed with an error whose object and
/// stack trace are given by the synchronous exception.
///
/// If the execution of [fn] results in an asynchronous exception that would
/// otherwise be unhandled, then the [Future] returned by [asyncGuard] is
/// completed with an error whose object and stack trace are given by the
/// asynchronous exception.
///
/// After the returned [Future] is completed, whether it be with a value or an
/// error, all further errors resulting from the execution of [fn] both
/// synchronous and asynchronous are ignored.
///
/// Rationale:
///
/// Consider the following snippet:
/// ```
/// try {
///   await foo();
///   ...
/// } catch (e) {
///   ...
/// }
/// ```
/// If the [Future] returned by `foo` is completed with an error, that error is
/// handled by the catch block. However, if `foo` spawns an asynchronous
/// operation whose errors are unhandled, those errors will not be caught by
/// the catch block, and will instead propagate to the containing [Zone]. This
/// behavior is non-intuitive to programmers expecting the `catch` to catch all
/// the errors resulting from the code under the `try`.
///
/// As such, it would be convenient if the `try {} catch {}` here could handle
/// not only errors completing the awaited [Future]s it contains, but also
/// any otherwise unhandled asynchronous errors occuring as a result of awaited
/// expressions. This is how `await` is often assumed to work, which leads to
/// unexpected unhandled exceptions.
///
/// [asyncGuard] is intended to wrap awaited expressions occuring in a `try`
/// block. The behavior described above gives the behavior that users
/// intuitively expect from `await`. Consider the snippet:
/// ```
/// try {
///   await asyncGuard(() async {
///     var c = Completer();
///     c.completeError('Error');
///   });
/// } catch (e) {
///   // e is 'Error';
/// }
/// ```
/// Without the [asyncGuard] the error 'Error' would be propagated to the
/// error handler of the containing [Zone]. With the [asyncGuard], the error
/// 'Error' is instead caught by the `catch`.
Future<T> asyncGuard<T>(Future<T> Function() fn) {
  final Completer<T> completer = Completer<T>();

  runZoned<void>(() async {
    try {
      final T result = await fn();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (e, s) {
      if (!completer.isCompleted) {
        completer.completeError(e, s);
      }
    }
  }, onError: (dynamic e, StackTrace s) {
    if (!completer.isCompleted) {
      completer.completeError(e, s);
    }
  });

  return completer.future;
}
