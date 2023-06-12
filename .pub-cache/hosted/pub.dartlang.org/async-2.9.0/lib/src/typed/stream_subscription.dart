// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class TypeSafeStreamSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription _subscription;

  @override
  bool get isPaused => _subscription.isPaused;

  TypeSafeStreamSubscription(this._subscription);

  @override
  void onData(void Function(T)? handleData) {
    if (handleData == null) return _subscription.onData(null);
    _subscription.onData((data) => handleData(data as T));
  }

  @override
  void onError(Function? handleError) {
    _subscription.onError(handleError);
  }

  @override
  void onDone(void Function()? handleDone) {
    _subscription.onDone(handleDone);
  }

  @override
  void pause([Future? resumeFuture]) {
    _subscription.pause(resumeFuture);
  }

  @override
  void resume() {
    _subscription.resume();
  }

  @override
  Future cancel() => _subscription.cancel();

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _subscription.asFuture(futureValue);
}
