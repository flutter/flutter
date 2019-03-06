// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// A [Future] whose [then] implementation calls the callback immediately.
///
/// This is similar to [new Future.value], except that the value is available in
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
  /// See also [new Future.value].
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
  Future<T> catchError(Function onError, { bool test(dynamic error) }) => Completer<T>().future;

  @override
  Future<E> then<E>(dynamic f(T value), { Function onError }) {
    final dynamic result = f(_value);
    if (result is Future<E>)
      return result;
    return SynchronousFuture<E>(result);
  }

  @override
  Future<T> timeout(Duration timeLimit, { dynamic onTimeout() }) {
    return Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(dynamic action()) {
    try {
      final dynamic result = action();
      if (result is Future)
        return result.then<T>((dynamic value) => _value);
      return this;
    } catch (e, stack) {
      return Future<T>.error(e, stack);
    }
  }
}
