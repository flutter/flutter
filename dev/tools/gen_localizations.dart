// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Given a directory that contains localized ".arb" (application resource
// bundle) files, generates a Dart "localizations" Map definition that combines
// the contents of the arb files. The map can be used to lookup a localized
// string: localizations[localeString][resourceId].
//
// See *.arb and localizations.dart in packages/flutter/lib/src/material/i18n/.
//
// The arb (JSON) format files must contain a single map indexed by locale.
// Each map value is itself a map with resource identifier keys and localized
// resource string values.
//
// The arb filenames are assumed to end in "prefix_lc.arb" or "prefix_lc_cc.arb",
// where prefix is the 2nd command line argument, lc is a language code and cc
// is the country code. In most cases both codes are just two characters. A typical
// filename would be "material_en.arb".
//
// This app is typically run by hand when a module's .arb files have been
// updated.
//
// Usage: dart gen_localizations.dart directory prefix

import 'dart:convert' show JSON;
import 'dart:io';

const String outputHeader = '''
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use:
// @(regenerate)
''';

final Map<String, Map<String, String>> localeToResources = <String, Map<String, String>>{};

// Return s as a Dart-parseable raw string in double quotes. Expand double quotes:
// foo => r"foo"
// foo "bar" => r"foo " '"' r"bar" '"'
String generateString(String s) {
  if (!s.contains('"'))
    return 'r"$s"';

  final StringBuffer output = new StringBuffer();
  bool started = false; // Have we started writing a raw string.
  for (int i = 0; i < s.length; i++) {
    if (s[i] == '"') {
      if (started)
        output.write('"');
      output.write(' \'"\' ');
      started = false;
    } else if (!started) {
      output.write('r"${s[i]}');
      started = true;
    } else {
      output.write(s[i]);
    }
  }
  if (started)
    output.write('"');
  return output.toString();
}

String generateLocalizationsMap() {
  final StringBuffer output = new StringBuffer();

  output.writeln('''
/// Maps from [Locale.languageCode] to a map that contains the localized strings
/// for that locale.
///
/// This variable is used by [MaterialLocalizations].
const Map<String, Map<String, String>> localizations = const <String, Map<String, String>> {''');

  final String lastLocale = localeToResources.keys.last;
  for (String locale in localeToResources.keys) {
    output.writeln('  "$locale": const <String, String>{');

    final Map<String, String> resources = localeToResources[locale];
    final String lastName = resources.keys.last;
    for (String name in resources.keys) {
      final String comma = name == lastName ? "" : ",";
      final String value = generateString(resources[name]);
      output.writeln('    "$name": $value$comma');
    }
    final String comma = locale == lastLocale ? "" : ",";
    output.writeln('  }$comma');
  }

  output.writeln('};');
  return output.toString();
}

void processBundle(File file, String locale) {
  localeToResources[locale] ??= <String, String>{};
  final Map<String, String> resources = localeToResources[locale];
  final Map<String, dynamic> bundle = JSON.decode(file.readAsStringSync());
  for (String key in bundle.keys) {
    // The ARB file resource "attributes" for foo are called @foo.
    if (key.startsWith('@'))
      continue;
    resources[key] = bundle[key];
  }
}

void main(List<String> args) {
  if (args.length != 2)
    stderr.writeln('Usage: dart gen_localizations.dart directory prefix');

  // filenames are assumed to end in "prefix_lc.arb" or "prefix_lc_cc.arb", where prefix
  // is the 2nd command line argument, lc is a language code and cc is the country
  // code. In most cases both codes are just two characters.

  final Directory directory = new Directory(args[0]);
  final String prefix = args[1];
  final RegExp filenameRE = new RegExp('${prefix}_(\\w+)\\.arb\$');

  for (FileSystemEntity entity in directory.listSync()) {
    final String path = entity.path;
    if (FileSystemEntity.isFileSync(path) && filenameRE.hasMatch(path)) {
      final String locale = filenameRE.firstMatch(path)[1];
      processBundle(new File(path), locale);
    }
  }

  final String regenerate = 'dart gen_localizations ${directory.path} ${args[1]}';
  print(outputHeader.replaceFirst('@(regenerate)', regenerate));
  print(generateLocalizationsMap());
}
