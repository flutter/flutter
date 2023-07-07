// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file should be imported, along with date_format.dart in order to read
/// locale data from files in the file system.

library date_symbol_data_file;

import 'package:path/path.dart' as path;

import 'date_symbols.dart';
import 'src/data/dates/locale_list.dart';
import 'src/date_format_internal.dart';
import 'src/file_data_reader.dart';
import 'src/lazy_locale_data.dart';

export 'src/data/dates/locale_list.dart';

/// This should be called for at least one [locale] before any date formatting
/// methods are called. It sets up the lookup for date symbols using [path].
/// The [path] parameter should end with a directory separator appropriate
/// for the platform.
Future<void> initializeDateFormatting(String locale, String filePath) {
  var reader = FileDataReader(path.join(filePath, 'symbols'));
  initializeDateSymbols(() => LazyLocaleData(
      reader, _createDateSymbol, availableLocalesForDateFormatting));
  var reader2 = FileDataReader(path.join(filePath, 'patterns'));
  initializeDatePatterns(() =>
      LazyLocaleData(reader2, (x) => x, availableLocalesForDateFormatting));
  return initializeIndividualLocaleDateFormatting((symbols, patterns) {
    return Future.wait(<Future<dynamic>>[
      symbols.initLocale(locale),
      patterns.initLocale(locale)
    ]);
  });
}

/// Defines how new date symbol entries are created.
DateSymbols _createDateSymbol(Map<dynamic, dynamic> map) =>
    DateSymbols.deserializeFromMap(map);
