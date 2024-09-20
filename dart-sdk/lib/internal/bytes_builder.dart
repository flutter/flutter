// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/// Builds a list of bytes, allowing bytes and lists of bytes to be added at the
/// end.
///
/// Used to efficiently collect bytes and lists of bytes.
abstract interface class BytesBuilder {
  /// Construct a new empty [BytesBuilder].
  ///
  /// If [copy] is true (the default), the created builder is a *copying*
  /// builder. A copying builder maintains its own internal buffer and copies
  /// the bytes added to it eagerly.
  ///
  /// If [copy] set to false, the created builder assumes that lists added
  /// to it will not change.
  /// Any [Uint8List] added using [add] is kept until
  /// [toBytes] or [takeBytes] is called,
  /// and only then are their contents copied.
  /// A non-[Uint8List] may be copied eagerly.
  /// If only a single [Uint8List] is added to the builder,
  /// that list is returned by [toBytes] or [takeBytes] directly, without any copying.
  /// A list added to a non-copying builder *should not* change its content
  /// after being added, and it *must not* change its length after being added.
  /// (Normal [Uint8List]s are fixed length lists, but growing lists implementing
  /// [Uint8List] exist.)
  factory BytesBuilder({bool copy = true}) =>
      copy ? _CopyingBytesBuilder() : _BytesBuilder();

  /// Appends [bytes] to the current contents of this builder.
  ///
  /// Each value of [bytes] will be truncated
  /// to an 8-bit value in the range 0 .. 255.
  void add(List<int> bytes);

  /// Appends [byte] to the current contents of this builder.
  ///
  /// The [byte] will be truncated to an 8-bit value in the range 0 .. 255.
  void addByte(int byte);

  /// Returns the bytes currently contained in this builder and clears it.
  ///
  /// The returned list may be a view of a larger buffer.
  Uint8List takeBytes();

  /// Returns a copy of the current byte contents of this builder.
  ///
  /// Leaves the contents of this builder intact.
  Uint8List toBytes();

  /// The number of bytes in this builder.
  int get length;

  /// Whether the buffer is empty.
  bool get isEmpty;

  /// Whether the buffer is non-empty.
  bool get isNotEmpty;

  /// Clears the contents of this builder.
  ///
  /// The current contents are discarded and this builder becomes empty.
  void clear();
}

/// A [BytesBuilder] which appends bytes to a growing internal buffer.
class _CopyingBytesBuilder implements BytesBuilder {
  /// Initial size of internal buffer.
  static const int _initSize = 1024;

  /// Reusable empty [Uint8List].
  ///
  /// Safe for reuse because a fixed-length empty list is immutable.
  static final _emptyList = Uint8List(0);

  /// Current count of bytes written to buffer.
  int _length = 0;

  /// Internal buffer accumulating bytes.
  ///
  /// Will grow as necessary
  Uint8List _buffer;

  _CopyingBytesBuilder() : _buffer = _emptyList;

  void add(List<int> bytes) {
    int byteCount = bytes.length;
    if (byteCount == 0) return;
    int required = _length + byteCount;
    if (_buffer.length < required) {
      _grow(required);
    }
    assert(_buffer.length >= required);
    if (bytes is Uint8List) {
      _buffer.setRange(_length, required, bytes);
    } else {
      for (int i = 0; i < byteCount; i++) {
        _buffer[_length + i] = bytes[i];
      }
    }
    _length = required;
  }

  void addByte(int byte) {
    if (_buffer.length == _length) {
      // The grow algorithm always at least doubles.
      // If we added one to _length it would quadruple unnecessarily.
      _grow(_length);
    }
    assert(_buffer.length > _length);
    _buffer[_length] = byte;
    _length++;
  }

  void _grow(int required) {
    // We will create a list in the range of 2-4 times larger than
    // required.
    int newSize = required * 2;
    if (newSize < _initSize) {
      newSize = _initSize;
    } else {
      newSize = _pow2roundup(newSize);
    }
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  Uint8List takeBytes() {
    if (_length == 0) return _emptyList;
    var buffer = Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length);
    _clear();
    return buffer;
  }

  Uint8List toBytes() {
    if (_length == 0) return _emptyList;
    return Uint8List.fromList(
        Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length));
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _clear();
  }

  void _clear() {
    _length = 0;
    _buffer = _emptyList;
  }

  /// Rounds numbers <= 2^32 up to the nearest power of 2.
  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}

/// A non-copying [BytesBuilder].
///
/// Accumulates lists of integers and lazily builds
/// a collected list with all the bytes when requested.
class _BytesBuilder implements BytesBuilder {
  int _length = 0;
  final List<Uint8List> _chunks = [];

  void add(List<int> bytes) {
    Uint8List typedBytes;
    if (bytes is Uint8List) {
      typedBytes = bytes;
    } else {
      typedBytes = Uint8List.fromList(bytes);
    }
    _chunks.add(typedBytes);
    _length += typedBytes.length;
  }

  void addByte(int byte) {
    // TODO(lrn): Optimize repeated `addByte` calls.
    _chunks.add(Uint8List(1)..[0] = byte);
    _length++;
  }

  Uint8List takeBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    if (_chunks.length == 1) {
      var buffer = _chunks[0];
      _clear();
      return buffer;
    }
    var buffer = Uint8List(_length);
    int offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _clear();
    return buffer;
  }

  Uint8List toBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    var buffer = Uint8List(_length);
    int offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return buffer;
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _clear();
  }

  void _clear() {
    _length = 0;
    _chunks.clear();
  }
}
