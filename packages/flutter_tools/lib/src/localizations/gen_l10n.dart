// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../convert.dart';
import '../flutter_manifest.dart';

import 'gen_l10n_templates.dart';
import 'gen_l10n_types.dart';
import 'localizations_utils.dart';

/// Run the localizations generation script with the configuration [options].
LocalizationsGenerator generateLocalizations({
  required Directory projectDir,
  Directory? dependenciesDir,
  required LocalizationOptions options,
  required Logger logger,
  required FileSystem fileSystem,
}) {
  // If generating a synthetic package, generate a warning if
  // flutter: generate is not set.
  final FlutterManifest? flutterManifest = FlutterManifest.createFromPath(
    projectDir.childFile('pubspec.yaml').path,
    fileSystem: projectDir.fileSystem,
    logger: logger,
  );
  if (options.useSyntheticPackage && (flutterManifest == null || !flutterManifest.generateSyntheticPackage)) {
    throwToolExit(
      'Attempted to generate localizations code without having '
      'the flutter: generate flag turned on.'
      '\n'
      'Check pubspec.yaml and ensure that flutter: generate: true has '
      'been added and rebuild the project. Otherwise, the localizations '
      'source code will not be importable.'
    );
  }

  precacheLanguageAndRegionTags();

  final String inputPathString = options.arbDirectory?.path ?? fileSystem.path.join('lib', 'l10n');
  final String templateArbFileName = options.templateArbFile?.toFilePath() ?? 'app_en.arb';
  final String outputFileString = options.outputLocalizationsFile?.toFilePath() ?? 'app_localizations.dart';
  LocalizationsGenerator generator;
  try {
    generator = LocalizationsGenerator(
      fileSystem: fileSystem,
      inputsAndOutputsListPath: dependenciesDir?.path,
      projectPathString: projectDir.path,
      inputPathString: inputPathString,
      templateArbFileName: templateArbFileName,
      outputFileString: outputFileString,
      outputPathString: options.outputDirectory?.path,
      classNameString: options.outputClass ?? 'AppLocalizations',
      preferredSupportedLocales: options.preferredSupportedLocales,
      headerString: options.header,
      headerFile: options.headerFile?.toFilePath(),
      useDeferredLoading: options.deferredLoading ?? false,
      useSyntheticPackage: options.useSyntheticPackage,
      areResourceAttributesRequired: options.areResourceAttributesRequired,
      untranslatedMessagesFile: options.untranslatedMessagesFile?.toFilePath(),
      usesNullableGetter: options.usesNullableGetter,
    )
      ..loadResources()
      ..writeOutputFiles(logger, isFromYaml: true);
  } on L10nException catch (e) {
    throwToolExit(e.message);
  }
  return generator;
}

/// The path for the synthetic package.
String _defaultSyntheticPackagePath(FileSystem fileSystem) => fileSystem.path.join('.dart_tool', 'flutter_gen');

/// The default path used when the `_useSyntheticPackage` setting is set to true
/// in [LocalizationsGenerator].
///
/// See [LocalizationsGenerator.initialize] for where and how it is used by the
/// localizations tool.
String _syntheticL10nPackagePath(FileSystem fileSystem) => fileSystem.path.join(_defaultSyntheticPackagePath(fileSystem), 'gen_l10n');

List<String> generateMethodParameters(Message message) {
  assert(message.placeholders.isNotEmpty);
  final Placeholder? countPlaceholder = message.isPlural ? message.getCountPlaceholder() : null;
  return message.placeholders.map((Placeholder placeholder) {
    final String? type = placeholder == countPlaceholder ? 'int' : placeholder.type;
    return '$type ${placeholder.name}';
  }).toList();
}

String generateDateFormattingLogic(Message message) {
  if (message.placeholders.isEmpty || !message.placeholdersRequireFormatting) {
    return '@(none)';
  }

  final Iterable<String> formatStatements = message.placeholders
    .where((Placeholder placeholder) => placeholder.isDate)
    .map((Placeholder placeholder) {
      final String? placeholderFormat = placeholder.format;
      if (placeholderFormat == null) {
        throw L10nException(
          'The placeholder, ${placeholder.name}, has its "type" resource attribute set to '
          'the "${placeholder.type}" type. To properly resolve for the right '
          '${placeholder.type} format, the "format" attribute needs to be set '
          'to determine which DateFormat to use. \n'
          "Check the intl library's DateFormat class constructors for allowed "
          'date formats.'
        );
      }
      final bool? isCustomDateFormat = placeholder.isCustomDateFormat;
      if (!placeholder.hasValidDateFormat
          && (isCustomDateFormat == null || !isCustomDateFormat)) {
        throw L10nException(
          'Date format "$placeholderFormat" for placeholder '
          '${placeholder.name} does not have a corresponding DateFormat '
          "constructor\n. Check the intl library's DateFormat class "
          'constructors for allowed date formats, or set "isCustomDateFormat" attribute '
          'to "true".'
        );
      }
      if (placeholder.hasValidDateFormat) {
        return dateFormatTemplate
          .replaceAll('@(placeholder)', placeholder.name)
          .replaceAll('@(format)', placeholderFormat);
      }
      return dateFormatCustomTemplate
        .replaceAll('@(placeholder)', placeholder.name)
        .replaceAll('@(format)', generateString(placeholderFormat));
    });

  return formatStatements.isEmpty ? '@(none)' : formatStatements.join('');
}

String generateNumberFormattingLogic(Message message) {
  if (message.placeholders.isEmpty || !message.placeholdersRequireFormatting) {
    return '@(none)';
  }

  final Iterable<String> formatStatements = message.placeholders
    .where((Placeholder placeholder) => placeholder.isNumber)
    .map((Placeholder placeholder) {
      final String? placeholderFormat = placeholder.format;
      if (!placeholder.hasValidNumberFormat || placeholderFormat == null) {
        throw L10nException(
          'Number format $placeholderFormat for the ${placeholder.name} '
          'placeholder does not have a corresponding NumberFormat constructor.\n'
          "Check the intl library's NumberFormat class constructors for allowed "
          'number formats.'
        );
      }
      final Iterable<String> parameters =
        placeholder.optionalParameters.map<String>((OptionalParameter parameter) {
          if (parameter.value is num) {
            return '${parameter.name}: ${parameter.value}';
          } else {
            return '${parameter.name}: ${generateString(parameter.value.toString())}';
          }
        },
      );

      if (placeholder.hasNumberFormatWithParameters) {
        return numberFormatNamedTemplate
            .replaceAll('@(placeholder)', placeholder.name)
            .replaceAll('@(format)', placeholderFormat)
            .replaceAll('@(parameters)', parameters.join(',\n      '));
      } else {
        return numberFormatPositionalTemplate
            .replaceAll('@(placeholder)', placeholder.name)
            .replaceAll('@(format)', placeholderFormat);
      }
    });

  return formatStatements.isEmpty ? '@(none)' : formatStatements.join('');
}

