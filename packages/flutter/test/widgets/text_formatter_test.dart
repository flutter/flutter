// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';

void main() {
  TextEditingValue testOldValue;
  TextEditingValue testNewValue;

  test('withFunction wraps formatting function', () {
    testOldValue = new TextEditingValue();
    testNewValue = new TextEditingValue();

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
      testNewValue = new TextEditingValue(
        text: 'a1b2c3\nd4e5f6',
        selection: new TextSelection(
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
      expect(actualValue, new TextEditingValue(
        text: '123\n456',
        selection: new TextSelection(
          baseOffset: 1,
          extentOffset: 5,
        ),
      ));
    });
  });
}
