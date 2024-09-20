// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// VM implementation of double.

@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
class double {
  @pragma("vm:external-name", "Double_parse")
  external static double? _nativeParse(String str, int start, int end);

  static double? _tryParseDouble(String str, int start, int end) {
    assert(start < end);
    const int _DOT = 0x2e; // '.'
    const int _ZERO = 0x30; // '0'
    const int _MINUS = 0x2d; // '-'
    const int _N = 0x4e; // 'N'
    const int _a = 0x61; // 'a'
    const int _I = 0x49; // 'I'
    const int _e = 0x65; // 'e'
    int exponent = 0;
    // Set to non-zero if a digit is seen. Avoids accepting ".".
    bool digitsSeen = false;
    // Added to exponent for each digit. Set to -1 when seeing '.'.
    int exponentDelta = 0;
    double doubleValue = 0.0;
    double sign = 1.0;
    int firstChar = str.codeUnitAt(start);
    if (firstChar == _MINUS) {
      sign = -1.0;
      start++;
      if (start == end) return null;
      firstChar = str.codeUnitAt(start);
    }
    if (firstChar == _I) {
      if (end == start + 8 && str.startsWith("nfinity", start + 1)) {
        return sign * double.infinity;
      }
      return null;
    }
    if (firstChar == _N) {
      if (end == start + 3 &&
          str.codeUnitAt(start + 1) == _a &&
          str.codeUnitAt(start + 2) == _N) {
        return double.nan;
      }
      return null;
    }

    int firstDigit = firstChar ^ _ZERO;
    if (firstDigit <= 9) {
      start++;
      doubleValue = firstDigit.toDouble();
      digitsSeen = true;
    }
    for (int i = start; i < end; i++) {
      int c = str.codeUnitAt(i);
      int digit = c ^ _ZERO; // '0'-'9' characters are now 0-9 integers.
      if (digit <= 9) {
        doubleValue = 10.0 * doubleValue + digit;
        // Doubles at or above this value (2**53) might have lost precision.
        const double MAX_EXACT_DOUBLE = 9007199254740992.0;
        if (doubleValue >= MAX_EXACT_DOUBLE) return null;
        exponent += exponentDelta;
        digitsSeen = true;
      } else if (c == _DOT && exponentDelta == 0) {
        exponentDelta = -1;
      } else if ((c | 0x20) == _e) {
        i++;
        if (i == end) return null;
        // int._tryParseSmi treats its end argument as inclusive.
        final int? expPart = int._tryParseSmi(str, i, end - 1);
        if (expPart == null) return null;
        exponent += expPart;
        break;
      } else {
        return null;
      }
    }
    if (!digitsSeen) return null; // No digits.
    if (exponent == 0) return sign * doubleValue;
    const P10 = POWERS_OF_TEN; // From shared library
    if (exponent < 0) {
      int negExponent = -exponent;
      if (negExponent >= P10.length) return null;
      return sign * (doubleValue / P10[negExponent]);
    }
    if (exponent >= P10.length) return null;
    return sign * (doubleValue * P10[exponent]);
  }

  static double? _parse(String str) {
    int len = str.length;
    final strbase = str as _StringBase;
    int start = strbase._firstNonWhitespace();
    if (start == len) return null; // All whitespace.
    int end = strbase._lastNonWhitespace() + 1;
    assert(start < end);
    var result = _tryParseDouble(str, start, end);
    if (result != null) return result;
    return _nativeParse(str, start, end);
  }

  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    var result = _parse(source);
    if (result == null) {
      if (onError == null) throw new FormatException("Invalid double", source);
      return onError(source);
    }
    return result;
  }

  @patch
  static double? tryParse(String source) => _parse(source);
}
