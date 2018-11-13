// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This program generates a getTranslation() function that looks up the
// translations contained by the arb files. The returned value is an
// instance of GlobalMaterialLocalizations that corresponds to a single
// locale.
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
// If the data looks good, use the `-w` or `--overwrite` option to overwrite the
// packages/flutter_localizations/lib/src/l10n/localizations.dart file:
//
// ```
// dart dev/tools/gen_localizations.dart --overwrite
// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:meta/meta.dart';

import 'localizations_utils.dart';
import 'localizations_validator.dart';

const String outputHeader = '''
// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use:
// @(regenerate)

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../material_localizations.dart';
''';

/// Maps locales to resource key/value pairs.
final Map<LocaleInfo, Map<String, String>> localeToResources = <LocaleInfo, Map<String, String>>{};

/// Maps locales to resource key/attributes pairs.
///
/// See also: <https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification#resource-attributes>
final Map<LocaleInfo, Map<String, dynamic>> localeToResourceAttributes = <LocaleInfo, Map<String, dynamic>>{};

/// Set that holds the locales that were assumed from the existing locales.
///
/// For example, when the data lacks data for zh_Hant, we will use the data of
/// the first Hant Chinese locale as a default by repeating the data. If an
/// explicit match is later found, we can reference this set to see if we should
/// overwrite the existing assumed data.
final Set<LocaleInfo> assumedLocales = Set<LocaleInfo>();

