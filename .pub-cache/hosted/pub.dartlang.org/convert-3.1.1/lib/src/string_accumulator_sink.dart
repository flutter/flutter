// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// A sink that provides access to the concatenated strings passed to it.
///
/// See also [StringConversionSink.withCallback].
class StringAccumulatorSink extends StringConversionSinkBase {
  /// The string accumulated so far.
  String get string => _buffer.toString();
  final _buffer = StringBuffer();

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  /// Empties [string].
  ///
  /// This can be used to avoid double-processing data.
  void clear() {
    _buffer.clear();
  }

  @override
  void add(String str) {
    if (_isClosed) {
      throw StateError("Can't add to a closed sink.");
    }

    _buffer.write(str);
  }

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    if (_isClosed) {
      throw StateError("Can't add to a closed sink.");
    }

    _buffer.write(str.substring(start, end));
    if (isLast) _isClosed = true;
  }

  @override
  void close() {
    _isClosed = true;
  }
}
