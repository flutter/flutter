// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

/// An indexed position in a String which can read by specified character
/// counts, or read digits up to a delimiter.
class StringStack {
  final String contents;
  int _index = 0;

  StringStack(this.contents);

  bool get atStart => _index == 0;

  bool get atEnd => _index >= contents.length;

  String next() => contents[_index++];

  /// Advance the index by [n].
  void pop([int n = 1]) => _index += n;

  /// Return the next [n] characters, or as many as there are remaining,
  /// and advance the index.
  String read([int n = 1]) {
    var result = peek(n);
    pop(n);
    return result;
  }

  /// Returns whether the input starts with [pattern] from the current index.
  bool startsWith(String pattern) => contents.startsWith(pattern, _index);

  /// Return the next [howMany] characters, or as many as there are remaining,
  /// without advancing the index.
  String peek([int howMany = 1]) =>
      contents.substring(_index, min(_index + howMany, contents.length));

  /// Return the remaining contents of the String, without advancing the index.
  String peekAll() => peek(contents.length - _index);

  @override
  String toString() {
    return '$contents at $_index';
  }
}