String _generatePluralMethod(Message message, String translationForMessage) {
  if (message.placeholders.isEmpty) {
    throw L10nException(
      'Unable to find placeholders for the plural message: ${message.resourceId}.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String easyMessage = translationForMessage;
  for (final Placeholder placeholder in message.placeholders) {
    easyMessage = easyMessage.replaceAll('{${placeholder.name}}', '#${placeholder.name}#');
  }

  final Placeholder countPlaceholder = message.getCountPlaceholder();
  const Map<String, String> pluralIds = <String, String>{
    '=0': 'zero',
    '=1': 'one',
    '=2': 'two',
    'few': 'few',
    'many': 'many',
    'other': 'other',
  };

  final List<String> pluralLogicArgs = <String>[];
  for (final String pluralKey in pluralIds.keys) {
    final RegExp expRE = RegExp('($pluralKey)\\s*{([^}]+)}');
    final RegExpMatch? match = expRE.firstMatch(easyMessage);
    if (match != null && match.groupCount == 2) {
      String argValue = generateString(match.group(2)!);
      for (final Placeholder placeholder in message.placeholders) {
        String variable = placeholder.name;
        if (placeholder.requiresFormatting) {
          variable += 'String';
        }
        argValue = argValue.replaceAll(
          '#${placeholder.name}#',
          _needsCurlyBracketStringInterpolation(argValue, placeholder.name)
            ? '\${$variable}'
            : '\$$variable'
        );
      }
      pluralLogicArgs.add('      ${pluralIds[pluralKey]}: $argValue');
    }
  }

  final List<String> parameters = message.placeholders.map((Placeholder placeholder) {
    final String? placeholderType = placeholder == countPlaceholder ? 'int' : placeholder.type;
    return '$placeholderType ${placeholder.name}';
  }).toList();

  final String comment = message.description ?? 'No description provided in @${message.resourceId}';

  if (translationForMessage.startsWith('{') && translationForMessage.endsWith('}')) {
    return pluralMethodTemplate
      .replaceAll('@(comment)', comment)
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
      .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
      .replaceAll('@(parameters)', parameters.join(', '))
      .replaceAll('@(count)', countPlaceholder.name)
      .replaceAll('@(pluralLogicArgs)', pluralLogicArgs.join(',\n'))
      .replaceAll('@(none)\n', '');
  }

  const String variable = 'pluralString';
  final String string = _replaceWithVariable(translationForMessage, variable);
  return pluralMethodTemplateInString
    .replaceAll('@(comment)', comment)
    .replaceAll('@(name)', message.resourceId)
    .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
    .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
    .replaceAll('@(parameters)', parameters.join(', '))
    .replaceAll('@(variable)', variable)
    .replaceAll('@(count)', countPlaceholder.name)
    .replaceAll('@(pluralLogicArgs)', pluralLogicArgs.join(',\n'))
    .replaceAll('@(none)\n', '')
    .replaceAll('@(string)', string);
}

String _replaceWithVariable(String translation, String variable) {
  String prefix = generateString(translation.substring(0, translation.indexOf('{')));
  prefix = prefix.substring(0, prefix.length - 1);
  String suffix = generateString(translation.substring(translation.lastIndexOf('}') + 1));
  suffix = suffix.substring(1);

  // escape variable when the suffix can be combined with the variable
  if (suffix.isNotEmpty && !suffix.startsWith(' ')) {
    variable = '{$variable}';
  }
  return prefix + r'$' + variable + suffix;
}

String _generateSelectMethod(Message message, String translationForMessage) {
  if (message.placeholders.isEmpty) {
    throw L10nException(
      'Unable to find placeholders for the select message: ${message.resourceId}.\n'
      'Check to see if the select message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

  final List<String> cases = <String>[];

  final RegExpMatch? selectMatch =
    LocalizationsGenerator._selectRE.firstMatch(translationForMessage);
  String? choice;
  if (selectMatch != null && selectMatch.groupCount == 2) {
    choice = selectMatch.group(1);
    final String pattern = selectMatch.group(2)!;
    final RegExp patternRE = RegExp(r'\s*([\w\d]+)\s*\{(.*?)\}');
    for (final RegExpMatch patternMatch in patternRE.allMatches(pattern)) {
      if (patternMatch.groupCount == 2) {
        final String value = patternMatch.group(2)!
          .replaceAll("'", r"\'")
          .replaceAll('"', r'\"');
        cases.add(
          "        '${patternMatch.group(1)}': '$value'",
        );
      }
    }
  }

  final List<String> parameters = message.placeholders.map((Placeholder placeholder) {
    final String placeholderType = placeholder.type ?? 'object';
    return '$placeholderType ${placeholder.name}';
  }).toList();

  final String description = message.description ?? 'No description provided in @${message.resourceId}';

  if (translationForMessage.startsWith('{') && translationForMessage.endsWith('}')) {
    return selectMethodTemplate
        .replaceAll('@(name)', message.resourceId)
        .replaceAll('@(parameters)', parameters.join(', '))
        .replaceAll('@(choice)', choice!)
        .replaceAll('@(cases)', cases.join(',\n').trim())
        .replaceAll('@(description)', description);
  }

  const String variable = 'selectString';
  final String string = _replaceWithVariable(translationForMessage, variable);
  return selectMethodTemplateInString
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(parameters)', parameters.join(', '))
      .replaceAll('@(variable)', variable)
      .replaceAll('@(choice)', choice!)
      .replaceAll('@(cases)', cases.join(',\n').trim())
      .replaceAll('@(description)', description)
      .replaceAll('@(string)', string);
}

bool _needsCurlyBracketStringInterpolation(String messageString, String placeholder) {
  final int placeholderIndex = messageString.indexOf(placeholder);
  // This means that this message does not contain placeholders/parameters,
  // since one was not found in the message.
  if (placeholderIndex == -1) {
    return false;
  }

  final bool isPlaceholderEndOfSubstring = placeholderIndex + placeholder.length + 2 == messageString.length;

  if (placeholderIndex > 2 && !isPlaceholderEndOfSubstring) {
    // Normal case
    // Examples:
    // "'The number of {hours} elapsed is: 44'" // no curly brackets.
    // "'哈{hours}哈'" // no curly brackets.
    // "'m#hours#m'" // curly brackets.
    // "'I have to work _#hours#_' sometimes." // curly brackets.
    final RegExp commonCaseRE = RegExp('[^a-zA-Z_][#{]$placeholder[#}][^a-zA-Z_]');
    return !commonCaseRE.hasMatch(messageString);
  } else if (placeholderIndex == 2) {
    // Example:
    // "'{hours} elapsed.'" // no curly brackets
    // '#placeholder# ' // no curly brackets
    // '#placeholder#m' // curly brackets
    final RegExp startOfString = RegExp('[#{]$placeholder[#}][^a-zA-Z_]');
    return !startOfString.hasMatch(messageString);
  } else {
    // Example:
    // "'hours elapsed: {hours}'"
    // "'Time elapsed: {hours}'" // no curly brackets
    // ' #placeholder#' // no curly brackets
    // 'm#placeholder#' // curly brackets
    final RegExp endOfString = RegExp('[^a-zA-Z_][#{]$placeholder[#}]');
    return !endOfString.hasMatch(messageString);
  }
}

String _generateMethod(Message message, String translationForMessage) {
  String generateMessage() {
    String messageValue = generateString(translationForMessage);
    for (final Placeholder placeholder in message.placeholders) {
      String variable = placeholder.name;
      if (placeholder.requiresFormatting) {
        variable += 'String';
      }
      messageValue = messageValue.replaceAll(
        '{${placeholder.name}}',
        _needsCurlyBracketStringInterpolation(messageValue, placeholder.name)
          ? '\${$variable}'
          : '\$$variable'
      );
    }

    return messageValue;
  }

  if (message.isPlural) {
    return _generatePluralMethod(message, translationForMessage);
  }

  if (message.isSelect) {
    return _generateSelectMethod(message, translationForMessage);
  }

  if (message.placeholdersRequireFormatting) {
    return formatMethodTemplate
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(parameters)', generateMethodParameters(message).join(', '))
      .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
      .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
      .replaceAll('@(message)', generateMessage())
      .replaceAll('@(none)\n', '');
  }

  if (message.placeholders.isNotEmpty) {
    return methodTemplate
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(parameters)', generateMethodParameters(message).join(', '))
      .replaceAll('@(message)', generateMessage());
  }

  return getterTemplate
    .replaceAll('@(name)', message.resourceId)
    .replaceAll('@(message)', generateMessage());
}

String generateBaseClassMethod(Message message, LocaleInfo? templateArbLocale) {
  final String comment = message.description ?? 'No description provided for @${message.resourceId}.';
  final String templateLocaleTranslationComment = '''
  /// In $templateArbLocale, this message translates to:
  /// **${generateString(message.value)}**''';

  if (message.placeholders.isNotEmpty) {
    return baseClassMethodTemplate
      .replaceAll('@(comment)', comment)
      .replaceAll('@(templateLocaleTranslationComment)', templateLocaleTranslationComment)
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(parameters)', generateMethodParameters(message).join(', '));
  }
  return baseClassGetterTemplate
    .replaceAll('@(comment)', comment)
    .replaceAll('@(templateLocaleTranslationComment)', templateLocaleTranslationComment)
    .replaceAll('@(name)', message.resourceId);
}

// Add spaces to pad the start of each line. Skips the first line
// assuming that the padding is already present.
String _addSpaces(String message, {int spaces = 0}) {
  bool isFirstLine = true;
  return message
    .split('\n')
    .map((String value) {
      if (isFirstLine) {
        isFirstLine = false;
        return value;
      }
      return value.padLeft(spaces);
    })
    .join('\n');
}

String _generateLookupByAllCodes(
  AppResourceBundleCollection allBundles,
  String Function(LocaleInfo) generateSwitchClauseTemplate,
) {
  final Iterable<LocaleInfo> localesWithAllCodes = allBundles.locales.where((LocaleInfo locale) {
    return locale.scriptCode != null && locale.countryCode != null;
  });

  if (localesWithAllCodes.isEmpty) {
    return '';
  }

  final Iterable<String> switchClauses = localesWithAllCodes.map<String>((LocaleInfo locale) {
    return generateSwitchClauseTemplate(locale)
      .replaceAll('@(case)', locale.toString());
  });

  return allCodesLookupTemplate.replaceAll(
    '@(allCodesSwitchClauses)',
    switchClauses.join('\n        '),
  );
}

String _generateLookupByScriptCode(
  AppResourceBundleCollection allBundles,
  String Function(LocaleInfo) generateSwitchClauseTemplate,
) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithScriptCodes = locales.where((LocaleInfo locale) {
      return locale.scriptCode != null && locale.countryCode == null;
    });

    if (localesWithScriptCodes.isEmpty) {
      return null;
    }

    return _addSpaces(nestedSwitchTemplate
      .replaceAll('@(languageCode)', language)
      .replaceAll('@(code)', 'scriptCode')
      .replaceAll('@(switchClauses)',
        _addSpaces(
          localesWithScriptCodes.map((LocaleInfo locale) {
            return generateSwitchClauseTemplate(locale)
              .replaceAll('@(case)', locale.scriptCode!);
          }).join('\n'),
          spaces: 8,
        ),
      ),
      spaces: 4,
    );
  }).whereType<String>();

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when language+script codes are specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n      '),
  );
}

