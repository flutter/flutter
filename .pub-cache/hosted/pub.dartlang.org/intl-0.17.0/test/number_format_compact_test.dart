/// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

/// Tests for compact format numbers, e.g. 1.2M rather than 1,200,000
import 'dart:math';
import 'package:test/test.dart';
import 'package:intl/intl.dart';
import 'package:fixnum/fixnum.dart';
import 'package:intl/number_symbols_data.dart' as patterns;
import 'compact_number_test_data_33.dart' as testdata33;
// End-goal: to stop testing against testdata33 and use testdata35 instead:
// import 'compact_number_test_data.dart' as testdata35;
import 'more_compact_number_test_data.dart' as more_testdata;

/// A place to put a case that's causing a problem and have it run first when
/// debugging
var interestingCases = <String, List<List<String>>>{
//  'mn' : [['4321', '4.32M', 'whatever']]
};

void main() {
  interestingCases.forEach(validate);
  testdata33.compactNumberTestData.forEach(validate);
  more_testdata.oldIntlCompactNumTests.forEach(validateFancy);
  // Once code and data is updated to CLDR35:
  // testdata35.compactNumberTestData.forEach(validate);
  // more_testdata.cldr35CompactNumTests.forEach(validateFancy);

  test("Patterns are consistent across locales", () {
    patterns.compactNumberSymbols.forEach((locale, patterns) {
      expect(patterns.COMPACT_DECIMAL_SHORT_PATTERN.keys,
          orderedEquals([3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]),
          reason: "Precision algorithm expects no gaps in pattern magnitudes");
    });
  });

  // ICU doesn't support compact currencies yet, so we don't have a way to
  // generate automatic data for comparison. Hard-coded a couple of cases as a
  // smoke test. JPY is a useful test because it has no decimalDigits and
  // different grouping than USD, as well as a different currency symbol and
  // suffixes.
  testCurrency('ja', 1.2345, '¥1', '¥1');
  testCurrency('ja', 1, '¥1', '¥1');
  testCurrency('ja', 12, '¥12', '¥10');
  testCurrency('ja', 123, '¥123', '¥100');
  testCurrency('ja', 1234, '¥1230', '¥1000');
  testCurrency('ja', 12345, '¥1.23\u4E07', '¥1\u4E07');
  testCurrency('ja', 123456, '¥12.3\u4E07', '¥10\u4E07');
  testCurrency('ja', 1234567, '¥123\u4e07', '¥100\u4e07');
  testCurrency('ja', 12345678, '¥1230\u4e07', '¥1000\u4e07');
  testCurrency('ja', 123456789, '¥1.23\u5104', '¥1\u5104');

  testCurrency('ja', 0.9876, '¥1', '¥1');
  testCurrency('ja', 9, '¥9', '¥9');
  testCurrency('ja', 98, '¥98', '¥100');
  testCurrency('ja', 987, '¥987', '¥1000');
  testCurrency('ja', 9876, '¥9880', '¥1\u4E07');
  testCurrency('ja', 98765, '¥9.88\u4E07', '¥10\u4E07');
  testCurrency('ja', 987656, '¥98.8\u4E07', '¥100\u4E07');
  testCurrency('ja', 9876567, '¥988\u4e07', '¥1000\u4e07');
  testCurrency('ja', 98765678, '¥9880\u4e07', '¥1\u5104');
  testCurrency('ja', 987656789, '¥9.88\u5104', '¥10\u5104');

  testCurrency('en_US', 1.2345, r'$1.23', r'$1');
  testCurrency('en_US', 1, r'$1.00', r'$1');
  testCurrency('en_US', 12, r'$12.00', r'$10');
  testCurrency('en_US', 12.3, r'$12.30', r'$10');
  testCurrency('en_US', 123, r'$123', r'$100');
  testCurrency('en_US', 1000, r'$1K', r'$1K');
  testCurrency('en_US', 1234, r'$1.23K', r'$1K');
  testCurrency('en_US', 12345, r'$12.3K', r'$10K');
  testCurrency('en_US', 123456, r'$123K', r'$100K');
  testCurrency('en_US', 1234567, r'$1.23M', r'$1M');

  // Check for order of currency symbol when currency is a suffix.
  testCurrency('ru', 4420, '4,42\u00A0тыс.\u00A0руб.', '4\u00A0тыс.\u00A0руб.');

  // Locales which don't have a suffix for thousands.
  testCurrency('it', 442, '442\u00A0€', '400\u00A0€');
  testCurrency('it', 4420, '4420\u00A0\$', '4000\u00A0\$', currency: 'CAD');
  testCurrency('it', 4420000, '4,42\u00A0Mio\u00A0\$', '4\u00A0Mio\u00A0\$',
      currency: 'USD');

  testCurrency('he', 335, '\u200F335 ₪', '\u200F300 ₪',
      reason: 'TODO(b/36488375): Short format throws away significant digits '
          'without good reason.');

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
      'ru': 'руб.',
      'it': '€',
      'he': '₪',
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

// TODO(alanknight): Don't just skip the whole locale if there's one problem
// case.
// TODO(alanknight): Fix the problems, or at least figure out precisely where
// the differences are.
var problemLocalesShort = [
  'am', // AM Suffixes differ, not sure why.
  'ca', // For CA, CLDR rules are different. Jumps from 0000 to 00 prefix, so
  // 11 digits prints as 11900.
  'es_419', // Some odd formatting rules for these which seem to be different
  // from CLDR. wants e.g. '160000000000k' Actual: '160 B'
  'es_ES', // The reverse of es_419 for a few cases. We're printing a longer
  // form.
  'es_US', // Like es_419 but not as many of them. e.g. Expected: '87700k'
  // Actual: '87.7 M'
  'es_MX', // like es_419
  'es',
  'fa',
  'fr_CA', // Several where PyICU isn't compacting. Expected: '988000000'
  // Actual: '988 M'.
  'gsw', // Suffixes disagree
  'in', // IN not compacting 54321, looks similar to tr.
  'id', // ID not compacting 54321, looks similar to tr.
  'ka', // K Slight difference in the suffix
  'kk', 'mn', // We're picking the wrong pattern for 654321.
  'lo', 'mk', 'my',
  'pt_PT', // Seems to differ in appending mil or not after thousands. pt_BR
  // does it.
  'sd', // ICU considers this locale data questionable
  'th', // TH Expected abbreviations as '1.09 พ.ล.' rather than '1.09 พ'
  'tr', // TR Doesn't have a 0B format, goes directly to 00B, as a result 54321
  // just prints as 54321
  'ur', // UR Fails one with Expected: '15 ٹریلین'  Actual: '150 کھرب'
];

/// Locales that have problems in the long format.
///
/// These are mostly minor differences in the characters, and many I can't read,
/// but I'm suspicious many of them are essentially the difference between
/// million and millions, which we don't distinguish. That's definitely the case
/// with e.g. DE, but our data definitely has Millionen throughout.
///
//TODO(alanknight): Narrow these down to particular numbers. Often it's just
// 999999.
var problemLocalesLong = [
  'ar', 'ar_DZ', 'ar_EG',
  'be', 'bg', 'bs',
  'ca', 'cs', 'da', 'de', 'de_AT', 'de_CH', 'el', 'es', 'es_419', 'es_ES',
  'es_MX', 'es_US', 'et', 'fi',
  'fil', // FIL is different, seems like a genuine difference in suffixes
  'fr', 'fr_CA',
  'fr_CH', // TODO(alanknight): million/millions, supported since CLDR 31.
  'ga', 'gl',
  'gsw', // GSW seems like we have long forms and pyICU doesn't
  'hr', 'is', 'it',
  'it_CH', 'lo', // LO seems to be picking up a different pattern.
  'lt', 'lv', 'mk',
  'my', // Seems to come out in the reverse order
  'nb', 'ne', 'no', 'no_NO', 'pl',
  'pt', // PT has some issues with scale as well, but I think it's differences
  // in the patterns.
  'pt_BR', 'pt_PT', 'ro', 'ru',
  'sd', // ICU considers this locale data questionable
  'sk', 'sl', 'sr', 'sr_Latn', 'sv', 'te', 'tl',
  'ur',
  'uk',
];

void validate(String locale, List<List<String>> expected) {
  validateShort(locale, expected);
  validateLong(locale, expected);
}

/// Check each bit of test data against the short compact format, both
/// formatting and parsing.
void validateShort(String locale, List<List<String>> expected) {
  if (problemLocalesShort.contains(locale)) {
    print("Skipping problem locale '$locale' for SHORT compact number tests");
    return;
  }
  var shortFormat = NumberFormat.compact(locale: locale);
  test('Validate $locale SHORT', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      validateNumber(number, shortFormat, data[1]);
      var int64Number = Int64(number as int);
      validateNumber(int64Number, shortFormat, data[1]);
      // TODO(alanknight): Make this work for MicroMoney
    }
  });
}

