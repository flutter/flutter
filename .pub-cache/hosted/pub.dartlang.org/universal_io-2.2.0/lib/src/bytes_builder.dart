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
class BytesBuilder {
  final bool _copy;
  int _length = 0;
  final List<List<int>> _chunks = [];

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
  factory BytesBuilder({bool copy = true}) {
    return BytesBuilder._(copy: copy);
  }

  BytesBuilder._({bool copy = true}) : _copy = copy;

  /// Whether the buffer is empty.
  bool get isEmpty => length == 0;

  /// Whether the buffer is non-empty.
  bool get isNotEmpty => length != 0;

  /// The number of bytes in this builder.
  int get length => _length;

  /// Appends [bytes] to the current contents of this builder.
  ///
  /// Each value of [bytes] will be truncated
  /// to an 8-bit value in the range 0 .. 255.
  void add(List<int> bytes) {
    _length += bytes.length;
    if (_copy) {
      final copy = Uint8List(bytes.length);
      copy.setRange(0, bytes.length, bytes);
      _chunks.add(copy);
    } else {
      _chunks.add(bytes);
    }
  }

  /// Appends [byte] to the current contents of this builder.
  ///
  /// The [byte] will be truncated to an 8-bit value in the range 0 .. 255.
  void addByte(int byte) {
    add([byte]);
  }

  /// Clears the contents of this builder.
  ///
  /// The current contents are discarded and this builder becomes empty.
  void clear() {
    _length = 0;
    _chunks.clear();
  }

  /// Returns the bytes currently contained in this builder and clears it.
  ///
  /// The returned list may be a view of a larger buffer.
  Uint8List takeBytes() {
    final result = toBytes();
    clear();
    return result;
  }

  /// Returns a copy of the current byte contents of this builder.
  ///
  /// Leaves the contents of this builder intact.
  Uint8List toBytes() {
    final result = Uint8List(_length);
    var offset = 0;
    for (final chunk in _chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }
}
