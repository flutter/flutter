// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/number_symbols.dart';

import 'constants.dart' as constants;
import 'intl_stream.dart';
import 'number_format.dart';
import 'number_format_parser.dart';

///  A one-time object for parsing a particular numeric string. One-time here
/// means an instance can only parse one string. This is implemented by
/// transforming from a locale-specific format to one that the system can parse,
/// then calls the system parsing methods on it.
class NumberParser {
  /// The format for which we are parsing.
  final NumberFormat format;

  /// The text we are parsing.
  final String text;

  /// What we use to iterate over the input text.
  final IntlStream input;

  /// The result of parsing [text] according to [format]. Automatically
  /// populated in the constructor.
  num? value;

  /// The symbols used by our format.
  NumberSymbols get symbols => format.symbols;

  /// Where we accumulate the normalized representation of the number.
  final StringBuffer _normalized = StringBuffer();

  /// Did we see something that indicates this is, or at least might be,
  /// a positive number.
  bool gotPositive = false;

  /// Did we see something that indicates this is, or at least might be,
  /// a negative number.
  bool gotNegative = false;

  /// Did we see the required positive suffix at the end. Should
  /// match [gotPositive].
  bool gotPositiveSuffix = false;

  /// Did we see the required negative suffix at the end. Should
  /// match [gotNegative].
  bool gotNegativeSuffix = false;

  /// Should we stop parsing before hitting the end of the string.
  bool done = false;

  /// Have we already skipped over any required prefixes.
  bool prefixesSkipped = false;

  /// If the number is percent or permill, what do we divide by at the end.
  int scale = 1;

  String get _positivePrefix => format.positivePrefix;
  String get _negativePrefix => format.negativePrefix;
  String get _positiveSuffix => format.positiveSuffix;
  String get _negativeSuffix => format.negativeSuffix;
  int get _localeZero => format.localeZero;

  ///  Create a new [_NumberParser] on which we can call parse().
  NumberParser(this.format, this.text) : input = IntlStream(text) {
    scale = format.multiplier;
    value = parse();
  }

  ///  The strings we might replace with functions that return the replacement
  /// values. They are functions because we might need to check something
  /// in the context. Note that the ordering is important here. For example,
  /// `symbols.PERCENT` might be " %", and we must handle that before we
  /// look at an individual space.
  Map<String, Function> get replacements =>
      _replacements ??= _initializeReplacements();

  Map<String, Function>? _replacements;

  Map<String, Function> _initializeReplacements() => {
        symbols.DECIMAL_SEP: () => '.',
        symbols.EXP_SYMBOL: () => 'E',
        symbols.GROUP_SEP: handleSpace,
        symbols.PERCENT: () {
          scale = NumberFormatParser.PERCENT_SCALE;
          return '';
        },
        symbols.PERMILL: () {
          scale = NumberFormatParser.PER_MILLE_SCALE;
          return '';
        },
        ' ': handleSpace,
        '\u00a0': handleSpace,
        '+': () => '+',
        '-': () => '-',
      };

  void invalidFormat() =>
      throw FormatException('Invalid number: ${input.contents}');

  /// Replace a space in the number with the normalized form. If space is not
  /// a significant character (normally grouping) then it's just invalid. If it
  /// is the grouping character, then it's only valid if it's followed by a
  /// digit. e.g. '$12 345.00'
  void handleSpace() =>
      groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit ? '' : invalidFormat();

  /// Determine if a space is a valid character in the number. See
  /// [handleSpace].
  bool get groupingIsNotASpaceOrElseItIsSpaceFollowedByADigit {
    if (symbols.GROUP_SEP != '\u00a0' || symbols.GROUP_SEP != ' ') return true;
    var peeked = input.peek(symbols.GROUP_SEP.length + 1);
    return asDigit(peeked[peeked.length - 1]) != null;
  }

  /// Turn [char] into a number representing a digit, or null if it doesn't
  /// represent a digit in this locale.
  int? asDigit(String char) {
    var charCode = char.codeUnitAt(0);
    var digitValue = charCode - _localeZero;
    if (digitValue >= 0 && digitValue < 10) {
      return digitValue;
    } else {
      return null;
    }
  }

