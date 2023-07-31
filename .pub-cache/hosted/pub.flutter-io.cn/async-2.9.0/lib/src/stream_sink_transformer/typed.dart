// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../stream_sink_transformer.dart';

/// A wrapper that coerces the generic type of the sink returned by an inner
/// transformer to `S`.
class TypeSafeStreamSinkTransformer<S, T>
    implements StreamSinkTransformer<S, T> {
  final StreamSinkTransformer _inner;

  TypeSafeStreamSinkTransformer(this._inner);

  @override
  StreamSink<S> bind(StreamSink<T> sink) => StreamController(sync: true)
    ..stream.cast<dynamic>().pipe(_inner.bind(sink));
}
