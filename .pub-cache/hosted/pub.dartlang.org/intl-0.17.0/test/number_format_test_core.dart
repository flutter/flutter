/// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
/// for details. All rights reserved. Use of this source code is governed by a
/// BSD-style license that can be found in the LICENSE file.

library number_format_test;

import 'package:test/test.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:intl/intl.dart';
import 'number_test_data.dart';

/// Tests the Numeric formatting library in dart.
var testNumbersWeCanReadBack = {
  '-1': -1,
  '-2': -2.0,
  '-0.01': -0.01,
  '-1.23': -1.23,
  '0.001': 0.001,
  '0.01': 0.01,
  '0.1': 0.1,
  '1': 1,
  '2': 2.0,
  '10': 10,
  '100': 100,
  '1,000': 1000,
  '2,000,000,000,000': 2000000000000,
  '0.123': 0.123,
  '1,234': 1234.0,
  '1.234': 1.234,
  '1.23': 1.230,
  'NaN': 0.0 / 0.0,
  '∞': 1.0 / 0.0,
  '-∞': -1.0 / 0.0,
};

/// Test numbers that we can't parse because we lose precision in formatting.
var testNumbersWeCannotReadBack = {
  '3.142': 3.1415926535897932,
  '-1.234': -1.2342,
  '-1.235': -1.2348,
  '1.234': 1.2342,
  '1.235': 1.2348
};

var testExponential = const {'1E-3': 0.001, '1E-2': 0.01, '1.23E0': 1.23};

// TODO(alanknight): Test against currency, which requires generating data
// for the three different forms that this now supports.
// TODO(alanknight): Test against scientific, which requires significant
// digit support.
List<NumberFormat> standardFormats(String locale) {
  return [
    NumberFormat.decimalPattern(locale),
    NumberFormat.percentPattern(locale),
  ];
}

Map<String, num> get testNumbers =>
    Map.from(testNumbersWeCanReadBack)..addAll(testNumbersWeCannotReadBack);

