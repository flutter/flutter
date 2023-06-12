// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'number_format.dart';

// Suppress naming issues as changes would be breaking.
// ignore_for_file: constant_identifier_names

/// An abstract class for compact number styles.
abstract class _CompactStyleBase {
  /// The _CompactStyle for the [number].
  _CompactStyle styleForNumber(dynamic number, _CompactNumberFormat format);

  /// What should we divide the number by in order to print. Normally it is
  /// either `10^normalizedExponent` or 1 if we shouldn't divide at all.
  int get divisor;

  /// The iterable of all possible styles which we represent.
  ///
  /// Normally this will be either a list with just ourself, or of two elements
  /// for our positive and negative styles.
  Iterable<_CompactStyle> get allStyles;
}

/// A compact format with separate styles for plural forms.
class _CompactStyleWithPlurals extends _CompactStyleBase {
  int exponent;
  Map<String, _CompactStyleBase> styles;
  plural_rules.PluralCase Function()? _plural;
  late _CompactStyleBase _defaultStyle;

  _CompactStyleWithPlurals(this.styles, this.exponent, String? locale) {
    _plural = plural_rules.pluralRules[locale];
    _defaultStyle = styles['other']!;
  }

  @override
  Iterable<_CompactStyle> get allStyles =>
      styles.values.expand((x) => x.allStyles);

  @override
  int get divisor => _defaultStyle.divisor;

  @override
  _CompactStyle styleForNumber(dynamic number, _CompactNumberFormat format) {
    var value = number.abs();
    if (_plural == null) {
      return _defaultStyle.styleForNumber(number, format);
    }

    var displayed = value;
    var precision = format._minimumFractionDigits;

    if (format.significantDigitsInUse) {
      // Note: this is not 100% correct, but good enough for most cases.
      var integerPart = format._floor(value);
      var integerLength = NumberFormat.numberOfIntegerDigits(integerPart);
      if (format.minimumSignificantDigits != null) {
        precision = max(0, format.minimumSignificantDigits! - integerLength);
      }
    }

    // Round to the right precision.
    var factor = pow(10, precision);
    displayed = (displayed * factor).round() / factor;

    if (format.significantDigitsInUse &&
        !format.minimumSignificantDigitsStrict) {
      // Check for trailing 0.
      var fractionStr = format._floor(displayed * factor).toString();
      while (precision > 0 && fractionStr.endsWith('0')) {
        precision--;
        fractionStr = fractionStr.substring(0, fractionStr.length - 1);
      }
    }

    // Direct value? (French 1000 => "mille" has key "1".)
    if (number >= 0 && precision == 0) {
      var indexed = styles[format._floor(displayed).toString()];
      if (indexed != null) {
        return indexed.styleForNumber(number, format);
      }
    }

    plural_rules.startRuleEvaluation(displayed, precision);
    var pluralCase = _plural!();
    var style = _defaultStyle;
    switch (pluralCase) {
      case plural_rules.PluralCase.ZERO:
        style = styles['zero'] ?? _defaultStyle;
        break;
      case plural_rules.PluralCase.ONE:
        style = styles['one'] ?? _defaultStyle;
        break;
      case plural_rules.PluralCase.TWO:
        style = styles['two'] ?? styles['few'] ?? _defaultStyle;
        break;
      case plural_rules.PluralCase.FEW:
        style = styles['few'] ?? _defaultStyle;
        break;
      case plural_rules.PluralCase.MANY:
        style = styles['many'] ?? _defaultStyle;
        break;
      default:
      // Keep _defaultStyle;
    }
    return style.styleForNumber(number, format);
  }
}

/// A compact format with separate styles for positive and negative numbers.
class _CompactStyleWithNegative extends _CompactStyleBase {
  _CompactStyleWithNegative(this.positiveStyle, this.negativeStyle);
  final _CompactStyle positiveStyle;
  final _CompactStyle negativeStyle;

  @override
  _CompactStyle styleForNumber(dynamic number, _CompactNumberFormat format) =>
      number < 0 ? negativeStyle : positiveStyle;

  @override
  int get divisor => positiveStyle.divisor;

