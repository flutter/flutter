// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

void main() {
  group('Timeout.parse', () {
    group('for "none"', () {
      test('successfully parses', () {
        expect(Timeout.parse('none'), equals(Timeout.none));
      });

      test('rejects invalid input', () {
        expect(() => Timeout.parse(' none'), throwsFormatException);
        expect(() => Timeout.parse('none '), throwsFormatException);
        expect(() => Timeout.parse('xnone'), throwsFormatException);
        expect(() => Timeout.parse('nonex'), throwsFormatException);
        expect(() => Timeout.parse('noxe'), throwsFormatException);
      });
    });

    group('for a relative timeout', () {
      test('successfully parses', () {
        expect(Timeout.parse('1x'), equals(Timeout.factor(1)));
        expect(Timeout.parse('2.5x'), equals(Timeout.factor(2.5)));
        expect(Timeout.parse('1.2e3x'), equals(Timeout.factor(1.2e3)));
      });

      test('rejects invalid input', () {
        expect(() => Timeout.parse('.x'), throwsFormatException);
        expect(() => Timeout.parse('x'), throwsFormatException);
        expect(() => Timeout.parse('ax'), throwsFormatException);
        expect(() => Timeout.parse('1x '), throwsFormatException);
        expect(() => Timeout.parse('1x5m'), throwsFormatException);
      });
    });

    group('for an absolute timeout', () {
      test('successfully parses all supported units', () {
        expect(Timeout.parse('2d'), equals(Timeout(Duration(days: 2))));
        expect(Timeout.parse('2h'), equals(Timeout(Duration(hours: 2))));
        expect(Timeout.parse('2m'), equals(Timeout(Duration(minutes: 2))));
        expect(Timeout.parse('2s'), equals(Timeout(Duration(seconds: 2))));
        expect(
            Timeout.parse('2ms'), equals(Timeout(Duration(milliseconds: 2))));
        expect(
            Timeout.parse('2us'), equals(Timeout(Duration(microseconds: 2))));
      });

      test('supports non-integer units', () {
        expect(
            Timeout.parse('2.73d'), equals(Timeout(Duration(days: 1) * 2.73)));
      });

      test('supports multiple units', () {
        expect(
            Timeout.parse('1d 2h3m  4s5ms\t6us'),
            equals(Timeout(Duration(
                days: 1,
                hours: 2,
                minutes: 3,
                seconds: 4,
                milliseconds: 5,
                microseconds: 6))));
      });

      test('rejects invalid input', () {
        expect(() => Timeout.parse('.d'), throwsFormatException);
        expect(() => Timeout.parse('d'), throwsFormatException);
        expect(() => Timeout.parse('ad'), throwsFormatException);
        expect(() => Timeout.parse('1z'), throwsFormatException);
        expect(() => Timeout.parse('1u'), throwsFormatException);
        expect(() => Timeout.parse('1d5x'), throwsFormatException);
        expect(() => Timeout.parse('1d*5m'), throwsFormatException);
      });
    });
  });
}