/// Return `s` as a Dart-parseable raw string in single or double quotes.
///
/// Double quotes are expanded:
///
/// ```
/// foo => r'foo'
/// foo "bar" => r'foo "bar"'
/// foo 'bar' => r'foo ' "'" r'bar' "'"
/// ```
String generateString(String s) {
  if (!s.contains("'"))
    return "r'$s'";

  final StringBuffer output = StringBuffer();
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

/// This is the core of this script; it generates the code used for translations.
String generateTranslationBundles() {
  final StringBuffer output = StringBuffer();
  final StringBuffer supportedLocales = StringBuffer();

  final Map<String, List<LocaleInfo>> languageToLocales = <String, List<LocaleInfo>>{};
  final Map<String, Set<String>> languageToScriptCodes = <String, Set<String>>{};
  // Used to calculate if there are any corresponding countries for a given language and script.
  final Map<LocaleInfo, Set<String>> languageAndScriptToCountryCodes = <LocaleInfo, Set<String>>{};
  final Set<String> allResourceIdentifiers = Set<String>();
  for (LocaleInfo locale in localeToResources.keys.toList()..sort()) {
    if (locale.scriptCode != null) {
      languageToScriptCodes[locale.languageCode] ??= Set<String>();
      languageToScriptCodes[locale.languageCode].add(locale.scriptCode);
    }
    if (locale.countryCode != null && locale.scriptCode != null) {
      final LocaleInfo key = LocaleInfo.fromString(locale.languageCode + '_' + locale.scriptCode);
      languageAndScriptToCountryCodes[key] ??= Set<String>();
      languageAndScriptToCountryCodes[key].add(locale.countryCode);
    }
    languageToLocales[locale.languageCode] ??= <LocaleInfo>[];
    languageToLocales[locale.languageCode].add(locale);
    allResourceIdentifiers.addAll(localeToResources[locale].keys);
  }

  output.writeln('''
// The classes defined here encode all of the translations found in the
// `flutter_localizations/lib/src/l10n/*.arb` files.
//
// These classes are constructed by the [getTranslation] method at the bottom of
// this file, and used by the [_MaterialLocalizationsDelegate.load] method defined
// in `flutter_localizations/lib/src/material_localizations.dart`.''');

  // We generate one class per supported language (e.g.
  // `MaterialLocalizationEn`). These implement everything that is needed by
  // GlobalMaterialLocalizations.

  // We also generate one subclass for each locale with a script code (e.g.
  // `MaterialLocalizationZhHant`). Their superclasses are the aforementioned
  // language classes for the same locale but without a script code (e.g.
  // `MaterialLocalizationZh`).

  // We also generate one subclass for each locale with a country code (e.g.
  // `MaterialLocalizationEnGb`). Their superclasses are the aforementioned
  // language classes for the same locale but without a country code (e.g.
  // `MaterialLocalizationEn`).

  // If scriptCodes for a language are defined, we expect a scriptCode to be
  // defined for locales that contain a countryCode. The superclass becomes
  // the script sublcass (e.g. `MaterialLocalizationZhHant`) and the generated
  // subclass will also contain the script code (e.g. `MaterialLocalizationZhHantTW`).

  // When scriptCodes are not defined for languages that use scriptCodes to distinguish
  // between significantly differing scripts, we assume the scriptCodes in the
  // [LocaleInfo.fromString] factory and add it to the [LocaleInfo]. We then generate
  // the script classes based on the first locale that we assume to use the script.

  final List<String> allKeys = allResourceIdentifiers.toList()..sort();
  final List<String> languageCodes = languageToLocales.keys.toList()..sort();
  final LocaleInfo canonicalLocale = LocaleInfo.fromString('en');
  for (String languageName in languageCodes) {
    final LocaleInfo languageLocale = LocaleInfo.fromString(languageName);
    writeClassHeader(output, languageLocale, 'GlobalMaterialLocalizations');
    final Map<String, String> languageResources = localeToResources[languageLocale];
    for (String key in allKeys) {
      final Map<String, dynamic> attributes = localeToResourceAttributes[canonicalLocale][key];
      output.writeln(generateGetter(key, languageResources[key], attributes));
    }
    output.writeln('}');
    int countryCodeCount = 0;
    int scriptCodeCount = 0;
    if (languageToScriptCodes.containsKey(languageName)) {
      scriptCodeCount = languageToScriptCodes[languageName].length;
      // Language has scriptCodes, so we need to properly fallback countries to corresponding
      // script default values before language default values.
      for (String scriptCode in languageToScriptCodes[languageName]) {
        final LocaleInfo scriptBaseLocale = LocaleInfo.fromString(languageName + '_' + scriptCode);
        writeClassHeader(output, scriptBaseLocale, 'MaterialLocalization${camelCase(languageLocale)}');
        final Map<String, String> scriptResources = localeToResources[scriptBaseLocale];
        for (String key in scriptResources.keys) {
          if (languageResources[key] == scriptResources[key])
            continue;
          final Map<String, dynamic> attributes = localeToResourceAttributes[canonicalLocale][key];
          output.writeln(generateGetter(key, scriptResources[key], attributes));
        }
        output.writeln('}');

        final List<LocaleInfo> localeCodes = languageToLocales[languageName]..sort();
        for (LocaleInfo locale in localeCodes) {
          if (locale.originalString == languageName)
            continue;
          if (locale.originalString == languageName + '_' + scriptCode)
            continue;
          if (locale.scriptCode != scriptCode)
            continue;
          countryCodeCount += 1;
          writeClassHeader(output, locale, 'MaterialLocalization${camelCase(scriptBaseLocale)}');
          final Map<String, String> localeResources = localeToResources[locale];
          for (String key in localeResources.keys) {
            // When script fallback contains the key, we compare to it instead of language fallback.
            if (scriptResources.containsKey(key) ? scriptResources[key] == localeResources[key] : languageResources[key] == localeResources[key])
              continue;
            final Map<String, dynamic> attributes = localeToResourceAttributes[canonicalLocale][key];
            output.writeln(generateGetter(key, localeResources[key], attributes));
          }
         output.writeln('}');
        }
      }
    } else {
      // No scriptCode. Here, we do not compare against script default (because it
      // doesn't exist).
      final List<LocaleInfo> localeCodes = languageToLocales[languageName]..sort();
      for (LocaleInfo locale in localeCodes) {
        if (locale.originalString == languageName)
          continue;
        countryCodeCount += 1;
        final Map<String, String> localeResources = localeToResources[locale];
        writeClassHeader(output, locale, 'MaterialLocalization${camelCase(languageLocale)}');
        for (String key in localeResources.keys) {
          if (languageResources[key] == localeResources[key])
            continue;
          final Map<String, dynamic> attributes = localeToResourceAttributes[canonicalLocale][key];
          output.writeln(generateGetter(key, localeResources[key], attributes));
        }
       output.writeln('}');
      }
    }
    final String scriptCodeMessage = scriptCodeCount == 0 ? '' : ' and $scriptCodeCount script' + (scriptCodeCount == 1 ? '' : 's');
    if (countryCodeCount == 0) {
      if (scriptCodeCount == 0)
        supportedLocales.writeln('///  * `$languageName` - ${describeLocale(languageName)}');
      else
        supportedLocales.writeln('///  * `$languageName` - ${describeLocale(languageName)} (plus $scriptCodeCount script' + (scriptCodeCount == 1 ? '' : 's') + ')');

    } else if (countryCodeCount == 1) {
      supportedLocales.writeln('///  * `$languageName` - ${describeLocale(languageName)} (plus one country variation$scriptCodeMessage)');
    } else {
      supportedLocales.writeln('///  * `$languageName` - ${describeLocale(languageName)} (plus $countryCodeCount country variations$scriptCodeMessage)');
    }
  }

  // Generate the getTranslation function. Given a Locale it returns the
  // corresponding const GlobalMaterialLocalizations.
  output.writeln('''

/// The set of supported languages, as language code strings.
///
/// The [GlobalMaterialLocalizations.delegate] can generate localizations for
/// any [Locale] with a language code from this set, regardless of the region.
/// Some regions have specific support (e.g. `de` covers all forms of German,
/// but there is support for `de-CH` specifically to override some of the
/// translations for Switzerland).
///
/// See also:
///
///  * [getTranslation], whose documentation describes these values.
final Set<String> kSupportedLanguages = HashSet<String>.from(const <String>[
${languageCodes.map<String>((String value) => "  '$value', // ${describeLocale(value)}").toList().join('\n')}
]);

/// Creates a [GlobalMaterialLocalizations] instance for the given `locale`.
///
/// All of the function's arguments except `locale` will be passed to the [new
/// GlobalMaterialLocalizations] constructor. (The `localeName` argument of that
/// constructor is specified by the actual subclass constructor by this
/// function.)
///
/// The following locales are supported by this package:
///
/// {@template flutter.localizations.languages}
$supportedLocales/// {@endtemplate}
///
/// Generally speaking, this method is only intended to be used by
/// [GlobalMaterialLocalizations.delegate].
GlobalMaterialLocalizations getTranslation(
  Locale locale,
  intl.DateFormat fullYearFormat,
  intl.DateFormat mediumDateFormat,
  intl.DateFormat longDateFormat,
  intl.DateFormat yearMonthFormat,
  intl.NumberFormat decimalFormat,
  intl.NumberFormat twoDigitZeroPaddedFormat,
) {
  switch (locale.languageCode) {''');
  const String arguments = 'fullYearFormat: fullYearFormat, mediumDateFormat: mediumDateFormat, longDateFormat: longDateFormat, yearMonthFormat: yearMonthFormat, decimalFormat: decimalFormat, twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat';
  for (String language in languageToLocales.keys) {
    // Only one instance of the language.
    if (languageToLocales[language].length == 1) {
      output.writeln('''
    case '$language':
      return MaterialLocalization${camelCase(languageToLocales[language][0])}($arguments);''');
    } else if (!languageToScriptCodes.containsKey(language)) { // Does not distinguish between scripts. Switch on countryCode directly.
      output.writeln('''
    case '$language': {
      switch (locale.countryCode) {''');
      for (LocaleInfo locale in languageToLocales[language]) {
        if (locale.originalString == language)
          continue;
        assert(locale.length > 1);
        final String countryCode = locale.countryCode;
        output.writeln('''
        case '$countryCode':
          return MaterialLocalization${camelCase(locale)}($arguments);''');
      }
      output.writeln('''
      }
      return MaterialLocalization${camelCase(LocaleInfo.fromString(language))}($arguments);
    }''');
    } else { // Language has scriptCode, add additional switch logic.
      bool hasCountryCode = false;
      output.writeln('''
    case '$language': {
      switch (locale.scriptCode) {''');
      for (String scriptCode in languageToScriptCodes[language]) {
        final LocaleInfo scriptLocale = LocaleInfo.fromString(language + '_' + scriptCode);
        output.writeln('''
        case '$scriptCode': {''');
        if (languageAndScriptToCountryCodes.containsKey(scriptLocale)) {
          output.writeln('''
          switch (locale.countryCode) {''');
          for (LocaleInfo locale in languageToLocales[language]) {
            if (locale.countryCode == null)
              continue;
            else
              hasCountryCode = true;
            if (locale.originalString == language)
              continue;
            if (locale.scriptCode != scriptCode && locale.scriptCode != null)
              continue;
            final String countryCode = locale.countryCode;
            output.writeln('''
            case '$countryCode':
              return MaterialLocalization${camelCase(locale)}($arguments);''');
          }
        }
        // Return a fallback locale that matches scriptCode, but not countryCode.
        //
        // Explicitly defined scriptCode fallback:
        if (languageToLocales[language].contains(scriptLocale)) {
          if (languageAndScriptToCountryCodes.containsKey(scriptLocale)) {
            output.writeln('''
          }''');
          }
          output.writeln('''
          return MaterialLocalization${camelCase(scriptLocale)}($arguments);
        }''');
        } else {
          // Not Explicitly defined, fallback to first locale with the same language and
          // script:
          for (LocaleInfo locale in languageToLocales[language]) {
            if (locale.scriptCode != scriptCode)
              continue;
            if (languageAndScriptToCountryCodes.containsKey(scriptLocale)) {
              output.writeln('''
          }''');
            }
            output.writeln('''
          return MaterialLocalization${camelCase(scriptLocale)}($arguments);
        }''');
            break;
          }
        }
      }
      output.writeln('''
      }''');
      if (hasCountryCode) {
      output.writeln('''
      switch (locale.countryCode) {''');
        for (LocaleInfo locale in languageToLocales[language]) {
          if (locale.originalString == language)
            continue;
          assert(locale.length > 1);
          if (locale.countryCode == null)
            continue;
          final String countryCode = locale.countryCode;
          output.writeln('''
        case '$countryCode':
          return MaterialLocalization${camelCase(locale)}($arguments);''');
        }
        output.writeln('''
      }''');
      }
      output.writeln('''
      return MaterialLocalization${camelCase(LocaleInfo.fromString(language))}($arguments);
    }''');
    }
  }
  output.writeln('''
  }
  assert(false, 'getTranslation() called for unsupported locale "\$locale"');
  return null;
}''');

  return output.toString();
}

/// Writes the header of each class which corresponds to a locale.
void writeClassHeader(StringBuffer output, LocaleInfo locale, String superClass) {
  final String camelCaseName = camelCase(locale);
  final String className = 'MaterialLocalization$camelCaseName';
  final String constructor = generateConstructor(className, locale);
  output.writeln('');
  output.writeln('/// The translations for ${describeLocale(locale.originalString)} (`${locale.originalString}`).');
  output.writeln('class $className extends $superClass {');
  output.writeln(constructor);
}

/// Returns the appropriate type for getters with the given attributes.
///
/// Typically "String", but some (e.g. "timeOfDayFormat") return enums.
///
/// Used by [generateGetter] below.
String generateType(Map<String, dynamic> attributes) {
  if (attributes != null) {
    switch (attributes['x-flutter-type']) {
      case 'icuShortTimePattern':
        return 'TimeOfDayFormat';
      case 'scriptCategory':
        return 'ScriptCategory';
    }
  }
  return 'String';
}

/// Returns the appropriate name for getters with the given attributes.
///
/// Typically this is the key unmodified, but some have parameters, and
/// the GlobalMaterialLocalizations class does the substitution, and for
/// those we have to therefore provide an alternate name.
///
/// Used by [generateGetter] below.
String generateKey(String key, Map<String, dynamic> attributes) {
  if (attributes != null) {
    if (attributes.containsKey('parameters'))
      return '${key}Raw';
    switch (attributes['x-flutter-type']) {
      case 'icuShortTimePattern':
        return '${key}Raw';
    }
  }
  return key;
}

const Map<String, String> _icuTimeOfDayToEnum = <String, String>{
  'HH:mm': 'TimeOfDayFormat.HH_colon_mm',
  'HH.mm': 'TimeOfDayFormat.HH_dot_mm',
  "HH 'h' mm": 'TimeOfDayFormat.frenchCanadian',
  'HH:mm น.': 'TimeOfDayFormat.HH_colon_mm',
  'H:mm': 'TimeOfDayFormat.H_colon_mm',
  'h:mm a': 'TimeOfDayFormat.h_colon_mm_space_a',
  'a h:mm': 'TimeOfDayFormat.a_space_h_colon_mm',
  'ah:mm': 'TimeOfDayFormat.a_space_h_colon_mm',
};

const Map<String, String> _scriptCategoryToEnum = <String, String>{
  'English-like': 'ScriptCategory.englishLike',
  'dense': 'ScriptCategory.dense',
  'tall': 'ScriptCategory.tall',
};

/// Returns the literal that describes the value returned by getters
/// with the given attributes.
///
/// This handles cases like the value being a literal `null`, an enum, and so
/// on. The default is to treat the value as a string and escape it and quote
/// it.
///
/// Used by [generateGetter] below.
String generateValue(String value, Map<String, dynamic> attributes) {
  if (value == null)
    return null;
  if (attributes != null) {
    switch (attributes['x-flutter-type']) {
      case 'icuShortTimePattern':
        if (!_icuTimeOfDayToEnum.containsKey(value)) {
          throw Exception(
            '"$value" is not one of the ICU short time patterns supported '
            'by the material library. Here is the list of supported '
            'patterns:\n  ' + _icuTimeOfDayToEnum.keys.join('\n  ')
          );
        }
        return _icuTimeOfDayToEnum[value];
      case 'scriptCategory':
        if (!_scriptCategoryToEnum.containsKey(value)) {
          throw Exception(
            '"$value" is not one of the scriptCategory values supported '
            'by the material library. Here is the list of supported '
            'values:\n  ' + _scriptCategoryToEnum.keys.join('\n  ')
          );
        }
        return _scriptCategoryToEnum[value];
    }
  }
  return generateString(value);
}

/// Combines [generateType], [generateKey], and [generateValue] to return
/// the source of getters for the GlobalMaterialLocalizations subclass.
String generateGetter(String key, String value, Map<String, dynamic> attributes) {
  final String type = generateType(attributes);
  key = generateKey(key, attributes);
  value = generateValue(value, attributes);
      return '''

  @override
  $type get $key => $value;''';
}

/// Returns the source of the constructor for a GlobalMaterialLocalizations
/// subclass.
String generateConstructor(String className, LocaleInfo locale) {
  final String localeName = locale.originalString;
  return '''
  /// Create an instance of the translation bundle for ${describeLocale(localeName)}.
  ///
  /// For details on the meaning of the arguments, see [GlobalMaterialLocalizations].
  const $className({
    String localeName = '$localeName',
    @required intl.DateFormat fullYearFormat,
    @required intl.DateFormat mediumDateFormat,
    @required intl.DateFormat longDateFormat,
    @required intl.DateFormat yearMonthFormat,
    @required intl.NumberFormat decimalFormat,
    @required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : super(
    localeName: localeName,
    fullYearFormat: fullYearFormat,
    mediumDateFormat: mediumDateFormat,
    longDateFormat: longDateFormat,
    yearMonthFormat: yearMonthFormat,
    decimalFormat: decimalFormat,
    twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat,
  );''';
}

/// Parse the data for a locale from a file, and store it in the [attributes]
/// and [resources] keys.
void processBundle(File file, { @required String localeString }) {
  assert(localeString != null);
  // Helper method to fill the maps with the correct data from file.
  void populateResources(LocaleInfo locale) {
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
  // Only pre-assume scriptCode if there is a country or script code to assume off of.
  // When we assume scriptCode based on languageCode-only, we want this initial pass
  // to use the un-assumed version as a base class.
  LocaleInfo locale = LocaleInfo.fromString(localeString, assume: localeString.split('_').length > 1);
  // Allow overwrite if the existing data is assumed.
  if (assumedLocales.contains(locale)) {
    localeToResources[locale] = <String, String>{};
    localeToResourceAttributes[locale] = <String, dynamic>{};
    assumedLocales.remove(locale);
  } else {
    localeToResources[locale] ??= <String, String>{};
    localeToResourceAttributes[locale] ??= <String, dynamic>{};
  }
  populateResources(locale);
  // Add an assumed locale to default to when there is no info on scriptOnly locales.
  locale = LocaleInfo.fromString(localeString, assume: true);
  if (locale.scriptCode != null) {
    final LocaleInfo scriptLocale = LocaleInfo.fromString(locale.languageCode + '_' + locale.scriptCode);
    if (!localeToResources.containsKey(scriptLocale)) {
      assumedLocales.add(scriptLocale);
      localeToResources[scriptLocale] ??= <String, String>{};
      localeToResourceAttributes[scriptLocale] ??= <String, dynamic>{};
      populateResources(scriptLocale);
    }
  }
}

Future<void> main(List<String> rawArgs) async {
  checkCwdIsRepoRoot('gen_localizations');
  final GeneratorOptions options = parseArgs(rawArgs);

  // filenames are assumed to end in "prefix_lc.arb" or "prefix_lc_cc.arb", where prefix
  // is the 2nd command line argument, lc is a language code and cc is the country
  // code. In most cases both codes are just two characters.

  final Directory directory = Directory(path.join('packages', 'flutter_localizations', 'lib', 'src', 'l10n'));
  final RegExp filenameRE = RegExp(r'material_(\w+)\.arb$');

  try {
    validateEnglishLocalizations(File(path.join(directory.path, 'material_en.arb')));
  } on ValidationError catch (exception) {
    exitWithError('$exception');
  }

  await precacheLanguageAndRegionTags();

  for (FileSystemEntity entity in directory.listSync()) {
    final String entityPath = entity.path;
    if (FileSystemEntity.isFileSync(entityPath) && filenameRE.hasMatch(entityPath)) {
      processBundle(File(entityPath), localeString: filenameRE.firstMatch(entityPath)[1]);
    }
  }

  try {
    validateLocalizations(localeToResources, localeToResourceAttributes);
  } on ValidationError catch (exception) {
    exitWithError('$exception');
  }

  final StringBuffer buffer = StringBuffer();
  buffer.writeln(outputHeader.replaceFirst('@(regenerate)', 'dart dev/tools/gen_localizations.dart --overwrite'));
  buffer.write(generateTranslationBundles());

  if (options.writeToFile) {
    final File localizationsFile = File(path.join(directory.path, 'localizations.dart'));
    localizationsFile.writeAsStringSync(buffer.toString());
  } else {
    stdout.write(buffer.toString());
  }
}