  /// Check to see if the input begins with either the positive or negative
  /// prefixes. Set the [gotPositive] and [gotNegative] variables accordingly.
  void checkPrefixes({bool skip = false}) {
    bool checkPrefix(String prefix) =>
        prefix.isNotEmpty && input.startsWith(prefix);

    // TODO(alanknight): There's a faint possibility of a bug here where
    // a positive prefix is followed by a negative prefix that's also a valid
    // part of the number, but that seems very unlikely.
    if (checkPrefix(_positivePrefix)) gotPositive = true;
    if (checkPrefix(_negativePrefix)) gotNegative = true;

    // The positive prefix might be a substring of the negative, in
    // which case both would match.
    if (gotPositive && gotNegative) {
      if (_positivePrefix.length > _negativePrefix.length) {
        gotNegative = false;
      } else if (_negativePrefix.length > _positivePrefix.length) {
        gotPositive = false;
      }
    }
    if (skip) {
      if (gotPositive) input.read(_positivePrefix.length);
      if (gotNegative) input.read(_negativePrefix.length);
    }
  }

  /// If the rest of our input is either the positive or negative suffix,
  /// set [gotPositiveSuffix] or [gotNegativeSuffix] accordingly.
  void checkSuffixes() {
    var remainder = input.rest();
    if (remainder == _positiveSuffix) gotPositiveSuffix = true;
    if (remainder == _negativeSuffix) gotNegativeSuffix = true;
  }

  /// We've encountered a character that's not a digit. Go through our
  /// replacement rules looking for how to handle it. If we see something
  /// that's not a digit and doesn't have a replacement, then we're done
  /// and the number is probably invalid.
  void processNonDigit() {
    // It might just be a prefix that we haven't skipped. We don't want to
    // skip them initially because they might also be semantically meaningful,
    // e.g. leading %. So we allow them through the loop, but only once.
    var foundAnInterpretation = false;
    if (input.index == 0 && !prefixesSkipped) {
      prefixesSkipped = true;
      checkPrefixes(skip: true);
      foundAnInterpretation = true;
    }

    for (var key in replacements.keys) {
      if (input.startsWith(key)) {
        _normalized.write(replacements[key]!());
        input.read(key.length);
        return;
      }
    }
    // We haven't found either of these things, this seems invalid.
    if (!foundAnInterpretation) {
      done = true;
    }
  }

  /// Parse [text] and return the resulting number. Throws [FormatException]
  /// if we can't parse it.
  num parse() {
    if (text == symbols.NAN) return 0.0 / 0.0;
    if (text == '$_positivePrefix${symbols.INFINITY}$_positiveSuffix') {
      return 1.0 / 0.0;
    }
    if (text == '$_negativePrefix${symbols.INFINITY}$_negativeSuffix') {
      return -1.0 / 0.0;
    }

    checkPrefixes();
    var parsed = parseNumber(input);

    if (gotPositive && !gotPositiveSuffix) invalidNumber();
    if (gotNegative && !gotNegativeSuffix) invalidNumber();
    if (!input.atEnd()) invalidNumber();

    return parsed;
  }

  /// The number is invalid, throw a [FormatException].
  void invalidNumber() =>
      throw FormatException('Invalid Number: ${input.contents}');

  /// Parse the number portion of the input, i.e. not any prefixes or suffixes,
  /// and assuming NaN and Infinity are already handled.
  num parseNumber(IntlStream input) {
    if (gotNegative) {
      _normalized.write('-');
    }
    while (!done && !input.atEnd()) {
      var digit = asDigit(input.peek());
      if (digit != null) {
        _normalized.writeCharCode(constants.asciiZeroCodeUnit + digit);
        input.next();
      } else {
        processNonDigit();
      }
      checkSuffixes();
    }

    var normalizedText = _normalized.toString();
    num? parsed = int.tryParse(normalizedText);
    parsed ??= double.parse(normalizedText);
    return parsed / scale;
  }
}