  @override
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
///       _CompactStyle(pattern: '00K', divisor: 1000,
///           prefix: '', suffix: 'K');
class _CompactStyle extends _CompactStyleBase {
  _CompactStyle(
      {this.pattern,
      this.divisor = 1,
      this.positivePrefix = '',
      this.negativePrefix = '',
      this.positiveSuffix = '',
      this.negativeSuffix = '',
      this.isDirectValue = false});

  /// The pattern on which this is based.
  ///
  /// We don't actually need this, but it makes debugging easier.
  String? pattern;

  /// What should we divide the number by in order to print. Normally is either
  /// 10^normalizedExponent or 1 if we shouldn't divide at all.
  @override
  int divisor;

  // Prefixes / suffixes.
  String positivePrefix;
  String negativePrefix;
  String positiveSuffix;
  String negativeSuffix;

  /// Whether this pattern omits numbers. Ex: "mille" for 1000 in fr.
  bool isDirectValue;

  /// Return true if this is the fallback compact pattern, printing the number
  /// un-compacted. e.g. 1200 might print as '1.2K', but 12 just prints as '12'.
  ///
  /// For currencies, with the fallback pattern we use the super implementation
  /// so that we will respect things like the default number of decimal digits
  /// for a particular currency (e.g. two for USD, zero for JPY)
  bool get isFallback => pattern == null || pattern == '0';

  @override
  _CompactStyle styleForNumber(dynamic number, _CompactNumberFormat format) =>
      this;

  @override
  List<_CompactStyle> get allStyles => [this];

  static final _regex = RegExp('([^0]*)(0+)(.*)');

  static final _justZeros = RegExp(r'^0*$');

  /// Does pattern have any additional characters or is it just zeros.
  static bool _hasNonZeroContent(String pattern) =>
      !_justZeros.hasMatch(pattern);

