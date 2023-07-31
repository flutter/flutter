// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'result.dart';
import 'value.dart';

/// A result representing a thrown error.
class ErrorResult implements Result<Never> {
  /// The error object that was thrown.
  final Object error;

  /// The stack trace corresponding to where [error] was thrown.
  final StackTrace stackTrace;

  @override
  bool get isValue => false;
  @override
  bool get isError => true;
  @override
  ValueResult<Never>? get asValue => null;
  @override
  ErrorResult get asError => this;

  ErrorResult(this.error, [StackTrace? stackTrace])
      : stackTrace = stackTrace ?? AsyncError.defaultStackTrace(error);

  @override
  void complete(Completer completer) {
    completer.completeError(error, stackTrace);
  }

  @override
  void addTo(EventSink sink) {
    sink.addError(error, stackTrace);
  }

  @override
  Future<Never> get asFuture => Future<Never>.error(error, stackTrace);

  /// Calls an error handler with the error and stacktrace.
  ///
  /// An async error handler function is either a function expecting two
  /// arguments, which will be called with the error and the stack trace, or it
  /// has to be a function expecting only one argument, which will be called
  /// with only the error.
  void handle(Function errorHandler) {
    if (errorHandler is ZoneBinaryCallback) {
      errorHandler(error, stackTrace);
    } else {
      (errorHandler as ZoneUnaryCallback)(error);
    }
  }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode ^ 0x1d61823f;

  /// This is equal only to an error result with equal [error] and [stackTrace].
  @override
  bool operator ==(Object other) =>
      other is ErrorResult &&
      error == other.error &&
      stackTrace == other.stackTrace;
}
