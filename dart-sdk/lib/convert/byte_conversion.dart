// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// The [ByteConversionSink] provides an interface for converters to
/// efficiently transmit byte data.
///
/// Instead of limiting the interface to one non-chunked list of bytes it
/// accepts its input in chunks (themselves being lists of bytes).
abstract mixin class ByteConversionSink
    implements ChunkedConversionSink<List<int>> {
  const ByteConversionSink();

  factory ByteConversionSink.withCallback(
      void callback(List<int> accumulated)) = _ByteCallbackSink;
  factory ByteConversionSink.from(Sink<List<int>> sink) = _ByteAdapterSink;

  /// Adds the next [chunk] to `this`.
  ///
  /// Adds the bytes defined by [start] and [end]-exclusive to `this`.
  ///
  /// If [isLast] is `true` closes `this`.
  ///
  /// Contrary to `add` the given [chunk] must not be held onto.
  /// Once the method returns, it is safe to overwrite the data in it.
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    add(chunk.sublist(start, end));
    if (isLast) close();
  }
}

/// This class provides a base-class for converters that need to accept byte
/// inputs.
// TODO(lrn): @Deprecated("Use ByteConversionSink instead")
typedef ByteConversionSinkBase = ByteConversionSink;

/// This class adapts a simple [Sink] to a [ByteConversionSink].
///
/// All additional methods of the [ByteConversionSink] (compared to the
/// ChunkedConversionSink) are redirected to the `add` method.
class _ByteAdapterSink extends ByteConversionSink {
  final Sink<List<int>> _sink;

  _ByteAdapterSink(this._sink);

  void add(List<int> chunk) {
    _sink.add(chunk);
  }

  void close() {
    _sink.close();
  }
}

/// This class accumulates all chunks into one list of bytes
/// and invokes a callback when the sink is closed.
///
/// This class can be used to terminate a chunked conversion.
class _ByteCallbackSink extends ByteConversionSink {
  static const _INITIAL_BUFFER_SIZE = 1024;

  final void Function(List<int>) _callback;
  List<int> _buffer = Uint8List(_INITIAL_BUFFER_SIZE);
  int _bufferIndex = 0;

  _ByteCallbackSink(void callback(List<int> accumulated))
      : _callback = callback;

  void add(Iterable<int> chunk) {
    var freeCount = _buffer.length - _bufferIndex;
    if (chunk.length > freeCount) {
      // Grow the buffer.
      var oldLength = _buffer.length;
      var newLength = _roundToPowerOf2(chunk.length + oldLength) * 2;
      var grown = Uint8List(newLength);
      grown.setRange(0, _buffer.length, _buffer);
      _buffer = grown;
    }
    _buffer.setRange(_bufferIndex, _bufferIndex + chunk.length, chunk);
    _bufferIndex += chunk.length;
  }

  static int _roundToPowerOf2(int v) {
    assert(v > 0);
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
  }

  void close() {
    _callback(_buffer.sublist(0, _bufferIndex));
  }
}
