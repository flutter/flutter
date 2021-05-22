// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../convert.dart';
import '../flutter_manifest.dart';
import '../globals_null_migrated.dart' as globals;

import 'gen_l10n_templates.dart';
import 'gen_l10n_types.dart';
import 'localizations_utils.dart';

/// Run the localizations generation script with the configuration [options].
void generateLocalizations({
  @required Directory projectDir,
  @required Directory dependenciesDir,
  @required LocalizationOptions options,
  @required LocalizationsGenerator localizationsGenerator,
  @required Logger logger,
}) {
  // If generating a synthetic package, generate a warning if
  // flutter: generate is not set.
  final FlutterManifest flutterManifest = FlutterManifest.createFromPath(
    projectDir.childFile('pubspec.yaml').path,
    fileSystem: projectDir.fileSystem,
    logger: logger,
  );
  if (options.useSyntheticPackage && !flutterManifest.generateSyntheticPackage) {
    logger.printError(
      'Attempted to generate localizations code without having '
      'the flutter: generate flag turned on.'
      '\n'
      'Check pubspec.yaml and ensure that flutter: generate: true has '
      'been added and rebuild the project. Otherwise, the localizations '
      'source code will not be importable.'
    );
    throw Exception();
  }

  precacheLanguageAndRegionTags();

  final String inputPathString = options?.arbDirectory?.path ?? globals.fs.path.join('lib', 'l10n');
  final String templateArbFileName = options?.templateArbFile?.toFilePath() ?? 'app_en.arb';
  final String outputFileString = options?.outputLocalizationsFile?.toFilePath() ?? 'app_localizations.dart';

  try {
    localizationsGenerator
      ..initialize(
        inputsAndOutputsListPath: dependenciesDir?.path,
        projectPathString: projectDir.path,
        inputPathString: inputPathString,
        templateArbFileName: templateArbFileName,
        outputFileString: outputFileString,
        outputPathString: options?.outputDirectory?.path,
        classNameString: options.outputClass ?? 'AppLocalizations',
        preferredSupportedLocales: options.preferredSupportedLocales,
        headerString: options.header,
        headerFile: options?.headerFile?.toFilePath(),
        useDeferredLoading: options.deferredLoading ?? false,
        useSyntheticPackage: options.useSyntheticPackage ?? true,
        areResourceAttributesRequired: options.areResourceAttributesRequired ?? false,
        untranslatedMessagesFile: options?.untranslatedMessagesFile?.toFilePath(),
        usesNullableGetter: options?.usesNullableGetter ?? true,
      )
      ..loadResources()
      ..writeOutputFiles(logger, isFromYaml: true);
  } on L10nException catch (e) {
    logger.printError(e.message);
    throw Exception();
  }
}

/// The path for the synthetic package.
final String defaultSyntheticPackagePath = globals.fs.path.join('.dart_tool', 'flutter_gen');

/// The default path used when the `_useSyntheticPackage` setting is set to true
/// in [LocalizationsGenerator].
///
/// See [LocalizationsGenerator.initialize] for where and how it is used by the
/// localizations tool.
final String syntheticL10nPackagePath = globals.fs.path.join(defaultSyntheticPackagePath, 'gen_l10n');

