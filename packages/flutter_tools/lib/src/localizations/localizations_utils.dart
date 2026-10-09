// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../runner/flutter_command.dart';
import 'gen_l10n_types.dart';
import 'language_subtag_registry.dart';

int sortFilesByPath(File a, File b) {
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
  factory LocaleInfo.fromString(String locale, {bool deriveScriptCode = false}) {
    final List<String> codes = locale.split('_'); // [language, script, country]
    assert(codes.isNotEmpty && codes.length < 4);
    final String languageCode = codes[0];
    String? scriptCode;
    String? countryCode;
    int length = codes.length;
    var originalString = locale;
    if (codes.length == 2) {
      scriptCode = codes[1].length >= 4 ? codes[1] : null;
      countryCode = codes[1].length < 4 ? codes[1] : null;
    } else if (codes.length == 3) {
      scriptCode = codes[1].length > codes[2].length ? codes[1] : codes[2];
      countryCode = codes[1].length < codes[2].length ? codes[1] : codes[2];
    }
    assert(codes[0].isNotEmpty);
    assert(countryCode == null || countryCode.isNotEmpty);
    assert(scriptCode == null || scriptCode.isNotEmpty);

    /// Adds scriptCodes to locales where we are able to assume it to provide
    /// finer granularity when resolving locales.
    ///
    /// The basis of the assumptions here are based off of known usage of scripts
    /// across various countries. For example, we know Taiwan uses traditional (Hant)
    /// script, so it is safe to apply (Hant) to Taiwanese languages.
    if (deriveScriptCode && scriptCode == null) {
      scriptCode = switch ((languageCode, countryCode)) {
        ('zh', 'CN' || 'SG' || null) => 'Hans',
        ('zh', 'TW' || 'HK' || 'MO') => 'Hant',
        ('sr', null) => 'Cyrl',
        _ => null,
      };
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
  final int length; // The number of fields. Ranges from 1-3.
  final String originalString; // Original un-parsed locale string.

  String camelCase() {
    return originalString
        .split('_')
        .map<String>(
          (String part) => part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join();
  }

  @override
  bool operator ==(Object other) {
    return other is LocaleInfo && other.originalString == originalString;
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
  final result = <String, List<String>>{};
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

final _languages = <String, String>{};
final _regions = <String, String>{};
final _scripts = <String, String>{};
const kProvincePrefix = ', Province of ';
const kParentheticalPrefix = ' (';

/// Prepares the data for the [describeLocale] method below.
///
/// The data is obtained from the official IANA registry.
void precacheLanguageAndRegionTags() {
  final List<Map<String, List<String>>> sections = languageSubtagRegistry
      .split('%%')
      .skip(1)
      .map<Map<String, List<String>>>(_parseSection)
      .toList();
  for (final section in sections) {
    assert(section.containsKey('Type'), section.toString());
    final String type = section['Type']!.single;
    if (type == 'language' || type == 'region' || type == 'script') {
      assert(
        section.containsKey('Subtag') && section.containsKey('Description'),
        section.toString(),
      );
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
        case 'region':
          _regions[subtag] = description;
        case 'script':
          _scripts[subtag] = description;
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
  var output = language;
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
/// ```none
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
/// ```none
/// foo\bar => 'foo\\bar'
/// foo\nbar => 'foo\\nbar'
/// foo\\nbar => 'foo\\\\nbar'
/// foo\\bar => 'foo\\\\bar'
/// foo\ bar => 'foo\\ bar'
/// foo$bar = 'foo\$bar'
/// ```
String generateString(String value) {
  const backslash = '__BACKSLASH__';
  assert(
    !value.contains(backslash),
    'Input string cannot contain the sequence: '
    '"__BACKSLASH__", as it is used as part of '
    'backslash character processing.',
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

/// Given a list of normal strings or interpolated variables, concatenate them
/// into a single dart string to be returned. An example of a normal string
/// would be "'Hello world!'" and an example of a interpolated variable would be
/// "'$placeholder'".
///
/// Each of the strings in [expressions] should be a raw string, which, if it
/// were to be added to a dart file, would be a properly formatted dart string
/// with escapes and/or interpolation. The purpose of this function is to
/// concatenate these dart strings into a single dart string which can be
/// returned in the generated localization files.
///
/// The following rules describe the kinds of string expressions that can be
/// handled:
/// 1. If [expressions] is empty, return the empty string "''".
/// 2. If [expressions] has only one [String] which is an interpolated variable,
///    it is converted to the variable itself e.g. ["'$expr'"] -> "expr".
/// 3. If one string in [expressions] is an interpolation and the next begins
///    with an alphanumeric character, then the former interpolation should be
///    wrapped in braces e.g. ["'$expr1'", "'another'"] -> "'${expr1}another'".
String generateReturnExpr(List<String> expressions, {bool isSingleStringVar = false}) {
  if (expressions.isEmpty) {
    return "''";
  } else if (isSingleStringVar) {
    // If our expression is "$varName" where varName is a String, this is equivalent to just varName.
    return expressions[0].substring(1);
  } else {
    final String string = expressions.reversed.fold<String>('', (String string, String expression) {
      if (expression[0] != r'$') {
        return expression + string;
      }
      final alphanumeric = RegExp(r'^([0-9a-zA-Z]|_)+$');
      if (alphanumeric.hasMatch(expression.substring(1)) &&
          !(string.isNotEmpty && alphanumeric.hasMatch(string[0]))) {
        return '$expression$string';
      } else {
        return '\${${expression.substring(1)}}$string';
      }
    });
    return "'$string'";
  }
}

/// Generic representation of runtime symbols referenced by generated localization code.
@immutable
class LocalizationRuntimeSymbols {
  const LocalizationRuntimeSymbols({
    this.canonicalizedLocale = defaultCanonicalizedLocale,
    this.pluralLogic = defaultPluralLogic,
    this.selectLogic = defaultSelectLogic,
    this.dateFormat = defaultDateFormat,
    this.numberFormat = defaultNumberFormat,
  });

  static const String defaultCanonicalizedLocale = 'Intl.canonicalizedLocale';
  static const String defaultPluralLogic = 'Intl.pluralLogic';
  static const String defaultSelectLogic = 'Intl.selectLogic';
  static const String defaultDateFormat = 'DateFormat';
  static const String defaultNumberFormat = 'NumberFormat';

  /// The symbol referenced for canonicalizing locales.
  ///
  /// Defaults to `'Intl.canonicalizedLocale'`.
  final String canonicalizedLocale;

  /// The symbol referenced for plural logic.
  ///
  /// Defaults to `'Intl.pluralLogic'`.
  final String pluralLogic;

  /// The symbol referenced for select logic.
  ///
  /// Defaults to `'Intl.selectLogic'`.
  final String selectLogic;

  /// The class or type name used for date formatting.
  ///
  /// Defaults to `'DateFormat'`.
  final String dateFormat;

  /// The class or type name used for number formatting.
  ///
  /// Defaults to `'NumberFormat'`.
  final String numberFormat;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizationRuntimeSymbols &&
          canonicalizedLocale == other.canonicalizedLocale &&
          pluralLogic == other.pluralLogic &&
          selectLogic == other.selectLogic &&
          dateFormat == other.dateFormat &&
          numberFormat == other.numberFormat;

  @override
  int get hashCode =>
      Object.hash(canonicalizedLocale, pluralLogic, selectLogic, dateFormat, numberFormat);
}

/// Configuration for the localization runtime library used by generated code.
@immutable
class LocalizationRuntimeOptions {
  const LocalizationRuntimeOptions({
    this.package = defaultPackage,
    this.alias = defaultAlias,
    this.symbols = const LocalizationRuntimeSymbols(),
  });

  static const String defaultPackage = 'package:intl/intl.dart';
  static const String defaultAlias = 'intl';

  /// The URI of the package imported by generated localization files.
  ///
  /// Defaults to `'package:intl/intl.dart'`.
  final String package;

  /// The import alias for the localization library.
  ///
  /// Defaults to `'intl'`. Can be empty if no alias is needed.
  final String alias;

  /// Configured symbol references used in generated localization code.
  final LocalizationRuntimeSymbols symbols;

  /// Returns [symbol] qualified with the library [alias] if non-empty and not already prefixed.
  String qualifiedSymbol(String symbol) {
    if (alias.isEmpty) {
      return symbol;
    }
    if (symbol == alias || symbol.startsWith('$alias.')) {
      return symbol;
    }
    return '$alias.$symbol';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizationRuntimeOptions &&
          package == other.package &&
          alias == other.alias &&
          symbols == other.symbols;

  @override
  int get hashCode => Object.hash(package, alias, symbols);
}

/// Typed configuration from the localizations config file.
class LocalizationOptions {
  LocalizationOptions({
    required this.arbDir,
    this.outputDir,
    String? templateArbFile,
    String? outputLocalizationFile,
    this.untranslatedMessagesFile,
    String? outputClass,
    this.preferredSupportedLocales,
    this.header,
    this.headerFile,
    bool? useDeferredLoading,
    this.genInputsAndOutputsList,
    this.projectDir,
    bool? requiredResourceAttributes,
    bool? nullableGetter,
    bool? format,
    bool? useEscaping,
    bool? suppressWarnings,
    bool? relaxSyntax,
    bool? useNamedParameters,
    this.outputClassMixins,
    this.outputBaseClassMixins,
    this.fallbackLocale,
    LocalizationRuntimeOptions? localizationRuntime,
    String? libraryPackage,
    String? libraryAlias,
    this.arbDirs,
    Set<String>? ignoreArbKeys,
    ArbConflictResolution? arbConflictResolution,
  }) : templateArbFile = templateArbFile ?? 'app_en.arb',
       outputLocalizationFile = outputLocalizationFile ?? 'app_localizations.dart',
       outputClass = outputClass ?? 'AppLocalizations',
       useDeferredLoading = useDeferredLoading ?? false,
       requiredResourceAttributes = requiredResourceAttributes ?? false,
       nullableGetter = nullableGetter ?? true,
       format = format ?? true,
       useEscaping = useEscaping ?? false,
       suppressWarnings = suppressWarnings ?? false,
       relaxSyntax = relaxSyntax ?? false,
       useNamedParameters = useNamedParameters ?? false,
       localizationRuntime =
           localizationRuntime ??
           LocalizationRuntimeOptions(
             package: libraryPackage ?? LocalizationRuntimeOptions.defaultPackage,
             alias: libraryAlias ?? LocalizationRuntimeOptions.defaultAlias,
           ),
       ignoreArbKeys = ignoreArbKeys ?? const <String>{},
       arbConflictResolution = arbConflictResolution ?? ArbConflictResolution.error;

  /// The `--arb-dir` argument.
  ///
  /// The directory where all input localization files should reside.
  final String arbDir;

  /// The list of directories where input localization files reside if `arb-dir` was configured as a list of paths.
  final List<String>? arbDirs;

  /// The `--output-dir` argument.
  ///
  /// The directory where all output localization files should be generated.
  final String? outputDir;

  /// The `--template-arb-file` argument.
  ///
  /// This path is relative to [arbDir].
  final String templateArbFile;

  /// The `--output-localization-file` argument.
  ///
  /// This path is relative to [arbDir].
  final String outputLocalizationFile;

  /// The `--untranslated-messages-file` argument.
  ///
  /// This path is relative to [arbDir].
  final String? untranslatedMessagesFile;

  /// The `--output-class` argument.
  final String outputClass;

  /// The `--preferred-supported-locales` argument.
  final List<String>? preferredSupportedLocales;

  /// The `--header` argument.
  ///
  /// The header to prepend to the generated Dart localizations.
  final String? header;

  /// The `--header-file` argument.
  ///
  /// A file containing the header to prepend to the generated
  /// Dart localizations.
  final String? headerFile;

  /// The `--use-deferred-loading` argument.
  ///
  /// Whether to generate the Dart localization file with locales imported
  /// as deferred.
  final bool useDeferredLoading;

  /// The `--gen-inputs-and-outputs-list` argument.
  ///
  /// This path is relative to [arbDir].
  final String? genInputsAndOutputsList;

  /// The `--project-dir` argument.
  ///
  /// This path is relative to [arbDir].
  final String? projectDir;

  /// The `required-resource-attributes` argument.
  ///
  /// Whether to require all resource ids to contain a corresponding
  /// resource attribute.
  final bool requiredResourceAttributes;

  /// The `nullable-getter` argument.
  ///
  /// Whether or not the localizations class getter is nullable.
  final bool nullableGetter;

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

  /// The `relax-syntax` argument.
  ///
  /// Whether or not to relax the syntax. When specified, the syntax will be
  /// relaxed so that the special character "{" is treated as a string if it is
  /// not followed by a valid placeholder and "}" is treated as a string if it
  /// does not close any previous "{" that is treated as a special character.
  /// This was added in for backward compatibility and is not recommended
  /// as it may mask errors.
  final bool relaxSyntax;

  /// The `use-named-parameters` argument.
  ///
  /// Whether or not to use named parameters for the generated localization
  /// methods.
  ///
  /// Defaults to `false`.
  final bool useNamedParameters;

  /// Mixins to add to the generated output localization classes.
  ///
  /// Can be global (keyed with `'*'`), per-locale, or fallback (keyed with
  /// `'fallback'` or falling back to [fallbackLocale]).
  final Map<String, List<String>>? outputClassMixins;

  /// Mixins to add to the generated base localization class.
  final List<String>? outputBaseClassMixins;

  /// Fallback locale when locale lookup cannot find a matching locale.
  final String? fallbackLocale;

  /// The localization runtime library configuration.
  final LocalizationRuntimeOptions localizationRuntime;

  /// The package URI of the localization library used by generated code.
  ///
  /// Defaults to `'package:intl/intl.dart'`.
  String get libraryPackage => localizationRuntime.package;

  /// The import alias for the localization library used by generated code.
  ///
  /// Defaults to `'intl'`.
  String get libraryAlias => localizationRuntime.alias;

  /// Set of ARB keys to ignore during code generation from `ignore-arb-keys`.
  final Set<String> ignoreArbKeys;

  /// The conflict resolution strategy for duplicate ARB keys across multiple ARB sources.
  final ArbConflictResolution arbConflictResolution;
}

/// Parse the localizations configuration options from [file].
///
/// Throws [Exception] if any of the contents are invalid. Returns a
/// [LocalizationOptions] with all fields as `null` if the config file exists
/// but is empty.
LocalizationOptions parseLocalizationsOptionsFromYAML({
  required File file,
  required Logger logger,
  required FileSystem fileSystem,
  required String defaultArbDir,
}) {
  final String contents = file.readAsStringSync();
  if (contents.trim().isEmpty) {
    return LocalizationOptions(arbDir: defaultArbDir);
  }
  final YamlNode yamlNode;
  try {
    yamlNode = loadYamlNode(file.readAsStringSync());
  } on YamlException catch (err) {
    throwToolExit(err.message);
  }
  if (yamlNode is! YamlMap) {
    logger.printError('Expected ${file.path} to contain a map, instead was $yamlNode');
    throw Exception();
  }
  const kSyntheticPackage = 'synthetic-package';
  const kFlutterGenNotice = 'http://flutter.dev/to/flutter-gen-deprecation';
  final bool? syntheticPackage = _tryReadBool(yamlNode, kSyntheticPackage, logger);
  if (syntheticPackage != null) {
    if (syntheticPackage) {
      throwToolExit(
        '${file.path}: Cannot enable "$kSyntheticPackage", this feature has '
        'been removed. See $kFlutterGenNotice.',
      );
    } else {
      logger.printWarning(
        '${file.path}: The argument "$kSyntheticPackage" no longer has any '
        'effect and should be removed. See $kFlutterGenNotice',
      );
    }
  }
  final ({String arbDir, List<String>? arbDirs}) arbDirs = _tryReadArbDirs(
    yamlNode,
    'arb-dir',
    logger,
    fileSystem,
    defaultArbDir,
  );
  final LocalizationRuntimeOptions localizationRuntime = _tryReadLocalizationRuntime(
    yamlNode,
    logger,
  );

  return LocalizationOptions(
    arbDir: arbDirs.arbDir,
    arbDirs: arbDirs.arbDirs,
    outputDir: _tryReadFilePath(yamlNode, 'output-dir', logger, fileSystem),
    templateArbFile: _tryReadFilePath(yamlNode, 'template-arb-file', logger, fileSystem),
    outputLocalizationFile: _tryReadFilePath(
      yamlNode,
      'output-localization-file',
      logger,
      fileSystem,
    ),
    untranslatedMessagesFile: _tryReadFilePath(
      yamlNode,
      'untranslated-messages-file',
      logger,
      fileSystem,
    ),
    outputClass: _tryReadString(yamlNode, 'output-class', logger),
    header: _tryReadString(yamlNode, 'header', logger),
    headerFile: _tryReadFilePath(yamlNode, 'header-file', logger, fileSystem),
    useDeferredLoading: _tryReadBool(yamlNode, 'use-deferred-loading', logger),
    preferredSupportedLocales: _tryReadStringList(yamlNode, 'preferred-supported-locales', logger),
    requiredResourceAttributes: _tryReadBool(yamlNode, 'required-resource-attributes', logger),
    nullableGetter: _tryReadBool(yamlNode, 'nullable-getter', logger),
    format: _tryReadBool(yamlNode, 'format', logger),
    useEscaping: _tryReadBool(yamlNode, 'use-escaping', logger),
    suppressWarnings: _tryReadBool(yamlNode, 'suppress-warnings', logger),
    relaxSyntax: _tryReadBool(yamlNode, 'relax-syntax', logger),
    useNamedParameters: _tryReadBool(yamlNode, 'use-named-parameters', logger),
    outputClassMixins: _tryReadClassMixins(yamlNode, 'output-class-mixins', logger),
    outputBaseClassMixins: _tryReadBaseClassMixins(yamlNode, 'output-base-class-mixins', logger),
    fallbackLocale: _tryReadFallbackLocale(yamlNode, 'fallback-locale', logger),
    localizationRuntime: localizationRuntime,
    ignoreArbKeys: _tryReadIgnoreArbKeys(yamlNode, logger),
    arbConflictResolution: _tryReadArbConflictResolution(yamlNode, logger),
  );
}

/// Parse the localizations configuration from [FlutterCommand].
LocalizationOptions parseLocalizationsOptionsFromCommand({
  required FlutterCommand command,
  required String defaultArbDir,
  required Logger logger,
}) {
  const kSyntheticPackage = 'synthetic-package';
  const kFlutterGenNotice = 'http://flutter.dev/to/flutter-gen-deprecation';
  if (command.argResults!.wasParsed(kSyntheticPackage)) {
    if (command.boolArg(kSyntheticPackage)) {
      throwToolExit(
        'Cannot enable "$kSyntheticPackage", this feature has been removed. '
        'See $kFlutterGenNotice.',
      );
    } else {
      logger.printWarning(
        'The argument "$kSyntheticPackage" no longer has any effect and should '
        'be removed. See $kFlutterGenNotice',
      );
    }
  }
  return LocalizationOptions(
    arbDir: command.stringArg('arb-dir') ?? defaultArbDir,
    outputDir: command.stringArg('output-dir'),
    outputLocalizationFile: command.stringArg('output-localization-file'),
    templateArbFile: command.stringArg('template-arb-file'),
    untranslatedMessagesFile: command.stringArg('untranslated-messages-file'),
    outputClass: command.stringArg('output-class'),
    header: command.stringArg('header'),
    headerFile: command.stringArg('header-file'),
    useDeferredLoading: command.boolArg('use-deferred-loading'),
    genInputsAndOutputsList: command.stringArg('gen-inputs-and-outputs-list'),
    projectDir: command.stringArg('project-dir'),
    requiredResourceAttributes: command.boolArg('required-resource-attributes'),
    nullableGetter: command.boolArg('nullable-getter'),
    format: command.boolArg('format'),
    useEscaping: command.boolArg('use-escaping'),
    suppressWarnings: command.boolArg('suppress-warnings'),
    useNamedParameters: command.boolArg('use-named-parameters'),
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

// Try to read a valid file `Uri` or null from `yamlMap` to file path, otherwise throw.
String? _tryReadFilePath(YamlMap yamlMap, String key, Logger logger, FileSystem fileSystem) {
  final String? value = _tryReadString(yamlMap, key, logger);
  if (value == null) {
    return null;
  }
  final Uri? uri = Uri.tryParse(value);
  if (uri == null) {
    logger.printError('"$value" must be a relative file URI');
  }
  return uri != null ? fileSystem.path.normalize(uri.path) : null;
}

/// Checks whether [name] is a valid Dart identifier.
bool isValidDartIdentifier(String name) {
  if (name.isEmpty) {
    return false;
  }
  if (name.contains(RegExp(r'[^a-zA-Z_\d$]'))) {
    return false;
  }
  if (name[0].contains(RegExp(r'\d'))) {
    return false;
  }
  return true;
}

/// Checks whether [symbol] is a valid Dart symbol reference (e.g., `DateFormat` or `Intl.pluralLogic`).
bool isValidSymbolReference(String symbol) {
  if (symbol.isEmpty) {
    return false;
  }
  final List<String> parts = symbol.split('.');
  return parts.every(isValidDartIdentifier);
}

/// Checks whether [className] is a valid public Dart class name.
bool isValidClassName(String className) {
  if (className.isEmpty) {
    return false;
  }
  if (className[0] == '_') {
    return false;
  }
  if (className.contains(RegExp(r'[^a-zA-Z_\d]'))) {
    return false;
  }
  if (className[0].contains(RegExp(r'[a-z]'))) {
    return false;
  }
  if (className[0].contains(RegExp(r'\d'))) {
    return false;
  }
  return true;
}

/// Checks whether [typeRef] is a valid Dart mixin type reference.
///
/// Supports either an unqualified class name (e.g. `CoreLocalizations`) or a
/// library-prefixed class name (e.g. `coreX.CoreLocalizations`).
bool isValidMixinTypeReference(String typeRef) {
  if (typeRef.isEmpty) {
    return false;
  }
  final List<String> parts = typeRef.split('.');
  if (parts.length == 1) {
    return isValidClassName(parts[0]);
  }
  if (parts.length == 2) {
    return isValidDartIdentifier(parts[0]) && isValidClassName(parts[1]);
  }
  return false;
}

Map<String, List<String>>? _tryReadClassMixins(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is YamlList || value is List) {
    final list = <String>[];
    for (final Object? item in value as Iterable) {
      if (item is! String || !isValidMixinTypeReference(item)) {
        logger.printError(
          'Expected "$key" entries to be valid Dart mixin type references, instead found "$item"',
        );
        throw L10nException(
          'The mixin "$item" specified in "$key" is not a valid Dart mixin type reference.',
        );
      }
      list.add(item);
    }
    return <String, List<String>>{'*': list};
  }
  if (value is YamlMap || value is Map) {
    final result = <String, List<String>>{};
    for (final MapEntry<dynamic, dynamic> entry in (value as Map).entries) {
      final Object? localeKey = entry.key;
      if (localeKey is! String || localeKey.isEmpty) {
        logger.printError(
          'Expected "$key" keys to be non-empty strings, instead found "$localeKey"',
        );
        throw L10nException('Invalid locale "$localeKey" specified in "$key".');
      }
      final Object? mixins = entry.value;
      if (mixins is! Iterable) {
        logger.printError(
          'Expected "$key.$localeKey" to be a list of mixin class names, instead found "$mixins"',
        );
        throw L10nException('Expected a list of mixins for locale "$localeKey" in "$key".');
      }
      final list = <String>[];
      for (final Object? item in mixins) {
        if (item is! String || !isValidMixinTypeReference(item)) {
          logger.printError(
            'Expected "$key.$localeKey" entries to be valid Dart mixin type references, instead found "$item"',
          );
          throw L10nException(
            'The mixin "$item" specified in "$key.$localeKey" is not a valid Dart mixin type reference.',
          );
        }
        list.add(item);
      }
      result[localeKey] = list;
    }
    return result;
  }
  logger.printError('Expected "$key" to be a List or Map, instead was "$value"');
  throw L10nException('Expected "$key" to be a list or map of mixin class names.');
}

List<String>? _tryReadBaseClassMixins(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! Iterable) {
    logger.printError('Expected "$key" to be a list of mixin class names, instead was "$value"');
    throw L10nException('Expected "$key" to be a list of mixin class names.');
  }
  final list = <String>[];
  for (final Object? item in value) {
    if (item is! String || !isValidMixinTypeReference(item)) {
      logger.printError(
        'Expected "$key" entries to be valid Dart mixin type references, instead found "$item"',
      );
      throw L10nException(
        'The mixin "$item" specified in "$key" is not a valid Dart mixin type reference.',
      );
    }
    list.add(item);
  }
  return list;
}

String? _tryReadFallbackLocale(YamlMap yamlMap, String key, Logger logger) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    logger.printError('Expected "$key" to be a non-empty string, instead found "$value"');
    throw L10nException('Expected "$key" to be a valid locale string.');
  }
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    logger.printError('Expected "$key" to be a non-empty string, instead found "$value"');
    throw L10nException('Expected "$key" to be a valid locale string.');
  }
  final localeInfo = LocaleInfo.fromString(trimmed);
  if (localeInfo.languageCode.isEmpty || trimmed.contains(' ')) {
    logger.printError('Invalid locale identifier for "$key": "$trimmed"');
    throw L10nException('Invalid fallback-locale "$trimmed": must be a valid locale identifier.');
  }
  return trimmed;
}

LocalizationRuntimeOptions _tryReadLocalizationRuntime(YamlMap yamlMap, Logger logger) {
  if (yamlMap.containsKey('localization-library')) {
    logger.printError(
      'The "localization-library" configuration key is not supported. Use "localization-runtime" instead.',
    );
    throw L10nException(
      'The "localization-library" configuration key is not supported. Use "localization-runtime" instead.',
    );
  }
  if (!yamlMap.containsKey('localization-runtime')) {
    return const LocalizationRuntimeOptions();
  }
  const key = 'localization-runtime';
  final Object? value = yamlMap[key];
  if (value == null) {
    return const LocalizationRuntimeOptions();
  }
  if (value is! YamlMap && value is! Map) {
    logger.printError('Expected "$key" to be a map, instead was "$value"');
    throw L10nException('Expected "$key" to be a map.');
  }
  final map = value as Map<dynamic, dynamic>;
  for (final Object? subKey in map.keys) {
    if (subKey != 'package' &&
        subKey != 'alias' &&
        subKey != 'symbols' &&
        subKey != 'apis' &&
        subKey != 'references') {
      logger.printError(
        'Invalid key "$subKey" in "$key". Allowed keys are "package", "alias", and "symbols".',
      );
      throw L10nException('Invalid key "$subKey" specified in "$key".');
    }
  }

  final Object? packageVal = map['package'];
  String package = LocalizationRuntimeOptions.defaultPackage;
  if (packageVal != null) {
    if (packageVal is! String || packageVal.trim().isEmpty) {
      logger.printError(
        'Expected "$key.package" to be a non-empty string, instead was "$packageVal"',
      );
      throw L10nException('Expected "$key.package" to be a non-empty string.');
    }
    final String trimmed = packageVal.trim();
    final Uri? parsedUri = Uri.tryParse(trimmed);
    if (parsedUri == null || !trimmed.contains(':')) {
      logger.printError('Expected "$key.package" to be a valid URI, instead was "$packageVal"');
      throw L10nException('The package "$packageVal" specified in "$key" is not a valid URI.');
    }
    package = trimmed;
  }

  final Object? aliasVal = map['alias'];
  String alias = LocalizationRuntimeOptions.defaultAlias;
  if (aliasVal != null) {
    if (aliasVal is! String) {
      logger.printError('Expected "$key.alias" to be a string, instead was "$aliasVal"');
      throw L10nException('Expected "$key.alias" to be a string.');
    }
    final String trimmed = aliasVal.trim();
    if (trimmed.isNotEmpty && !isValidDartIdentifier(trimmed)) {
      logger.printError(
        'Expected "$key.alias" to be a valid Dart identifier, instead was "$aliasVal"',
      );
      throw L10nException(
        'The alias "$aliasVal" specified in "$key.alias" is not a valid Dart identifier.',
      );
    }
    alias = trimmed;
  }

  final Object? symbolsVal = map['symbols'] ?? map['apis'] ?? map['references'];
  var symbols = const LocalizationRuntimeSymbols();
  if (symbolsVal != null) {
    if (symbolsVal is! YamlMap && symbolsVal is! Map) {
      logger.printError('Expected "$key.symbols" to be a map, instead was "$symbolsVal"');
      throw L10nException('Expected "$key.symbols" to be a map.');
    }
    final symbolsMap = symbolsVal as Map<dynamic, dynamic>;

    String canonicalizedLocale = LocalizationRuntimeSymbols.defaultCanonicalizedLocale;
    String pluralLogic = LocalizationRuntimeSymbols.defaultPluralLogic;
    String selectLogic = LocalizationRuntimeSymbols.defaultSelectLogic;
    String dateFormat = LocalizationRuntimeSymbols.defaultDateFormat;
    String numberFormat = LocalizationRuntimeSymbols.defaultNumberFormat;

    for (final MapEntry<dynamic, dynamic> entry in symbolsMap.entries) {
      final Object? symbolKey = entry.key;
      if (symbolKey is! String || symbolKey.trim().isEmpty) {
        logger.printError(
          'Expected "$key.symbols" keys to be non-empty strings, instead found "$symbolKey"',
        );
        throw L10nException('Invalid symbol key "$symbolKey" specified in "$key.symbols".');
      }
      final String trimmedKey = symbolKey.trim();
      final Object? val = entry.value;

      String readSimpleSymbol(String name) {
        if (val is String && val.trim().isNotEmpty) {
          final String trimmed = val.trim();
          if (!isValidSymbolReference(trimmed)) {
            logger.printError(
              'The symbol "$trimmed" specified in "$key.symbols.$trimmedKey" is not a valid Dart symbol reference.',
            );
            throw L10nException(
              'The symbol "$trimmed" specified in "$key.symbols.$trimmedKey" is not a valid Dart symbol reference.',
            );
          }
          return trimmed;
        }
        if (val is Map) {
          final Map<dynamic, dynamic> m = val;
          final Object? sym =
              m['symbol'] ?? m['name'] ?? m['member'] ?? m['function'] ?? m['method'];
          if (sym is String && sym.trim().isNotEmpty && isValidSymbolReference(sym.trim())) {
            return sym.trim();
          }
        }
        logger.printError(
          'Expected "$key.symbols.$trimmedKey" to be a non-empty string, instead found "$val"',
        );
        throw L10nException('Expected "$key.symbols.$trimmedKey" to be a non-empty string.');
      }

      switch (trimmedKey) {
        case 'canonicalized-locale':
        case 'canonicalizedLocale':
        case 'canonicalize-locale':
        case 'canonicalizeLocale':
          canonicalizedLocale = readSimpleSymbol('canonicalizedLocale');
        case 'plural-logic':
        case 'pluralLogic':
        case 'plural':
          pluralLogic = readSimpleSymbol('pluralLogic');
        case 'select-logic':
        case 'selectLogic':
        case 'select':
          selectLogic = readSimpleSymbol('selectLogic');
        case 'date-format':
        case 'dateFormat':
          dateFormat = readSimpleSymbol('dateFormat');
        case 'number-format':
        case 'numberFormat':
          numberFormat = readSimpleSymbol('numberFormat');
        default:
          logger.printError('Invalid symbol key "$trimmedKey" in "$key.symbols".');
          throw L10nException('Invalid symbol key "$trimmedKey" specified in "$key.symbols".');
      }
    }

    symbols = LocalizationRuntimeSymbols(
      canonicalizedLocale: canonicalizedLocale,
      pluralLogic: pluralLogic,
      selectLogic: selectLogic,
      dateFormat: dateFormat,
      numberFormat: numberFormat,
    );
  }

  return LocalizationRuntimeOptions(package: package, alias: alias, symbols: symbols);
}

({String arbDir, List<String>? arbDirs}) _tryReadArbDirs(
  YamlMap yamlMap,
  String key,
  Logger logger,
  FileSystem fileSystem,
  String defaultArbDir,
) {
  final Object? value = yamlMap[key];
  if (value == null) {
    return (arbDir: defaultArbDir, arbDirs: null);
  }
  if (value is YamlList || value is List) {
    final paths = <String>[];
    for (final Object? item in value as Iterable) {
      if (item is! String || item.trim().isEmpty) {
        logger.printError('Expected "$key" entries to be non-empty strings, instead was "$item"');
        throw L10nException('Expected "$key" entries to be non-empty directory paths.');
      }
      final Uri? uri = Uri.tryParse(item.trim());
      if (uri == null) {
        logger.printError('"$item" must be a relative file URI');
        throw L10nException('"$item" must be a relative file URI');
      }
      paths.add(fileSystem.path.normalize(uri.path));
    }
    if (paths.isEmpty) {
      return (arbDir: defaultArbDir, arbDirs: null);
    }
    return (arbDir: paths.first, arbDirs: paths);
  }
  final String? singlePath = _tryReadFilePath(yamlMap, key, logger, fileSystem);
  return (arbDir: singlePath ?? defaultArbDir, arbDirs: null);
}

Set<String> _tryReadIgnoreArbKeys(YamlMap yamlMap, Logger logger) {
  const key = 'ignore-arb-keys';
  if (!yamlMap.containsKey(key)) {
    return const <String>{};
  }
  final Object? value = yamlMap[key];
  if (value == null) {
    return const <String>{};
  }
  if (value is Iterable) {
    final result = <String>{};
    for (final Object? item in value) {
      if (item is! String || item.trim().isEmpty) {
        logger.printError('Expected "$key" entries to be non-empty strings, instead was "$item"');
        throw L10nException('Expected "$key" entries to be non-empty strings.');
      }
      result.add(item.trim());
    }
    return Set<String>.unmodifiable(result);
  }
  logger.printError('Expected "$key" to be a list of ARB keys, instead was "$value"');
  throw L10nException('Expected "$key" to be a list of ARB keys.');
}

ArbConflictResolution _tryReadArbConflictResolution(YamlMap yamlMap, Logger logger) {
  const key = 'arb-conflict-resolution';
  if (!yamlMap.containsKey(key)) {
    return ArbConflictResolution.error;
  }
  final Object? value = yamlMap[key];
  if (value == null) {
    return ArbConflictResolution.error;
  }
  if (value is! String) {
    logger.printError('Expected "$key" to have a String value, instead was "$value"');
    throw L10nException(
      'Invalid "$key" value: "$value". Supported values are "error", "first", and "last".',
    );
  }
  final String trimmed = value.trim();
  try {
    return ArbConflictResolution.fromString(trimmed);
  } on L10nException catch (e) {
    logger.printError(e.message);
    rethrow;
  }
}