  /// Creates a [_CompactStyle] instance for pattern with [normalizedExponent].
  static _CompactStyle createStyle(
      NumberSymbols symbols, String pattern, int normalizedExponent,
      {bool isSigned = false, bool explicitSign = false}) {
    var prefix = '';
    var suffix = '';
    var divisor = 1;
    var isDirectValue = false;
    var match = _regex.firstMatch(pattern);
    if (match != null) {
      prefix = match.group(1)!;
      suffix = match.group(3)!;
      // If the pattern is just zeros, with no suffix, then we shouldn't divide
      // by the number of digits. e.g. for 'af', the pattern for 3 is '0', but
      // it doesn't mean that 4321 should print as 4. But if the pattern was
      // '0K', then it should print as '4K'. So we have to check if the pattern
      // has a suffix. This seems extremely hacky, but I don't know how else to
      // encode that. Check what other things are doing.
      if (_hasNonZeroContent(pattern)) {
        var integerDigits = match.group(2)!.length;
        divisor = pow(10, normalizedExponent - integerDigits + 1) as int;
      }
    } else {
      if (pattern.isNotEmpty && !pattern.contains('0')) {
        // "Direct" pattern: no numbers.
        divisor = pow(10, normalizedExponent) as int;
        isDirectValue = true;
      }
    }

    final positivePrefix =
        (explicitSign && !isSigned) ? '${symbols.PLUS_SIGN}$prefix' : prefix;
    final negativePrefix =
        (!isSigned) ? '${symbols.MINUS_SIGN}$prefix' : prefix;
    final positiveSuffix = suffix;
    final negativeSuffix = suffix;

    return _CompactStyle(
        pattern: pattern,
        positivePrefix: positivePrefix,
        negativePrefix: negativePrefix,
        positiveSuffix: positiveSuffix,
        negativeSuffix: negativeSuffix,
        divisor: divisor,
        isDirectValue: isDirectValue);
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

  // Map exponent => style.
  final Map<int, _CompactStyleBase> _styles;

  // Whether positive sign should be explicitly printed.
  final bool _explicitSign;

  factory _CompactNumberFormat(
      {String? locale,
      _CompactFormatType? formatType,
      String? name,
      String? currencySymbol,
      String? Function(NumberSymbols) getPattern = _forDecimal,
      int? decimalDigits,
      bool explicitSign = false,
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
    Map<int, Map<String, String>> patterns;

    var compactSymbols = compactNumberSymbols[locale]!;

    var styles = <int, _CompactStyleBase>{};
    switch (formatType) {
      case _CompactFormatType.COMPACT_DECIMAL_SHORT_PATTERN:
        patterns = compactSymbols.COMPACT_DECIMAL_SHORT_PATTERN;
        break;
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

    patterns.forEach((int exponent, Map<String, String> patterns) {
      _CompactStyleBase style;
      if (patterns.keys.length == 1 && patterns.keys.single == 'other') {
        // No plural.
        var pattern = patterns.values.single;
        style = _styleFromPattern(pattern, exponent, explicitSign, symbols);
      } else {
        style = _CompactStyleWithPlurals(
            patterns.map((key, value) => MapEntry(key,
                _styleFromPattern(value, exponent, explicitSign, symbols))),
            exponent,
            locale);
      }
      styles[exponent] = style;
    });

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
        styles,
        explicitSign);
  }

  static _CompactStyleBase _styleFromPattern(
      String pattern, int exponent, bool explicitSign, NumberSymbols symbols) {
    if (pattern.contains(';')) {
      var patterns = pattern.split(';');
      var positivePattern = patterns.first;
      var negativePattern = patterns.last;
      if (explicitSign &&
          !positivePattern.contains(symbols.PLUS_SIGN) &&
          negativePattern.contains(symbols.MINUS_SIGN) &&
          positivePattern ==
              negativePattern.replaceAll(symbols.MINUS_SIGN, '')) {
        // Re-use the negative pattern, with plus sign.
        positivePattern =
            negativePattern.replaceAll(symbols.MINUS_SIGN, symbols.PLUS_SIGN);
      }
      return _CompactStyleWithNegative(
          _CompactStyle.createStyle(symbols, positivePattern, exponent,
              isSigned: positivePattern.contains(symbols.PLUS_SIGN)),
          _CompactStyle.createStyle(symbols, negativePattern, exponent,
              isSigned: true));
    } else {
      return _CompactStyle.createStyle(symbols, pattern, exponent,
          explicitSign: explicitSign);
    }
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
      this._styles,
      this._explicitSign)
      : super._(currencyName, currencySymbol, isForCurrency, locale, localeZero,
            pattern, symbols, zeroOffset, result) {
    significantDigits = 3;
    turnOffGrouping();
  }

  @override
  set significantDigits(int? x) {
    // Replicate ICU behavior: set only the minimumSignificantDigits and
    // do not force trailing 0 in fractional part.
    _explicitMinimumFractionDigits = false;
    minimumSignificantDigits = x;
    maximumSignificantDigits = null;
    minimumSignificantDigitsStrict = false;
  }

  @override
  int get minimumFractionDigits =>
      _style != null && !_style!.isFallback && !_explicitMinimumFractionDigits
          ? 0
          : super.minimumFractionDigits;

  /// The style in which we will format a particular number.
  ///
  /// This is a temporary variable that is only valid within a call to format
  /// and parse.
  _CompactStyle? _style;

  // We delegate prefixes to current _style.
  @override
  String get positivePrefix =>
      _style!.isFallback ? super.positivePrefix : _style!.positivePrefix;
  @override
  String get negativePrefix =>
      _style!.isFallback ? super.negativePrefix : _style!.negativePrefix;
  @override
  String get positiveSuffix =>
      _style!.isFallback ? super.positiveSuffix : _style!.positiveSuffix;
  @override
  String get negativeSuffix =>
      _style!.isFallback ? super.negativeSuffix : _style!.negativeSuffix;

  @override
  String format(dynamic number) {
    var style = _styleFor(number);
    _style = style;
    final divisor = style.isFallback ? 1 : style.divisor;
    final numberToFormat = _divide(number, divisor);
    var formatted = style.isDirectValue
        ? '${_signPrefix(number)}${style.pattern}${_signSuffix(number)}'
        : super.format(numberToFormat);
    if (_explicitSign &&
        style.isFallback &&
        number >= 0 &&
        !formatted.contains(symbols.PLUS_SIGN)) {
      formatted = '${symbols.PLUS_SIGN}$formatted';
    }
    if (_isForCurrency && !style.isFallback) {
      formatted = formatted.replaceFirst('\u00a4', currencySymbol);
    }
    _style = null;
    return formatted;
  }

  @override
  bool _useDefaultSignificantDigits() {
    // For non-currencies, or for currencies if the numbers are large enough to
    // compact, always use the number of significant digits and ignore
    // decimalDigits.
    return !_isForCurrency || !_style!.isFallback;
  }

  /// Divide numbers that may not have a division operator (e.g. Int64).
  ///
  /// Only used for powers of 10, so we require an integer denominator.
  static num _divide(numerator, int denominator) {
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
    if (number.abs() < 10) {
      // Cannot be compacted.
      return _defaultCompactStyle;
    }
    var rounded = number.toDouble(); // No rounding yet...
    var digitLength = NumberFormat.numberOfIntegerDigits(number);
    var divisor = 1; // Default.

    void updateRounding() {
      var fractionDigits = maximumFractionDigits;
      if (significantDigitsInUse) {
        var divisorLength = NumberFormat.numberOfIntegerDigits(divisor);
        // We have to round the number based on the number of significant
        // digits so that we pick the right style based on the rounded form
        // and format 999999 as 1M rather than 1000K.
        fractionDigits =
            (maximumSignificantDigits ?? minimumSignificantDigits ?? 0) -
                digitLength +
                divisorLength -
                1;
        if (maximumSignificantDigits == null) {
          // Keep all digits of the integer part.
          fractionDigits = max(0, fractionDigits);
        }
      }
      var fractionMultiplier = pow(10, fractionDigits);
      rounded = (rounded * fractionMultiplier / divisor).round() *
          divisor /
          fractionMultiplier;
      digitLength = NumberFormat.numberOfIntegerDigits(rounded);
    }

    updateRounding();

    _CompactStyleBase? style;
    for (var entry in _styles.entries) {
      var exponent = entry.key + 1;
      if (exponent > digitLength) {
        break;
      }
      style = entry.value;
      // Recompute digits length based on new exponent.
      divisor = style.divisor;
      updateRounding();
    }
    return style?.styleForNumber(_divide(number, divisor), this) ??
        _defaultCompactStyle;
  }

  Iterable<_CompactStyle> get _stylesForSearching =>
      _styles.values.expand((x) => x.allStyles);

  String _normalize(String input) {
    return input
        .replaceAll('\u200e', '') // LEFT-TO-RIGHT MARK.
        .replaceAll('\u200f', '') // RIGHT-TO-LEFT MARK.
        .replaceAll('\u0020', '') // SPACE.
        .replaceAll('\u00a0', '') // NO-BREAK SPACE.
        .replaceAll('\u202f', '') // NARROW NO-BREAK SPACE.
        .replaceAll('\u2212', '-'); // MINUS SIGN.
  }

  @override
  num parse(final String inputText) {
    for (var style in [_defaultCompactStyle, ..._stylesForSearching]) {
      _style = style;
      var text = _normalize(inputText);
      var negative = false;
      var negativePrefix = _normalize(style.negativePrefix);
      var negativeSuffix = _normalize(style.negativeSuffix);
      var positivePrefix = _normalize(style.positivePrefix);
      var positiveSuffix = _normalize(style.positiveSuffix);
      if (!style.isFallback) {
        if (text.startsWith(negativePrefix) && text.endsWith(negativeSuffix)) {
          text = text.substring(
              negativePrefix.length, text.length - negativeSuffix.length);
          negative = true;
        } else if (text.startsWith(positivePrefix) &&
            text.endsWith(positiveSuffix)) {
          text = text.substring(
              positivePrefix.length, text.length - positiveSuffix.length);
        } else {
          continue;
        }
      }
      if (style.isDirectValue) {
        // "Direct formatting" pattern (1000 => "mille").
        if (text == style.pattern!) {
          _style = null;
          return style.divisor * (negative ? -1 : 1);
        } else {
          // Do not attempt parsing: no number.
          continue;
        }
      }
      var number = _tryParsing(text);
      if (number == null && _zeroOffset != 0) {
        // Locale has non-roman numerals.
        // Try simple number parse, in case input contains roman numerals.
        number = num.tryParse(text);
      }
      if (number != null) {
        _style = null;
        return number * style.divisor * (negative ? -1 : 1);
      }
    }
    _style = null;

    throw FormatException(
        "Cannot parse compact number in locale '$locale'", inputText);
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

final _defaultCompactStyle = _CompactStyle();
