// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file should be imported, along with date_format.dart in order to read
/// locale data via http requests to a web server..
library date_symbol_data_http_request;

import 'date_symbols.dart';
import 'intl.dart';
import 'src/data/dates/locale_list.dart';
import 'src/date_format_internal.dart';
import 'src/http_request_data_reader.dart';
import 'src/lazy_locale_data.dart';

export 'src/data/dates/locale_list.dart';

/// This should be called for at least one [locale] before any date formatting
/// methods are called. It sets up the lookup for date symbols using [url].
/// The [url] parameter should end with a "/". For example,
///   "http://localhost:8000/dates/"
Future<void> initializeDateFormatting(String locale, String url) {
  var reader = HttpRequestDataReader('${url}symbols/');
  initializeDateSymbols(() => LazyLocaleData(
      reader, _createDateSymbol, availableLocalesForDateFormatting));
  var reader2 = HttpRequestDataReader('${url}patterns/');
  initializeDatePatterns(() =>
      LazyLocaleData(reader2, (x) => x, availableLocalesForDateFormatting));
  var actualLocale =
      Intl.verifiedLocale(locale, availableLocalesForDateFormatting.contains);
  return initializeIndividualLocaleDateFormatting((symbols, patterns) {
    return Future.wait(<Future<List<dynamic>>>[
      symbols.initLocale(actualLocale),
      patterns.initLocale(actualLocale)
    ]);
  });
}

/// Defines how new date symbol entries are created.
DateSymbols _createDateSymbol(Map<dynamic, dynamic> map) =>
    DateSymbols.deserializeFromMap(map);
