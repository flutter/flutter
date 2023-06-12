// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library number_symbols;

// Suppress naming issues as changes would be breaking.
// ignore_for_file: avoid_types_as_parameter_names, non_constant_identifier_names

/// This holds onto information about how a particular locale formats
/// numbers. It contains strings for things like the decimal separator, digit to
/// use for "0" and infinity. We expect the data for instances to be generated
/// out of ICU or a similar reference source.
class NumberSymbols {
  final String NAME;
  final String DECIMAL_SEP,
      GROUP_SEP,
      PERCENT,
      ZERO_DIGIT,
      PLUS_SIGN,
      MINUS_SIGN,
      EXP_SYMBOL,
      PERMILL,
      INFINITY,
      NAN,
      DECIMAL_PATTERN,
      SCIENTIFIC_PATTERN,
      PERCENT_PATTERN,
      CURRENCY_PATTERN,
      DEF_CURRENCY_CODE;

  const NumberSymbols(
      {required this.NAME,
      required this.DECIMAL_SEP,
      required this.GROUP_SEP,
      required this.PERCENT,
      required this.ZERO_DIGIT,
      required this.PLUS_SIGN,
      required this.MINUS_SIGN,
      required this.EXP_SYMBOL,
      required this.PERMILL,
      required this.INFINITY,
      required this.NAN,
      required this.DECIMAL_PATTERN,
      required this.SCIENTIFIC_PATTERN,
      required this.PERCENT_PATTERN,
      required this.CURRENCY_PATTERN,
      required this.DEF_CURRENCY_CODE});

  String toString() => NAME;
}

/// A container class for SHORT, LONG, and SHORT CURRENCY patterns.
///
/// (This class' members contain more than just symbols: they contain the full
/// number formatting pattern.)
class CompactNumberSymbols {
  final Map<int, String> COMPACT_DECIMAL_SHORT_PATTERN;
  final Map<int, String>? COMPACT_DECIMAL_LONG_PATTERN;
  final Map<int, String> COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN;
  CompactNumberSymbols(
      {required this.COMPACT_DECIMAL_SHORT_PATTERN,
      this.COMPACT_DECIMAL_LONG_PATTERN,
      required this.COMPACT_DECIMAL_SHORT_CURRENCY_PATTERN});
}