String _generateLookupByCountryCode(
  AppResourceBundleCollection allBundles,
  String Function(LocaleInfo) generateSwitchClauseTemplate,
) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithCountryCodes = locales.where((LocaleInfo locale) {
      return locale.countryCode != null && locale.scriptCode == null;
    });

    if (localesWithCountryCodes.isEmpty) {
      return null;
    }

    return _addSpaces(
      nestedSwitchTemplate
        .replaceAll('@(languageCode)', language)
        .replaceAll('@(code)', 'countryCode')
        .replaceAll('@(switchClauses)', _addSpaces(
          localesWithCountryCodes.map((LocaleInfo locale) {
            return generateSwitchClauseTemplate(locale).replaceAll('@(case)', locale.countryCode!);
          }).join('\n'),
          spaces: 4,
        )),
      spaces: 4,
    );
  }).whereType<String>();

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when language+country codes are specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n    '));
}

String _generateLookupByLanguageCode(
  AppResourceBundleCollection allBundles,
  String Function(LocaleInfo) generateSwitchClauseTemplate,
) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithLanguageCode = locales.where((LocaleInfo locale) {
      return locale.countryCode == null && locale.scriptCode == null;
    });

    if (localesWithLanguageCode.isEmpty) {
      return null;
    }

    return localesWithLanguageCode.map((LocaleInfo locale) {
      return generateSwitchClauseTemplate(locale)
        .replaceAll('@(case)', locale.languageCode);
    }).join('\n      ');
  }).whereType<String>();

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when only language code is specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n    '));
}

