// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests case-ignoring compare and equality.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('equality ignore ASCII case', () {
    var strings = [
      '0@`aopz[{',
      '0@`aopz[{',
      '0@`Aopz[{',
      '0@`aOpz[{',
      '0@`AOpz[{',
      '0@`aoPz[{',
      '0@`AoPz[{',
      '0@`aOPz[{',
      '0@`AOPz[{',
      '0@`aopZ[{',
      '0@`AopZ[{',
      '0@`aOpZ[{',
      '0@`AOpZ[{',
      '0@`aoPZ[{',
      '0@`AoPZ[{',
      '0@`aOPZ[{',
      '0@`AOPZ[{',
    ];

    for (var s1 in strings) {
      for (var s2 in strings) {
        var reason = '$s1 =?= $s2';
        expect(equalsIgnoreAsciiCase(s1, s2), true, reason: reason);
        expect(hashIgnoreAsciiCase(s1), hashIgnoreAsciiCase(s2),
            reason: reason);
      }
    }

    var upperCaseLetters = '@`abcdefghijklmnopqrstuvwxyz[{åÅ';
    var lowerCaseLetters = '@`ABCDEFGHIJKLMNOPQRSTUVWXYZ[{åÅ';
    expect(equalsIgnoreAsciiCase(upperCaseLetters, lowerCaseLetters), true);

    void testChars(String char1, String char2, bool areEqual) {
      expect(equalsIgnoreAsciiCase(char1, char2), areEqual,
          reason: "$char1 ${areEqual ? "=" : "!"}= $char2");
    }

    for (var i = 0; i < upperCaseLetters.length; i++) {
      for (var j = 0; i < upperCaseLetters.length; i++) {
        testChars(upperCaseLetters[i], upperCaseLetters[j], i == j);
        testChars(lowerCaseLetters[i], upperCaseLetters[j], i == j);
        testChars(upperCaseLetters[i], lowerCaseLetters[j], i == j);
        testChars(lowerCaseLetters[i], lowerCaseLetters[j], i == j);
      }
    }
  });
}
