// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Simple delegating wrapper around a [StreamSink].
///
/// Subclasses can override individual methods, or use this to expose only the
/// [StreamSink] methods of a subclass.
class DelegatingStreamSink<T> implements StreamSink<T> {
  final StreamSink _sink;

  @override
  Future get done => _sink.done;

  /// Create delegating sink forwarding calls to [sink].
  DelegatingStreamSink(StreamSink<T> sink) : _sink = sink;

  DelegatingStreamSink._(this._sink);

  /// Creates a wrapper that coerces the type of [sink].
  ///
  /// Unlike [StreamSink.new], this only requires its argument to be an instance
  /// of `StreamSink`, not `StreamSink<T>`. This means that calls to [add] may
  /// throw a [TypeError] if the argument type doesn't match the reified type of
  /// [sink].
  @Deprecated(
      'Use StreamController<T>(sync: true)..stream.cast<S>().pipe(sink)')
  static StreamSink<T> typed<T>(StreamSink sink) =>
      sink is StreamSink<T> ? sink : DelegatingStreamSink._(sink);

  @override
  void add(T data) {
    _sink.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<T> stream) => _sink.addStream(stream);

  @override
  Future close() => _sink.close();
}