String _generateLookupBody(
  AppResourceBundleCollection allBundles,
  String className,
  bool useDeferredLoading,
  String fileName,
) {
  String generateSwitchClauseTemplate(LocaleInfo locale) {
    return (useDeferredLoading ?
      switchClauseDeferredLoadingTemplate : switchClauseTemplate)
      .replaceAll('@(localeClass)', '$className${locale.camelCase()}')
      .replaceAll('@(appClass)', className)
      .replaceAll('@(library)', '${fileName}_${locale.languageCode}');
  }
  return lookupBodyTemplate
    .replaceAll('@(lookupAllCodesSpecified)', _generateLookupByAllCodes(
      allBundles,
      generateSwitchClauseTemplate,
    ))
    .replaceAll('@(lookupScriptCodeSpecified)', _generateLookupByScriptCode(
      allBundles,
      generateSwitchClauseTemplate,
    ))
    .replaceAll('@(lookupCountryCodeSpecified)', _generateLookupByCountryCode(
      allBundles,
      generateSwitchClauseTemplate,
    ))
    .replaceAll('@(lookupLanguageCodeSpecified)', _generateLookupByLanguageCode(
      allBundles,
      generateSwitchClauseTemplate,
    ));
}

String _generateDelegateClass({
  required AppResourceBundleCollection allBundles,
  required String className,
  required Set<String> supportedLanguageCodes,
  required bool useDeferredLoading,
  required String fileName,
}) {

  final String lookupBody = _generateLookupBody(
    allBundles,
    className,
    useDeferredLoading,
    fileName,
  );
  final String loadBody = (
    useDeferredLoading ? loadBodyDeferredLoadingTemplate : loadBodyTemplate
  )
    .replaceAll('@(class)', className)
    .replaceAll('@(lookupName)', 'lookup$className');
  final String lookupFunction = (useDeferredLoading ?
  lookupFunctionDeferredLoadingTemplate : lookupFunctionTemplate)
    .replaceAll('@(class)', className)
    .replaceAll('@(lookupName)', 'lookup$className')
    .replaceAll('@(lookupBody)', lookupBody);
  return delegateClassTemplate
    .replaceAll('@(class)', className)
    .replaceAll('@(loadBody)', loadBody)
    .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.join(', '))
    .replaceAll('@(lookupFunction)', lookupFunction);
}

class LocalizationsGenerator {
  /// Initializes [inputDirectory], [outputDirectory], [templateArbFile],
  /// [outputFile] and [className].
  ///
  /// Throws an [L10nException] when a provided configuration is not allowed
  /// by [LocalizationsGenerator].
  ///
  /// Throws a [FileSystemException] when a file operation necessary for setting
  /// up the [LocalizationsGenerator] cannot be completed.
  factory LocalizationsGenerator({
    required FileSystem fileSystem,
    required String inputPathString,
    String? outputPathString,
    required String templateArbFileName,
    required String outputFileString,
    required String classNameString,
    List<String>? preferredSupportedLocales,
    String? headerString,
    String? headerFile,
    bool useDeferredLoading = false,
    String? inputsAndOutputsListPath,
    bool useSyntheticPackage = true,
    String? projectPathString,
    bool areResourceAttributesRequired = false,
    String? untranslatedMessagesFile,
    bool usesNullableGetter = true,
  }) {
    final Directory? projectDirectory = projectDirFromPath(fileSystem, projectPathString);
    final Directory inputDirectory = inputDirectoryFromPath(fileSystem, inputPathString, projectDirectory);
    final Directory outputDirectory = outputDirectoryFromPath(fileSystem, outputPathString ?? inputPathString, useSyntheticPackage, projectDirectory);
    return LocalizationsGenerator._(
      fileSystem,
      useSyntheticPackage: useSyntheticPackage,
      usesNullableGetter: usesNullableGetter,
      className: classNameFromString(classNameString),
      projectDirectory: projectDirectory,
      inputDirectory: inputDirectory,
      outputDirectory: outputDirectory,
      templateArbFile: templateArbFileFromFileName(templateArbFileName, inputDirectory),
      baseOutputFile: outputDirectory.childFile(outputFileString),
      preferredSupportedLocales: preferredSupportedLocalesFromLocales(preferredSupportedLocales),
      header: headerFromFile(headerString, headerFile, inputDirectory),
      useDeferredLoading: useDeferredLoading,
      untranslatedMessagesFile: _untranslatedMessagesFileFromPath(fileSystem, untranslatedMessagesFile),
      inputsAndOutputsListFile: _inputsAndOutputsListFileFromPath(fileSystem, inputsAndOutputsListPath),
      areResourceAttributesRequired: areResourceAttributesRequired,
    );
  }

  /// Creates an instance of the localizations generator class.
  ///
  /// It takes in a [FileSystem] representation that the class will act upon.
  LocalizationsGenerator._(this._fs, {
    required this.inputDirectory,
    required this.outputDirectory,
    required this.templateArbFile,
    required this.baseOutputFile,
    required this.className,
    this.preferredSupportedLocales = const <LocaleInfo>[],
    this.header = '',
    this.useDeferredLoading = false,
    required this.inputsAndOutputsListFile,
    this.useSyntheticPackage = true,
    this.projectDirectory,
    this.areResourceAttributesRequired = false,
    this.untranslatedMessagesFile,
    this.usesNullableGetter = true,
  });

