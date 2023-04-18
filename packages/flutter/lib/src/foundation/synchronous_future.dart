// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// A [Future] whose [then] implementation calls the callback immediately.
///
/// This is similar to [Future.value], except that the value is available in
/// the same event-loop iteration.
///
/// ⚠ This class is useful in cases where you want to expose a single API, where
/// you normally want to have everything execute synchronously, but where on
/// rare occasions you want the ability to switch to an asynchronous model. **In
/// general use of this class should be avoided as it is very difficult to debug
/// such bimodal behavior.**
class SynchronousFuture<T> implements Future<T> {
  /// Creates a synchronous future.
  ///
  /// See also:
  ///
  ///  * [Future.value] for information about creating a regular
  ///    [Future] that completes with a value.
  SynchronousFuture(this._value);

  final T _value;

  @override
  Stream<T> asStream() {
    final StreamController<T> controller = StreamController<T>();
    controller.add(_value);
    controller.close();
    return controller.stream;
  }

  @override
  Future<T> catchError(final Function onError, { final bool Function(Object error)? test }) => Completer<T>().future;

  @override
  Future<R> then<R>(final FutureOr<R> Function(T value) onValue, { final Function? onError }) {
    final FutureOr<R> result = onValue(_value);
    if (result is Future<R>) {
      return result;
    }
    return SynchronousFuture<R>(result);
  }

  @override
  Future<T> timeout(final Duration timeLimit, { final FutureOr<T> Function()? onTimeout }) {
    return Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(final FutureOr<dynamic> Function() action) {
    try {
      final FutureOr<dynamic> result = action();
      if (result is Future) {
        return result.then<T>((final dynamic value) => _value);
      }
      return this;
    } catch (e, stack) {
      return Future<T>.error(e, stack);
    }
  }
}
