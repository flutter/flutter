// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'error.dart';
import 'result.dart';

/// A result representing a returned value.
class ValueResult<T> implements Result<T> {
  /// The result of a successful computation.
  final T value;

  @override
  bool get isValue => true;
  @override
  bool get isError => false;
  @override
  ValueResult<T> get asValue => this;
  @override
  ErrorResult? get asError => null;

  ValueResult(this.value);

  @override
  void complete(Completer<T> completer) {
    completer.complete(value);
  }

  @override
  void addTo(EventSink<T> sink) {
    sink.add(value);
  }

  @override
  Future<T> get asFuture => Future.value(value);

  @override
  int get hashCode => value.hashCode ^ 0x323f1d61;

  @override
  bool operator ==(Object other) =>
      other is ValueResult && value == other.value;
}
