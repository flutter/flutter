// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A utility similar to [fold] which emits intermediate accumulations.
extension Scan<T> on Stream<T> {
  /// Emits a sequence of the accumulated values from repeatedly applying
  /// [combine].
  ///
  /// Like [fold], but instead of producing a single value it yields each
  /// intermediate result.
  ///
  /// If [combine] returns a future it will not be called again for subsequent
  /// events from the source until it completes, therefore [combine] is always
  /// called for elements in order, and the result stream always maintains the
  /// same order as this stream.
  Stream<S> scan<S>(
      S initialValue, FutureOr<S> Function(S soFar, T element) combine) {
    var accumulated = initialValue;
    return asyncMap((value) {
      var result = combine(accumulated, value);
      if (result is Future<S>) {
        return result.then((r) => accumulated = r);
      } else {
        return accumulated = result;
      }
    });
  }
}
