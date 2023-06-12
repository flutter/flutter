// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math';

import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

import 'string_iterator.dart';

// ignore_for_file: constant_identifier_names

/// Output of [_NumberFormatParser.parse].
///
/// Everything needed to initialize a [NumberFormat].
class NumberFormatParseResult {
  String negativePrefix;
  String positivePrefix = '';
  String negativeSuffix = '';
  String positiveSuffix = '';

  int multiplier = 1;
  int get multiplierDigits => (log(multiplier) / _ln10).round();

  int minimumExponentDigits = 0;

  int maximumIntegerDigits = 40;
  int minimumIntegerDigits = 1;
  int maximumFractionDigits = 3;
  int minimumFractionDigits = 0;

  int groupingSize = 3;
  int finalGroupingSize = 3;

  bool decimalSeparatorAlwaysShown = false;
  bool useSignForPositiveExponent = false;
  bool useExponentialNotation = false;

  int? decimalDigits;

  // [decimalDigits] is both input and output of parsing.
  NumberFormatParseResult(NumberSymbols symbols, this.decimalDigits)
      : negativePrefix = symbols.MINUS_SIGN;
}

/// Private class that parses the numeric formatting pattern and sets the
/// variables in [format] to appropriate values. Instances of this are
/// transient and store parsing state in instance variables, so can only be used
/// to parse a single pattern.
class NumberFormatParser {
  /// The special characters in the pattern language. All others are treated
  /// as literals.
  static const PATTERN_SEPARATOR = ';';
  static const QUOTE = "'";
  static const PATTERN_DIGIT = '#';
  static const PATTERN_ZERO_DIGIT = '0';
  static const PATTERN_GROUPING_SEPARATOR = ',';
  static const PATTERN_DECIMAL_SEPARATOR = '.';
  static const PATTERN_CURRENCY_SIGN = '\u00A4';
  static const PATTERN_PER_MILLE = '\u2030';
  static const PER_MILLE_SCALE = 1000;
  static const PATTERN_PERCENT = '%';
  static const PERCENT_SCALE = 100;
  static const PATTERN_EXPONENT = 'E';
  static const PATTERN_PLUS = '+';

  /// The format whose state we are setting.
  final NumberSymbols symbols;

  /// The pattern we are parsing.
  final StringIterator pattern;

  /// Whether this is a currency.
  final bool isForCurrency;

  /// We can be passed a specific currency symbol, regardless of the locale.
  final String currencySymbol;

  final String currencyName;

  // The result being constructed.
  final NumberFormatParseResult result;

  bool groupingSizeSetExplicitly = false;

  /// Create a new [_NumberFormatParser] for a particular [NumberFormat] and
  /// [input] pattern.
  ///
  /// [decimalDigits] is optional, if specified it overrides the default.
  NumberFormatParser(this.symbols, String input, this.isForCurrency,
      this.currencySymbol, this.currencyName, int? decimalDigits)
      : result = NumberFormatParseResult(symbols, decimalDigits),
        pattern = StringIterator(input) {
    pattern.moveNext();
  }

  static NumberFormatParseResult parse(
          NumberSymbols symbols,
          String? input,
          bool isForCurrency,
          String currencySymbol,
          String currencyName,
          int? decimalDigits) =>
      input == null
          ? NumberFormatParseResult(symbols, decimalDigits)
          : (NumberFormatParser(symbols, input, isForCurrency, currencySymbol,
                  currencyName, decimalDigits)
                .._parse())
              .result;

  /// For currencies, the default number of decimal places to use in
  /// formatting. Defaults to two for non-currencies or currencies where it's
  /// not specified.
  int get _defaultDecimalDigits =>
      currencyFractionDigits[currencyName.toUpperCase()] ??
      currencyFractionDigits['DEFAULT']!;

