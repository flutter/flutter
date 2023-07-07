// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API to allow setting Date/Time formatting in a custom way.
///
/// It does not actually provide any data - that's left to the user of the API.
import 'date_symbols.dart';
import 'src/date_format_internal.dart';

/// This should be called for at least one [locale] before any date
/// formatting methods are called.
///
/// It sets up the lookup for date information. The [symbols] argument should
/// contain a populated [DateSymbols], and [patterns] should contain a Map for
/// the same locale from skeletons to the specific format strings. For examples,
/// see date_time_patterns.dart.
///
/// If data for this locale has already been initialized it will be overwritten.
void initializeDateFormattingCustom(
    {String? locale, DateSymbols? symbols, Map<String, String>? patterns}) {
  initializeDateSymbols(_emptySymbols);
  initializeDatePatterns(_emptyPatterns);
  if (symbols == null) {
    throw ArgumentError('Missing DateTime formatting symbols');
  }
  if (patterns == null) {
    throw ArgumentError('Missing DateTime formatting patterns');
  }
  if (locale != symbols.NAME) {
    throw ArgumentError.value(
        [locale, symbols.NAME], 'Locale does not match symbols.NAME');
  }
  dateTimeSymbols[symbols.NAME] = symbols;
  dateTimePatterns[symbols.NAME] = patterns;
}

Map<String, DateSymbols> _emptySymbols() => {};
Map<String, Map<String, String>> _emptyPatterns() => {};
