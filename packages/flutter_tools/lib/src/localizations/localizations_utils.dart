// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import 'gen_l10n_types.dart';
import 'language_subtag_registry.dart';

typedef HeaderGenerator = String Function(String regenerateInstructions);
typedef ConstructorGenerator = String Function(LocaleInfo locale);

int sortFilesByPath (File a, File b) {
  return a.path.compareTo(b.path);
}

/// Simple data class to hold parsed locale. Does not promise validity of any data.
@immutable
class LocaleInfo implements Comparable<LocaleInfo> {
  const LocaleInfo({
    required this.languageCode,
    required this.scriptCode,
    required this.countryCode,
    required this.length,
    required this.originalString,
  });

  /// Simple parser. Expects the locale string to be in the form of 'language_script_COUNTRY'
  /// where the language is 2 characters, script is 4 characters with the first uppercase,
  /// and country is 2-3 characters and all uppercase.
  ///
  /// 'language_COUNTRY' or 'language_script' are also valid. Missing fields will be null.
  ///
  /// When `deriveScriptCode` is true, if [scriptCode] was unspecified, it will
  /// be derived from the [languageCode] and [countryCode] if possible.
  factory LocaleInfo.fromString(String locale, { bool deriveScriptCode = false }) {
    final List<String> codes = locale.split('_'); // [language, script, country]
    assert(codes.isNotEmpty && codes.length < 4);
    final String languageCode = codes[0];
    String? scriptCode;
    String? countryCode;
    int length = codes.length;
    String originalString = locale;
    if (codes.length == 2) {
      scriptCode = codes[1].length >= 4 ? codes[1] : null;
      countryCode = codes[1].length < 4 ? codes[1] : null;
    } else if (codes.length == 3) {
      scriptCode = codes[1].length > codes[2].length ? codes[1] : codes[2];
      countryCode = codes[1].length < codes[2].length ? codes[1] : codes[2];
    }
    assert(codes[0] != null && codes[0].isNotEmpty);
    assert(countryCode == null || countryCode.isNotEmpty);
    assert(scriptCode == null || scriptCode.isNotEmpty);

    /// Adds scriptCodes to locales where we are able to assume it to provide
    /// finer granularity when resolving locales.
    ///
    /// The basis of the assumptions here are based off of known usage of scripts
    /// across various countries. For example, we know Taiwan uses traditional (Hant)
    /// script, so it is safe to apply (Hant) to Taiwanese languages.
    if (deriveScriptCode && scriptCode == null) {
      switch (languageCode) {
        case 'zh': {
          if (countryCode == null) {
            scriptCode = 'Hans';
          }
          switch (countryCode) {
            case 'CN':
            case 'SG':
              scriptCode = 'Hans';
              break;
            case 'TW':
            case 'HK':
            case 'MO':
              scriptCode = 'Hant';
              break;
          }
          break;
        }
        case 'sr': {
          if (countryCode == null) {
            scriptCode = 'Cyrl';
          }
          break;
        }
      }
      // Increment length if we were able to assume a scriptCode.
      if (scriptCode != null) {
        length += 1;
      }
      // Update the base string to reflect assumed scriptCodes.
      originalString = languageCode;
      if (scriptCode != null) {
        originalString += '_$scriptCode';
      }
      if (countryCode != null) {
        originalString += '_$countryCode';
      }
    }

    return LocaleInfo(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
      length: length,
      originalString: originalString,
    );
  }

  final String languageCode;
  final String? scriptCode;
  final String? countryCode;
  final int length;             // The number of fields. Ranges from 1-3.
  final String originalString;  // Original un-parsed locale string.

  String camelCase() {
    return originalString
      .split('_')
      .map<String>((String part) => part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase())
      .join();
  }

  @override
  bool operator ==(Object other) {
    return other is LocaleInfo
        && other.originalString == originalString;
  }

  @override
  int get hashCode => originalString.hashCode;

  @override
  String toString() {
    return originalString;
  }

