// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' as js;

@patch
class StringBuffer {
  String _contents;

  @patch
  @pragma("wasm:prefer-inline")
  StringBuffer([Object content = ""]) : _contents = content.toString();

  @patch
  @pragma("wasm:prefer-inline")
  int get length => _contents.length;

  @patch
  @pragma("wasm:prefer-inline")
  void write(Object? obj) {
    if (obj is String) {
      _writeString(obj);
    } else {
      _writeString(obj.toString());
    }
  }

  @patch
  @pragma("wasm:prefer-inline")
  void writeCharCode(int charCode) =>
      _writeString(String.fromCharCode(charCode));

  @patch
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _contents = _writeAll(_contents, objects, separator);
  }

  @patch
  @pragma("wasm:prefer-inline")
  void writeln([Object? obj = ""]) => _writeString('$obj\n');

  @patch
  @pragma("wasm:prefer-inline")
  void clear() => _contents = "";

  @patch
  @pragma("wasm:prefer-inline")
  String toString() => _contents;

  @pragma("wasm:prefer-inline")
  void _writeString(String str) {
    _contents = _contents + str;
  }

  static String _writeAll(
    String string,
    Iterable<Object?> objects,
    String separator,
  ) {
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

  @pragma("wasm:prefer-inline")
  static String _writeOne(String string, Object? obj) =>
      string + obj.toString();
}