  final FileSystem _fs;
  Iterable<Message> _allMessages = <Message>[];
  late final AppResourceBundleCollection _allBundles = AppResourceBundleCollection(inputDirectory);

  late final AppResourceBundle _templateBundle = AppResourceBundle(templateArbFile);
  late final LocaleInfo _templateArbLocale = _templateBundle.locale;

  @visibleForTesting
  final bool useSyntheticPackage;

  // Used to decide if the generated code is nullable or not
  // (whether AppLocalizations? or AppLocalizations is returned from
  // `static {name}Localizations{?} of (BuildContext context))`
  @visibleForTesting
  final bool usesNullableGetter;

  /// The directory that contains the project's arb files, as well as the
  /// header file, if specified.
  ///
  /// It is assumed that all input files (e.g. [templateArbFile], arb files
  /// for translated messages, header file templates) will reside here.
  final Directory inputDirectory;

  /// The Flutter project's root directory.
  final Directory? projectDirectory;

  /// The directory to generate the project's localizations files in.
  ///
  /// It is assumed that all output files (e.g. The localizations
  /// [outputFile], `messages_<locale>.dart` and `messages_all.dart`)
  /// will reside here.
  final Directory outputDirectory;

  /// The input arb file which defines all of the messages that will be
  /// exported by the generated class that's written to [outputFile].
  final File templateArbFile;

  /// The file to write the generated abstract localizations and
  /// localizations delegate classes to. Separate localizations
  /// files will also be generated for each language using this
  /// filename as a prefix and the locale as the suffix.
  final File baseOutputFile;

  /// The class name to be used for the localizations class in [outputFile].
  ///
  /// For example, if 'AppLocalizations' is passed in, a class named
  /// AppLocalizations will be used for localized message lookups.
  final String className;

  /// The list of preferred supported locales.
  ///
  /// By default, the list of supported locales in the localizations class
  /// will be sorted in alphabetical order. However, this option
  /// allows for a set of preferred locales to appear at the top of the
  /// list.
  ///
  /// The order of locales in this list will also be the order of locale
  /// priority. For example, if a device supports 'en' and 'es' and
  /// ['es', 'en'] is passed in, the 'es' locale will take priority over 'en'.
  final List<LocaleInfo> preferredSupportedLocales;

  /// The list of all arb path strings in [inputDirectory].
  List<String> get arbPathStrings {
    return _allBundles.bundles.map((AppResourceBundle bundle) => bundle.file.path).toList();
  }

  /// The supported language codes as found in the arb files located in
  /// [inputDirectory].
  final Set<String> supportedLanguageCodes = <String>{};

  /// The supported locales as found in the arb files located in
  /// [inputDirectory].
  final Set<LocaleInfo> supportedLocales = <LocaleInfo>{};

  /// The header to be prepended to the generated Dart localization file.
  final String header;

  final Map<LocaleInfo, List<String>> _unimplementedMessages = <LocaleInfo, List<String>>{};

  /// Whether to generate the Dart localization file with locales imported as
  /// deferred, allowing for lazy loading of each locale in Flutter web.
  ///
  /// This can reduce a web app’s initial startup time by decreasing the size of
  /// the JavaScript bundle. When [_useDeferredLoading] is set to true, the
  /// messages for a particular locale are only downloaded and loaded by the
  /// Flutter app as they are needed. For projects with a lot of different
  /// locales and many localization strings, it can be an performance
  /// improvement to have deferred loading. For projects with a small number of
  /// locales, the difference is negligible, and might slow down the start up
  /// compared to bundling the localizations with the rest of the application.
  ///
  /// Note that this flag does not affect other platforms such as mobile or
  /// desktop.
  final bool useDeferredLoading;

  /// Contains a map of each output language file to its corresponding content in
  /// string format.
  final Map<File, String> _languageFileMap = <File, String>{};

  /// A generated file that will contain the list of messages for each locale
  /// that do not have a translation yet.
  @visibleForTesting
  final File? untranslatedMessagesFile;

  /// The file that contains the list of inputs and outputs for generating
  /// localizations.
  @visibleForTesting
  final File? inputsAndOutputsListFile;
  final List<String> _inputFileList = <String>[];
  final List<String> _outputFileList = <String>[];

  /// Whether or not resource attributes are required for each corresponding
  /// resource id.
  ///
  /// Resource attributes provide metadata about the message.
  @visibleForTesting
  final bool areResourceAttributesRequired;

  static final RegExp _selectRE = RegExp(r'\{([\w\s,]*),\s*select\s*,\s*([\w\d]+\s*\{.*\})+\s*\}');

  static bool _isNotReadable(FileStat fileStat) {
    final String rawStatString = fileStat.modeString();
    // Removes potential prepended permission bits, such as '(suid)' and '(guid)'.
    final String statString = rawStatString.substring(rawStatString.length - 9);
    return !(statString[0] == 'r' || statString[3] == 'r' || statString[6] == 'r');
  }

  static bool _isNotWritable(FileStat fileStat) {
    final String rawStatString = fileStat.modeString();
    // Removes potential prepended permission bits, such as '(suid)' and '(guid)'.
    final String statString = rawStatString.substring(rawStatString.length - 9);
    return !(statString[1] == 'w' || statString[4] == 'w' || statString[7] == 'w');
  }

  @visibleForTesting
  static Directory? projectDirFromPath(FileSystem fileSystem, String? projectPathString) {
    if (projectPathString == null) {
      return null;
    }

    final Directory directory = fileSystem.directory(projectPathString);
    if (!directory.existsSync()) {
      throw L10nException(
        'Directory does not exist: $directory.\n'
        "Please select a directory that contains the project's localizations "
        'resource files.'
      );
    }
    return directory;
  }

  /// Sets the reference [Directory] for [inputDirectory].
  @visibleForTesting
  static Directory inputDirectoryFromPath(FileSystem fileSystem, String inputPathString, Directory? projectDirectory) {
    final Directory inputDirectory = fileSystem.directory(
      projectDirectory != null
        ? _getAbsoluteProjectPath(inputPathString, projectDirectory)
        : inputPathString
    );

    if (!inputDirectory.existsSync()) {
      throw L10nException(
        "The 'arb-dir' directory, '$inputDirectory', does not exist.\n"
        'Make sure that the correct path was provided.'
      );
    }

    final FileStat fileStat = inputDirectory.statSync();
    if (_isNotReadable(fileStat) || _isNotWritable(fileStat)) {
      throw L10nException(
        "The 'arb-dir' directory, '$inputDirectory', doesn't allow reading and writing.\n"
        'Please ensure that the user has read and write permissions.'
      );
    }
    return inputDirectory;
  }

