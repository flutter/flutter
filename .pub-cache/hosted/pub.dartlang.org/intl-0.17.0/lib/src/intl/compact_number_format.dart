// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'number_format.dart';

// Suppress naming issues as changes would be breaking.
// ignore_for_file: constant_identifier_names

/// An abstract class for compact number styles.
abstract class _CompactStyleBase {
  /// The _CompactStyle for the sign of [number], i.e. positive or
  /// negative.
  _CompactStyle styleForSign(number);

  /// How many total digits do we expect in the number.
  ///
  /// If the pattern is
  ///
  ///       4: '00K',
  ///
  /// then this is 5, meaning we expect this to be a 5-digit (or more)
  /// number. We will scale by 1000 and expect 2 integer digits remaining, so we
  /// get something like '12K'. This is used to find the closest pattern for a
  /// number.
  int get totalDigits;

  /// What should we divide the number by in order to print. Normally it is
  /// either `10^normalizedExponent` or 1 if we shouldn't divide at all.
  int get divisor;

  /// The iterable of all possible styles which we represent.
  ///
  /// Normally this will be either a list with just ourself, or of two elements
  /// for our positive and negative styles.
  Iterable<_CompactStyle> get allStyles;
}

/// A compact format with separate styles for positive and negative numbers.
class _CompactStyleWithNegative extends _CompactStyleBase {
  _CompactStyleWithNegative(this.positiveStyle, this.negativeStyle);
  final _CompactStyle positiveStyle;
  final _CompactStyle negativeStyle;
  _CompactStyle styleForSign(number) =>
      number < 0 ? negativeStyle : positiveStyle;
  int get totalDigits => positiveStyle.totalDigits;
  int get divisor => positiveStyle.divisor;
  List<_CompactStyle> get allStyles => [positiveStyle, negativeStyle];
}

/// Represents a compact format for a particular base
///
/// For example, 10K can be used to represent 10,000.  Corresponds to one of the
/// patterns in COMPACT_DECIMAL_SHORT_FORMAT. So, for example, in en_US we have
/// the pattern
///
///       4: '00K'
/// which matches
///
///       _CompactStyle(pattern: '00K', normalizedExponent: 4, divisor: 1000,
///           expectedDigits: 1, prefix: '', suffix: 'K');
///
/// where expectedDigits is the number of zeros.
class _CompactStyle extends _CompactStyleBase {
  _CompactStyle(
      {this.pattern,
      this.normalizedExponent = 0,
      this.divisor = 1,
      this.expectedDigits = 1,
      this.prefix = '',
      this.suffix = ''});

  /// The pattern on which this is based.
  ///
  /// We don't actually need this, but it makes debugging easier.
  String? pattern;

  /// The normalized scientific notation exponent for which the format applies.
  ///
  /// So if this is 3, we expect it to apply for numbers from 1000 and up.
  /// Typically it would be from 1000 to 9999, but that depends if there's a
  /// style for 4 or not. This is the CLDR index of the pattern, and usually
  /// determines the divisor, but if the pattern is just a 0 with no prefix or
  /// suffix then we don't divide at all.
  int normalizedExponent;

  /// What should we divide the number by in order to print. Normally is either
  /// 10^normalizedExponent or 1 if we shouldn't divide at all.
  int divisor;

  /// How many integer digits do we expect to print - the number of zeros in the
  /// CLDR pattern.
  int expectedDigits;

  /// Text we put in front of the number part.
  String prefix;

  /// Text we put after the number part.
  String suffix;

  /// How many total digits do we expect in the number.
  ///
  /// If the pattern is
  ///
  ///       4: '00K',
  ///
  /// then this is 5, meaning we expect this to be a 5-digit (or more)
  /// number. We will scale by 1000 and expect 2 integer digits remaining, so we
  /// get something like '12K'. This is used to find the closest pattern for a
  /// number.
  int get totalDigits => normalizedExponent + expectedDigits - 1;

  /// Return true if this is the fallback compact pattern, printing the number
  /// un-compacted. e.g. 1200 might print as '1.2K', but 12 just prints as '12'.
  ///
  /// For currencies, with the fallback pattern we use the super implementation
  /// so that we will respect things like the default number of decimal digits
  /// for a particular currency (e.g. two for USD, zero for JPY)
  bool get isFallback => pattern == null || pattern == '0';

  /// Should we print the number as-is, without dividing.
  ///
  /// This happens if the pattern has no abbreviation for scaling (e.g. K, M).
  /// So either the pattern is empty or it is of a form like '0 $'. This is a
  /// workaround for locales like 'it', which include patterns with no suffix
  /// for numbers >= 1000 but < 1,000,000.
  bool get printsAsIs =>
      isFallback || pattern!.replaceAll(RegExp('[0\u00a0\u00a4]'), '').isEmpty;

  _CompactStyle styleForSign(number) => this;
  List<_CompactStyle> get allStyles => [this];

  static final _regex = RegExp('([^0]*)(0+)(.*)');

  static final _justZeros = RegExp(r'^0*$');

  /// Does pattern have any additional characters or is it just zeros.
  static bool _hasNonZeroContent(String pattern) =>
      !_justZeros.hasMatch(pattern);