  /// Parse the input pattern and update [result].
  void _parse() {
    result.positivePrefix = _parseAffix();
    var trunk = _parseTrunk();
    result.positiveSuffix = _parseAffix();
    // If we have separate positive and negative patterns, now parse the
    // the negative version.
    if (pattern.current == NumberFormatParser.PATTERN_SEPARATOR) {
      pattern.moveNext();
      result.negativePrefix = _parseAffix();
      // Skip over the negative trunk, verifying that it's identical to the
      // positive trunk.
      var trunkIterator = StringIterator(trunk);
      while (trunkIterator.moveNext()) {
        var each = trunkIterator.current;
        if (pattern.current != each && pattern.current != null) {
          throw FormatException(
              'Positive and negative trunks must be the same', trunk);
        }
        pattern.moveNext();
      }
      result.negativeSuffix = _parseAffix();
    } else {
      // If no negative affix is specified, they share the same positive affix.
      result.negativePrefix = result.negativePrefix + result.positivePrefix;
      result.negativeSuffix = result.positiveSuffix + result.negativeSuffix;
    }

    if (isForCurrency) {
      result.decimalDigits ??= _defaultDecimalDigits;
    }
    if (result.decimalDigits != null) {
      result.minimumFractionDigits = result.decimalDigits!;
      result.maximumFractionDigits = result.decimalDigits!;
    }
  }

  /// Variable used in parsing prefixes and suffixes to keep track of
  /// whether or not we are in a quoted region.
  bool inQuote = false;

  /// Parse a prefix or suffix and return the prefix/suffix string. Note that
  /// this also may modify the state of [format].
  String _parseAffix() {
    var affix = StringBuffer();
    inQuote = false;
    while (parseCharacterAffix(affix) && pattern.moveNext()) {}
    return affix.toString();
  }

  /// Parse an individual character as part of a prefix or suffix.  Return true
  /// if we should continue to look for more affix characters, and false if
  /// we have reached the end.
  bool parseCharacterAffix(StringBuffer affix) {
    var ch = pattern.current;
    if (ch == null) return false;
    if (ch == QUOTE) {
      if (pattern.peek == QUOTE) {
        pattern.moveNext();
        affix.write(QUOTE); // 'don''t'
      } else {
        inQuote = !inQuote;
      }
      return true;
    }

    if (inQuote) {
      affix.write(ch);
    } else {
      switch (ch) {
        case PATTERN_DIGIT:
        case PATTERN_ZERO_DIGIT:
        case PATTERN_GROUPING_SEPARATOR:
        case PATTERN_DECIMAL_SEPARATOR:
        case PATTERN_SEPARATOR:
          return false;
        case PATTERN_CURRENCY_SIGN:
          // TODO(alanknight): Handle the local/global/portable currency signs
          affix.write(currencySymbol);
          break;
        case PATTERN_PERCENT:
          if (result.multiplier != 1 && result.multiplier != PERCENT_SCALE) {
            throw const FormatException('Too many percent/permill');
          }
          result.multiplier = PERCENT_SCALE;
          affix.write(symbols.PERCENT);
          break;
        case PATTERN_PER_MILLE:
          if (result.multiplier != 1 && result.multiplier != PER_MILLE_SCALE) {
            throw const FormatException('Too many percent/permill');
          }
          result.multiplier = PER_MILLE_SCALE;
          affix.write(symbols.PERMILL);
          break;
        default:
          affix.write(ch);
      }
    }
    return true;
  }

  /// Variables used in [_parseTrunk] and [parseTrunkCharacter].
  var decimalPos = -1;
  var digitLeftCount = 0;
  var zeroDigitCount = 0;
  var digitRightCount = 0;
  var groupingCount = -1;

