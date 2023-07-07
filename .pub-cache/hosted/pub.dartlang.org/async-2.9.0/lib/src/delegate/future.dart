// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A wrapper that forwards calls to a [Future].
class DelegatingFuture<T> implements Future<T> {
  /// The wrapped [Future].
  final Future<T> _future;

  DelegatingFuture(this._future);

  /// Creates a wrapper which throws if [future]'s value isn't an instance of
  /// `T`.
  ///
  /// This soundly converts a [Future] to a `Future<T>`, regardless of its
  /// original generic type, by asserting that its value is an instance of `T`
  /// whenever it's provided. If it's not, the future throws a [TypeError].
  @Deprecated('Use future.then((v) => v as T) instead.')
  static Future<T> typed<T>(Future future) =>
      future is Future<T> ? future : future.then((v) => v as T);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<S> then<S>(FutureOr<S> Function(T) onValue, {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<T> whenComplete(FutureOr Function() action) =>
      _future.whenComplete(action);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);
}
