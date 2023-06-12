// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns true if [a] and [b] are the same ignoring case and all instances of
///  `-` and `_`.
///
/// This is specialized code for comparing enum names.
/// Works only for ascii strings containing letters and `_` and `-`.
bool permissiveCompare(String a, String b) {
  const dash = 45;
  const underscore = 95;

  var i = 0;
  var j = 0;

  while (true) {
    int ca, cb;
    do {
      ca = i < a.length ? a.codeUnitAt(i++) : -1;
    } while (ca == dash || ca == underscore);
    do {
      cb = j < b.length ? b.codeUnitAt(j++) : -1;
    } while (cb == dash || cb == underscore);
    if (ca == cb) {
      if (ca == -1) return true; // Both at end
      continue;
    }
    if (ca ^ cb != 0x20 || !_isAsciiLetter(ca)) {
      return false;
    }
  }
}

bool _isAsciiLetter(int char) {
  const lowerA = 97;
  const lowerZ = 122;
  const capitalA = 65;
  char |= lowerA ^ capitalA;
  return lowerA <= char && char <= lowerZ;
}
