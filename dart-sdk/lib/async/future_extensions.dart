// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

@Since("3.0")
extension FutureIterable<T> on Iterable<Future<T>> {
  /// Waits for futures in parallel.
  ///
  /// Waits for all the futures in this iterable.
  /// Returns a list of the resulting values,
  /// in the same order as the futures which created them,
  /// if all futures are successful.
  ///
  /// Similar to [Future.wait], but reports errors using a
  /// [ParallelWaitError], which allows the caller to
  /// handle errors and dispose successful results if necessary.
  ///
  /// The returned future is completed when all the futures have completed.
  /// If any of the futures do not complete, nor does the returned future.
  ///
  /// If any future completes with an error,
  /// the returned future completes with a [ParallelWaitError].
  /// The [ParallelWaitError.values] is a list of the values for
  /// successful futures and `null` for futures with errors.
  /// The [ParallelWaitError.errors] is a list of the same length,
  /// with `null` values for the successful futures
  /// and an [AsyncError] with the error for futures
  /// which completed with an error.
  Future<List<T>> get wait {
    var results = [for (var f in this) _FutureResult<T>(f)];
    if (results.isEmpty) return Future<List<T>>.value(<T>[]);
    final c = Completer<List<T>>.sync();
    _FutureResult._waitAll(results, (errors) {
      if (errors == 0) {
        c.complete([for (var r in results) r.value]);
      } else {
        var errorList = [for (var r in results) r.errorOrNull];
        c.completeError(ParallelWaitError<List<T?>, List<AsyncError?>>(
            [for (var r in results) r.valueOrNull], errorList,
            errorCount: errors, defaultError: errorList.firstWhere(_notNull)));
      }
    });
    return c.future;
  }
}

bool _notNull(Object? object) => object != null;

