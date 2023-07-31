// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9

/// A utility program to take locale data represented as a Dart map whose keys
/// are locale names and write it into individual JSON files named by locale.
/// This should be run any time the locale data changes.
///
/// The files are written under 'data/dates', in two subdirectories, 'symbols'
/// and 'patterns'. In 'data/dates' it will also generate 'locale_list.dart',
/// which is sourced by the date_symbol_data... files.
import 'dart:convert';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../test/data_directory.dart';

void main() {
  initializeDateFormatting('en_IGNORED', null);
  writeSymbolData();
  writePatternData();
  writeLocaleList();
}

void writeLocaleList() {
  var file = File(path.join(dataDirectory, 'locale_list.dart'));
  var output = file.openWrite();
  output.write(
      '// Copyright (c) 2012, the Dart project authors.  Please see the '
      'AUTHORS file\n// for details. All rights reserved. Use of this source'
      'code is governed by a\n// BSD-style license that can be found in the'
      ' LICENSE file.\n\n'
      '/// Hard-coded list of all available locales for dates.\n');
  output.write('final availableLocalesForDateFormatting = const [');
  var allLocales = DateFormat.allLocalesWithSymbols();
  for (var locale in allLocales) {
    output.write("'$locale'");
    if (locale == allLocales.last) {
      output.write('];');
    } else {
      output.write(',\n    ');
    }
  }
  output.close();
}

void writeSymbolData() {
  dateTimeSymbolMap().forEach(writeSymbols);
}

void writePatternData() {
  dateTimePatternMap().forEach(writePatterns);
}

void writeSymbols(locale, symbols) {
  var file = File(path.join(dataDirectory, 'symbols', '$locale.json'));
  var output = file.openWrite();
  writeToJSON(symbols, output);
  output.close();
}

void writePatterns(locale, patterns) {
  var file = File(path.join(dataDirectory, 'patterns', '$locale.json'));
  file.openWrite()
    ..write(json.encode(patterns))
    ..close();
}

void writeToJSON(dynamic data, IOSink out) {
  out.write(json.encode(data.serializeToMap()));
}