  /// Sets the reference [Directory] for [outputDirectory].
  @visibleForTesting
  static Directory outputDirectoryFromPath(FileSystem fileSystem, String outputPathString, bool useSyntheticPackage, Directory? projectDirectory) {
    Directory outputDirectory;
    if (useSyntheticPackage) {
      outputDirectory = fileSystem.directory(
        projectDirectory != null
          ? _getAbsoluteProjectPath(_syntheticL10nPackagePath(fileSystem), projectDirectory)
          : _syntheticL10nPackagePath(fileSystem)
      );
    } else {
      outputDirectory = fileSystem.directory(
        projectDirectory != null
          ? _getAbsoluteProjectPath(outputPathString, projectDirectory)
          : outputPathString
      );
    }
    return outputDirectory;
  }

  /// Sets the reference [File] for [templateArbFile].
  @visibleForTesting
  static File templateArbFileFromFileName(String templateArbFileName, Directory inputDirectory) {
    final File templateArbFile = inputDirectory.childFile(templateArbFileName);
    final String templateArbFileStatModeString = templateArbFile.statSync().modeString();
    if (templateArbFileStatModeString[0] == '-' && templateArbFileStatModeString[3] == '-') {
      throw L10nException(
        "The 'template-arb-file', $templateArbFile, is not readable.\n"
        'Please ensure that the user has read permissions.'
      );
    }
    return templateArbFile;
  }

  static bool _isValidClassName(String className) {
    // Public Dart class name cannot begin with an underscore
    if (className[0] == '_') {
      return false;
    }
    // Dart class name cannot contain non-alphanumeric symbols
    if (className.contains(RegExp(r'[^a-zA-Z_\d]'))) {
      return false;
    }
    // Dart class name must start with upper case character
    if (className[0].contains(RegExp(r'[a-z]'))) {
      return false;
    }
    // Dart class name cannot start with a number
    if (className[0].contains(RegExp(r'\d'))) {
      return false;
    }
    return true;
  }

  /// Sets the [className] for the localizations and localizations delegate
  /// classes.
  @visibleForTesting
  static String classNameFromString(String classNameString) {
    if (classNameString.isEmpty) {
      throw L10nException('classNameString argument cannot be empty');
    }
    if (!_isValidClassName(classNameString)) {
      throw L10nException(
        "The 'output-class', $classNameString, is not a valid public Dart class name.\n"
      );
    }
    return classNameString;
  }

  /// Sets [preferredSupportedLocales] so that this particular list of locales
  /// will take priority over the other locales.
  @visibleForTesting
  static List<LocaleInfo> preferredSupportedLocalesFromLocales(List<String>? inputLocales) {
    if (inputLocales == null || inputLocales.isEmpty) {
      return const <LocaleInfo>[];
    }
    return inputLocales.map((String localeString) {
      return LocaleInfo.fromString(localeString);
    }).toList();
  }

  static String headerFromFile(String? headerString, String? headerFile, Directory inputDirectory) {
    if (headerString != null && headerFile != null) {
      throw L10nException(
        'Cannot accept both header and header file arguments. \n'
        'Please make sure to define only one or the other. '
      );
    }

    if (headerString != null) {
      return headerString;
    } else if (headerFile != null) {
      try {
        return inputDirectory.childFile(headerFile).readAsStringSync();
      } on FileSystemException catch (error) {
        throw L10nException (
          'Failed to read header file: "$headerFile". \n'
          'FileSystemException: ${error.message}'
        );
      }
    }
    return '';
  }

  static String _getAbsoluteProjectPath(String relativePath, Directory projectDirectory) =>
      projectDirectory.fileSystem.path.join(projectDirectory.path, relativePath);

  static File? _untranslatedMessagesFileFromPath(FileSystem fileSystem, String? untranslatedMessagesFileString) {
    if (untranslatedMessagesFileString == null || untranslatedMessagesFileString.isEmpty) {
      return null;
    }

    return fileSystem.file(untranslatedMessagesFileString);
  }

  static File? _inputsAndOutputsListFileFromPath(FileSystem fileSystem, String? inputsAndOutputsListPath) {
    if (inputsAndOutputsListPath == null) {
      return null;
    }

    return fileSystem.file(
      fileSystem.path.join(inputsAndOutputsListPath, 'gen_l10n_inputs_and_outputs.json'),
    );
  }

  static bool _isValidGetterAndMethodName(String name) {
    // Public Dart method name must not start with an underscore
    if (name[0] == '_') {
      return false;
    }
    // Dart getter and method name cannot contain non-alphanumeric symbols
    if (name.contains(RegExp(r'[^a-zA-Z_\d]'))) {
      return false;
    }
    // Dart method name must start with lower case character
    if (name[0].contains(RegExp(r'[A-Z]'))) {
      return false;
    }
    // Dart class name cannot start with a number
    if (name[0].contains(RegExp(r'\d'))) {
      return false;
    }
    return true;
  }

  // Load _allMessages from templateArbFile and _allBundles from all of the ARB
  // files in inputDirectory. Also initialized: supportedLocales.
  void loadResources() {
    _allMessages = _templateBundle.resourceIds.map((String id) => Message(
      _templateBundle.resources, id, areResourceAttributesRequired,
    ));
    for (final String resourceId in _templateBundle.resourceIds) {
      if (!_isValidGetterAndMethodName(resourceId)) {
        throw L10nException(
          'Invalid ARB resource name "$resourceId" in $templateArbFile.\n'
          'Resources names must be valid Dart method names: they have to be '
          'camel case, cannot start with a number or underscore, and cannot '
          'contain non-alphanumeric characters.'
        );
      }
    }

    if (inputsAndOutputsListFile != null) {
      _inputFileList.addAll(_allBundles.bundles.map((AppResourceBundle bundle) {
        return bundle.file.absolute.path;
      }));
    }

    final List<LocaleInfo> allLocales = List<LocaleInfo>.from(_allBundles.locales);
    for (final LocaleInfo preferredLocale in preferredSupportedLocales) {
      final int index = allLocales.indexOf(preferredLocale);
      if (index == -1) {
        throw L10nException(
          "The preferred supported locale, '$preferredLocale', cannot be "
          'added. Please make sure that there is a corresponding ARB file '
          'with translations for the locale, or remove the locale from the '
          'preferred supported locale list.'
        );
      }
      allLocales.removeAt(index);
      allLocales.insertAll(0, preferredSupportedLocales);
    }
    supportedLocales.addAll(allLocales);
  }

