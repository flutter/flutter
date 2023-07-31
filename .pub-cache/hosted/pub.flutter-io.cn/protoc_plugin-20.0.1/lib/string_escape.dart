// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns a quoted version of [input] with contents escaped as a Dart literal.
String quoted(String input) {
  final sb = StringBuffer();
  for (final r in input.runes) {
    sb.write(_escapeCharacter(r));
  }
  return '\'${sb.toString()}\'';
}

/// Escapes [char] such that it will have it's own value in a single
/// quoted dart string.
String _escapeCharacter(int char) {
  // Handle characters with a specific escape.
  const tab = 9;
  const bell = 8;
  const newline = 10;
  const verticalTab = 11;
  const ret = 13;
  const dollar = 36;
  const singleQuote = 39;
  const backslash = 92;
  switch (char) {
    case backslash:
      return r'\\';
    case tab:
      return r'\t';
    case verticalTab:
      return r'\v';
    case bell:
      return r'\b';
    case newline:
      return r'\n';
    case ret:
      return r'\r';
    case singleQuote:
      return r"\'";
    case dollar:
      return r'\$';
  }
  // use \xcc to represent other non-printable characters.
  if (char < 32) return '\\x${char.toRadixString(16).padLeft(2, '0')}';
  return String.fromCharCode(char);
}