/// Parallel operations on a record of futures.
///
/// {@template record-parallel-wait}
/// Waits for futures in parallel.
///
/// Waits for all the futures in this record.
/// Returns a record of the values, if all futures are successful.
///
/// The returned future is completed when all the futures have completed.
/// If any of the futures do not complete, nor does the returned future.
///
/// If some futures complete with an error,
/// the returned future completes with a [ParallelWaitError].
/// The [ParallelWaitError.values] is a record of the values of
/// successful futures, and `null` for futures with errors.
/// The [ParallelWaitError.errors] is a record of the same shape,
/// with `null` values for the successful futures
/// and an [AsyncError] with the error of futures
/// which completed with an error.
/// {@endtemplate}
@Since("3.0")
extension FutureRecord2<T1, T2> on (Future<T1>, Future<T2>) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2)> get wait {
    final c = Completer<(T1, T2)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);

    _FutureResult._waitAll([v1, v2], (int errors) {
      if (errors == 0) {
        c.complete((v1.value, v2.value));
      } else {
        c.completeError(ParallelWaitError(
          (v1.valueOrNull, v2.valueOrNull),
          (v1.errorOrNull, v2.errorOrNull),
            errorCount: errors,
            defaultError: v1.errorOrNull ?? v2.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord3<T1, T2, T3> on (Future<T1>, Future<T2>, Future<T3>) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3)> get wait {
    final c = Completer<(T1, T2, T3)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);

    _FutureResult._waitAll([v1, v2, v3], (int errors) {
      if (errors == 0) {
        c.complete((v1.value, v2.value, v3.value));
      } else {
        c.completeError(ParallelWaitError(
          (v1.valueOrNull, v2.valueOrNull, v3.valueOrNull),
          (v1.errorOrNull, v2.errorOrNull, v3.errorOrNull),
          errorCount: errors,
          defaultError: v1.errorOrNull ?? v2.errorOrNull ?? v3.errorOrNull,
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord4<T1, T2, T3, T4> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4)> get wait {
    final c = Completer<(T1, T2, T3, T4)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);

    _FutureResult._waitAll([v1, v2, v3, v4], (int errors) {
      if (errors == 0) {
        c.complete((v1.value, v2.value, v3.value, v4.value));
      } else {
        c.completeError(ParallelWaitError(
          (v1.valueOrNull, v2.valueOrNull, v3.valueOrNull, v4.valueOrNull),
          (v1.errorOrNull, v2.errorOrNull, v3.errorOrNull, v4.errorOrNull),
          errorCount: errors,
          defaultError: v1.errorOrNull ??
              v2.errorOrNull ??
              v3.errorOrNull ??
              v4.errorOrNull,
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord5<T1, T2, T3, T4, T5> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>,
  Future<T5>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4, T5)> get wait {
    final c = Completer<(T1, T2, T3, T4, T5)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);
    final v5 = _FutureResult<T5>($5);

    _FutureResult._waitAll([v1, v2, v3, v4, v5], (int errors) {
      if (errors == 0) {
        c.complete((v1.value, v2.value, v3.value, v4.value, v5.value));
      } else {
        c.completeError(ParallelWaitError(
          (
            v1.valueOrNull,
            v2.valueOrNull,
            v3.valueOrNull,
            v4.valueOrNull,
            v5.valueOrNull
          ),
          (
            v1.errorOrNull,
            v2.errorOrNull,
            v3.errorOrNull,
            v4.errorOrNull,
            v5.errorOrNull
          ),
            errorCount: errors,
            defaultError: v1.errorOrNull ??
                v2.errorOrNull ??
                v3.errorOrNull ??
                v4.errorOrNull ??
                v5.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord6<T1, T2, T3, T4, T5, T6> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>,
  Future<T5>,
  Future<T6>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4, T5, T6)> get wait {
    final c = Completer<(T1, T2, T3, T4, T5, T6)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);
    final v5 = _FutureResult<T5>($5);
    final v6 = _FutureResult<T6>($6);

    _FutureResult._waitAll([v1, v2, v3, v4, v5, v6], (int errors) {
      if (errors == 0) {
        c.complete(
            (v1.value, v2.value, v3.value, v4.value, v5.value, v6.value));
      } else {
        c.completeError(ParallelWaitError(
          (
            v1.valueOrNull,
            v2.valueOrNull,
            v3.valueOrNull,
            v4.valueOrNull,
            v5.valueOrNull,
            v6.valueOrNull
          ),
          (
            v1.errorOrNull,
            v2.errorOrNull,
            v3.errorOrNull,
            v4.errorOrNull,
            v5.errorOrNull,
            v6.errorOrNull
        ),
            errorCount: errors,
            defaultError: v1.errorOrNull ??
                v2.errorOrNull ??
                v3.errorOrNull ??
                v4.errorOrNull ??
                v5.errorOrNull ??
                v6.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord7<T1, T2, T3, T4, T5, T6, T7> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>,
  Future<T5>,
  Future<T6>,
  Future<T7>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4, T5, T6, T7)> get wait {
    final c = Completer<(T1, T2, T3, T4, T5, T6, T7)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);
    final v5 = _FutureResult<T5>($5);
    final v6 = _FutureResult<T6>($6);
    final v7 = _FutureResult<T7>($7);

    _FutureResult._waitAll([v1, v2, v3, v4, v5, v6, v7], (int errors) {
      if (errors == 0) {
        c.complete((
          v1.value,
          v2.value,
          v3.value,
          v4.value,
          v5.value,
          v6.value,
          v7.value
        ));
      } else {
        c.completeError(ParallelWaitError(
          (
            v1.valueOrNull,
            v2.valueOrNull,
            v3.valueOrNull,
            v4.valueOrNull,
            v5.valueOrNull,
            v6.valueOrNull,
            v7.valueOrNull
          ),
          (
            v1.errorOrNull,
            v2.errorOrNull,
            v3.errorOrNull,
            v4.errorOrNull,
            v5.errorOrNull,
            v6.errorOrNull,
            v7.errorOrNull
          ),
            errorCount: errors,
            defaultError: v1.errorOrNull ??
                v2.errorOrNull ??
                v3.errorOrNull ??
                v4.errorOrNull ??
                v5.errorOrNull ??
                v6.errorOrNull ??
                v7.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord8<T1, T2, T3, T4, T5, T6, T7, T8> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>,
  Future<T5>,
  Future<T6>,
  Future<T7>,
  Future<T8>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4, T5, T6, T7, T8)> get wait {
    final c = Completer<(T1, T2, T3, T4, T5, T6, T7, T8)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);
    final v5 = _FutureResult<T5>($5);
    final v6 = _FutureResult<T6>($6);
    final v7 = _FutureResult<T7>($7);
    final v8 = _FutureResult<T8>($8);

    _FutureResult._waitAll([v1, v2, v3, v4, v5, v6, v7, v8], (int errors) {
      if (errors == 0) {
        c.complete((
          v1.value,
          v2.value,
          v3.value,
          v4.value,
          v5.value,
          v6.value,
          v7.value,
          v8.value
        ));
      } else {
        c.completeError(ParallelWaitError(
          (
            v1.valueOrNull,
            v2.valueOrNull,
            v3.valueOrNull,
            v4.valueOrNull,
            v5.valueOrNull,
            v6.valueOrNull,
            v7.valueOrNull,
            v8.valueOrNull
          ),
          (
            v1.errorOrNull,
            v2.errorOrNull,
            v3.errorOrNull,
            v4.errorOrNull,
            v5.errorOrNull,
            v6.errorOrNull,
            v7.errorOrNull,
            v8.errorOrNull
          ),
            errorCount: errors,
            defaultError: v1.errorOrNull ??
                v2.errorOrNull ??
                v3.errorOrNull ??
                v4.errorOrNull ??
                v5.errorOrNull ??
                v6.errorOrNull ??
                v7.errorOrNull ??
                v8.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Parallel operations on a record of futures.
@Since("3.0")
extension FutureRecord9<T1, T2, T3, T4, T5, T6, T7, T8, T9> on (
  Future<T1>,
  Future<T2>,
  Future<T3>,
  Future<T4>,
  Future<T5>,
  Future<T6>,
  Future<T7>,
  Future<T8>,
  Future<T9>
) {
  /// {@macro record-parallel-wait}
  Future<(T1, T2, T3, T4, T5, T6, T7, T8, T9)> get wait {
    final c = Completer<(T1, T2, T3, T4, T5, T6, T7, T8, T9)>.sync();
    final v1 = _FutureResult<T1>($1);
    final v2 = _FutureResult<T2>($2);
    final v3 = _FutureResult<T3>($3);
    final v4 = _FutureResult<T4>($4);
    final v5 = _FutureResult<T5>($5);
    final v6 = _FutureResult<T6>($6);
    final v7 = _FutureResult<T7>($7);
    final v8 = _FutureResult<T8>($8);
    final v9 = _FutureResult<T9>($9);

    _FutureResult._waitAll([v1, v2, v3, v4, v5, v6, v7, v8, v9], (int errors) {
      if (errors == 0) {
        c.complete((
          v1.value,
          v2.value,
          v3.value,
          v4.value,
          v5.value,
          v6.value,
          v7.value,
          v8.value,
          v9.value
        ));
      } else {
        c.completeError(ParallelWaitError(
          (
            v1.valueOrNull,
            v2.valueOrNull,
            v3.valueOrNull,
            v4.valueOrNull,
            v5.valueOrNull,
            v6.valueOrNull,
            v7.valueOrNull,
            v8.valueOrNull,
            v9.valueOrNull
          ),
          (
            v1.errorOrNull,
            v2.errorOrNull,
            v3.errorOrNull,
            v4.errorOrNull,
            v5.errorOrNull,
            v6.errorOrNull,
            v7.errorOrNull,
            v8.errorOrNull,
            v9.errorOrNull
          ),
            errorCount: errors,
            defaultError: v1.errorOrNull ??
                v2.errorOrNull ??
                v3.errorOrNull ??
                v4.errorOrNull ??
                v5.errorOrNull ??
                v6.errorOrNull ??
                v7.errorOrNull ??
                v8.errorOrNull ??
                v9.errorOrNull
        ));
      }
    });
    return c.future;
  }
}

/// Error thrown when waiting for multiple futures, when some have errors.
///
/// The [V] and [E] types will have the same basic shape as the
/// original collection of futures that was waited on.
///
/// For example, if the original awaited futures were a record
/// `(Future<T1>, ..., Future<Tn>)`,
/// the type `V` will be `(T1?, ..., Tn?)` which allows keeping the
/// values of futures that completed with a value,
/// and `E` will be `(AsyncError?, ..., AsyncError?)`, also with *n*
/// fields, which can contain the errors for the futures which completed
/// with an error.
///
/// Waiting for a list or iterable of futures should provide
/// a list of nullable values and errors of the same length.
@Since("3.0")
class ParallelWaitError<V, E> extends Error {
  /// Values of successful futures.
  ///
  /// Has the same shape as the original collection of futures,
  /// with values for each successful future and `null` values
  /// for each failing future.
  final V values;

  /// Errors of failing futures.
  ///
  /// Has the same shape as the original collection of futures,
  /// with errors, typically [AsyncError], for each failing
  /// future and `null` values for each successful future.
  final E errors;

  /// An error which, if present, is included in the [toString] output.
  ///
  /// If the default error has a stack trace, it's also reported by the
  /// [stackTrace] getter, instead of where this [ParallelWaitError] was thrown.
  final AsyncError? _defaultError;

  /// Number of errors, if available.
  final int? _errorCount;

  /// Creates error with the provided [values] and [errors].
  ///
  /// If [defaultError] is provided, its [AsyncError.error] is used in
  /// the [toString] of this parallel error, and its [AsyncError.stackTrace]
  /// is returned by [stackTrace].
  ///
  /// If [errorCount] is provided, and it's greater than one,
  /// the number is reported in the [toString].
  ParallelWaitError(this.values, this.errors,
      {@Since("3.4") int? errorCount, @Since("3.4") AsyncError? defaultError})
      : _defaultError = defaultError,
        _errorCount = errorCount;

  String toString() {
    if (_defaultError == null) {
      if (_errorCount == null || _errorCount <= 1) {
        return "ParallelWaitError";
      }
      return "ParallelWaitError($_errorCount errors)";
    }
    return "ParallelWaitError${_errorCount != null && _errorCount > 1 //
        ? "($_errorCount errors)" : ""}: ${_defaultError.error}";
  }

  StackTrace? get stackTrace => _defaultError?.stackTrace ?? super.stackTrace;
}

/// The result of a future, when it has completed.
///
/// Stores a value result in [value] and an error result in [error].
/// Then calls [onReady] with a 0 argument for a value, and 1 for an error.
///
/// The [onReady] callback must be set synchronously,
/// before the future has a chance to complete.
///
/// Abstracted into a class of its own in order to reuse code.
class _FutureResult<T> {
  // Consider integrating directly into `_Future` as a `_FutureListener`
  // to avoid creating as many function tear-offs.

  /// The value or `null`.
  ///
  /// Set when the future completes with a value.
  T? valueOrNull;

  /// Set when the future completes with an error or value.
  AsyncError? errorOrNull;

  void Function(int errors) onReady = _noop;

  _FutureResult(Future<T> future) {
    future.then(_onValue, onError: _onError);
  }

  /// The value.
  ///
  /// Should only be used when the future is known to have completed with
  /// a value.
  T get value => valueOrNull ?? valueOrNull as T;

  void _onValue(T value) {
    valueOrNull = value;
    onReady(0);
  }

  void _onError(Object error, StackTrace stack) {
    this.errorOrNull = AsyncError(error, stack);
    onReady(1);
  }

  /// Waits for a number of [_FutureResult]s to all have completed.
  ///
  /// List must not be empty.
  static void _waitAll(
      List<_FutureResult> results, void Function(int) whenReady) {
    assert(results.isNotEmpty);
    var ready = 0;
    var errors = 0;
    void onReady(int error) {
      errors += error;
      if (++ready == results.length) {
        whenReady(errors);
      }
    }

    for (var r in results) {
      r.onReady = onReady;
    }
  }

  static void _noop(_) {}
}
