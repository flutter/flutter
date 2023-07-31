// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Simple delegating wrapper around a [Sink].
///
/// Subclasses can override individual methods, or use this to expose only the
/// [Sink] methods of a subclass.
class DelegatingSink<T> implements Sink<T> {
  final Sink _sink;

  /// Create a delegating sink forwarding calls to [sink].
  DelegatingSink(Sink<T> sink) : _sink = sink;

  DelegatingSink._(this._sink);

  /// Creates a wrapper that coerces the type of [sink].
  ///
  /// Unlike [DelegatingSink.new], this only requires its argument to be an
  /// instance of `Sink`, not `Sink<T>`. This means that calls to [add] may
  /// throw a [TypeError] if the argument type doesn't match the reified type of
  /// [sink].
  @Deprecated(
      'Use StreamController<T>(sync: true)..stream.cast<S>().pipe(sink)')
  static Sink<T> typed<T>(Sink sink) =>
      sink is Sink<T> ? sink : DelegatingSink._(sink);

  @override
  void add(T data) {
    _sink.add(data);
  }

  @override
  void close() {
    _sink.close();
  }
}
