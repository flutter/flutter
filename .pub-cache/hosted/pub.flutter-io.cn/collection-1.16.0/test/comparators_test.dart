// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  var strings = [
    '',
    '\x00',
    ' ',
    '+',
    '/',
    '0',
    '00',
    '000',
    '001',
    '01',
    '011',
    '1',
    '100',
    '11',
    '110',
    '9',
    ':',
    '=',
    '@',
    'A',
    'A0',
    'A000A',
    'A001A',
    'A00A',
    'A01A',
    'A0A',
    'A1A',
    'AA',
    'AAB',
    'AB',
    'Z',
    '[',
    '_',
    '`',
    'a',
    'a0',
    'a000a',
    'a001a',
    'a00a',
    'a01a',
    'a0a',
    'a1a',
    'aa',
    'aab',
    'ab',
    'z',
    '{',
    '~'
  ];

  List<String> sortedBy(int Function(String, String)? compare) =>
      strings.toList()
        ..shuffle()
        ..sort(compare);

  test('String.compareTo', () {
    expect(sortedBy(null), strings);
  });

  test('compareAsciiLowerCase', () {
    expect(sortedBy(compareAsciiLowerCase), sortedBy((a, b) {
      var delta = a.toLowerCase().compareTo(b.toLowerCase());
      if (delta != 0) return delta;
      if (a == b) return 0;
      return a.compareTo(b);
    }));
  });

  test('compareAsciiUpperCase', () {
    expect(sortedBy(compareAsciiUpperCase), sortedBy((a, b) {
      var delta = a.toUpperCase().compareTo(b.toUpperCase());
      if (delta != 0) return delta;
      if (a == b) return 0;
      return a.compareTo(b);
    }));
  });

  // Replace any digit sequence by ("0", value, length) as char codes.
  // This will sort alphabetically (by charcode) the way digits sort
  // numerically, and the leading 0 means it sorts like a digit
  // compared to non-digits.
  String replaceNumbers(String string) =>
      string.replaceAllMapped(RegExp(r'\d+'), (m) {
        var digits = m[0]!;
        return String.fromCharCodes([0x30, int.parse(digits), digits.length]);
      });

  test('compareNatural', () {
    expect(sortedBy(compareNatural),
        sortedBy((a, b) => replaceNumbers(a).compareTo(replaceNumbers(b))));
  });

  test('compareAsciiLowerCaseNatural', () {
    expect(sortedBy(compareAsciiLowerCaseNatural), sortedBy((a, b) {
      var delta = replaceNumbers(a.toLowerCase())
          .compareTo(replaceNumbers(b.toLowerCase()));
      if (delta != 0) return delta;
      if (a == b) return 0;
      return a.compareTo(b);
    }));
  });

  test('compareAsciiUpperCaseNatural', () {
    expect(sortedBy(compareAsciiUpperCaseNatural), sortedBy((a, b) {
      var delta = replaceNumbers(a.toUpperCase())
          .compareTo(replaceNumbers(b.toUpperCase()));
      if (delta != 0) return delta;
      if (a == b) return 0;
      return a.compareTo(b);
    }));
  });
}