void validateLong(String locale, List<List<String>> expected) {
  if (problemLocalesLong.contains(locale)) {
    print("Skipping problem locale '$locale' for LONG compact number tests");
    return;
  }
  var longFormat = NumberFormat.compactLong(locale: locale);
  test('Validate $locale LONG', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      validateNumber(number, longFormat, data[2]);
    }
  });
}

void validateNumber(number, NumberFormat format, String expected) {
  var formatted = format.format(number);
  var ok = closeEnough(formatted, expected);
  if (!ok) {
    expect(
        '$formatted ${formatted.codeUnits}', '$expected ${expected.codeUnits}');
  }
  var parsed = format.parse(formatted);
  var rounded = roundForPrinting(number, format);
  expect((parsed - rounded) / rounded < 0.001, isTrue);
}

/// Duplicate a bit of the logic in formatting, where if we have a
/// number that will round to print differently depending on the number
/// of significant digits, we need to check that as well, e.g.
/// 999999 may print as 1M.
num roundForPrinting(number, NumberFormat format) {
  var originalLength = NumberFormat.numberOfIntegerDigits(number);
  var additionalDigits = originalLength - format.significantDigits!;
  if (additionalDigits > 0) {
    var divisor = pow(10, additionalDigits);
    // If we have an Int64, value speed over precision and make it double.
    var rounded = (number.toDouble() / divisor).round() * divisor;
    return rounded;
  }
  return number.toDouble();
}

