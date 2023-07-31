// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'async_memoizer.dart';

typedef _AsyncHandler<T> = Future Function(StreamSubscription<T> inner);

typedef _VoidHandler<T> = void Function(StreamSubscription<T> inner);

/// Creates a [StreamTransformer] that modifies the behavior of subscriptions to
/// a stream.
///
/// When [StreamSubscription.cancel], [StreamSubscription.pause], or
/// [StreamSubscription.resume] is called, the corresponding handler is invoked.
/// By default, handlers just forward to the underlying subscription.
///
/// Guarantees that none of the [StreamSubscription] callbacks and none of the
/// callbacks passed to `subscriptionTransformer()` will be invoked once the
/// transformed [StreamSubscription] has been canceled and `handleCancel()` has
/// run. The [handlePause] and [handleResume] are invoked regardless of whether
/// the subscription is paused already or not.
///
/// In order to preserve [StreamSubscription] guarantees, **all callbacks must
/// synchronously call the corresponding method** on the inner
/// [StreamSubscription]: [handleCancel] must call `cancel()`, [handlePause]
/// must call `pause()`, and [handleResume] must call `resume()`.
StreamTransformer<T, T> subscriptionTransformer<T>(
    {Future Function(StreamSubscription<T>)? handleCancel,
    void Function(StreamSubscription<T>)? handlePause,
    void Function(StreamSubscription<T>)? handleResume}) {
  return StreamTransformer((stream, cancelOnError) {
    return _TransformedSubscription(
        stream.listen(null, cancelOnError: cancelOnError),
        handleCancel ?? (inner) => inner.cancel(),
        handlePause ??
            (inner) {
              inner.pause();
            },
        handleResume ??
            (inner) {
              inner.resume();
            });
  });
}

/// A [StreamSubscription] wrapper that calls callbacks for subscription
/// methods.
class _TransformedSubscription<T> implements StreamSubscription<T> {
  /// The wrapped subscription.
  StreamSubscription<T>? _inner;

  /// The callback to run when [cancel] is called.
  final _AsyncHandler<T> _handleCancel;

  /// The callback to run when [pause] is called.
  final _VoidHandler<T> _handlePause;

  /// The callback to run when [resume] is called.
  final _VoidHandler<T> _handleResume;

  @override
  bool get isPaused => _inner?.isPaused ?? false;

  _TransformedSubscription(
      this._inner, this._handleCancel, this._handlePause, this._handleResume);

  @override
  void onData(void Function(T)? handleData) {
    _inner?.onData(handleData);
  }

  @override
  void onError(Function? handleError) {
    _inner?.onError(handleError);
  }

  @override
  void onDone(void Function()? handleDone) {
    _inner?.onDone(handleDone);
  }

  @override
  Future cancel() => _cancelMemoizer.runOnce(() {
        var inner = _inner!;
        inner.onData(null);
        inner.onDone(null);

        // Setting onError to null will cause errors to be top-leveled.
        inner.onError((_, __) {});
        _inner = null;
        return _handleCancel(inner);
      });
  final _cancelMemoizer = AsyncMemoizer();

  @override
  void pause([Future? resumeFuture]) {
    if (_cancelMemoizer.hasRun) return;
    if (resumeFuture != null) resumeFuture.whenComplete(resume);
    _handlePause(_inner!);
  }

  @override
  void resume() {
    if (_cancelMemoizer.hasRun) return;
    _handleResume(_inner!);
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _inner?.asFuture(futureValue) ?? Completer<E>().future;
}