  void _addUnimplementedMessage(LocaleInfo locale, String message) {
    if (_unimplementedMessages.containsKey(locale)) {
      _unimplementedMessages[locale]!.add(message);
    } else {
      _unimplementedMessages.putIfAbsent(locale, () => <String>[message]);
    }
  }

  String _generateBaseClassFile(
    String className,
    String fileName,
    String header,
    AppResourceBundle bundle,
    AppResourceBundle templateBundle,
    Iterable<Message> messages,
  ) {
    final LocaleInfo locale = bundle.locale;

    final Iterable<String> methods = messages.map((Message message) {
      if (bundle.translationFor(message) == null) {
        _addUnimplementedMessage(locale, message.resourceId);
      }

      return _generateMethod(
        message,
        bundle.translationFor(message) ?? templateBundle.translationFor(message)!,
      );
    });

    return classFileTemplate
      .replaceAll('@(header)', header)
      .replaceAll('@(language)', describeLocale(locale.toString()))
      .replaceAll('@(baseClass)', className)
      .replaceAll('@(fileName)', fileName)
      .replaceAll('@(class)', '$className${locale.camelCase()}')
      .replaceAll('@(localeName)', locale.toString())
      .replaceAll('@(methods)', methods.join('\n\n'))
      .replaceAll('@(requiresIntlImport)', _requiresIntlImport() ? "import 'package:intl/intl.dart' as intl;" : '');
  }

  String _generateSubclass(
    String className,
    AppResourceBundle bundle,
    Iterable<Message> messages,
  ) {
    final LocaleInfo locale = bundle.locale;
    final String baseClassName = '$className${LocaleInfo.fromString(locale.languageCode).camelCase()}';

    messages
      .where((Message message) => bundle.translationFor(message) == null)
      .forEach((Message message) {
        _addUnimplementedMessage(locale, message.resourceId);
      });

    final Iterable<String> methods = messages
      .where((Message message) => bundle.translationFor(message) != null)
      .map((Message message) => _generateMethod(message, bundle.translationFor(message)!));

    return subclassTemplate
      .replaceAll('@(language)', describeLocale(locale.toString()))
      .replaceAll('@(baseLanguageClassName)', baseClassName)
      .replaceAll('@(class)', '$className${locale.camelCase()}')
      .replaceAll('@(localeName)', locale.toString())
      .replaceAll('@(methods)', methods.join('\n\n'));
  }

