// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class _WhereTypeStreamSink<S, T> implements EventSink<S> {
  final EventSink<T> _sink;

  _WhereTypeStreamSink(this._sink);

  @override
  void add(S data) {
    if (data is T) {
      _sink.add(data);
    }
  }

  @override
  void addError(e, [StackTrace? stackTrace]) => _sink.addError(e, stackTrace);

  @override
  void close() => _sink.close();
}

class _WhereTypeStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  @override
  Stream<T> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _WhereTypeStreamSink<S, T>(sink));
}

extension StreamExtension<T> on Stream<T> {
  Stream<S> whereType<S>() => transform(_WhereTypeStreamTransformer<T, S>());
}