  @override
  int compareTo(LocaleInfo other) {
    return originalString.compareTo(other.originalString);
  }
}

// See also //master/tools/gen_locale.dart in the engine repo.
Map<String, List<String>> _parseSection(String section) {
  final Map<String, List<String>> result = <String, List<String>>{};
  late List<String> lastHeading;
  for (final String line in section.split('\n')) {
    if (line == '') {
      continue;
    }
    if (line.startsWith('  ')) {
      lastHeading[lastHeading.length - 1] = '${lastHeading.last}${line.substring(1)}';
      continue;
    }
    final int colon = line.indexOf(':');
    if (colon <= 0) {
      throw Exception('not sure how to deal with "$line"');
    }
    final String name = line.substring(0, colon);
    final String value = line.substring(colon + 2);
    lastHeading = result.putIfAbsent(name, () => <String>[]);
    result[name]!.add(value);
  }
  return result;
}

final Map<String, String> _languages = <String, String>{};
final Map<String, String> _regions = <String, String>{};
final Map<String, String> _scripts = <String, String>{};
const String kProvincePrefix = ', Province of ';
const String kParentheticalPrefix = ' (';

/// Prepares the data for the [describeLocale] method below.
///
/// The data is obtained from the official IANA registry.
void precacheLanguageAndRegionTags() {
  final List<Map<String, List<String>>> sections =
      languageSubtagRegistry.split('%%').skip(1).map<Map<String, List<String>>>(_parseSection).toList();
  for (final Map<String, List<String>> section in sections) {
    assert(section.containsKey('Type'), section.toString());
    final String type = section['Type']!.single;
    if (type == 'language' || type == 'region' || type == 'script') {
      assert(section.containsKey('Subtag') && section.containsKey('Description'), section.toString());
      final String subtag = section['Subtag']!.single;
      String description = section['Description']!.join(' ');
      if (description.startsWith('United ')) {
        description = 'the $description';
      }
      if (description.contains(kParentheticalPrefix)) {
        description = description.substring(0, description.indexOf(kParentheticalPrefix));
      }
      if (description.contains(kProvincePrefix)) {
        description = description.substring(0, description.indexOf(kProvincePrefix));
      }
      if (description.endsWith(' Republic')) {
        description = 'the $description';
      }
      switch (type) {
        case 'language':
          _languages[subtag] = description;
          break;
        case 'region':
          _regions[subtag] = description;
          break;
        case 'script':
          _scripts[subtag] = description;
          break;
      }
    }
  }
}

String describeLocale(String tag) {
  final List<String> subtags = tag.split('_');
  assert(subtags.isNotEmpty);
  final String languageCode = subtags[0];
  if (!_languages.containsKey(languageCode)) {
    throw L10nException(
      '"$languageCode" is not a supported language code.\n'
      'See https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry '
      'for the supported list.',
    );
  }
  final String language = _languages[languageCode]!;
  String output = language;
  String? region;
  String? script;
  if (subtags.length == 2) {
    region = _regions[subtags[1]];
    script = _scripts[subtags[1]];
    assert(region != null || script != null);
  } else if (subtags.length >= 3) {
    region = _regions[subtags[2]];
    script = _scripts[subtags[1]];
    assert(region != null && script != null);
  }
  if (region != null) {
    output += ', as used in $region';
  }
  if (script != null) {
    output += ', using the $script script';
  }
  return output;
}

