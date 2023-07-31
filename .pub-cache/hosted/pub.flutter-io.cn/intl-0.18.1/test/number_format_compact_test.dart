/// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

/// Tests for compact format numbers, e.g. 1.2M rather than 1,200,000
import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart' as patterns;
import 'package:test/test.dart';

import 'compact_number_test_data.dart' as testdata;
import 'more_compact_number_test_data.dart' as more_testdata;

/// A place to put a case that's causing a problem and have it run first when
/// debugging
Map<String, List<List<String>>> interestingCases = <String, List<List<String>>>{
//  'mn' : [['4321', '4.32M', 'whatever']]
};

Map<String, List<List<String>>> compactWithExplicitSign =
    <String, List<List<String>>>{
  'en_US': [
    ['0', '+0', '+0'],
    ['0.012', '+0.012', '+0.012'],
    ['0.123', '+0.123', '+0.123'],
    ['1.234', '+1.23', '+1.23'],
    ['12', '+12', '+12'],
    ['12.34', '+12.3', '+12.3'],
    ['123.4', '+123', '+123'],
    ['123.41', '+123', '+123'],
    ['1234.1', '+1.23K', '+1.23 thousand'],
    ['12341', '+12.3K', '+12.3 thousand'],
    ['123412', '+123K', '+123 thousand'],
    ['1234123', '+1.23M', '+1.23 million'],
    ['12341234', '+12.3M', '+12.3 million'],
    ['123412341', '+123M', '+123 million'],
    ['1234123412', '+1.23B', '+1.23 billion'],
    ['-0.012', '-0.012', '-0.012'],
    ['-0.123', '-0.123', '-0.123'],
    ['-1.234', '-1.23', '-1.23'],
    ['-12', '-12', '-12'],
    ['-12.34', '-12.3', '-12.3'],
    ['-123.4', '-123', '-123'],
    ['-123.41', '-123', '-123'],
    ['-1234.1', '-1.23K', '-1.23 thousand'],
    ['-12341', '-12.3K', '-12.3 thousand'],
    ['-123412', '-123K', '-123 thousand'],
    ['-1234123', '-1.23M', '-1.23 million'],
    ['-12341234', '-12.3M', '-12.3 million'],
    ['-123412341', '-123M', '-123 million'],
    ['-1234123412', '-1.23B', '-1.23 billion'],
  ],
  'sw': [
    ['12', '+12', '+12'],
    ['12341', 'elfu\u00A0+12.3', 'elfu +12.3'],
    ['-12', '-12', '-12'],
    ['-12341', 'elfu\u00A0-12.3', 'elfu -12.3'],
  ],
  'he': [
    ['12', '\u200e+12', '\u200e+12'],
    ['12341', '\u200e+12.3K\u200f', '\u200e+\u200f12.3 אלף'],
    ['-12', '\u200e-12', '\u200e-12'],
    ['-12341', '\u200e-12.3K\u200f', '\u200e-\u200f12.3 אלף'],
  ],
};

Map<String, List<List<String>>> parsingTestCases = <String, List<List<String>>>{
  'en_US': [
    ['1230', '1.23 K', '1.23  thousand'], // Random spaces.
    ['1230', '1.23\u00a0K', '1.23\u00a0thousand'], // NO-BREAK SPACE.
    ['1230', '1.23\u202fK', '1.23\u202fthousand'], // NARROW NO-BREAK SPACE.
  ],
  'fi': [
    ['4320', '4,32t.', '4,32tuhatta'], // Actual format uses NO-BREAK SPACE.
    ['-4320', '-4,32t.', '-4,32tuhatta'], // Actual format uses MINUS SIGN.
    ['-4320', '\u22124,32t.', '\u22124,32tuhatta'], // Like actual format.
  ],
  'he': [
    ['-12300', '-12.3 K', '-12.3\u05D0\u05DC\u05E3'], // LTR/RTL marks dropped.
  ],
  'fa': [
    [
      '123',
      // With locale numerals.
      '\u06F1\u06F2\u06F3',
      '\u06F1\u06F2\u06F3'
    ],
    [
      '4320',
      // With locale numerals.
      '\u06F4\u066B\u06F3\u06F2 \u0647\u0632\u0627\u0631',
      '\u06F4\u066B\u06F3\u06F2 \u0647\u0632\u0627\u0631'
    ],
    ['123', '123', '123'], // With roman numerals.
    [
      '4320',
      // With roman numerals.
      '4.32 \u0647\u0632\u0627\u0631',
      '4.32 \u0647\u0632\u0627\u0631'
    ],
  ]
};

