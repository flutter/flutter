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
  //Initialize symbols
  var symbolReader = HttpRequestDataReader('${url}symbols/');
  LazyLocaleData symbolsInitializer() => LazyLocaleData(
        symbolReader,
        _createDateSymbol,
        availableLocalesForDateFormatting,
      );
  initializeDateSymbols(symbolsInitializer);

  //Initialize patterns
  var patternsReader = HttpRequestDataReader('${url}patterns/');
  LazyLocaleData patternsInitializer() => LazyLocaleData(
        patternsReader,
        (x) => x,
        availableLocalesForDateFormatting,
      );
  initializeDatePatterns(patternsInitializer);

  var actualLocale = Intl.verifiedLocale(
    locale,
    availableLocalesForDateFormatting.contains,
  )!;

  //Initialize locale for both symbols and patterns
  Future<List<void>> initLocale(
    LazyLocaleData symbols,
    LazyLocaleData patterns,
  ) {
    return Future.wait([
      symbols.initLocale(actualLocale),
      patterns.initLocale(actualLocale),
    ]);
  }

  return initializeIndividualLocaleDateFormatting(initLocale);
}

/// Defines how new date symbol entries are created.
DateSymbols _createDateSymbol(Map<dynamic, dynamic> map) =>
    DateSymbols.deserializeFromMap(map);