final _nbsp = 0xa0;
final _nbspString = String.fromCharCode(_nbsp);

/// Return true if the strings are close enough to what we
/// expected to consider a pass.
///
/// In particular, there seem to be minor differences between what PyICU is
/// currently producing and the CLDR data. So if the strings differ only in the
/// presence or absence of a period at the end or of a space between the number
/// and the suffix, consider it close enough and return true.
bool closeEnough(String result, String reference) {
  var expected = reference.replaceAll(' ', _nbspString);
  if (result == expected) {
    return true;
  }
  if ('$result.' == expected) {
    return true;
  }
  if (result == '$expected.') {
    return true;
  }
  if (_oneSpaceOnlyDifference(result, expected)) {
    return true;
  }
  return false;
}

/// Do the two strings differ only by a single space being
/// omitted in one of them.
///
/// We assume non-breaking spaces because we
/// know that's what the Intl data uses. We already know the strings aren't
/// equal because that's checked first in the only caller.
bool _oneSpaceOnlyDifference(String result, String expected) {
  var resultWithoutSpaces =
      String.fromCharCodes(result.codeUnits.where((x) => x != _nbsp));
  var expectedWithoutSpaces =
      String.fromCharCodes(expected.codeUnits.where((x) => x != _nbsp));
  var resultDifference = result.length - resultWithoutSpaces.length;
  var expectedDifference = expected.length - expectedWithoutSpaces.length;
  return resultWithoutSpaces == expectedWithoutSpaces &&
      resultDifference <= 1 &&
      expectedDifference <= 1;
}

void validateFancy(more_testdata.CompactRoundingTestCase t) {
  var shortFormat = NumberFormat.compact(locale: 'en');
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

  if (t.significantDigits != null) {
    shortFormat.significantDigits = t.significantDigits;
  }

  test(t.toString(), () {
    expect(shortFormat.format(t.number), t.expected);
  });
}