void main() {
  interestingCases.forEach(_validate);
  testdata.compactNumberTestData.forEach(_validate);
  // Once code and data is updated to CLDR35:
  more_testdata.cldr35CompactNumTests.forEach(_validateFancy);

  compactWithExplicitSign.forEach(_validateWithExplicitSign);
  parsingTestCases.forEach(_validateParsing);

  test('Patterns are consistent across locales', () {
    void checkPatterns(Map<int, Map<String, String>> patterns) {
      expect(patterns, isNotEmpty);
      // Check patterns are iterable in order.
      var lastExp = -1;
      for (var entries in patterns.entries) {
        var exp = entries.key;
        expect(exp, isPositive);
        expect(exp, greaterThan(lastExp));
        lastExp = exp;
        var patternMap = entries.value;
        expect(patternMap, isNotEmpty);
      }
    }

    patterns.compactNumberSymbols.forEach((locale, patterns) {
      checkPatterns(patterns.COMPACT_DECIMAL_SHORT_PATTERN);
      if (patterns.COMPACT_DECIMAL_LONG_PATTERN != null) {
        checkPatterns(patterns.COMPACT_DECIMAL_LONG_PATTERN!);
      }
      checkPatterns(patterns.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN);
    });
  });

  // ICU doesn't support compact currencies yet, so we don't have a way to
  // generate automatic data for comparison. Hard-coded a couple of cases as a
  // smoke test. JPY is a useful test because it has no decimalDigits and
  // different grouping than USD, as well as a different currency symbol and
  // suffixes.
  testCurrency('ja', 1.2345, '¥1', '¥1');
  testCurrency('ja', 1, '¥1', '¥1');
  testCurrency('ja', 12, '¥12', '¥12');
  testCurrency('ja', 123, '¥123', '¥123');
  testCurrency('ja', 1234, '¥1234', '¥1234');
  testCurrency('ja', 12345, '¥1.23\u4E07', '¥1\u4E07');
  testCurrency('ja', 123456, '¥12.3\u4E07', '¥12\u4E07');
  testCurrency('ja', 1234567, '¥123\u4e07', '¥123\u4e07');
  testCurrency('ja', 12345678, '¥1235\u4e07', '¥1235\u4e07');
  testCurrency('ja', 123456789, '¥1.23\u5104', '¥1\u5104');

  testCurrency('ja', 0.9876, '¥1', '¥1');
  testCurrency('ja', 9, '¥9', '¥9');
  testCurrency('ja', 98, '¥98', '¥98');
  testCurrency('ja', 987, '¥987', '¥987');
  testCurrency('ja', 9876, '¥9876', '¥9876');
  testCurrency('ja', 98765, '¥9.88\u4E07', '¥10\u4E07');
  testCurrency('ja', 987656, '¥98.8\u4E07', '¥99\u4E07');
  testCurrency('ja', 9876567, '¥988\u4e07', '¥988\u4e07');
  testCurrency('ja', 98765678, '¥9877\u4e07', '¥9877\u4e07');
  testCurrency('ja', 987656789, '¥9.88\u5104', '¥10\u5104');

  testCurrency('en_US', 0.1234, r'$0.12', r'$0.12');
  testCurrency('en_US', 1, r'$1.00', r'$1');
  testCurrency('en_US', 1.2345, r'$1.23', r'$1');
  testCurrency('en_US', 12, r'$12.00', r'$12');
  testCurrency('en_US', 12.3, r'$12.30', r'$12');
  testCurrency('en_US', 99, r'$99.00', r'$99');
  testCurrency('en_US', 99.9, r'$99.90', r'$100');
  testCurrency('en_US', 99.99, r'$99.99', r'$100');
  testCurrency('en_US', 99.999, r'$100', r'$100');
  testCurrency('en_US', 100, r'$100', r'$100');
  testCurrency('en_US', 100.001, r'$100', r'$100');
  testCurrency('en_US', 100.01, r'$100', r'$100');
  testCurrency('en_US', 100.1, r'$100', r'$100');
  testCurrency('en_US', 100.9, r'$101', r'$101');
  testCurrency('en_US', 100.99, r'$101', r'$101');
  testCurrency('en_US', 123, r'$123', r'$123');
  testCurrency('en_US', 999, r'$999', r'$999');
  testCurrency('en_US', 999.9, r'$1K', r'$1K');
  testCurrency('en_US', 999.99, r'$1K', r'$1K');
  testCurrency('en_US', 1000, r'$1K', r'$1K');
  testCurrency('en_US', 1000.01, r'$1K', r'$1K');
  testCurrency('en_US', 1000.1, r'$1K', r'$1K');
  testCurrency('en_US', 1001, r'$1K', r'$1K');
  testCurrency('en_US', 1234, r'$1.23K', r'$1K');
  testCurrency('en_US', 12345, r'$12.3K', r'$12K');
  testCurrency('en_US', 123456, r'$123K', r'$123K');
  testCurrency('en_US', 1234567, r'$1.23M', r'$1M');

  testCurrency('en_US', -1, r'-$1.00', r'-$1');
  testCurrency('en_US', -12.3, r'-$12.30', r'-$12');
  testCurrency('en_US', -999, r'-$999', r'-$999');
  testCurrency('en_US', -1234, r'-$1.23K', r'-$1K');

  // Check for order of currency symbol when currency is a suffix.
  testCurrency(
    'ru',
    4420,
    '4,42\u00A0тыс.\u00A0\u20BD',
    '4\u00A0тыс.\u00A0\u20BD',
  );

  // Check for sign location when multiple patterns.
  testCurrency('sw', 12341, 'TSh\u00A0elfu12.3', 'TSh\u00A0elfu12');
  testCurrency('sw', -12341, 'TShelfu\u00A0-12.3', 'TShelfu\u00A0-12');

  // Locales which don't have a suffix for thousands.
  testCurrency('it', 442, '442\u00A0€', '442\u00A0€');
  testCurrency('it', 4420, '4420\u00A0\$', '4420\u00A0\$', currency: 'CAD');
  testCurrency('it', 4420000, '4,42\u00A0Mio\u00A0\$', '4\u00A0Mio\u00A0\$',
      currency: 'USD');

  testCurrency('he', 335, '\u200F335\u00A0\u200F₪', '\u200F335\u00A0\u200F₪');
  testCurrency(
      'he', -335, '\u200F-335\u00A0\u200F₪', '\u200F-335\u00A0\u200F₪');
  testCurrency('he', 12341, '₪12.3K\u200f', '₪12K\u200f');
  testCurrency('he', -12341, '\u200e-₪12.3K\u200f', '\u200e-₪12K\u200f');

  group('Currency with minimumFractionDigits + significant digits', () {
    var expectedBase = <double, String>{
      0.001: r'$0.00',
      0.009: r'$0.01',
      0.01: r'$0.01',
      0.09: r'$0.09',
      0.1: r'$0.10',
      0.9: r'$0.90',
      1: r'$1.00',
      1.1: r'$1.10',
      1.9: r'$1.90',
      1.999: r'$2.00',
      10: r'$10.00',
      100: r'$100',
      999: r'$999',
      999.1: r'$999',
      999.9: r'$1K',
      1001: r'$1K',
      1009: r'$1.01K',
      1234.56: r'$1.23K',
    };
    for (var entry in expectedBase.entries) {
      test('en_US - minimumFractionDigits: not set - ${entry.key}', () {
        var f = NumberFormat.compactSimpleCurrency(locale: 'en_US', name: 'USD')
          ..significantDigitsInUse = true;
        expect(f.format(entry.key), entry.value);
      });
    }

    var expected0 = <double, String>{
      0.001: r'$0',
      0.009: r'$0.01',
      0.01: r'$0.01',
      0.09: r'$0.09',
      0.1: r'$0.1',
      0.9: r'$0.9',
      1: r'$1',
      1.1: r'$1.1',
      1.9: r'$1.9',
      1.999: r'$2',
      10: r'$10',
      100: r'$100',
      999: r'$999',
      999.1: r'$999',
      999.9: r'$1K',
      1001: r'$1K',
      1009: r'$1.01K',
      1234.56: r'$1.23K',
    };
    for (var entry in expected0.entries) {
      test('en_US - minimumFractionDigits: 0 - ${entry.key}', () {
        var f = NumberFormat.compactSimpleCurrency(locale: 'en_US', name: 'USD')
          ..minimumFractionDigits = 0
          ..significantDigitsInUse = true;
        expect(f.format(entry.key), entry.value);
      });
    }

    var expected1 = <double, String>{
      0.001: r'$0.0',
      0.009: r'$0.01',
      0.01: r'$0.01',
      0.09: r'$0.09',
      0.1: r'$0.1',
      0.9: r'$0.9',
      1: r'$1.0',
      1.1: r'$1.1',
      1.9: r'$1.9',
      10: r'$10.0',
      100: r'$100.0',
      1.999: r'$2.0',
      999: r'$999.0',
      999.1: r'$999.1',
      999.9: r'$1.0K',
      1001: r'$1.0K',
      1009: r'$1.01K',
      1234.56: r'$1.23K',
    };
    for (var entry in expected1.entries) {
      test('en_US - minimumFractionDigits: 1 - ${entry.key}', () {
        var f = NumberFormat.compactSimpleCurrency(locale: 'en_US', name: 'USD')
          ..minimumFractionDigits = 1
          ..significantDigitsInUse = true;
        expect(f.format(entry.key), entry.value);
      });
    }
  });

  test('Explicit non-default symbol with compactCurrency', () {
    var format = NumberFormat.compactCurrency(locale: 'ja', symbol: '()');
    var result = format.format(98765);
    expect(result, '()9.88\u4e07');
  });
}

