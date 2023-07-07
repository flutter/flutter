// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../delegate/future.dart';
import 'result.dart';

/// A [Future] wrapper that provides synchronous access to the result of the
/// wrapped [Future] once it's completed.
class ResultFuture<T> extends DelegatingFuture<T> {
  /// Whether the future has fired and [result] is available.
  bool get isComplete => result != null;

  /// The result of the wrapped [Future], if it's completed.
  ///
  /// If it hasn't completed yet, this will be `null`.
  Result<T>? get result => _result;
  Result<T>? _result;

  ResultFuture(Future<T> future) : super(future) {
    Result.capture(future).then((result) {
      _result = result;
    });
  }
}