List<String> generateMethodParameters(Message message) {
  assert(message.placeholders.isNotEmpty);
  final Placeholder countPlaceholder = message.isPlural ? message.getCountPlaceholder() : null;
  return message.placeholders.map((Placeholder placeholder) {
    final String type = placeholder == countPlaceholder ? 'int' : placeholder.type;
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
      if (placeholder.format == null) {
        throw L10nException(
          'The placeholder, ${placeholder.name}, has its "type" resource attribute set to '
          'the "${placeholder.type}" type. To properly resolve for the right '
          '${placeholder.type} format, the "format" attribute needs to be set '
          'to determine which DateFormat to use. \n'
          'Check the intl library\'s DateFormat class constructors for allowed '
          'date formats.'
        );
      }
      if (!placeholder.hasValidDateFormat) {
        throw L10nException(
          'Date format "${placeholder.format}" for placeholder '
          '${placeholder.name} does not have a corresponding DateFormat '
          'constructor\n. Check the intl library\'s DateFormat class '
          'constructors for allowed date formats.'
        );
      }
      return dateFormatTemplate
        .replaceAll('@(placeholder)', placeholder.name)
        .replaceAll('@(format)', placeholder.format);
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
      if (!placeholder.hasValidNumberFormat) {
        throw L10nException(
          'Number format ${placeholder.format} for the ${placeholder.name} '
          'placeholder does not have a corresponding NumberFormat constructor.\n'
          'Check the intl library\'s NumberFormat class constructors for allowed '
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
            .replaceAll('@(format)', placeholder.format)
            .replaceAll('@(parameters)', parameters.join(',\n      '));
      } else {
        return numberFormatPositionalTemplate
            .replaceAll('@(placeholder)', placeholder.name)
            .replaceAll('@(format)', placeholder.format);
      }
    });

  return formatStatements.isEmpty ? '@(none)' : formatStatements.join('');
}

String generatePluralMethod(Message message, AppResourceBundle bundle) {
  if (message.placeholders.isEmpty) {
    throw L10nException(
      'Unable to find placeholders for the plural message: ${message.resourceId}.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String easyMessage = bundle.translationFor(message);
  for (final Placeholder placeholder in message.placeholders) {
    easyMessage = easyMessage.replaceAll('{${placeholder.name}}', '#${placeholder.name}#');
  }

  final Placeholder countPlaceholder = message.getCountPlaceholder();
  if (countPlaceholder == null) {
    throw L10nException(
      'Unable to find the count placeholder for the plural message: ${message.resourceId}.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

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
    final RegExpMatch match = expRE.firstMatch(easyMessage);
    if (match != null && match.groupCount == 2) {
      String argValue = generateString(match.group(2));
      for (final Placeholder placeholder in message.placeholders) {
        if (placeholder != countPlaceholder && placeholder.requiresFormatting) {
          argValue = argValue.replaceAll(
            '#${placeholder.name}#',
            _needsCurlyBracketStringInterpolation(argValue, placeholder.name)
              ? '\${${placeholder.name}String}'
              : '\$${placeholder.name}String'
          );
        } else {
          argValue = argValue.replaceAll(
            '#${placeholder.name}#',
            _needsCurlyBracketStringInterpolation(argValue, placeholder.name)
              ? '\${${placeholder.name}}'
              : '\$${placeholder.name}'
          );
        }
      }
      pluralLogicArgs.add('      ${pluralIds[pluralKey]}: $argValue');
    }
  }

  final List<String> parameters = message.placeholders.map((Placeholder placeholder) {
    final String placeholderType = placeholder == countPlaceholder ? 'int' : placeholder.type;
    return '$placeholderType ${placeholder.name}';
  }).toList();

  final String comment = message.description ?? 'No description provided in @${message.resourceId}';

  return pluralMethodTemplate
    .replaceAll('@(comment)', comment)
    .replaceAll('@(name)', message.resourceId)
    .replaceAll('@(parameters)', parameters.join(', '))
    .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
    .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
    .replaceAll('@(count)', countPlaceholder.name)
    .replaceAll('@(pluralLogicArgs)', pluralLogicArgs.join(',\n'))
    .replaceAll('@(none)\n', '');
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

String generateMethod(Message message, AppResourceBundle bundle) {
  String generateMessage() {
    String messageValue = generateString(bundle.translationFor(message));
    for (final Placeholder placeholder in message.placeholders) {
      if (placeholder.requiresFormatting) {
        messageValue = messageValue.replaceAll(
          '{${placeholder.name}}',
          _needsCurlyBracketStringInterpolation(messageValue, placeholder.name)
            ? '\${${placeholder.name}String}'
            : '\$${placeholder.name}String'
        );
      } else {
        messageValue = messageValue.replaceAll(
          '{${placeholder.name}}',
          _needsCurlyBracketStringInterpolation(messageValue, placeholder.name)
            ? '\${${placeholder.name}}'
            : '\$${placeholder.name}'
        );
      }
    }

    return messageValue;
  }

  if (message.isPlural) {
    return generatePluralMethod(message, bundle);
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

String generateBaseClassMethod(Message message, LocaleInfo templateArbLocale) {
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
    switchClauses.join('\n    '),
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

    return nestedSwitchTemplate
      .replaceAll('@(languageCode)', language)
      .replaceAll('@(code)', 'scriptCode')
      .replaceAll('@(switchClauses)', localesWithScriptCodes.map((LocaleInfo locale) {
          return generateSwitchClauseTemplate(locale)
            .replaceAll('@(case)', locale.scriptCode);
        }).join('\n        '));
  }).where((String switchClause) => switchClause != null);

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when language+script codes are specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n    '),
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

    return nestedSwitchTemplate
      .replaceAll('@(languageCode)', language)
      .replaceAll('@(code)', 'countryCode')
      .replaceAll('@(switchClauses)', localesWithCountryCodes.map((LocaleInfo locale) {
          return generateSwitchClauseTemplate(locale)
            .replaceAll('@(case)', locale.countryCode);
        }).join('\n        '));
  }).where((String switchClause) => switchClause != null);

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
    }).join('\n        ');
  }).where((String switchClause) => switchClause != null);

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
  AppResourceBundleCollection allBundles,
  String className,
  Set<String> supportedLanguageCodes,
  bool useDeferredLoading,
  String fileName,
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
    .replaceAll('@(lookupName)', '_lookup$className');
  final String lookupFunction = (useDeferredLoading ?
  lookupFunctionDeferredLoadingTemplate : lookupFunctionTemplate)
    .replaceAll('@(class)', className)
    .replaceAll('@(lookupName)', '_lookup$className')
    .replaceAll('@(lookupBody)', lookupBody);
  return delegateClassTemplate
    .replaceAll('@(class)', className)
    .replaceAll('@(loadBody)', loadBody)
    .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.join(', '))
    .replaceAll('@(lookupFunction)', lookupFunction);
}

