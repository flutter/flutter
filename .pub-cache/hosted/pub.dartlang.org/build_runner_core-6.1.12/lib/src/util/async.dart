// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Invokes [callback] and returns the result as soon as possible. This will
/// happen synchronously if [value] is available.
FutureOr<S> doAfter<T, S>(
    FutureOr<T> value, FutureOr<S> Function(T value) callback) {
  if (value is Future<T>) {
    return value.then(callback);
  } else {
    return callback(value as T);
  }
}

/// Converts [value] to a [Future] if it is not already.
Future<T> toFuture<T>(FutureOr<T> value) =>
    value is Future<T> ? value : Future.value(value);