  /// Creates a [_CompactStyle] instance for pattern with [normalizedExponent].
  static _CompactStyle createStyle(String pattern, int normalizedExponent) {
    var match = _regex.firstMatch(pattern);
    var integerDigits = match!.group(2)!.length;
    var prefix = match.group(1)!;
    var suffix = match.group(3)!;
    // If the pattern is just zeros, with no suffix, then we shouldn't divide
    // by the number of digits. e.g. for 'af', the pattern for 3 is '0', but
    // it doesn't mean that 4321 should print as 4. But if the pattern was
    // '0K', then it should print as '4K'. So we have to check if the pattern
    // has a suffix. This seems extremely hacky, but I don't know how else to
    // encode that. Check what other things are doing.
    var divisor = 1;
    if (_hasNonZeroContent(pattern)) {
      divisor = pow(10, normalizedExponent - integerDigits + 1) as int;
    }
    return _CompactStyle(
        pattern: pattern,
        normalizedExponent: normalizedExponent,
        expectedDigits: integerDigits,
        prefix: prefix,
        suffix: suffix,
        divisor: divisor);
  }
}

/// Enumerates the different formats supported.
enum _CompactFormatType {
  COMPACT_DECIMAL_SHORT_PATTERN,
  COMPACT_DECIMAL_LONG_PATTERN,
  COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN
}

class _CompactNumberFormat extends NumberFormat {
  /// A default, using the decimal pattern, for the `getPattern` constructor parameter.
  static String _forDecimal(NumberSymbols symbols) => symbols.DECIMAL_PATTERN;

  final List<_CompactStyleBase> _styles;

  factory _CompactNumberFormat(
      {String? locale,
      _CompactFormatType? formatType,
      String? name,
      String? currencySymbol,
      String? Function(NumberSymbols) getPattern = _forDecimal,
      int? decimalDigits,
      bool lookupSimpleCurrencySymbol = false,
      bool isForCurrency = false}) {
    // Initialization copied from `NumberFormat` constructor.
    // TODO(davidmorgan): deduplicate.
    locale = helpers.verifiedLocale(locale, NumberFormat.localeExists, null)!;
    var symbols = numberFormatSymbols[locale] as NumberSymbols;
    var localeZero = symbols.ZERO_DIGIT.codeUnitAt(0);
    var zeroOffset = localeZero - constants.asciiZeroCodeUnit;
    name ??= symbols.DEF_CURRENCY_CODE;
    if (currencySymbol == null && lookupSimpleCurrencySymbol) {
      currencySymbol = constants.simpleCurrencySymbols[name];
    }
    currencySymbol ??= name;
    var pattern = getPattern(symbols);

    // CompactNumberFormat initialization.

    /// Map from magnitude to formatting pattern for that magnitude.
    ///
    /// The magnitude is the exponent when using the normalized scientific
    /// notation (so numbers from 1000 to 9999 correspond to magnitude 3).
    ///
    /// These patterns are taken from the appropriate CompactNumberSymbols
    /// instance's COMPACT_DECIMAL_SHORT_PATTERN, COMPACT_DECIMAL_LONG_PATTERN,
    /// or COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN members.
    Map<int, String> patterns;

    var compactSymbols = compactNumberSymbols[locale]!;

    var styles = <_CompactStyleBase>[];
    switch (formatType) {
      case _CompactFormatType.COMPACT_DECIMAL_SHORT_PATTERN:
        patterns = compactSymbols.COMPACT_DECIMAL_SHORT_PATTERN;
        break;
      // TODO(alanknight): Long formats may have different forms for different
      // plural cases (e.g. million/millions).
      case _CompactFormatType.COMPACT_DECIMAL_LONG_PATTERN:
        patterns = compactSymbols.COMPACT_DECIMAL_LONG_PATTERN ??
            compactSymbols.COMPACT_DECIMAL_SHORT_PATTERN;
        break;
      case _CompactFormatType.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN:
        patterns = compactSymbols.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN;
        break;
      default:
        throw ArgumentError.notNull('formatType');
    }
    patterns.forEach((int exponent, String pattern) {
      if (pattern.contains(';')) {
        var patterns = pattern.split(';');
        styles.add(_CompactStyleWithNegative(
            _CompactStyle.createStyle(patterns.first, exponent),
            _CompactStyle.createStyle(patterns.last, exponent)));
      } else {
        styles.add(_CompactStyle.createStyle(pattern, exponent));
      }
    });

    // Reverse the styles so that we look through them from largest to smallest.
    styles = styles.reversed.toList();
    // Add a fallback style that just prints the number.
    styles.add(_CompactStyle());

    return _CompactNumberFormat._(
        name,
        currencySymbol,
        isForCurrency,
        locale,
        localeZero,
        pattern,
        symbols,
        zeroOffset,
        NumberFormatParser.parse(symbols, pattern, isForCurrency,
            currencySymbol, name, decimalDigits),
        styles);
  }

