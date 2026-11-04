// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordCharacterClass', () {
    test('toString', () {
      expect(PasswordCharacterClass.upper.toString(), 'PasswordCharacterClass.upper');
      expect(
        PasswordCharacterClass.asciiPrintable.toString(),
        'PasswordCharacterClass.asciiPrintable',
      );
      expect(
        const PasswordCharacterClass.custom('-_').toString(),
        "PasswordCharacterClass.custom('-_')",
      );
    });

    test('characters is null for predefined classes', () {
      expect(PasswordCharacterClass.digit.characters, isNull);
      expect(const PasswordCharacterClass.custom('-_').characters, '-_');
    });

    test('const custom classes are identical', () {
      expect(
        identical(
          const PasswordCharacterClass.custom('-_'),
          const PasswordCharacterClass.custom('-_'),
        ),
        isTrue,
      );
    });

    test('custom asserts that characters is not empty', () {
      expect(() => PasswordCharacterClass.custom(''), throwsAssertionError);
    });
  });

  group('PasswordRules', () {
    test('toJson omits empty and null values', () {
      expect(const PasswordRules().toJson(), isEmpty);
    });

    test('toJson includes all rules', () {
      const rules = PasswordRules(
        required: <Set<PasswordCharacterClass>>[
          <PasswordCharacterClass>{PasswordCharacterClass.upper, PasswordCharacterClass.lower},
          <PasswordCharacterClass>{PasswordCharacterClass.digit},
        ],
        allowed: <PasswordCharacterClass>{
          PasswordCharacterClass.special,
          PasswordCharacterClass.asciiPrintable,
          PasswordCharacterClass.unicode,
          PasswordCharacterClass.custom('-_'),
        },
        minLength: 8,
        maxLength: 64,
        maxConsecutive: 2,
      );

      expect(rules.toJson(), <String, Object>{
        'required': <List<Object>>[
          <Object>['upper', 'lower'],
          <Object>['digit'],
        ],
        'allowed': <Object>[
          'special',
          'asciiPrintable',
          'unicode',
          <String, String>{'custom': '-_'},
        ],
        'minLength': 8,
        'maxLength': 64,
        'maxConsecutive': 2,
      });
    });

    test('equality and hashCode', () {
      PasswordRules rulesWith(
        PasswordCharacterClass first,
        PasswordCharacterClass second,
        PasswordCharacterClass allowed,
      ) {
        return PasswordRules(
          required: <Set<PasswordCharacterClass>>[
            <PasswordCharacterClass>{first, second},
          ],
          allowed: <PasswordCharacterClass>{allowed},
          minLength: 12,
        );
      }

      final PasswordRules rules1 = rulesWith(
        PasswordCharacterClass.upper,
        PasswordCharacterClass.digit,
        PasswordCharacterClass.lower,
      );
      final PasswordRules rules2 = rulesWith(
        PasswordCharacterClass.digit,
        PasswordCharacterClass.upper,
        PasswordCharacterClass.lower,
      );

      expect(identical(rules1, rules2), isFalse);
      expect(rules1, rules2);
      expect(rules1.hashCode, rules2.hashCode);

      expect(rules1, isNot(const PasswordRules(minLength: 12)));
      expect(
        rules1,
        isNot(
          const PasswordRules(
            required: <Set<PasswordCharacterClass>>[
              <PasswordCharacterClass>{PasswordCharacterClass.upper},
              <PasswordCharacterClass>{PasswordCharacterClass.digit},
            ],
            allowed: <PasswordCharacterClass>{PasswordCharacterClass.lower},
            minLength: 12,
          ),
        ),
      );
      expect(const PasswordRules(maxLength: 12), isNot(const PasswordRules(maxConsecutive: 12)));
    });

    test('toString', () {
      expect(const PasswordRules().toString(), 'PasswordRules()');
      expect(
        const PasswordRules(
          required: <Set<PasswordCharacterClass>>[
            <PasswordCharacterClass>{PasswordCharacterClass.upper},
          ],
          allowed: <PasswordCharacterClass>{PasswordCharacterClass.custom('-_')},
          minLength: 8,
          maxLength: 64,
          maxConsecutive: 2,
        ).toString(),
        'PasswordRules('
        'required: [{PasswordCharacterClass.upper}], '
        "allowed: {PasswordCharacterClass.custom('-_')}, "
        'minLength: 8, maxLength: 64, maxConsecutive: 2)',
      );
    });

    test('asserts on invalid lengths', () {
      expect(() => PasswordRules(minLength: 0), throwsAssertionError);
      expect(() => PasswordRules(maxLength: 0), throwsAssertionError);
      expect(() => PasswordRules(minLength: 13, maxLength: 12), throwsAssertionError);
      expect(() => PasswordRules(maxConsecutive: 0), throwsAssertionError);
      expect(() => const PasswordRules(minLength: 12, maxLength: 12), returnsNormally);
    });
  });
}