/// Tests for [NumberFormat.compactSimpleCurrency] and
/// [Numberformat.compactCurrency]. For `compactCurrency`, it also passes the
/// `symbol` parameter after which the result is expected to be the same as for
/// `compactSimpleCurrency`. The `expectedShort` string is compared to the
/// output of the formatters with significantDigits set to `1`.
void testCurrency(
    String locale, num number, String expected, String expectedShort,
    {String? currency, String? reason}) {
  test('Compact simple currency for $locale, $number', () {
    var format =
        NumberFormat.compactSimpleCurrency(locale: locale, name: currency);
    var result = format.format(number);
    expect(result, expected, reason: '$reason');
    var shortFormat =
        NumberFormat.compactSimpleCurrency(locale: locale, name: currency);
    shortFormat.significantDigits = 1;
    var shortResult = shortFormat.format(number);
    expect(shortResult, expectedShort, reason: 'shortFormat: $reason');
  });
  test('Compact currency for $locale, $number', () {
    var symbols = {
      'ja': '¥',
      'en_US': r'$',
      'ru': '\u20BD',
      'it': '€',
      'he': '₪',
      'sw': 'TSh',
      'CAD': r'$',
      'USD': r'$'
    };
    var symbol = symbols[currency] ?? symbols[locale];
    var format = NumberFormat.compactCurrency(
        locale: locale, name: currency, symbol: symbol);
    var result = format.format(number);
    expect(result, expected, reason: '$reason');
    var shortFormat = NumberFormat.compactCurrency(
        locale: locale, name: currency, symbol: symbol);
    shortFormat.significantDigits = 1;
    var shortResult = shortFormat.format(number);
    expect(shortResult, expectedShort, reason: 'shortFormat: $reason');
  });
}