class LocalizationsGenerator {
  /// Creates an instance of the localizations generator class.
  ///
  /// It takes in a [FileSystem] representation that the class will act upon.
  LocalizationsGenerator(this._fs);

  final FileSystem _fs;
  Iterable<Message> _allMessages;
  AppResourceBundleCollection _allBundles;
  LocaleInfo _templateArbLocale;
  bool _useSyntheticPackage = true;
  // Used to decide if the generated code is nullable or not
  // (whether AppLocalizations? or AppLocalizations is returned from
  // `static {name}Localizations{?} of (BuildContext context))`
  bool _usesNullableGetter = true;

  /// The directory that contains the project's arb files, as well as the
  /// header file, if specified.
  ///
  /// It is assumed that all input files (e.g. [templateArbFile], arb files
  /// for translated messages, header file templates) will reside here.
  ///
  /// This directory is specified with the [initialize] method.
  Directory inputDirectory;

  /// The Flutter project's root directory.
  ///
  /// This directory is specified with the [initialize] method.
  Directory projectDirectory;

  /// The directory to generate the project's localizations files in.
  ///
  /// It is assumed that all output files (e.g. The localizations
  /// [outputFile], `messages_<locale>.dart` and `messages_all.dart`)
  /// will reside here.
  ///
  /// This directory is specified with the [initialize] method.
  Directory outputDirectory;

  /// The input arb file which defines all of the messages that will be
  /// exported by the generated class that's written to [outputFile].
  ///
  /// This file is specified with the [initialize] method.
  File templateArbFile;

  /// The file to write the generated abstract localizations and
  /// localizations delegate classes to. Separate localizations
  /// files will also be generated for each language using this
  /// filename as a prefix and the locale as the suffix.
  ///
  /// This file is specified with the [initialize] method.
  File baseOutputFile;

  /// The class name to be used for the localizations class in [outputFile].
  ///
  /// For example, if 'AppLocalizations' is passed in, a class named
  /// AppLocalizations will be used for localized message lookups.
  ///
  /// The class name is specified with the [initialize] method.
  String get className => _className;
  String _className;

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
  ///
  /// The list of preferred locales is specified with the [initialize] method.
  List<LocaleInfo> get preferredSupportedLocales => _preferredSupportedLocales;
  List<LocaleInfo> _preferredSupportedLocales;

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
  String header = '';

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
  bool get useDeferredLoading => _useDeferredLoading;
  bool _useDeferredLoading;

  /// Contains a map of each output language file to its corresponding content in
  /// string format.
  final Map<File, String> _languageFileMap = <File, String>{};

  /// Contains the generated application's localizations and localizations delegate
  /// classes.
  String _generatedLocalizationsFile;

  /// A generated file that will contain the list of messages for each locale
  /// that do not have a translation yet.
  File _untranslatedMessagesFile;

  /// The file that contains the list of inputs and outputs for generating
  /// localizations.
  File _inputsAndOutputsListFile;
  List<String> _inputFileList;
  List<String> _outputFileList;

  /// Whether or not resource attributes are required for each corresponding
  /// resource id.
  ///
  /// Resource attributes provide metadata about the message.
  bool _areResourceAttributesRequired;

