// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LengthLimitingTextInputFormatter', () {
    group('truncate', () {
      test('Removes characters from the end', () async {
        const TextEditingValue value = TextEditingValue(
          text: '01234567890',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        final TextEditingValue truncated = LengthLimitingTextInputFormatter
            .truncate(value, 10);
        expect(truncated.text, '0123456789');
      });
    });

    group('formatEditUpdate', () {
      const int maxLength = 10;

      test('Passes through when under limit', () async {
        const TextEditingValue oldValue = TextEditingValue(
          text: 'aaa',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        const TextEditingValue newValue = TextEditingValue(
          text: 'aaab',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        final LengthLimitingTextInputFormatter formatter =
            LengthLimitingTextInputFormatter(maxLength);
        final TextEditingValue formatted = formatter.formatEditUpdate(
          oldValue,
          newValue
        );
        expect(formatted.text, newValue.text);
      });

      test('Uses old value when at the limit', () async {
        const TextEditingValue oldValue = TextEditingValue(
          text: 'aaaaaaaaaa',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        const TextEditingValue newValue = TextEditingValue(
          text: 'aaaaabbbbbaaaaa',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        final LengthLimitingTextInputFormatter formatter =
            LengthLimitingTextInputFormatter(maxLength);
        final TextEditingValue formatted = formatter.formatEditUpdate(
          oldValue,
          newValue
        );
        expect(formatted.text, oldValue.text);
      });

      test('Truncates newValue when oldValue already over limit', () async {
        const TextEditingValue oldValue = TextEditingValue(
          text: 'aaaaaaaaaaaaaaaaaaaa',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        const TextEditingValue newValue = TextEditingValue(
          text: 'bbbbbbbbbbbbbbbbbbbb',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        );
        final LengthLimitingTextInputFormatter formatter =
            LengthLimitingTextInputFormatter(maxLength);
        final TextEditingValue formatted = formatter.formatEditUpdate(
          oldValue,
          newValue
        );
        expect(formatted.text, 'bbbbbbbbbb');
      });
    });
  });
}