/// Locales that have problems in the short format.
// TODO(alanknight): Don't just skip the whole locale if there's one problem
// case.
var _skipLocalsShort = <String>{
  'bn', // Bug in CLDR: ambiguous parsing: 10^9 ("000 কো") and 10^11 ("000কো") only differ by a nbsp.
};

/// Locales that have problems in the long format.
var _skipLocalesLong = <String>{
  // None ;o)
};

void _validate(String locale, List<List<String>> expected) {
  _validateShort(locale, expected);
  _validateLong(locale, expected);
}

/// Check each bit of test data against the short compact format, both
/// formatting and parsing.
void _validateShort(String locale, List<List<String>> expected) {
  var skip = _skipLocalsShort.contains(locale)
      ? "Skipping problem locale '$locale' for SHORT compact number tests"
      : false;
  var shortFormat = NumberFormat.compact(locale: locale)
    ..significantDigits = 2; // Default in ICU.
  test('Validate $locale SHORT', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      _validateNumber(number, shortFormat, data[1]);
      if (number == number.round()) {
        // Check against int64.
        var int64Number = Int64(number.round());
        _validateNumber(int64Number, shortFormat, data[1]);
      }
      // TODO(alanknight): Make this work for MicroMoney
    }
  }, skip: skip);
}

void _validateLong(String locale, List<List<String>> expected) {
  var skip = _skipLocalesLong.contains(locale)
      ? "Skipping problem locale '$locale' for LONG compact number tests"
      : false;
  var longFormat = NumberFormat.compactLong(locale: locale)
    ..significantDigits = 2; // Default in ICU.
  test('Validate $locale LONG', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      _validateNumber(number, longFormat, data[2]);
    }
  }, skip: skip);
}

