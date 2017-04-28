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
  });
}
