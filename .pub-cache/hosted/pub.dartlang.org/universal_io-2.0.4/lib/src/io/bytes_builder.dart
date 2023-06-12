// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

/// Builds a list of bytes, allowing bytes and lists of bytes to be added at the
/// end.
///
/// Used to efficiently collect bytes and lists of bytes.
abstract class BytesBuilder {
  /// Construct a empty [BytesBuilder].
  ///
  /// If [copy] is true, the data is always copied when added to the list. If
  /// it [copy] is false, the data is only copied if needed. That means that if
  /// the lists are changed after added to the [BytesBuilder], it may effect the
  /// output. Default is `true`.
  factory BytesBuilder({bool copy = true}) {
    if (copy) {
      return _CopyingBytesBuilder();
    } else {
      return _BytesBuilder();
    }
  }

  /// Returns `true` if the buffer is empty.
  bool get isEmpty;

  /// Returns `true` if the buffer is not empty.
  bool get isNotEmpty;

  /// The number of bytes in the builder.
  int get length;

  /// Appends [bytes] to the current contents of the builder.
  ///
  /// Each value of [bytes] will be bit-representation truncated to the range
  /// 0 .. 255.
  void add(List<int> bytes);

  /// Append [byte] to the current contents of the builder.
  ///
  /// The [byte] will be bit-representation truncated to the range 0 .. 255.
  void addByte(int byte);

  /// Clear the contents of the builder.
  void clear();

  /// Returns the contents of `this` and clears `this`.
  ///
  /// The list returned is a view of the internal buffer, limited to the
  /// [length].
  Uint8List takeBytes();

  /// Returns a copy of the current contents of the builder.
  ///
  /// Leaves the contents of the builder intact.
  Uint8List toBytes();
}

class _BytesBuilder implements BytesBuilder {
  int _length = 0;
  final List<Uint8List> _chunks = [];

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @override
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

  @override
  void addByte(int byte) {
    _chunks.add(Uint8List(1)..[0] = byte);
    _length++;
  }

  @override
  void clear() {
    _length = 0;
    _chunks.clear();
  }

  @override
  Uint8List takeBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    if (_chunks.length == 1) {
      var buffer = _chunks[0];
      clear();
      return buffer;
    }
    var buffer = Uint8List(_length);
    var offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    clear();
    return buffer;
  }

  @override
  Uint8List toBytes() {
    if (_length == 0) return _CopyingBytesBuilder._emptyList;
    var buffer = Uint8List(_length);
    var offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return buffer;
  }
}

class _CopyingBytesBuilder implements BytesBuilder {
  // Start with 1024 bytes.
  static const int _initSize = 1024;

  // Safe for reuse because a fixed-length empty list is immutable.
  static final _emptyList = Uint8List(0);

  int _length = 0;
  Uint8List _buffer;

  _CopyingBytesBuilder([int initialCapacity = 0])
      : _buffer = (initialCapacity <= 0)
            ? _emptyList
            : Uint8List(_pow2roundup(initialCapacity));

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @override
  void add(List<int> bytes) {
    var bytesLength = bytes.length;
    if (bytesLength == 0) return;
    var required = _length + bytesLength;
    if (_buffer.length < required) {
      _grow(required);
    }
    assert(_buffer.length >= required);
    if (bytes is Uint8List) {
      _buffer.setRange(_length, required, bytes);
    } else {
      for (var i = 0; i < bytesLength; i++) {
        _buffer[_length + i] = bytes[i];
      }
    }
    _length = required;
  }

  @override
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

  @override
  void clear() {
    _length = 0;
    _buffer = _emptyList;
  }

  @override
  Uint8List takeBytes() {
    if (_length == 0) return _emptyList;
    var buffer = Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length);
    clear();
    return buffer;
  }

  @override
  Uint8List toBytes() {
    if (_length == 0) return _emptyList;
    return Uint8List.fromList(
        Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length));
  }

  void _grow(int required) {
    // We will create a list in the range of 2-4 times larger than
    // required.
    var newSize = required * 2;
    if (newSize < _initSize) {
      newSize = _initSize;
    } else {
      newSize = _pow2roundup(newSize);
    }
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

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
