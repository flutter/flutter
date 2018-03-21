// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This program generates a Dart "localizations" Map definition that combines
// the contents of the arb files. The map can be used to lookup a localized
// string: `localizations[localeString][resourceId]`.
//
// The *.arb files are in packages/flutter_localizations/lib/src/l10n.
//
// The arb (JSON) format files must contain a single map indexed by locale.
// Each map value is itself a map with resource identifier keys and localized
// resource string values.
//
// The arb filenames are expected to have the form "material_(\w+)\.arb", where
// the group following "_" identifies the language code and the country code,
// e.g. "material_en.arb" or "material_en_GB.arb". In most cases both codes are
// just two characters.
//
// This app is typically run by hand when a module's .arb files have been
// updated.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// The following outputs the generated Dart code to the console as a dry run:
//
// ```
// dart dev/tools/gen_localizations.dart
// ```
//
// If the data looks good, use the `-w` option to overwrite the
// packages/flutter_localizations/lib/src/l10n/localizations.dart file:
//
// ```
// dart dev/tools/gen_localizations.dart --overwrite
// ```

import 'dart:convert' show json;
import 'dart:io';

import 'package:path/path.dart' as pathlib;

import 'localizations_utils.dart';
import 'localizations_validator.dart';

const String outputHeader = '''
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use:
// @(regenerate)
''';

/// Maps locales to resource key/value pairs.
final Map<String, Map<String, String>> localeToResources = <String, Map<String, String>>{};

/// Maps locales to resource attributes.
///
/// See also https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification#resource-attributes
final Map<String, Map<String, dynamic>> localeToResourceAttributes = <String, Map<String, dynamic>>{};

// Return s as a Dart-parseable raw string in single or double quotes. Expand double quotes:
// foo => r'foo'
// foo "bar" => r'foo "bar"'
// foo 'bar' => r'foo ' "'" r'bar' "'"
String generateString(String s) {
  if (!s.contains("'"))
    return "r'$s'";

  final StringBuffer output = new StringBuffer();
  bool started = false; // Have we started writing a raw string.
  for (int i = 0; i < s.length; i++) {
    if (s[i] == "'") {
      if (started)
        output.write("'");
      output.write(' "\'" ');
      started = false;
    } else if (!started) {
      output.write("r'${s[i]}");
      started = true;
    } else {
      output.write(s[i]);
    }
  }
  if (started)
    output.write("'");
  return output.toString();
}

