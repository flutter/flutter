// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This program extracts localized date symbols and patterns from the intl
/// package for the subset of locales supported by the flutter_localizations
/// package.
///
/// The extracted data is written into:
///   packages/flutter_localizations/lib/src/l10n/generated_date_localizations.dart
///
/// ## Usage
///
/// Run this program from the root of the git repository.
///
/// The following outputs the generated Dart code to the console as a dry run:
///
/// ```
/// dart dev/tools/localization/gen_date_localizations.dart
/// ```
///
/// If the data looks good, use the `--overwrite` option to overwrite the
/// lib/src/l10n/date_localizations.dart file:
///
/// ```
/// dart dev/tools/localization/gen_date_localizations.dart --overwrite
/// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'localizations_utils.dart';

const String _kCommandName = 'gen_date_localizations.dart';

Future<void> main(List<String> rawArgs) async {
  checkCwdIsRepoRoot(_kCommandName);

  final bool writeToFile = parseArgs(rawArgs).writeToFile;

  final File dotPackagesFile = File(path.join('packages', 'flutter_localizations', '.packages'));
  final bool dotPackagesExists = dotPackagesFile.existsSync();

  if (!dotPackagesExists) {
    exitWithError(
      'File not found: ${dotPackagesFile.path}. $_kCommandName must be run '
      'after a successful "flutter update-packages".'
    );
  }

  final String pathToIntl = dotPackagesFile
    .readAsStringSync()
    .split('\n')
    .firstWhere(
      (String line) => line.startsWith('intl:'),
      orElse: () {
        exitWithError('intl dependency not found in ${dotPackagesFile.path}');
        return null; // unreachable
      },
    )
    .split(':')
    .last;

  final Directory dateSymbolsDirectory = Directory(path.join(pathToIntl, 'src', 'data', 'dates', 'symbols'));
  final Map<String, File> symbolFiles = _listIntlData(dateSymbolsDirectory);
  final Directory datePatternsDirectory = Directory(path.join(pathToIntl, 'src', 'data', 'dates', 'patterns'));
  final Map<String, File> patternFiles = _listIntlData(datePatternsDirectory);
  final StringBuffer buffer = StringBuffer();

  buffer.writeln(
'''
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate run (omit --overwrite to print to console instead of the file):
// dart --enable-asserts dev/tools/localization/gen_date_localizations.dart --overwrite

'''
);
  buffer.writeln('''
/// The subset of date symbols supported by the intl package which are also
/// supported by flutter_localizations.''');
  buffer.writeln('const Map<String, dynamic> dateSymbols = <String, dynamic> {');
  symbolFiles.forEach((String locale, File data) {
    if (_supportedLocales().contains(locale))
      buffer.writeln(_jsonToMapEntry(locale, json.decode(data.readAsStringSync())));
  });
  buffer.writeln('};');

  // Code that uses datePatterns expects it to contain values of type
  // Map<String, String> not Map<String, dynamic>.
  buffer.writeln('''
/// The subset of date patterns supported by the intl package which are also
/// supported by flutter_localizations.''');
  buffer.writeln('const Map<String, Map<String, String>> datePatterns = <String, Map<String, String>> {');
  patternFiles.forEach((String locale, File data) {
    if (_supportedLocales().contains(locale)) {
      final Map<String, dynamic> patterns = json.decode(data.readAsStringSync());
      buffer.writeln("'$locale': <String, String>{");
      patterns.forEach((String key, dynamic value) {
        assert(value is String);
        buffer.writeln(_jsonToMapEntry(key, value));
      });
      buffer.writeln('},');
    }
  });
  buffer.writeln('};');

  if (writeToFile) {
    final File dateLocalizationsFile = File(path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n', 'generated_date_localizations.dart'));
    dateLocalizationsFile.writeAsStringSync(buffer.toString());
    Process.runSync(path.join('bin', 'cache', 'dart-sdk', 'bin', 'dartfmt'), <String>[
      '-w',
      dateLocalizationsFile.path,
    ]);
  } else {
    print(buffer);
  }
}

String _jsonToMapEntry(String key, dynamic value) {
  return "'$key': ${_jsonToMap(value)},";
}

String _jsonToMap(dynamic json) {
  if (json == null || json is num || json is bool)
    return '$json';

  if (json is String) {
    if (json.contains("'"))
      return 'r"""$json"""';
    else
      return "r'''$json'''";
  }

  if (json is Iterable)
    return '<dynamic>[${json.map<String>(_jsonToMap).join(',')}]';

  if (json is Map<String, dynamic>) {
    final StringBuffer buffer = StringBuffer('<String, dynamic>{');
    json.forEach((String key, dynamic value) {
      buffer.writeln(_jsonToMapEntry(key, value));
    });
    buffer.write('}');
    return buffer.toString();
  }

  throw 'Unsupported JSON type ${json.runtimeType} of value $json.';
}

Set<String> _supportedLocales() {
  final Set<String> supportedLocales = <String>{};
  final RegExp filenameRE = RegExp(r'(?:material|cupertino)_(\w+)\.arb$');
  final Directory supportedLocalesDirectory = Directory(path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n'));
  for (FileSystemEntity entity in supportedLocalesDirectory.listSync()) {
    final String filePath = entity.path;
    if (FileSystemEntity.isFileSync(filePath) && filenameRE.hasMatch(filePath))
      supportedLocales.add(filenameRE.firstMatch(filePath)[1]);
  }
  return supportedLocales;
}

Map<String, File> _listIntlData(Directory directory) {
  final Map<String, File> localeFiles = <String, File>{};
  for (FileSystemEntity entity in directory.listSync()) {
    final String filePath = entity.path;
    if (FileSystemEntity.isFileSync(filePath) && filePath.endsWith('.json')) {
      final String locale = path.basenameWithoutExtension(filePath);
      localeFiles[locale] = entity;
    }
  }

  final List<String> locales = localeFiles.keys.toList(growable: false);
  locales.sort();
  return Map<String, File>.fromIterable(locales, value: (dynamic locale) => localeFiles[locale]);
}