void _validateNumber(dynamic number, NumberFormat format, String expected) {
  var numberDouble = number.toDouble();
  var formatted = format.format(number);

  expect('$formatted ${formatted.codeUnits}', '$expected ${expected.codeUnits}',
      reason: 'for number: $number');

  var parsed = format.parse(formatted);
  var almostEquals = (number == 0 && parsed.abs() < 0.01) ||
      ((parsed - numberDouble) / numberDouble).abs() < 0.1;
  expect(almostEquals, isTrue,
      reason: 'for number: $number (formatted: $formatted, parsed: $parsed)');
}

void _validateFancy(more_testdata.CompactRoundingTestCase t) {
  var shortFormat = NumberFormat.compact(locale: 'en')
    ..significantDigits = 2; // Default in ICU.
  if (t.maximumIntegerDigits != null) {
    shortFormat.maximumIntegerDigits = t.maximumIntegerDigits!;
  }

  if (t.minimumIntegerDigits != null) {
    shortFormat.minimumIntegerDigits = t.minimumIntegerDigits!;
  }

  if (t.maximumFractionDigits != null) {
    shortFormat.maximumFractionDigits = t.maximumFractionDigits!;
  }

  if (t.minimumFractionDigits != null) {
    shortFormat.minimumFractionDigits = t.minimumFractionDigits!;
  }

  if (t.minimumExponentDigits != null) {
    shortFormat.minimumExponentDigits = t.minimumExponentDigits!;
  }

  if (t.maximumSignificantDigits != null) {
    shortFormat.maximumSignificantDigits = t.maximumSignificantDigits;
  }

  if (t.minimumSignificantDigits != null) {
    shortFormat.minimumSignificantDigits = t.minimumSignificantDigits;
  }

  test(t.toString(), () {
    expect(shortFormat.format(t.number), t.expected);
  });
}

void _validateWithExplicitSign(String locale, List<List<String>> expected) {
  for (var data in expected) {
    final input = num.parse(data[0]);
    test('Validate compact with $locale and explicit sign for $input', () {
      final numberFormat =
          NumberFormat.compact(locale: locale, explicitSign: true);
      expect(numberFormat.format(input), data[1]);
    });
    test('Validate compactLong with $locale and explicit sign for $input', () {
      final numberFormat =
          NumberFormat.compactLong(locale: locale, explicitSign: true);
      expect(numberFormat.format(input), data[2]);
    });
  }
}

void _validateParsing(String locale, List<List<String>> expected) {
  for (var data in expected) {
    final expected = num.parse(data[0]);
    final inputShort = data[1];
    test('Validate compact parsing with $locale for $inputShort', () {
      final numberFormat = NumberFormat.compact(locale: locale);
      expect(numberFormat.parse(inputShort), expected);
    });
    final inputLong = data[2];
    test('Validate compactLong parsing with $locale for $inputLong', () {
      final numberFormat = NumberFormat.compactLong(locale: locale);
      expect(numberFormat.parse(inputLong), expected);
    });
  }
}