String generateTranslationBundles() {
  final StringBuffer output = new StringBuffer();

  final Map<String, List<String>> languageToLocales = <String, List<String>>{};
  final Set<String> allResourceIdentifiers = new Set<String>();
  for (String locale in localeToResources.keys.toList()..sort()) {
    final List<String> codes = locale.split('_'); // [language, country]
    assert(codes.length == 1 || codes.length == 2);
    languageToLocales[codes[0]] ??= <String>[];
    languageToLocales[codes[0]].add(locale);
    allResourceIdentifiers.addAll(localeToResources[locale].keys);
  }

  // Generate the TranslationsBundle base class. It contains one getter
  // per resource identifier found in any of the .arb files.
  //
  // class TranslationsBundle {
  //   const TranslationsBundle(this.parent);
  //   final TranslationsBundle parent;
  //   String get scriptCategory => parent?.scriptCategory;
  //   ...
  // }
  output.writeln('''
// The TranslationBundle subclasses defined here encode all of the translations
// found in the flutter_localizations/lib/src/l10n/*.arb files.
//
// The [MaterialLocalizations] class uses the (generated)
// translationBundleForLocale() function to look up a const TranslationBundle
// instance for a locale.

// ignore_for_file: public_member_api_docs

import \'dart:ui\' show Locale;

class TranslationBundle {
  const TranslationBundle(this.parent);
  final TranslationBundle parent;''');
  for (String key in allResourceIdentifiers)
    output.writeln('  String get $key => parent?.$key;');
  output.writeln('''
}''');

  // Generate one private TranslationBundle subclass per supported
  // language. Each of these classes overrides every resource identifier
  // getter. For example:
  //
  // class _Bundle_en extends TranslationBundle {
  //   const _Bundle_en() : super(null);
  //   @override String get scriptCategory => r'English-like';
  //   ...
  // }
  for (String language in languageToLocales.keys) {
    final Map<String, String> resources = localeToResources[language];
    output.writeln('''

// ignore: camel_case_types
class _Bundle_$language extends TranslationBundle {
  const _Bundle_$language() : super(null);''');
    for (String key in resources.keys) {
      final String value = generateString(resources[key]);
      output.writeln('''
  @override String get $key => $value;''');
    }
   output.writeln('''
}''');
  }

  // Generate one private TranslationBundle subclass for each locale
  // with a country code. The parent of these subclasses is a const
  // instance of a translation bundle for the same locale, but without
  // a country code. These subclasses only override getters that
  // return different value than the parent class, or a resource identifier
  // that's not defined in the parent class. For example:
  //
  // class _Bundle_en_CA extends TranslationBundle {
  //   const _Bundle_en_CA() : super(const _Bundle_en());
  //   @override String get licensesPageTitle => r'Licences';
  //   ...
  // }
  for (String language in languageToLocales.keys) {
    final Map<String, String> languageResources = localeToResources[language];
    for (String localeName in languageToLocales[language]) {
      if (localeName == language)
        continue;
      final Map<String, String> localeResources = localeToResources[localeName];
      output.writeln('''

// ignore: camel_case_types
class _Bundle_$localeName extends TranslationBundle {
  const _Bundle_$localeName() : super(const _Bundle_$language());''');
      for (String key in localeResources.keys) {
        if (languageResources[key] == localeResources[key])
          continue;
        final String value = generateString(localeResources[key]);
        output.writeln('''
  @override String get $key => $value;''');
      }
     output.writeln('''
}''');
    }
  }

  // Generate the translationBundleForLocale function. Given a Locale
  // it returns the corresponding const TranslationBundle.
  output.writeln('''

TranslationBundle translationBundleForLocale(Locale locale) {
  switch (locale.languageCode) {''');
  for (String language in languageToLocales.keys) {
    if (languageToLocales[language].length == 1) {
      output.writeln('''
    case \'$language\':
      return const _Bundle_${languageToLocales[language][0]}();''');
    } else {
      output.writeln('''
    case \'$language\': {
      switch (locale.toString()) {''');
      for (String localeName in languageToLocales[language]) {
        if (localeName == language)
          continue;
        output.writeln('''
        case \'$localeName\':
          return const _Bundle_$localeName();''');
      }
      output.writeln('''
      }
      return const _Bundle_$language();
    }''');
    }
  }
  output.writeln('''
  }
  return const TranslationBundle(null);
}''');

  return output.toString();
}

void processBundle(File file, String locale) {
  localeToResources[locale] ??= <String, String>{};
  localeToResourceAttributes[locale] ??= <String, dynamic>{};
  final Map<String, String> resources = localeToResources[locale];
  final Map<String, dynamic> attributes = localeToResourceAttributes[locale];
  final Map<String, dynamic> bundle = json.decode(file.readAsStringSync());
  for (String key in bundle.keys) {
    // The ARB file resource "attributes" for foo are called @foo.
    if (key.startsWith('@'))
      attributes[key.substring(1)] = bundle[key];
    else
      resources[key] = bundle[key];
  }
}

void main(List<String> rawArgs) {
  checkCwdIsRepoRoot('gen_localizations');
  final GeneratorOptions options = parseArgs(rawArgs);

  // filenames are assumed to end in "prefix_lc.arb" or "prefix_lc_cc.arb", where prefix
  // is the 2nd command line argument, lc is a language code and cc is the country
  // code. In most cases both codes are just two characters.

  final Directory directory = new Directory(pathlib.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n'));
  final RegExp filenameRE = new RegExp(r'material_(\w+)\.arb$');

  exitWithError(
    validateEnglishLocalizations(new File(pathlib.join(directory.path, 'material_en.arb')))
  );

  for (FileSystemEntity entity in directory.listSync()) {
    final String path = entity.path;
    if (FileSystemEntity.isFileSync(path) && filenameRE.hasMatch(path)) {
      final String locale = filenameRE.firstMatch(path)[1];
      processBundle(new File(path), locale);
    }
  }

  exitWithError(
    validateLocalizations(localeToResources, localeToResourceAttributes)
  );

  const String regenerate = 'dart dev/tools/gen_localizations.dart --overwrite';
  final StringBuffer buffer = new StringBuffer();
  buffer.writeln(outputHeader.replaceFirst('@(regenerate)', regenerate));
  buffer.write(generateTranslationBundles());

  if (options.writeToFile) {
    final File localizationsFile = new File(pathlib.join(directory.path, 'localizations.dart'));
    localizationsFile.writeAsStringSync(buffer.toString());
  } else {
    stdout.write(buffer.toString());
  }
}