void runTests(Map<String, num> allTestNumbers) {
  // For data from a list of locales, run each locale's data as a separate
  // test so we can see exactly which ones pass or fail. The test data is
  // hard-coded as printing 123, -12.3, %12,300, -1,230% in each locale.
  var mainList = numberTestData;
  var sortedLocales = List.from(numberFormatSymbols.keys);
  sortedLocales.sort((a, b) => a.compareTo(b));
  for (var locale in sortedLocales) {
    var testFormats = standardFormats(locale);
    var testLength = (testFormats.length * 3) + 1;
    var list = mainList.take(testLength).iterator;
    list.moveNext();
    if (locale == list.current) {
      mainList = mainList.skip(testLength).toList();
      testAgainstIcu(locale, testFormats, list);
    } else if (!numberFormatSymbols.containsKey(list.current)) {
      throw Exception(
          'Test locale ${list.current} is lacking in numberFormatSymbols.');
    } else {
      print('No unit tests found in numberTestData for locale $locale.');
    }
  }
  if (mainList[0] != 'END') {
    throw Exception(
        'Test locale ${mainList[0]} is lacking in numberFormatSymbols.');
  }

  test('Simple set of numbers', () {
    var number = NumberFormat();
    for (var x in allTestNumbers.keys) {
      var formatted = number.format(allTestNumbers[x]);
      expect(formatted, x);
      if (!testNumbersWeCannotReadBack.containsKey(x)) {
        var readBack = number.parse(formatted);
        // Even among ones we can read back, we can't test NaN for equality.
        if (allTestNumbers[x]!.isNaN) {
          expect(readBack.isNaN, isTrue);
        } else {
          expect(readBack, allTestNumbers[x]);
        }
      }
    }
  });

  test('Padding left', () {
    var expected = [
      '1',
      '1',
      '01',
      '001',
      '0,001',
      '00,001',
      '000,001',
      '0,000,001'
    ];
    for (var i = 0; i < 7; i++) {
      var f = NumberFormat.decimalPattern();
      f.minimumIntegerDigits = i;
      expect(f.format(1), expected[i], reason: 'minimumIntegerDigits: $i');
    }
  });

  test('maximumIntegerDigits does not do much', () {
    var expected = [
      '9,876,543,210',
      '9,876,543,210',
      '9,876,543,210',
      '9,876,543,210',
      '9,876,543,210',
      '9,876,543,210',
    ];
    for (var i = 0; i < expected.length; i++) {
      var f = NumberFormat.decimalPattern();
      f.maximumIntegerDigits = i;
      expect(f.format(9876543210), expected[i],
          reason: 'maximumIntegerDigits: $i');
    }
  });

  test('Padding right', () {
    var expected = [
      '1',
      '1.0',
      '1.00',
      '1.000',
      '1.0000',
      '1.00000',
      '1.000000',
    ];
    for (var i = 0; i < 6; i++) {
      var f = NumberFormat.decimalPattern();
      f.minimumFractionDigits = i;
      if (i > f.maximumFractionDigits) f.maximumFractionDigits = i;
      expect(f.format(1), expected[i],
          reason: 'minimumFractionDigits: $i, '
              'maximumFractionDigits: ${f.maximumFractionDigits}');
    }
  });

  test('Rounding/truncating fractions', () {
    var expected = [
      '9',
      '9.1',
      '9.12',
      '9.123',
      '9.1235',
      '9.12346',
      '9.123457',
      '9.1234568',
      '9.12345679',
      '9.123456789',
      '9.123456789',
      '9.123456789',
    ];
    for (var i = 0; i < expected.length; i++) {
      var f = NumberFormat.decimalPattern();
      f.maximumFractionDigits = i;
      expect(f.format(9.123456789), expected[i],
          reason: 'maximumFractionDigits: $i');
    }
  });

  test('Exponential form', () {
    var f = NumberFormat('#.###E0');
    for (var x in testExponential.keys) {
      var formatted = f.format(testExponential[x]);
      expect(formatted, x);
      var readBack = f.parse(formatted);
      expect(testExponential[x], readBack);
    }
  });

  test('Exponential form with minimumExponentDigits', () {
    var expected = [
      '3.21E3',
      '3.21E3',
      '3.21E03',
      '3.21E003',
    ];
    for (var i = 0; i < expected.length; i++) {
      var f = NumberFormat("#.###E0");
      f.minimumExponentDigits = i;
      expect(f.format(3210), expected[i], reason: 'minimumExponentDigits: $i');
    }
  });

  test('Significant Digits', () {
    var expected = [
      '00,000,000',
      '10,000,000',
      '9,900,000',
      '9,880,000',
      '9,877,000',
      '9,876,500',
      '9,876,540',
      '9,876,543',
      '9,876,543.2',
      '9,876,543.21',
      '9,876,543.21',
      '9,876,543.2101',
      '9,876,543.21012',
      '9,876,543.21012',
    ];
    for (var i = 0; i < expected.length; i++) {
      var f = NumberFormat.decimalPattern();
      f.significantDigits = i;
      expect(f.format(9876543.21012), expected[i],
          reason: 'significantDigits: $i');
    }
  });

  test('Percent with no decimals and no integer part', () {
    var number = NumberFormat('#%');
    var formatted = number.format(0.12);
    expect(formatted, '12%');
    var readBack = number.parse(formatted);
    expect(0.12, readBack);
  });

  // We can't do these in the normal tests because those also format the
  // numbers and we're reading them in a format where they won't print
  // back the same way.
  test('Parsing modifiers,e.g. percent, in the base format', () {
    var number = NumberFormat();
    var modified = {'12%': 0.12, '12\u2030': 0.012};
    modified.addAll(testExponential);
    for (var x in modified.keys) {
      var parsed = number.parse(x);
      expect(parsed, modified[x]);
    }
  });

  test('Explicit currency name', () {
    var amount = 1000000.32;
    var usConvention = NumberFormat.currency(locale: 'en_US', symbol: '€');
    var formatted = usConvention.format(amount);
    expect(formatted, '€1,000,000.32');
    var readBack = usConvention.parse(formatted);
    expect(readBack, amount);
    // ignore: deprecated_member_use_from_same_package
    var swissConvention = NumberFormat.currencyPattern('de_CH', r'$');
    formatted = swissConvention.format(amount);
    var nbsp = String.fromCharCode(0xa0);
    var backquote = String.fromCharCode(0x2019);
    //ignore: prefer_interpolation_to_compose_strings
    expect(
        formatted,
        //ignore: prefer_interpolation_to_compose_strings
        r'$' + nbsp + '1' + backquote + '000' + backquote + '000.32');
    readBack = swissConvention.parse(formatted);
    expect(readBack, amount);

    // ignore: deprecated_member_use_from_same_package
    var italianSwiss = NumberFormat.currencyPattern('it_CH', r'$');
    formatted = italianSwiss.format(amount);
    expect(
        formatted,
        //ignore: prefer_interpolation_to_compose_strings
        r'$' + nbsp + '1' + backquote + '000' + backquote + '000.32');
    readBack = italianSwiss.parse(formatted);
    expect(readBack, amount);

    /// Verify we can leave off the currency and it gets filled in.
    var plainSwiss = NumberFormat.currency(locale: 'de_CH');
    formatted = plainSwiss.format(amount);
    expect(
        formatted,
        //ignore: prefer_interpolation_to_compose_strings
        r'CHF' + nbsp + '1' + backquote + '000' + backquote + '000.32');
    readBack = plainSwiss.parse(formatted);
    expect(readBack, amount);

    // Verify that we can pass null in order to specify the currency symbol
    // but use the default locale.
    // ignore: deprecated_member_use_from_same_package
    var defaultLocale = NumberFormat.currencyPattern(null, 'Smurfs');
    formatted = defaultLocale.format(amount);
    // We don't know what the exact format will be, but it should have Smurfs.
    expect(formatted.contains('Smurfs'), isTrue);
    readBack = defaultLocale.parse(formatted);
    expect(readBack, amount);
  });

  test('Delta percent format', () {
    var f = NumberFormat('+#,##0%;-#,##0%');
    expect(f.format(-0.07), '-7%');
    expect(f.format(0.12), '+12%');
  });

  test('Unparseable', () {
    var format = NumberFormat.currency();
    expect(() => format.parse('abcdefg'), throwsFormatException);
    expect(() => format.parse(''), throwsFormatException);
    expect(() => format.parse('1.0zzz'), throwsFormatException);
    expect(() => format.parse('-∞+1'), throwsFormatException);
  });

  var digitsCheck = {
    0: '@4',
    1: '@4.3',
    2: '@4.32',
    3: '@4.322',
    4: '@4.3220',
  };

  test('Decimal digits', () {
    var amount = 4.3219876;
    for (var digits in digitsCheck.keys) {
      var f = NumberFormat.currency(
          locale: 'en_US', symbol: '@', decimalDigits: digits);
      var formatted = f.format(amount);
      expect(formatted, digitsCheck[digits]);
    }
    var defaultFormat = NumberFormat.currency(locale: 'en_US', symbol: '@');
    var formatted = defaultFormat.format(amount);
    expect(formatted, digitsCheck[2]);

    var jpyUs =
        NumberFormat.currency(locale: 'en_US', name: 'JPY', symbol: '@');
    formatted = jpyUs.format(amount);
    expect(formatted, digitsCheck[0]);

    var jpyJa = NumberFormat.currency(locale: 'ja', name: 'JPY', symbol: '@');
    formatted = jpyJa.format(amount);
    expect(formatted, digitsCheck[0]);

    var jpySimple = NumberFormat.simpleCurrency(locale: 'ja', name: 'JPY');
    formatted = jpySimple.format(amount);
    expect(formatted, '¥4');

    var jpyLower =
        NumberFormat.currency(locale: 'en_US', name: 'jpy', symbol: '@');
    formatted = jpyLower.format(amount);
    expect(formatted, digitsCheck[0]);

    var tnd = NumberFormat.currency(name: 'TND', symbol: '@');
    formatted = tnd.format(amount);
    expect(formatted, digitsCheck[3]);
  });

  testSimpleCurrencySymbols();

  test('Padding digits with non-ascii zero', () {
    var format = NumberFormat('000', 'ar_EG');
    var padded = format.format(0);
    expect(padded, '٠٠٠');
  });

  // Exercise a custom pattern. There's not actually much logic here, so just
  // validate that the custom pattern is in fact being used.
  test('Custom currency pattern', () {
    var format =
        NumberFormat.currency(name: 'XYZZY', customPattern: '[\u00a4][#,##.#]');
    var text = format.format(12345.67);
    expect(text, '[XYZZY][1,23,45.67]');
  });
}

