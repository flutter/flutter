@TestOn('browser')
// Tests for compact number formatting in pure Dart and in ECMAScript.
//
// TODO(b/36488375): run all these tests against both implementations to prove
// consistency when the bug is fixed. Also fix documentation and perhaps
// merge tests: these tests currently also touch non-compact currency
// formatting.
import 'package:intl/intl.dart' as intl;
import 'package:js/js_util.dart' as js;
import 'package:test/test.dart';

import 'compact_number_test_data.dart' as testdata;
import 'more_compact_number_test_data.dart' as more_testdata;

void main() {
  testdata.compactNumberTestData.forEach(_validate);
  more_testdata.cldr35CompactNumTests.forEach(_validateMore);

  test('RTL currency formatting', () {
    var basic = intl.NumberFormat.currency(locale: 'he');
    expect(basic.format(1234), '\u200F1,234.00\u00A0\u200FILS');
    basic = intl.NumberFormat.currency(locale: 'he', symbol: '₪');
    expect(basic.format(1234), '\u200F1,234.00\u00A0\u200F₪');
    expect(_ecmaFormatNumber('he', 1234, style: 'currency', currency: 'ILS'),
        '\u200F1,234.00\u00A0\u200F₪');

    var compact = intl.NumberFormat.compactCurrency(locale: 'he');
    expect(compact.format(1234), 'ILS1.23K\u200F');
    compact = intl.NumberFormat.compactCurrency(locale: 'he', symbol: '₪');
    expect(compact.format(1234), '₪1.23K\u200F');
    // ECMAScript skips the RTL character for notation:'compact':
    expect(
        _ecmaFormatNumber('he', 1234,
            style: 'currency', currency: 'ILS', notation: 'compact'),
        '₪1.2K\u200F');
    // short/long compactDisplay doesn't change anything here:
    expect(
        _ecmaFormatNumber('he', 1234,
            style: 'currency',
            currency: 'ILS',
            notation: 'compact',
            compactDisplay: 'short'),
        '₪1.2K\u200F');
    expect(
        _ecmaFormatNumber('he', 1234,
            style: 'currency',
            currency: 'ILS',
            notation: 'compact',
            compactDisplay: 'long'),
        '₪1.2K\u200F');

    var compactSimple = intl.NumberFormat.compactSimpleCurrency(locale: 'he');
    expect(compactSimple.format(1234), '₪1.23K\u200F');
  });
}

String _ecmaFormatNumber(String locale, num number,
    {String? style,
    String? currency,
    String? notation,
    String? compactDisplay,
    int? maximumSignificantDigits,
    bool? useGrouping}) {
  var options = js.newObject();
  if (notation != null) js.setProperty(options, 'notation', notation);
  if (compactDisplay != null) {
    js.setProperty(options, 'compactDisplay', compactDisplay);
  }
  if (style != null) js.setProperty(options, 'style', style);
  if (currency != null) js.setProperty(options, 'currency', currency);
  if (maximumSignificantDigits != null) {
    js.setProperty(
        options, 'maximumSignificantDigits', maximumSignificantDigits);
  }
  if (useGrouping != null) js.setProperty(options, 'useGrouping', useGrouping);
  return js.callMethod(number, 'toLocaleString', [locale, options]);
}

var _unsupportedChromeLocales = [
  // Not supported in Chrome:
  'af', 'as', 'az', 'be', 'bm', 'br', 'bs', 'chr', 'cy', 'eu', 'fur', 'ga',
  'gl', 'gsw', 'haw', 'hy', 'is', 'ka', 'kk', 'km', 'ky', 'ln', 'lo', 'mg',
  'mk', 'mn', 'mt', 'my', 'ne', 'nyn', 'or', 'pa', 'si', 'sq', 'ur', 'uz', 'zu',
  'ps'
];

var _skipLocalesShort = [
  'ja', // Expected: '1京', actual: '10000兆'.
  'ca', // Expected: '4,3\u00A0k', actual: '4,3m'.
  ..._unsupportedChromeLocales
];

var _skipLocalesLong = [
  'ja', // Expected: '1京', actual: '10000兆'.
  ..._unsupportedChromeLocales
];

String _fixLocale(String locale) {
  return locale.replaceAll('_', '-');
}

void _validate(String locale, List<List<String>> expected) {
  _validateShort(_fixLocale(locale), expected);
  _validateLong(_fixLocale(locale), expected);
}

void _validateShort(String locale, List<List<String>> expected) {
  var skip = _skipLocalesShort.contains(locale)
      ? "Skipping problem locale '$locale' for SHORT compact number tests"
      : false;

  test('Validate $locale SHORT', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      expect(
          _ecmaFormatNumber(
            locale,
            number,
            notation: 'compact',
            useGrouping: false,
          ),
          data[1]);
    }
  }, skip: skip);
}

void _validateLong(String locale, List<List<String>> expected) {
  var skip = _skipLocalesLong.contains(locale)
      ? "Skipping problem locale '$locale' for LONG compact number tests"
      : false;

  test('Validate $locale LONG', () {
    for (var data in expected) {
      var number = num.parse(data.first);
      expect(
          _ecmaFormatNumber(
            locale,
            number,
            notation: 'compact',
            compactDisplay: 'long',
            useGrouping: false,
          ),
          data[2]);
    }
  }, skip: skip);
}

void _validateMore(more_testdata.CompactRoundingTestCase t) {
  var options = js.newObject();
  js.setProperty(options, 'notation', 'compact');
  if (t.maximumIntegerDigits != null) {
    js.setProperty(options, 'maximumIntegerDigits', t.maximumIntegerDigits);
  }

  if (t.minimumIntegerDigits != null) {
    js.setProperty(options, 'minimumIntegerDigits', t.minimumIntegerDigits);
  }

  if (t.maximumFractionDigits != null) {
    js.setProperty(options, 'maximumFractionDigits', t.maximumFractionDigits);
  }

  if (t.minimumFractionDigits != null) {
    js.setProperty(options, 'minimumFractionDigits', t.minimumFractionDigits);
  }

  if (t.minimumExponentDigits != null) {
    js.setProperty(options, 'minimumExponentDigits', t.minimumExponentDigits);
  }

  if (t.maximumSignificantDigits != null) {
    js.setProperty(
        options, 'maximumSignificantDigits', t.maximumSignificantDigits);
  }

  if (t.minimumSignificantDigits != null) {
    js.setProperty(
        options, 'minimumSignificantDigits', t.minimumSignificantDigits);
  }

  test(t.toString(), () {
    expect(js.callMethod(t.number, 'toLocaleString', ['en-US', options]),
        t.expected);
  });
}
