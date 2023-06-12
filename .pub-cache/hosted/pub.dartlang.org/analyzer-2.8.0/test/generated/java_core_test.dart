// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_core.dart';
import 'package:test/test.dart';

main() {
  group('Character', () {
    group('isLetter', () {
      test('digits', () {
        expect(Character.isLetter('0'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('1'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('9'.codeUnitAt(0)), isFalse);
      });

      test('letters', () {
        expect(Character.isLetter('a'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('b'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('z'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('C'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('D'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('Y'.codeUnitAt(0)), isTrue);
      });

      test('other', () {
        expect(Character.isLetter(' '.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('.'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('-'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('+'.codeUnitAt(0)), isFalse);
      });
    });

    group('isLetterOrDigit', () {
      test('digits', () {
        expect(Character.isLetterOrDigit('0'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('1'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('9'.codeUnitAt(0)), isTrue);
      });

      test('letters', () {
        expect(Character.isLetterOrDigit('a'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('b'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('z'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('C'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('D'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('Y'.codeUnitAt(0)), isTrue);
      });

      test('other', () {
        expect(Character.isLetterOrDigit(' '.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('.'.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('-'.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('+'.codeUnitAt(0)), isFalse);
      });
    });
  });
}
