// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' as js;

@patch
class StringBuffer {
  String _contents;

  @patch
  StringBuffer([Object content = ""]) : _contents = '$content';

  @patch
  int get length => _contents.length;

  @patch
  void write(Object? obj) => _writeString('$obj');

  @patch
  void writeCharCode(int charCode) =>
      _writeString(String.fromCharCode(charCode));

  @patch
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _contents = _writeAll(_contents, objects, separator);
  }

  @patch
  void writeln([Object? obj = ""]) => _writeString('$obj\n');

  @patch
  void clear() => _contents = "";

  @patch
  String toString() => _contents;

  void _writeString(String str) {
    _contents = _contents + str;
  }

  static String _writeAll(
      String string, Iterable<Object?> objects, String separator) {
    final iterator = objects.iterator;
    if (!iterator.moveNext()) return string;
    if (separator.isEmpty) {
      do {
        string = _writeOne(string, iterator.current);
      } while (iterator.moveNext());
    } else {
      string = _writeOne(string, iterator.current);
      while (iterator.moveNext()) {
        string = _writeOne(string, separator);
        string = _writeOne(string, iterator.current);
      }
    }
    return string;
  }

  static String _writeOne(String string, Object? obj) => string + '$obj';
}
