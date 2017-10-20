// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  TextEditingValue testOldValue;
  TextEditingValue testNewValue;

  test('withFunction wraps formatting function', () {
    testOldValue = const TextEditingValue();
    testNewValue = const TextEditingValue();

    TextEditingValue calledOldValue;
    TextEditingValue calledNewValue;

    final TextInputFormatter formatterUnderTest = TextInputFormatter.withFunction(
      (TextEditingValue oldValue, TextEditingValue newValue) {
        calledOldValue = oldValue;
        calledNewValue = newValue;
      }
    );

    formatterUnderTest.formatEditUpdate(testOldValue, testNewValue);

    expect(calledOldValue, equals(testOldValue));
    expect(calledNewValue, equals(testNewValue));
  });

  group('test provided formatters', () {
    setUp(() {
      // a1b(2c3
      // d4)e5f6
      // where the parentheses are the selection range.
      testNewValue = const TextEditingValue(
        text: 'a1b2c3\nd4e5f6',
        selection: const TextSelection(
          baseOffset: 3,
          extentOffset: 9,
        ),
      );
    });

    test('test blacklisting formatter', () {
      final TextEditingValue actualValue = 
          new BlacklistingTextInputFormatter(new RegExp(r'[a-z]'))
              .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // 1(23
      // 4)56
      expect(actualValue, const TextEditingValue(
        text: '123\n456',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 5,
        ),
      ));
    });

    test('test single line formatter', () {
      final TextEditingValue actualValue = 
          BlacklistingTextInputFormatter.singleLineFormatter
              .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // a1b(2c3d4)e5f6
      expect(actualValue, const TextEditingValue(
        text: 'a1b2c3d4e5f6',
        selection: const TextSelection(
          baseOffset: 3,
          extentOffset: 8,
        ),
      ));
    });

    test('test whitelisting formatter', () {
      final TextEditingValue actualValue = 
          new WhitelistingTextInputFormatter(new RegExp(r'[a-c]'))
              .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // ab(c)
      expect(actualValue, const TextEditingValue(
        text: 'abc',
        selection: const TextSelection(
          baseOffset: 2,
          extentOffset: 3,
        ),
      ));
    });

    test('test digits only formatter', () {
      final TextEditingValue actualValue = 
          WhitelistingTextInputFormatter.digitsOnly
              .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // 1(234)56
      expect(actualValue, const TextEditingValue(
        text: '123456',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 4,
        ),
      ));
    });

    test('test length limiting formatter', () {
      final TextEditingValue actualValue =
      new LengthLimitingTextInputFormatter(6)
          .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // a1b(2c3)
      expect(actualValue, const TextEditingValue(
        text: 'a1b2c3',
        selection: const TextSelection(
          baseOffset: 3,
          extentOffset: 6,
        ),
      ));
    });

    test('test length limiting formatter with zero-length string', () {
      testNewValue = const TextEditingValue(
        text: '',
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      );

      final TextEditingValue actualValue =
      new LengthLimitingTextInputFormatter(1)
        .formatEditUpdate(testOldValue, testNewValue);

      // Expecting the empty string.
      expect(actualValue, const TextEditingValue(
        text: '',
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ));
    });

    test('test length limiting formatter with non-ASCII runes', () {
      testNewValue = const TextEditingValue(
        text: '\u{1f984}\u{1f984}\u{1f984}\u{1f984}', // Unicode U+1f984 (UNICORN FACE)
        selection: const TextSelection(
          baseOffset: 4,
          extentOffset: 4,
        ),
      );

      final TextEditingValue actualValue =
      new LengthLimitingTextInputFormatter(2)
        .formatEditUpdate(testOldValue, testNewValue);

      // Expecting two runes.
      expect(actualValue, const TextEditingValue(
        text: '\u{1f984}\u{1f984}',
        selection: const TextSelection(
          baseOffset: 2,
          extentOffset: 2,
        ),
      ));
    });


    test('test length limiting formatter with complex Unicode characters', () {
      // TODO(gspencer): Test additional strings.  We can do this once the
      // formatter supports Unicode grapheme clusters.
      // The following should all be treated as single characters:
      //  - \u{0058}\u{0346}\u{0361}\u{035E}\u{032A}\u{031C}\u{0333}\u{0326}\u{031D}\u{0332}
      //  - \u{1F3F3}\u{FE0F}\u{200D}\u{1F308}
      testNewValue = const TextEditingValue(
        text: '\u{0000}\u{FEFF}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      );
      TextEditingValue actualValue = new LengthLimitingTextInputFormatter(1).formatEditUpdate(testOldValue, testNewValue);
      expect(actualValue, const TextEditingValue(
        text: '\u{0000}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      ));

      testNewValue = const TextEditingValue(
        text: '\u{1F984}\u{0020}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      );
      actualValue = new LengthLimitingTextInputFormatter(1).formatEditUpdate(testOldValue, testNewValue);
      expect(actualValue, const TextEditingValue(
        text: '\u{1F984}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      ));

      testNewValue = const TextEditingValue(
        text: '\u{0058}\u{0059}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      );
      actualValue = new LengthLimitingTextInputFormatter(1).formatEditUpdate(testOldValue, testNewValue);
      expect(actualValue, const TextEditingValue(
        text: '\u{0058}',
        selection: const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      ));
    });


    test('test length limiting formatter when selection is off the end', () {
      final TextEditingValue actualValue =
      new LengthLimitingTextInputFormatter(2)
          .formatEditUpdate(testOldValue, testNewValue);

      // Expecting
      // a1()
      expect(actualValue, const TextEditingValue(
        text: 'a1',
        selection: const TextSelection(
          baseOffset: 2,
          extentOffset: 2,
        ),
      ));
    });

  });
}
