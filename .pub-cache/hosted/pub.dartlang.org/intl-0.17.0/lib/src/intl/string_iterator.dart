// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides an 'iterator' over a string as a list of substrings, and also
/// gives us a lookahead of one via the [peek] method.
class StringIterator {
  final String input;
  int nextIndex = 0;
  String? _current;

  StringIterator(this.input);

  String? get current => _current;

  bool moveNext() {
    if (nextIndex >= input.length) {
      _current = null;
      return false;
    }
    _current = input[nextIndex++];
    return true;
  }

  String? get peek => nextIndex >= input.length ? null : input[nextIndex];
}