  /// Initializes [inputDirectory], [outputDirectory], [templateArbFile],
  /// [outputFile] and [className].
  ///
  /// Throws an [L10nException] when a provided configuration is not allowed
  /// by [LocalizationsGenerator].
  ///
  /// Throws a [FileSystemException] when a file operation necessary for setting
  /// up the [LocalizationsGenerator] cannot be completed.
  void initialize({
    String inputPathString,
    String outputPathString,
    String templateArbFileName,
    String outputFileString,
    String classNameString,
    List<String> preferredSupportedLocales,
    String headerString,
    String headerFile,
    bool useDeferredLoading = false,
    String inputsAndOutputsListPath,
    bool useSyntheticPackage = true,
    String projectPathString,
    bool areResourceAttributesRequired = false,
    String untranslatedMessagesFile,
    bool usesNullableGetter = true,
  }) {
    _useSyntheticPackage = useSyntheticPackage;
    _usesNullableGetter = usesNullableGetter;
    setProjectDir(projectPathString);
    setInputDirectory(inputPathString);
    setOutputDirectory(outputPathString ?? inputPathString);
    setTemplateArbFile(templateArbFileName);
    setBaseOutputFile(outputFileString);
    setPreferredSupportedLocales(preferredSupportedLocales);
    _setHeader(headerString, headerFile);
    _setUseDeferredLoading(useDeferredLoading);
    _setUntranslatedMessagesFile(untranslatedMessagesFile);
    className = classNameString;
    _setInputsAndOutputsListFile(inputsAndOutputsListPath);
    _areResourceAttributesRequired = areResourceAttributesRequired;
  }

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
  void setProjectDir(String projectPathString) {
    if (projectPathString == null) {
      return;
    }

    final Directory directory = _fs.directory(projectPathString);
    if (!directory.existsSync()) {
      throw L10nException(
        'Directory does not exist: $directory.\n'
        'Please select a directory that contains the project\'s localizations '
        'resource files.'
      );
    }
    projectDirectory = directory;
  }