/// Return the input string as a Dart-parsable string.
///
/// ```
/// foo => 'foo'
/// foo "bar" => 'foo "bar"'
/// foo 'bar' => "foo 'bar'"
/// foo 'bar' "baz" => '''foo 'bar' "baz"'''
/// ```
///
/// This function is used by tools that take in a JSON-formatted file to
/// generate Dart code. For this reason, characters with special meaning
/// in JSON files are escaped. For example, the backspace character (\b)
/// has to be properly escaped by this function so that the generated
/// Dart code correctly represents this character:
/// ```
/// foo\bar => 'foo\\bar'
/// foo\nbar => 'foo\\nbar'
/// foo\\nbar => 'foo\\\\nbar'
/// foo\\bar => 'foo\\\\bar'
/// foo\ bar => 'foo\\ bar'
/// foo$bar = 'foo\$bar'
/// ```
String generateString(String value) {
  const String backslash = '__BACKSLASH__';
  assert(
    !value.contains(backslash),
    'Input string cannot contain the sequence: '
    '"__BACKSLASH__", as it is used as part of '
    'backslash character processing.'
  );

  value = value
    // Replace backslashes with a placeholder for now to properly parse
    // other special characters.
    .replaceAll(r'\', backslash)
    .replaceAll(r'$', r'\$')
    .replaceAll("'", r"\'")
    .replaceAll('"', r'\"')
    .replaceAll('\n', r'\n')
    .replaceAll('\f', r'\f')
    .replaceAll('\t', r'\t')
    .replaceAll('\r', r'\r')
    .replaceAll('\b', r'\b')
    // Reintroduce escaped backslashes into generated Dart string.
    .replaceAll(backslash, r'\\');

  return value;
}

/// Given a list of strings, placeholders, or helper function calls, concatenate
/// them into one expression to be returned.
/// If isSingleStringVar is passed, then we want to convert "'$expr'" to simply "expr".
String generateReturnExpr(List<String> expressions, { bool isSingleStringVar = false }) {
  if (expressions.isEmpty) {
    return "''";
  } else if (isSingleStringVar) {
    // If our expression is "$varName" where varName is a String, this is equivalent to just varName.
    return expressions[0].substring(1);
  } else {
    final String string = expressions.reversed.fold<String>('', (String string, String expression) {
      if (expression[0] != r'$') {
        return generateString(expression) + string;
      }
      final RegExp alphanumeric = RegExp(r'^([0-9a-zA-Z]|_)+$');
      if (alphanumeric.hasMatch(expression.substring(1)) && !(string.isNotEmpty && alphanumeric.hasMatch(string[0]))) {
        return '$expression$string';
      } else {
        return '\${${expression.substring(1)}}$string';
      }
    });
    return "'$string'";
  }
}

/// Typed configuration from the localizations config file.
class LocalizationOptions {
  const LocalizationOptions({
    this.arbDirectory,
    this.templateArbFile,
    this.outputLocalizationsFile,
    this.untranslatedMessagesFile,
    this.header,
    this.outputClass,
    this.outputDirectory,
    this.preferredSupportedLocales,
    this.headerFile,
    this.deferredLoading,
    this.useSyntheticPackage = true,
    this.areResourceAttributesRequired = false,
    this.usesNullableGetter = true,
    this.format = false,
    this.useEscaping = false,
    this.suppressWarnings = false,
  }) : assert(useSyntheticPackage != null);

  /// The `--arb-dir` argument.
  ///
  /// The directory where all input localization files should reside.
  final Uri? arbDirectory;

  /// The `--template-arb-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri? templateArbFile;

  /// The `--output-localization-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri? outputLocalizationsFile;

  /// The `--untranslated-messages-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri? untranslatedMessagesFile;

  /// The `--header` argument.
  ///
  /// The header to prepend to the generated Dart localizations.
  final String? header;

  /// The `--output-class` argument.
  final String? outputClass;

  /// The `--output-dir` argument.
  ///
  /// The directory where all output localization files should be generated.
  final Uri? outputDirectory;

  /// The `--preferred-supported-locales` argument.
  final List<String>? preferredSupportedLocales;

  /// The `--header-file` argument.
  ///
  /// A file containing the header to prepend to the generated
  /// Dart localizations.
  final Uri? headerFile;

  /// The `--use-deferred-loading` argument.
  ///
  /// Whether to generate the Dart localization file with locales imported
  /// as deferred.
  final bool? deferredLoading;

  /// The `--synthetic-package` argument.
  ///
  /// Whether to generate the Dart localization files in a synthetic package
  /// or in a custom directory.
  final bool useSyntheticPackage;

  /// The `required-resource-attributes` argument.
  ///
  /// Whether to require all resource ids to contain a corresponding
  /// resource attribute.
  final bool areResourceAttributesRequired;

  /// The `nullable-getter` argument.
  ///
  /// Whether or not the localizations class getter is nullable.
  final bool usesNullableGetter;

  /// The `format` argument.
  ///
  /// Whether or not to format the generated files.
  final bool format;

  /// The `use-escaping` argument.
  ///
  /// Whether or not the ICU escaping syntax is used.
  final bool useEscaping;

  /// The `suppress-warnings` argument.
  ///
  /// Whether or not to suppress warnings.
  final bool suppressWarnings;
}

/// Parse the localizations configuration options from [file].
///
/// Throws [Exception] if any of the contents are invalid. Returns a
/// [LocalizationOptions] with all fields as `null` if the config file exists
/// but is empty.
LocalizationOptions parseLocalizationsOptions({
  required File file,
  required Logger logger,
}) {
  final String contents = file.readAsStringSync();
  if (contents.trim().isEmpty) {
    return const LocalizationOptions();
  }
  final YamlNode yamlNode = loadYamlNode(file.readAsStringSync());
  if (yamlNode is! YamlMap) {
    logger.printError('Expected ${file.path} to contain a map, instead was $yamlNode');
    throw Exception();
  }
  return LocalizationOptions(
    arbDirectory: _tryReadUri(yamlNode, 'arb-dir', logger),
    templateArbFile: _tryReadUri(yamlNode, 'template-arb-file', logger),
    outputLocalizationsFile: _tryReadUri(yamlNode, 'output-localization-file', logger),
    untranslatedMessagesFile: _tryReadUri(yamlNode, 'untranslated-messages-file', logger),
    header: _tryReadString(yamlNode, 'header', logger),
    outputClass: _tryReadString(yamlNode, 'output-class', logger),
    outputDirectory: _tryReadUri(yamlNode, 'output-dir', logger),
    preferredSupportedLocales: _tryReadStringList(yamlNode, 'preferred-supported-locales', logger),
    headerFile: _tryReadUri(yamlNode, 'header-file', logger),
    deferredLoading: _tryReadBool(yamlNode, 'use-deferred-loading', logger),
    useSyntheticPackage: _tryReadBool(yamlNode, 'synthetic-package', logger) ?? true,
    areResourceAttributesRequired: _tryReadBool(yamlNode, 'required-resource-attributes', logger) ?? false,
    usesNullableGetter: _tryReadBool(yamlNode, 'nullable-getter', logger) ?? true,
    format: _tryReadBool(yamlNode, 'format', logger) ?? false,
    useEscaping: _tryReadBool(yamlNode, 'use-escaping', logger) ?? false,
    suppressWarnings: _tryReadBool(yamlNode, 'suppress-warnings', logger) ?? false,
  );
}

// Try to read a `bool` value or null from `yamlMap`, otherwise throw.
bool? _tryReadBool(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    logger.printError('Expected "$key" to have a bool value, instead was "$value"');
    throw Exception();
  }
  return value;
}

// Try to read a `String` value or null from `yamlMap`, otherwise throw.
String? _tryReadString(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    logger.printError('Expected "$key" to have a String value, instead was "$value"');
    throw Exception();
  }
  return value;
}

List<String>? _tryReadStringList(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return <String>[value];
  }
  if (value is Iterable) {
    return value.map((dynamic e) => e.toString()).toList();
  }
  logger.printError('"$value" must be String or List.');
  throw Exception();
}

// Try to read a valid `Uri` or null from `yamlMap`, otherwise throw.
Uri? _tryReadUri(YamlMap yamlMap, String key, Logger logger) {
  final String? value = _tryReadString(yamlMap, key, logger);
  if (value == null) {
    return null;
  }
  final Uri? uri = Uri.tryParse(value);
  if (uri == null) {
    logger.printError('"$value" must be a relative file URI');
  }
  return uri;
}
