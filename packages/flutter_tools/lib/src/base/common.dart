// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// Throws a specialized exception to exit with an actionable [message].
///
/// A [ToolExit] is interpreted by the `flutter` tool to mean "exit the tool
/// gracefully with a human actionable error [message]", and should be used in
/// scenarios where a human (developer) can make a decision based on the result.
///
/// For example:
///
/// - An invalid set of command-line arguments were passed.
/// - The network appears to be unavailable.
/// - The project needs to be modified in some way for a command to succeed.
///
/// Prefer throwing an error (such as [StateError]) for cases such as:
///
/// - An internal tool (such as invoking `dart`) returns an unexpected response.
/// - An unrecoverable state is detected deeper in execution.
///
/// A stack trace is included in the tool output when `--verbose` is specified.
///
/// While supported, avoid passing `null` for [message]; this is a legacy
/// behavior that is not intended. For example, provide the message directly
/// instead of using a combination of `logger.error` and `throwToolExit`:
///
/// ```diff
/// - logger.error('Expected --foo to be provided in conjunction with --bar');
/// - throwToolExit(null);
/// + throwToolExit('Expected --foo to be provided in conjunction with --bar');
/// ```
Never throwToolExit(String? message, {int? exitCode}) {
  throw ToolExit._(message, exitCode: exitCode);
}

/// A specialized exception to exit with an actionable [message].
///
/// See [throwToolExit].
final class ToolExit implements Exception {
  ToolExit._(this.message, {this.exitCode});

  final String? message;
  final int? exitCode;

  @override
  String toString() => 'Error: $message';
}

/// Error handling extensions on [Future].
extension FutureErrorHandling<T> on Future<T> {
  /// Handles errors on this future without requiring an empty `.then` callback.
  ///
  /// Useful for guarding background sink/socket completion futures
  /// (e.g., `socket.done`, `sink.done`) against unhandled zone exceptions.
  ///
  /// This uses `Future.then` with a statically typed `(Object, StackTrace)`
  /// `onError` callback rather than `Future.catchError` or `Future.onError`,
  /// which are banned across `flutter_tools` by `AvoidFutureCatchError`
  /// (`dev/bots/custom_rules/avoid_future_catcherror.dart`, added in
  /// https://github.com/flutter/flutter/pull/130662) because they are not
  /// statically type-safe (see https://github.com/dart-lang/sdk/issues/51248).
  Future<void> handleError(
    void Function(Object error, StackTrace stackTrace) onError, {
    bool Function(Object error)? test,
  }) {
    return then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (test == null || test(error)) {
          onError(error, stackTrace);
        } else {
          Error.throwWithStackTrace(error, stackTrace);
        }
      },
    );
  }
}
