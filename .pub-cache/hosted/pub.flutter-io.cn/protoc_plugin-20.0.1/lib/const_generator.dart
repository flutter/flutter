// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'indenting_writer.dart';
import 'string_escape.dart';

/// Writes JSON data as a Dart constant expression.
/// Accepts null, bool, num, String, and maps and lists.
void writeJsonConst(IndentingWriter out, val) {
  if (val is Map) {
    if (val.values.any(_nonEmptyListOrMap)) {
      out.addBlock(
          'const {', '}', () => _writeMapItems(out, val, vertical: true),
          endWithNewline: false);
    } else {
      out.print('const {');
      _writeMapItems(out, val);
      out.print('}');
    }
  } else if (val is List) {
    if (val.any(_nonEmptyListOrMap)) {
      out.addBlock(
          'const [', ']', () => _writeListItems(out, val, vertical: true),
          endWithNewline: false);
    } else {
      out.print('const [');
      _writeListItems(out, val);
      out.print(']');
    }
  } else if (val is String) {
    _writeString(out, val);
  } else if (val is num || val is bool) {
    out.print(val.toString());
  } else if (val == null) {
    out.print('null');
  } else {
    throw 'not JSON: $val';
  }
}

bool _nonEmptyListOrMap(x) {
  if (x is List && x.isNotEmpty) return true;
  if (x is Map && x.isNotEmpty) return true;
  return false;
}

void _writeString(IndentingWriter out, String val) {
  out.print(quoted(val));
}

void _writeListItems(IndentingWriter out, List val, {bool vertical = false}) {
  var first = true;
  for (var item in val) {
    if (!first && !vertical) {
      out.print(', ');
    }
    writeJsonConst(out, item);
    if (vertical) {
      out.println(',');
    }
    first = false;
  }
}

void _writeMapItems(IndentingWriter out, Map<dynamic, dynamic> val,
    {bool vertical = false}) {
  var first = true;
  for (var key in val.keys) {
    if (!first && !vertical) out.print(', ');
    _writeString(out, key as String);
    out.print(': ');
    writeJsonConst(out, val[key]);
    if (vertical) {
      out.println(',');
    }
    first = false;
  }
}