  /// Sets the reference [Directory] for [inputDirectory].
  @visibleForTesting
  void setInputDirectory(String inputPathString) {
    if (inputPathString == null) {
      throw L10nException('inputPathString argument cannot be null');
    }
    inputDirectory = _fs.directory(
      projectDirectory != null
        ? _getAbsoluteProjectPath(inputPathString)
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
  }

  /// Sets the reference [Directory] for [outputDirectory].
  @visibleForTesting
  void setOutputDirectory(
    String outputPathString,
  ) {
    if (_useSyntheticPackage) {
      outputDirectory = _fs.directory(
        projectDirectory != null
          ? _getAbsoluteProjectPath(syntheticL10nPackagePath)
          : syntheticL10nPackagePath
      );
    } else {
      if (outputPathString == null) {
        throw L10nException(
          'outputPathString argument cannot be null if not using '
          'synthetic package option.'
        );
      }

      outputDirectory = _fs.directory(
        projectDirectory != null
          ? _getAbsoluteProjectPath(outputPathString)
          : outputPathString
      );
    }
  }

  /// Sets the reference [File] for [templateArbFile].
  @visibleForTesting
  void setTemplateArbFile(String templateArbFileName) {
    if (templateArbFileName == null) {
      throw L10nException('templateArbFileName argument cannot be null');
    }
    if (inputDirectory == null) {
      throw L10nException('inputDirectory cannot be null when setting template arb file');
    }

    templateArbFile = _fs.file(globals.fs.path.join(inputDirectory.path, templateArbFileName));
    final String templateArbFileStatModeString = templateArbFile.statSync().modeString();
    if (templateArbFileStatModeString[0] == '-' && templateArbFileStatModeString[3] == '-') {
      throw L10nException(
        "The 'template-arb-file', $templateArbFile, is not readable.\n"
        'Please ensure that the user has read permissions.'
      );
    }
  }

  /// Sets the reference [File] for the localizations delegate [outputFile].
  @visibleForTesting
  void setBaseOutputFile(String outputFileString) {
    if (outputFileString == null) {
      throw L10nException('outputFileString argument cannot be null');
    }
    baseOutputFile = _fs.file(globals.fs.path.join(outputDirectory.path, outputFileString));
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
  set className(String classNameString) {
    if (classNameString == null || classNameString.isEmpty) {
      throw L10nException('classNameString argument cannot be null or empty');
    }
    if (!_isValidClassName(classNameString)) {
      throw L10nException(
        "The 'output-class', $classNameString, is not a valid public Dart class name.\n"
      );
    }
    _className = classNameString;
  }

  /// Sets [preferredSupportedLocales] so that this particular list of locales
  /// will take priority over the other locales.
  @visibleForTesting
  void setPreferredSupportedLocales(List<String> inputLocales) {
    if (inputLocales == null || inputLocales.isEmpty) {
      _preferredSupportedLocales = const <LocaleInfo>[];
    } else {
      _preferredSupportedLocales = inputLocales.map((String localeString) {
        return LocaleInfo.fromString(localeString);
      }).toList();
    }
  }

  void _setHeader(String headerString, String headerFile) {
    if (headerString != null && headerFile != null) {
      throw L10nException(
        'Cannot accept both header and header file arguments. \n'
        'Please make sure to define only one or the other. '
      );
    }

    if (headerString != null) {
      header = headerString;
    } else if (headerFile != null) {
      try {
        header = _fs.file(globals.fs.path.join(inputDirectory.path, headerFile)).readAsStringSync();
      } on FileSystemException catch (error) {
        throw L10nException (
          'Failed to read header file: "$headerFile". \n'
          'FileSystemException: ${error.message}'
        );
      }
    }
  }

  String _getAbsoluteProjectPath(String relativePath) => globals.fs.path.join(projectDirectory.path, relativePath);

  void _setUseDeferredLoading(bool useDeferredLoading) {
    if (useDeferredLoading == null) {
      throw L10nException('useDeferredLoading argument cannot be null.');
    }
    _useDeferredLoading = useDeferredLoading;
  }

  void _setUntranslatedMessagesFile(String untranslatedMessagesFileString) {
    if (untranslatedMessagesFileString == null || untranslatedMessagesFileString.isEmpty) {
      return;
    }

    _untranslatedMessagesFile = _fs.file(
      globals.fs.path.join(untranslatedMessagesFileString),
    );
  }

  void _setInputsAndOutputsListFile(String inputsAndOutputsListPath) {
    if (inputsAndOutputsListPath == null) {
      return;
    }

    _inputsAndOutputsListFile = _fs.file(
      globals.fs.path.join(inputsAndOutputsListPath, 'gen_l10n_inputs_and_outputs.json'),
    );

    _inputFileList = <String>[];
    _outputFileList = <String>[];
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
    final AppResourceBundle templateBundle = AppResourceBundle(templateArbFile);
    _templateArbLocale = templateBundle.locale;
    _allMessages = templateBundle.resourceIds.map((String id) => Message(
      templateBundle.resources, id, _areResourceAttributesRequired,
    ));
    for (final String resourceId in templateBundle.resourceIds) {
      if (!_isValidGetterAndMethodName(resourceId)) {
        throw L10nException(
          'Invalid ARB resource name "$resourceId" in $templateArbFile.\n'
          'Resources names must be valid Dart method names: they have to be '
          'camel case, cannot start with a number or underscore, and cannot '
          'contain non-alphanumeric characters.'
        );
      }
    }

    _allBundles = AppResourceBundleCollection(inputDirectory);
    if (_inputsAndOutputsListFile != null) {
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
      _unimplementedMessages[locale].add(message);
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

      return generateMethod(
        message,
        bundle.translationFor(message) == null ? templateBundle : bundle,
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
      .map((Message message) => generateMethod(message, bundle));

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
  void _generateCode() {
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

    final String directory = globals.fs.path.basename(outputDirectory.path);
    final String outputFileName = globals.fs.path.basename(baseOutputFile.path);

    final Iterable<String> supportedLocalesCode = supportedLocales.map((LocaleInfo locale) {
      final String languageCode = locale.languageCode;
      final String countryCode = locale.countryCode;
      final String scriptCode = locale.scriptCode;

      if (countryCode == null && scriptCode == null) {
        return 'Locale(\'$languageCode\')';
      } else if (countryCode != null && scriptCode == null) {
        return 'Locale(\'$languageCode\', \'$countryCode\')';
      } else if (countryCode != null && scriptCode != null) {
        return 'Locale.fromSubtags(languageCode: \'$languageCode\', countryCode: \'$countryCode\', scriptCode: \'$scriptCode\')';
      } else {
        return 'Locale.fromSubtags(languageCode: \'$languageCode\', scriptCode: \'$scriptCode\')';
      }
    });

    final Set<String> supportedLanguageCodes = Set<String>.from(
      _allBundles.locales.map<String>((LocaleInfo locale) => '\'${locale.languageCode}\'')
    );

    final List<LocaleInfo> allLocales = _allBundles.locales.toList()..sort();
    final String fileName = outputFileName.split('.')[0];
    for (final LocaleInfo locale in allLocales) {
      if (isBaseClassLocale(locale, locale.languageCode)) {
        final File languageMessageFile = _fs.file(
          globals.fs.path.join(outputDirectory.path, '${fileName}_$locale.dart'),
        );

        // Generate the template for the base class file. Further string
        // interpolation will be done to determine if there are
        // subclasses that extend the base class.
        final String languageBaseClassFile = _generateBaseClassFile(
          className,
          outputFileName,
          header,
          _allBundles.bundleFor(locale),
          _allBundles.bundleFor(_templateArbLocale),
          _allMessages,
        );

        // Every locale for the language except the base class.
        final List<LocaleInfo> localesForLanguage = getLocalesForLanguage(locale.languageCode);

        // Generate every subclass that is needed for the particular language
        final Iterable<String> subclasses = localesForLanguage.map<String>((LocaleInfo locale) {
          return _generateSubclass(
            className,
            _allBundles.bundleFor(locale),
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

    _generatedLocalizationsFile = fileTemplate
      .replaceAll('@(header)', header)
      .replaceAll('@(class)', className)
      .replaceAll('@(methods)', _allMessages.map((Message message) => generateBaseClassMethod(message, _templateArbLocale)).join('\n'))
      .replaceAll('@(importFile)', '$directory/$outputFileName')
      .replaceAll('@(supportedLocales)', supportedLocalesCode.join(',\n    '))
      .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.join(', '))
      .replaceAll('@(messageClassImports)', sortedClassImports.join('\n'))
      .replaceAll('@(delegateClass)', delegateClass)
      .replaceAll('@(requiresFoundationImport)', _useDeferredLoading ? '' : "import 'package:flutter/foundation.dart';")
      .replaceAll('@(requiresIntlImport)', _requiresIntlImport() ? "import 'package:intl/intl.dart' as intl;" : '')
      .replaceAll('@(canBeNullable)', _usesNullableGetter ? '?' : '')
      .replaceAll('@(needsNullCheck)', _usesNullableGetter ? '' : '!');
  }

  bool _requiresIntlImport() => _allMessages.any((Message message) => message.isPlural || message.placeholdersRequireFormatting);

  void writeOutputFiles(Logger logger, { bool isFromYaml = false }) {
    // First, generate the string contents of all necessary files.
    _generateCode();

    // A pubspec.yaml file is required when using a synthetic package. If it does not
    // exist, create a blank one.
    if (_useSyntheticPackage) {
      final Directory syntheticPackageDirectory = _fs.directory(defaultSyntheticPackagePath);
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
      if (_inputsAndOutputsListFile != null) {
        _outputFileList.add(file.absolute.path);
      }
    });

    baseOutputFile.writeAsStringSync(_generatedLocalizationsFile);

    if (_untranslatedMessagesFile != null) {
      _generateUntranslatedMessagesFile(logger);
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

    if (_inputsAndOutputsListFile != null) {
      _outputFileList.add(baseOutputFile.absolute.path);

      // Generate a JSON file containing the inputs and outputs of the gen_l10n script.
      if (!_inputsAndOutputsListFile.existsSync()) {
        _inputsAndOutputsListFile.createSync(recursive: true);
      }

      _inputsAndOutputsListFile.writeAsStringSync(
        json.encode(<String, Object> {
          'inputs': _inputFileList,
          'outputs': _outputFileList,
        }),
      );
    }
  }

  void _generateUntranslatedMessagesFile(Logger logger) {
    if (logger == null) {
      throw L10nException(
        'Logger must be defined when generating untranslated messages file.'
      );
    }

    if (_unimplementedMessages.isEmpty) {
      _untranslatedMessagesFile.writeAsStringSync('{}');
      if (_inputsAndOutputsListFile != null) {
        _outputFileList.add(_untranslatedMessagesFile.absolute.path);
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
    _untranslatedMessagesFile.writeAsStringSync(resultingFile);
    if (_inputsAndOutputsListFile != null) {
      _outputFileList.add(_untranslatedMessagesFile.absolute.path);
    }
  }
}
