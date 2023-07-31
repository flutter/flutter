// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test date formatting and parsing using custom locale data, which we get
/// from the local copy.

import 'package:intl/date_symbol_data_local.dart' as local_symbols;
import 'package:intl/date_time_patterns.dart' as local_patterns;
import 'package:intl/date_symbol_data_custom.dart';

import 'date_time_format_test_stub.dart';

void main() {
  var symbols = local_symbols.dateTimeSymbolMap();
  var patterns = local_patterns.dateTimePatternMap();
  var locales = <String>[];
  symbols.keys.take(10).forEach((locale) => locales.add(locale));
  // Force inclusion of locales that are hard-coded in tests.
  var requiredLocales = ['en_US', 'de', 'fr', 'ja', 'el', 'de_AT'];
  locales.addAll(requiredLocales);
  for (var locale in locales) {
    print('initializing $locale');
    initializeDateFormattingCustom(
        locale: locale, symbols: symbols[locale], patterns: patterns[locale]);
  }
  runWith(() => locales, null, nullInitialization);
}

Future<void> nullInitialization(String a, String b) => Future.value();
