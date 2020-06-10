// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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

  test('FilteringTextInputFormatter should return the old value if new value contains non-white-listed character', () {
    const TextEditingValue oldValue = TextEditingValue(text: '12345');
    const TextEditingValue newValue = TextEditingValue(text: '12345@');

    final TextInputFormatter formatter = FilteringTextInputFormatter.digitsOnly;
    final TextEditingValue formatted = formatter.formatEditUpdate(oldValue, newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('12345'));
    // The new value is always the oldValue plus a non-digit character (user press @)
    expect(newValue.text, equals('12345@'));
    // we expect that the formatted value returns the oldValue only since the newValue does not
    // satisfy the formatter condition (which is, in this case, digitsOnly)
    expect(formatted.text, equals('12345'));
  });

  test('FilteringTextInputFormatter should move the cursor to the right position', () {
    TextEditingValue collapsedValue(String text, int offset) =>
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        );

    TextEditingValue oldValue = collapsedValue('123', 0);
    TextEditingValue newValue = collapsedValue('123456', 6);

    final TextInputFormatter formatter = FilteringTextInputFormatter.digitsOnly;
    TextEditingValue formatted = formatter.formatEditUpdate(oldValue, newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('123'));
    // assert that we are passing digits only at the second time
    expect(newValue.text, equals('123456'));
    // assert that cursor is at the end of the text
    expect(formatted.selection.baseOffset, equals(6));

    // move cursor at the middle of the text and then add the number 9.
    oldValue = newValue.copyWith(selection: const TextSelection.collapsed(offset: 4));
    newValue = oldValue.copyWith(text: '1239456');

    formatted = formatter.formatEditUpdate(oldValue, newValue);

    // cursor must be now at fourth position (right after the number 9)
    expect(formatted.selection.baseOffset, equals(4));
  });

  test('FilteringTextInputFormatter should remove non-allowed characters', () {
    const TextEditingValue oldValue = TextEditingValue(text: '12345');
    const TextEditingValue newValue = TextEditingValue(text: '12345@');

    final TextInputFormatter formatter = FilteringTextInputFormatter.digitsOnly;
    final TextEditingValue formatted = formatter.formatEditUpdate(oldValue, newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('12345'));
    // The new value is always the oldValue plus a non-digit character (user press @)
    expect(newValue.text, equals('12345@'));
    // we expect that the formatted value returns the oldValue only since the difference
    // between the oldValue and the newValue is only material that isn't allowed
    expect(formatted.text, equals('12345'));
  });

  test('WhitelistingTextInputFormatter should return the old value if new value contains non-allowed character', () {
    const TextEditingValue oldValue = TextEditingValue(text: '12345');
    const TextEditingValue newValue = TextEditingValue(text: '12345@');

    final WhitelistingTextInputFormatter formatter = WhitelistingTextInputFormatter.digitsOnly;
    final TextEditingValue formatted = formatter.formatEditUpdate(oldValue, newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('12345'));
    // The new value is always the oldValue plus a non-digit character (user press @)
    expect(newValue.text, equals('12345@'));
    // we expect that the formatted value returns the oldValue only since the newValue does not
    // satisfy the formatter condition (which is, in this case, digitsOnly)
    expect(formatted.text, equals('12345'));
  });

  test('FilteringTextInputFormatter should move the cursor to the right position', () {
    TextEditingValue collapsedValue(String text, int offset) =>
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        );

    TextEditingValue oldValue = collapsedValue('123', 0);
    TextEditingValue newValue = collapsedValue('123456', 6);

    final TextInputFormatter formatter =
        FilteringTextInputFormatter.digitsOnly;
    TextEditingValue formatted = formatter.formatEditUpdate(oldValue,
        newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('123'));
    // assert that we are passing digits only at the second time
    expect(newValue.text, equals('123456'));
    // assert that cursor is at the end of the text
    expect(formatted.selection.baseOffset, equals(6));

    // move cursor at the middle of the text and then add the number 9.
    oldValue = newValue.copyWith(
        selection: const TextSelection.collapsed(offset: 4));
    newValue = oldValue.copyWith(text: '1239456');

    formatted = formatter.formatEditUpdate(oldValue, newValue);

    // cursor must be now at fourth position (right after the number 9)
    expect(formatted.selection.baseOffset, equals(4));
  });

  test('WhitelistingTextInputFormatter should move the cursor to the right position', () {
    TextEditingValue collapsedValue(String text, int offset) =>
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        );

    TextEditingValue oldValue = collapsedValue('123', 0);
    TextEditingValue newValue = collapsedValue('123456', 6);

    final WhitelistingTextInputFormatter formatter =
        WhitelistingTextInputFormatter.digitsOnly;
    TextEditingValue formatted = formatter.formatEditUpdate(oldValue,
        newValue);

    // assert that we are passing digits only at the first time
    expect(oldValue.text, equals('123'));
    // assert that we are passing digits only at the second time
    expect(newValue.text, equals('123456'));
    // assert that cursor is at the end of the text
    expect(formatted.selection.baseOffset, equals(6));

    // move cursor at the middle of the text and then add the number 9.
    oldValue = newValue.copyWith(
        selection: const TextSelection.collapsed(offset: 4));
    newValue = oldValue.copyWith(text: '1239456');

    formatted = formatter.formatEditUpdate(oldValue, newValue);

    // cursor must be now at fourth position (right after the number 9)
    expect(formatted.selection.baseOffset, equals(4));
  });
}
