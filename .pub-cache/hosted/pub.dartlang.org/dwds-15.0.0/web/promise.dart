// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library webdev.web.promise;

import 'dart:async';

import 'package:js/js.dart';

/// Dart wrapper for native JavaScript Promise class.
@JS('Promise')
class Promise<T> {
  /// Constructs a new [Promise] object.
  ///
  /// The executor function is executed immediately by the Promise
  /// implementation. The resolve and reject functions, when called, resolve or
  /// reject the promise, respectively. If an error is thrown in the executor
  /// function, the promise is rejected.
  external Promise(
      void Function(void Function(T) resolve, void Function(dynamic) reject)
          executor);

  /// Appends fulfillment and rejection handlers to the promise.
  ///
  /// Returns a new promise resolving to the return value of the called handler,
  /// or to its original settled value if the promise was not handled.
  external Promise<dynamic> then(dynamic Function(T value) onSuccess,
      [dynamic Function(dynamic reason) onError]);
}

/// Returns a [Promise] that resolves once the given [future] resolves.
///
/// This also propagates errors to the returned [Promise].
Promise<T> toPromise<T>(Future<T> future) {
  return Promise(
      allowInterop((void Function(T) resolve, void Function(dynamic) reject) {
    future.then(resolve).catchError(reject);
  }));
}

/// Returns a [Future] that resolves once the given [promise] resolves.
///
/// This also propagates [Promise] rejection through to the returned [Future].
Future<T> toFuture<T>(Promise<T> promise) {
  final completer = Completer<T>();
  promise.then(
    allowInterop(completer.complete),
    allowInterop((e) => completer.completeError(e)),
  );
  return completer.future;
}
