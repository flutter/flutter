// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Creates a wrapper that coerces the type of [transformer].
///
/// This soundly converts a [StreamTransformer] to a `StreamTransformer<S, T>`,
/// regardless of its original generic type, by asserting that the events
/// emitted by the transformed stream are instances of `T` whenever they're
/// provided. If they're not, the stream throws a [TypeError].
@Deprecated('Use Stream.cast after binding a transformer instead')
StreamTransformer<S, T> typedStreamTransformer<S, T>(
        StreamTransformer transformer) =>
    transformer is StreamTransformer<S, T>
        ? transformer
        : _TypeSafeStreamTransformer(transformer);

/// A wrapper that coerces the type of the stream returned by an inner
/// transformer.
class _TypeSafeStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  final StreamTransformer _inner;

  _TypeSafeStreamTransformer(this._inner);

  @override
  Stream<T> bind(Stream<S> stream) => _inner.bind(stream).cast();
}