  /// Parse the "trunk" portion of the pattern, the piece that doesn't include
  /// positive or negative prefixes or suffixes.
  String _parseTrunk() {
    var loop = true;
    var trunk = StringBuffer();
    while (pattern.current != null && loop) {
      loop = parseTrunkCharacter(trunk);
    }

    if (zeroDigitCount == 0 && digitLeftCount > 0 && decimalPos >= 0) {
      // Handle '###.###' and '###.' and '.###'
      // Handle '.###'
      var n = decimalPos == 0 ? 1 : decimalPos;
      digitRightCount = digitLeftCount - n;
      digitLeftCount = n - 1;
      zeroDigitCount = 1;
    }

    // Do syntax checking on the digits.
    if (decimalPos < 0 && digitRightCount > 0 ||
        decimalPos >= 0 &&
            (decimalPos < digitLeftCount ||
                decimalPos > digitLeftCount + zeroDigitCount) ||
        groupingCount == 0) {
      throw FormatException('Malformed pattern "${pattern.input}"');
    }
    var totalDigits = digitLeftCount + zeroDigitCount + digitRightCount;

    result.maximumFractionDigits =
        decimalPos >= 0 ? totalDigits - decimalPos : 0;
    if (decimalPos >= 0) {
      result.minimumFractionDigits =
          digitLeftCount + zeroDigitCount - decimalPos;
      if (result.minimumFractionDigits < 0) {
        result.minimumFractionDigits = 0;
      }
    }

    // The effectiveDecimalPos is the position the decimal is at or would be at
    // if there is no decimal. Note that if decimalPos<0, then digitTotalCount
    // == digitLeftCount + zeroDigitCount.
    var effectiveDecimalPos = decimalPos >= 0 ? decimalPos : totalDigits;
    result.minimumIntegerDigits = effectiveDecimalPos - digitLeftCount;
    if (result.useExponentialNotation) {
      result.maximumIntegerDigits =
          digitLeftCount + result.minimumIntegerDigits;

      // In exponential display, we need to at least show something.
      if (result.maximumFractionDigits == 0 &&
          result.minimumIntegerDigits == 0) {
        result.minimumIntegerDigits = 1;
      }
    }

    result.finalGroupingSize = max(0, groupingCount);
    if (!groupingSizeSetExplicitly) {
      result.groupingSize = result.finalGroupingSize;
    }
    result.decimalSeparatorAlwaysShown =
        decimalPos == 0 || decimalPos == totalDigits;

    return trunk.toString();
  }

  /// Parse an individual character of the trunk. Return true if we should
  /// continue to look for additional trunk characters or false if we have
  /// reached the end.
  bool parseTrunkCharacter(trunk) {
    var ch = pattern.current;
    switch (ch) {
      case PATTERN_DIGIT:
        if (zeroDigitCount > 0) {
          digitRightCount++;
        } else {
          digitLeftCount++;
        }
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case PATTERN_ZERO_DIGIT:
        if (digitRightCount > 0) {
          throw FormatException('Unexpected "0" in pattern "${pattern.input}');
        }
        zeroDigitCount++;
        if (groupingCount >= 0 && decimalPos < 0) {
          groupingCount++;
        }
        break;
      case PATTERN_GROUPING_SEPARATOR:
        if (groupingCount > 0) {
          groupingSizeSetExplicitly = true;
          result.groupingSize = groupingCount;
        }
        groupingCount = 0;
        break;
      case PATTERN_DECIMAL_SEPARATOR:
        if (decimalPos >= 0) {
          throw FormatException(
              'Multiple decimal separators in pattern "$pattern"');
        }
        decimalPos = digitLeftCount + zeroDigitCount + digitRightCount;
        break;
      case PATTERN_EXPONENT:
        trunk.write(ch);
        if (result.useExponentialNotation) {
          throw FormatException(
              'Multiple exponential symbols in pattern "$pattern"');
        }
        result.useExponentialNotation = true;
        result.minimumExponentDigits = 0;

        // exponent pattern can have a optional '+'.
        pattern.moveNext();
        var nextChar = pattern.current;
        if (nextChar == PATTERN_PLUS) {
          trunk.write(pattern.current);
          pattern.moveNext();
          result.useSignForPositiveExponent = true;
        }

        // Use lookahead to parse out the exponential part
        // of the pattern, then jump into phase 2.
        while (pattern.current == PATTERN_ZERO_DIGIT) {
          trunk.write(pattern.current);
          pattern.moveNext();
          result.minimumExponentDigits++;
        }

        if ((digitLeftCount + zeroDigitCount) < 1 ||
            result.minimumExponentDigits < 1) {
          throw FormatException('Malformed exponential pattern "$pattern"');
        }
        return false;
      default:
        return false;
    }
    trunk.write(ch);
    pattern.moveNext();
    return true;
  }
}

final _ln10 = log(10);
