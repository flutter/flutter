/**
 * wtf8.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *    22/02/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */
// referred from https://github.com/mathiasbynens/wtf-8
class WTF8 {
  static String encode(String string) {
    var codePoints = _ucs2decode(string);
    var length = codePoints.length;
    var index = -1;
    var codePoint;
    var byteString = '';
    while (++index < length) {
      codePoint = codePoints[index];
      byteString += _encodeCodePoint(codePoint);
    }
    return byteString;
  }

  static List<int> _ucs2decode(String string) {
    List<int> output = [];
    var counter = 0;
    var length = string.length;
    var value;
    var extra;
    while (counter < length) {
      value = string.codeUnitAt(counter++);
      if (value >= 0xD800 && value <= 0xDBFF && counter < length) {
        // high surrogate, and there is a next character
        extra = string.codeUnitAt(counter++);
        if ((extra & 0xFC00) == 0xDC00) {
          // low surrogate
          output.add(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
        } else {
          // unmatched surrogate; only append this code unit, in case the next
          // code unit is the high surrogate of a surrogate pair
          output.add(value);
          counter--;
        }
      } else {
        output.add(value);
      }
    }
    return output;
  }

  static _encodeCodePoint(int codePoint) {
    if ((codePoint & 0xFFFFFF80) == 0) {
      // 1-byte sequence
      return new String.fromCharCode(codePoint);
    }
    var symbol = '';
    if ((codePoint & 0xFFFFF800) == 0) {
      // 2-byte sequence
      symbol = new String.fromCharCode(((codePoint >> 6) & 0x1F) | 0xC0);
    } else if ((codePoint & 0xFFFF0000) == 0) {
      // 3-byte sequence
      symbol = new String.fromCharCode(((codePoint >> 12) & 0x0F) | 0xE0);
      symbol += _createByte(codePoint, 6);
    } else if ((codePoint & 0xFFE00000) == 0) {
      // 4-byte sequence
      symbol = new String.fromCharCode(((codePoint >> 18) & 0x07) | 0xF0);
      symbol += _createByte(codePoint, 12);
      symbol += _createByte(codePoint, 6);
    }
    symbol += new String.fromCharCode((codePoint & 0x3F) | 0x80);
    return symbol;
  }

  static _createByte(codePoint, shift) {
    return new String.fromCharCode(((codePoint >> shift) & 0x3F) | 0x80);
  }
}