String stripExtras(String input) {
  // Some of these results from CLDR have a leading LTR/RTL indicator,
  // and/or Arabic letter indicator,
  // which we don't want. We also treat the difference between Unicode
  // minus sign (2212) and hyphen-minus (45) as not significant.
  return input
      .replaceAll('\u200e', '')
      .replaceAll('\u200f', '')
      .replaceAll('\u061c', '')
      .replaceAll('\u2212', '-');
}

void testAgainstIcu(locale, List<NumberFormat> testFormats, list) {
  test('Test against ICU data for $locale', () {
    for (var format in testFormats) {
      var formatted = format.format(123);
      var negative = format.format(-12.3);
      var large = format.format(1234567890);
      var expected = (list..moveNext()).current;
      expect(formatted, expected);
      var expectedNegative = (list..moveNext()).current;
      expect(stripExtras(negative), stripExtras(expectedNegative));
      var expectedLarge = (list..moveNext()).current;
      expect(large, expectedLarge);
      var readBack = format.parse(formatted);
      expect(readBack, 123);
      var readBackNegative = format.parse(negative);
      expect(readBackNegative, -12.3);
      var readBackLarge = format.parse(large);
      expect(readBackLarge, 1234567890);
    }
  });
}

void testSimpleCurrencySymbols() {
  var currencies = ['USD', 'CAD', 'EUR', 'CRC', null];
  //  Note that these print using the simple symbol as if we were in a
  // a locale where that currency symbol is well understood. So we
  // expect Canadian dollars printed as $, even though our locale is
  // en_US, and this would confuse users.
  var simple = currencies.map((currency) =>
      NumberFormat.simpleCurrency(locale: 'en_US', name: currency));
  var expectedSimple = [r'$', r'$', '\u20ac', '\u20a1', r'$'];
  // These will always print as the global name, regardless of locale
  var global = currencies.map(
      (currency) => NumberFormat.currency(locale: 'en_US', name: currency));
  var expectedGlobal = currencies.map((curr) => curr ?? 'USD').toList();

  testCurrencySymbolsFor(expectedGlobal, global, 'global');
  testCurrencySymbolsFor(expectedSimple, simple, 'simple');
}

void testCurrencySymbolsFor(expected, formats, name) {
  var amount = 1000000.32;
  Map<Object, NumberFormat>.fromIterables(expected, formats)
      .forEach((expected, NumberFormat format) {
    test('Test $name ${format.currencyName}', () {
      // Allow for currencies with different fraction digits, e.g. CRC.
      var maxDigits = format.maximumFractionDigits;
      var rounded = maxDigits == 0 ? amount.round() : amount;
      var fractionDigits = (amount - rounded) < 0.00001 ? '.32' : '';
      var formatted = format.format(rounded);
      expect(formatted, '${expected}1,000,000$fractionDigits');
      var parsed = format.parse(formatted);
      expect(parsed, rounded);
    });
  });
}