  // Generate the AppLocalizations class, its LocalizationsDelegate subclass,
  // and all AppLocalizations subclasses for every locale. This method by
  // itself does not generate the output files.
  String _generateCode() {
    bool isBaseClassLocale(LocaleInfo locale, String language) {
      return locale.languageCode == language
          && locale.countryCode == null
          && locale.scriptCode == null;
    }

    List<LocaleInfo> getLocalesForLanguage(String language) {
      return _allBundles.bundles
        // Return locales for the language specified, except for the base locale itself
        .where((AppResourceBundle bundle) {
          final LocaleInfo locale = bundle.locale;
          return !isBaseClassLocale(locale, language) && locale.languageCode == language;
        })
        .map((AppResourceBundle bundle) => bundle.locale).toList();
    }

    final String directory = _fs.path.basename(outputDirectory.path);
    final String outputFileName = _fs.path.basename(baseOutputFile.path);

    final Iterable<String> supportedLocalesCode = supportedLocales.map((LocaleInfo locale) {
      final String languageCode = locale.languageCode;
      final String? countryCode = locale.countryCode;
      final String? scriptCode = locale.scriptCode;

      if (countryCode == null && scriptCode == null) {
        return "Locale('$languageCode')";
      } else if (countryCode != null && scriptCode == null) {
        return "Locale('$languageCode', '$countryCode')";
      } else if (countryCode != null && scriptCode != null) {
        return "Locale.fromSubtags(languageCode: '$languageCode', countryCode: '$countryCode', scriptCode: '$scriptCode')";
      } else {
        return "Locale.fromSubtags(languageCode: '$languageCode', scriptCode: '$scriptCode')";
      }
    });

    final Set<String> supportedLanguageCodes = Set<String>.from(
      _allBundles.locales.map<String>((LocaleInfo locale) => "'${locale.languageCode}'")
    );

    final List<LocaleInfo> allLocales = _allBundles.locales.toList()..sort();
    final String fileName = outputFileName.split('.')[0];
    for (final LocaleInfo locale in allLocales) {
      if (isBaseClassLocale(locale, locale.languageCode)) {
        final File languageMessageFile = outputDirectory.childFile('${fileName}_$locale.dart');

        // Generate the template for the base class file. Further string
        // interpolation will be done to determine if there are
        // subclasses that extend the base class.
        final String languageBaseClassFile = _generateBaseClassFile(
          className,
          outputFileName,
          header,
          _allBundles.bundleFor(locale)!,
          _allBundles.bundleFor(_templateArbLocale)!,
          _allMessages,
        );

        // Every locale for the language except the base class.
        final List<LocaleInfo> localesForLanguage = getLocalesForLanguage(locale.languageCode);

        // Generate every subclass that is needed for the particular language
        final Iterable<String> subclasses = localesForLanguage.map<String>((LocaleInfo locale) {
          return _generateSubclass(
            className,
            _allBundles.bundleFor(locale)!,
            _allMessages,
          );
        });

        _languageFileMap.putIfAbsent(languageMessageFile, () {
          return languageBaseClassFile.replaceAll('@(subclasses)', subclasses.join());
        });
      }
    }

    final List<String> sortedClassImports = supportedLocales
      .where((LocaleInfo locale) => isBaseClassLocale(locale, locale.languageCode))
      .map((LocaleInfo locale) {
        final String library = '${fileName}_${locale.toString()}';
        if (useDeferredLoading) {
          return "import '$library.dart' deferred as $library;";
        } else {
          return "import '$library.dart';";
        }
      })
      .toList()
      ..sort();

    final String delegateClass = _generateDelegateClass(
      allBundles: _allBundles,
      className: className,
      supportedLanguageCodes: supportedLanguageCodes,
      useDeferredLoading: useDeferredLoading,
      fileName: fileName,
    );

    return fileTemplate
      .replaceAll('@(header)', header)
      .replaceAll('@(class)', className)
      .replaceAll('@(methods)', _allMessages.map((Message message) => generateBaseClassMethod(message, _templateArbLocale)).join('\n'))
      .replaceAll('@(importFile)', '$directory/$outputFileName')
      .replaceAll('@(supportedLocales)', supportedLocalesCode.join(',\n    '))
      .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.join(', '))
      .replaceAll('@(messageClassImports)', sortedClassImports.join('\n'))
      .replaceAll('@(delegateClass)', delegateClass)
      .replaceAll('@(requiresFoundationImport)', useDeferredLoading ? '' : "import 'package:flutter/foundation.dart';")
      .replaceAll('@(requiresIntlImport)', _requiresIntlImport() ? "import 'package:intl/intl.dart' as intl;" : '')
      .replaceAll('@(canBeNullable)', usesNullableGetter ? '?' : '')
      .replaceAll('@(needsNullCheck)', usesNullableGetter ? '' : '!')
      // Removes all trailing whitespace from the generated file.
      .split('\n').map((String line) => line.trimRight()).join('\n')
      // Cleans out unnecessary newlines.
      .replaceAll('\n\n\n', '\n\n');
  }

  bool _requiresIntlImport() => _allMessages.any((Message message) {
    return message.isPlural
        || message.isSelect
        || message.placeholdersRequireFormatting;
  });

  void writeOutputFiles(Logger logger, { bool isFromYaml = false }) {
    // First, generate the string contents of all necessary files.
    final String generatedLocalizationsFile = _generateCode();

    // A pubspec.yaml file is required when using a synthetic package. If it does not
    // exist, create a blank one.
    if (useSyntheticPackage) {
      final Directory syntheticPackageDirectory = _fs.directory(_defaultSyntheticPackagePath(_fs));
      syntheticPackageDirectory.createSync(recursive: true);
      final File flutterGenPubspec = syntheticPackageDirectory.childFile('pubspec.yaml');
      if (!flutterGenPubspec.existsSync()) {
        flutterGenPubspec.writeAsStringSync(emptyPubspecTemplate);
      }
    }

    // Since all validity checks have passed up to this point,
    // write the contents into the directory.
    outputDirectory.createSync(recursive: true);

    // Ensure that the created directory has read/write permissions.
    final FileStat fileStat = outputDirectory.statSync();
    if (_isNotReadable(fileStat) || _isNotWritable(fileStat)) {
      throw L10nException(
        "The 'output-dir' directory, $outputDirectory, doesn't allow reading and writing.\n"
        'Please ensure that the user has read and write permissions.'
      );
    }

    // Generate the required files for localizations.
    _languageFileMap.forEach((File file, String contents) {
      file.writeAsStringSync(contents);
      if (inputsAndOutputsListFile != null) {
        _outputFileList.add(file.absolute.path);
      }
    });

    baseOutputFile.writeAsStringSync(generatedLocalizationsFile);
    final File? messagesFile = untranslatedMessagesFile;
    if (messagesFile != null) {
      _generateUntranslatedMessagesFile(logger, messagesFile);
    } else if (_unimplementedMessages.isNotEmpty) {
      _unimplementedMessages.forEach((LocaleInfo locale, List<String> messages) {
        logger.printStatus('"$locale": ${messages.length} untranslated message(s).');
      });
      if (isFromYaml) {
        logger.printStatus(
          'To see a detailed report, use the untranslated-messages-file \n'
          'option in the l10n.yaml file:\n'
          'untranslated-messages-file: desiredFileName.txt\n'
          '<other option>: <other selection> \n\n'
        );
      } else {
        logger.printStatus(
          'To see a detailed report, use the --untranslated-messages-file \n'
          'option in the flutter gen-l10n tool:\n'
          'flutter gen-l10n --untranslated-messages-file=desiredFileName.txt\n'
          '<other options> \n\n'
        );
      }

      logger.printStatus(
        'This will generate a JSON format file containing all messages that \n'
        'need to be translated.'
      );
    }
    final File? inputsAndOutputsListFileLocal = inputsAndOutputsListFile;
    if (inputsAndOutputsListFileLocal != null) {
      _outputFileList.add(baseOutputFile.absolute.path);

      // Generate a JSON file containing the inputs and outputs of the gen_l10n script.
      if (!inputsAndOutputsListFileLocal.existsSync()) {
        inputsAndOutputsListFileLocal.createSync(recursive: true);
      }

      inputsAndOutputsListFileLocal.writeAsStringSync(
        json.encode(<String, Object> {
          'inputs': _inputFileList,
          'outputs': _outputFileList,
        }),
      );
    }
  }

  void _generateUntranslatedMessagesFile(Logger logger, File untranslatedMessagesFile) {
    if (_unimplementedMessages.isEmpty) {
      untranslatedMessagesFile.writeAsStringSync('{}');
      if (inputsAndOutputsListFile != null) {
        _outputFileList.add(untranslatedMessagesFile.absolute.path);
      }
      return;
    }

    String resultingFile = '{\n';
    int count = 0;
    final int numberOfLocales = _unimplementedMessages.length;
    _unimplementedMessages.forEach((LocaleInfo locale, List<String> messages) {
      resultingFile += '  "$locale": [\n';

      for (int i = 0; i < messages.length; i += 1) {
        resultingFile += '    "${messages[i]}"';
        if (i != messages.length - 1) {
          resultingFile += ',';
        }
        resultingFile += '\n';
      }

      resultingFile += '  ]';
      count += 1;
      if (count < numberOfLocales) {
        resultingFile += ',\n';
      }
      resultingFile += '\n';
    });

    resultingFile += '}\n';
    untranslatedMessagesFile.writeAsStringSync(resultingFile);
    if (inputsAndOutputsListFile != null) {
      _outputFileList.add(untranslatedMessagesFile.absolute.path);
    }
  }
}