  _CompactNumberFormat._(
      String currencyName,
      String currencySymbol,
      bool isForCurrency,
      String locale,
      int localeZero,
      String? pattern,
      NumberSymbols symbols,
      int zeroOffset,
      NumberFormatParseResult result,
      // Fields introduced in this class.
      this._styles)
      : super._(currencyName, currencySymbol, isForCurrency, locale, localeZero,
            pattern, symbols, zeroOffset, result) {
    significantDigits = 3;
    turnOffGrouping();
  }

  /// The style in which we will format a particular number.
  ///
  /// This is a temporary variable that is only valid within a call to format.
  _CompactStyle? _style;

  String format(number) {
    var style = _styleFor(number);
    _style = style;
    final divisor = style.printsAsIs ? 1 : style.divisor;
    final numberToFormat = _divide(number, divisor);
    var formatted = super.format(numberToFormat);
    var prefix = style.prefix;
    var suffix = style.suffix;
    // If this is for a currency, then the super call will have put the currency
    // somewhere. We don't want it there, we want it where our style indicates,
    // so remove it and replace. This has the remote possibility of a false
    // positive, but it seems unlikely that e.g. USD would occur as a string in
    // a regular number.
    if (_isForCurrency && !style.isFallback) {
      formatted = formatted.replaceFirst(currencySymbol, '').trim();
      prefix = prefix.replaceFirst('\u00a4', currencySymbol);
      suffix = suffix.replaceFirst('\u00a4', currencySymbol);
    }
    final withExtras = '$prefix$formatted$suffix';
    _style = null;
    return withExtras;
  }

  /// How many digits after the decimal place should we display, given that
  /// there are [remainingSignificantDigits] left to show.
  int _fractionDigitsAfter(int remainingSignificantDigits) {
    final newFractionDigits =
        super._fractionDigitsAfter(remainingSignificantDigits);
    // For non-currencies, or for currencies if the numbers are large enough to
    // compact, always use the number of significant digits and ignore
    // decimalDigits. That is, $1.23K but also ¥12.3\u4E07, even though yen
    // don't normally print decimal places.
    if (!_isForCurrency || !_style!.isFallback) return newFractionDigits;
    // If we are printing a currency and it's too small to compact, but
    // significant digits would have us only print some of the decimal digits,
    // use all of them. So $12.30, not $12.3
    if (newFractionDigits > 0 && newFractionDigits < decimalDigits!) {
      return decimalDigits!;
    } else {
      return min(newFractionDigits, decimalDigits!);
    }
  }

  /// Defines minimumFractionDigits based on current style being formatted.
  @override
  int get minimumFractionDigits {
    if (!_isForCurrency ||
        !significantDigitsInUse ||
        _style == null ||
        _style!.isFallback) {
      return super.minimumFractionDigits;
    } else {
      return 0;
    }
  }

  /// Divide numbers that may not have a division operator (e.g. Int64).
  ///
  /// Only used for powers of 10, so we require an integer denominator.
  num _divide(numerator, int denominator) {
    if (numerator is num) {
      return numerator / denominator;
    }
    // If it doesn't fit in a JS int after division, we're not going to be able
    // to meaningfully print a compact representation for it.
    var divided = numerator ~/ denominator;
    var integerPart = divided.toInt();
    if (divided != integerPart) {
      throw FormatException(
          'Number too big to use with compact format', numerator);
    }
    var remainder = numerator.remainder(denominator).toInt();
    var originalFraction = numerator - (numerator ~/ 1);
    var fraction = originalFraction == 0 ? 0 : originalFraction / denominator;
    return integerPart + (remainder / denominator) + fraction;
  }

  _CompactStyle _styleFor(number) {
    // We have to round the number based on the number of significant digits so
    // that we pick the right style based on the rounded form and format 999999
    // as 1M rather than 1000K.
    var originalLength = NumberFormat.numberOfIntegerDigits(number);
    var additionalDigits = originalLength - significantDigits!;
    var digitLength = originalLength;
    if (additionalDigits > 0) {
      var divisor = pow(10, additionalDigits);
      // If we have an Int64, value speed over precision and make it double.
      var rounded = (number.toDouble() / divisor).round() * divisor;
      digitLength = NumberFormat.numberOfIntegerDigits(rounded);
    }
    for (var style in _styles) {
      if (digitLength > style.totalDigits) {
        return style.styleForSign(number);
      }
    }
    throw FormatException(
        'No compact style found for number. This should not happen', number);
  }

  Iterable<_CompactStyle> get _stylesForSearching =>
      _styles.reversed.expand((x) => x.allStyles);

  num parse(String text) {
    for (var style in _stylesForSearching) {
      if (text.startsWith(style.prefix) && text.endsWith(style.suffix)) {
        var numberText = text.substring(
            style.prefix.length, text.length - style.suffix.length);
        var number = _tryParsing(numberText);
        if (number != null) {
          return number * style.divisor;
        }
      }
    }
    throw FormatException(
        "Cannot parse compact number in locale '$locale'", text);
  }

  /// Returns text parsed into a number if possible, else returns null.
  num? _tryParsing(String text) {
    try {
      return super.parse(text);
    } on FormatException {
      return null;
    }
  }
}
