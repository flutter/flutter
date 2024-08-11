// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch, unsafeCast;
import "dart:_string";

@patch
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
    RangeError.checkNotNegative(start, "start");
    if (end != null) {
      if (end < start) {
        throw RangeError.range(end, start, null, "end");
      }
      if (end == start) return "";
    }
    return StringBase.createFromCharCodes(charCodes, start, end);
  }

  @patch
  factory String.fromCharCode(int charCode) {
    if (charCode >= 0) {
      if (charCode <= 0xff) {
        final string = OneByteString.withLength(1);
        string.setUnchecked(0, charCode);
        return string;
      }
      if (charCode <= 0xffff) {
        final string = TwoByteString.withLength(1);
        string.setUnchecked(0, charCode);
        return string;
      }
      if (charCode <= 0x10ffff) {
        int low = 0xDC00 | (charCode & 0x3ff);
        int bits = charCode - 0x10000;
        int high = 0xD800 | (bits >> 10);
        final string = TwoByteString.withLength(2);
        string.setUnchecked(0, high);
        string.setUnchecked(1, low);
        return string;
      }
    }
    throw RangeError.range(charCode, 0, 0x10ffff);
  }

  @patch
  external const factory String.fromEnvironment(String name,
      {String defaultValue = ""});
}

extension _StringExt on String {
  int firstNonWhitespace() {
    final value = this;
    if (value is StringBase) return value.firstNonWhitespace();
    return unsafeCast<JSStringImpl>(value).firstNonWhitespace();
  }

  int lastNonWhitespace() {
    final value = this;
    if (value is StringBase) return value.lastNonWhitespace();
    return unsafeCast<JSStringImpl>(value).lastNonWhitespace();
  }
}
