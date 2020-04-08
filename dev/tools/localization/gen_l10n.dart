// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart' as file;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'gen_l10n_templates.dart';
import 'gen_l10n_types.dart';
import 'localizations_utils.dart';

List<String> generateMethodParameters(Message message) {
  assert(message.placeholders.isNotEmpty);
  final Placeholder countPlaceholder = message.isPlural ? message.getCountPlaceholder() : null;
  return message.placeholders.map((Placeholder placeholder) {
    final String type = placeholder == countPlaceholder ? 'int' : placeholder.type;
    return '$type ${placeholder.name}';
  }).toList();
}

String generateDateFormattingLogic(Message message) {
  if (message.placeholders.isEmpty || !message.placeholdersRequireFormatting)
    return '@(none)';

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
          return '${parameter.name}: ${parameter.value}';
        },
      );
      return numberFormatTemplate
        .replaceAll('@(placeholder)', placeholder.name)
        .replaceAll('@(format)', placeholder.format)
        .replaceAll('@(parameters)', parameters.join(',    \n'));
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
  for (final Placeholder placeholder in message.placeholders)
    easyMessage = easyMessage.replaceAll('{${placeholder.name}}', '#${placeholder.name}#');

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
    'other': 'other'
  };

  final List<String> pluralLogicArgs = <String>[];
  for (final String pluralKey in pluralIds.keys) {
    final RegExp expRE = RegExp('($pluralKey)\\s*{([^}]+)}');
    final RegExpMatch match = expRE.firstMatch(easyMessage);
    if (match != null && match.groupCount == 2) {
      String argValue = generateString(match.group(2));
      for (final Placeholder placeholder in message.placeholders) {
        if (placeholder != countPlaceholder && placeholder.requiresFormatting) {
          argValue = argValue.replaceAll('#${placeholder.name}#', '\${${placeholder.name}String}');
        } else {
          argValue = argValue.replaceAll('#${placeholder.name}#', '\${${placeholder.name}}');
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

String generateMethod(Message message, AppResourceBundle bundle) {
  String generateMessage() {
    String messageValue = generateString(bundle.translationFor(message));
    for (final Placeholder placeholder in message.placeholders) {
      if (placeholder.requiresFormatting) {
        messageValue = messageValue.replaceAll('{${placeholder.name}}', '\${${placeholder.name}String}');
      } else {
        messageValue = messageValue.replaceAll('{${placeholder.name}}', '\${${placeholder.name}}');
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

String generateBaseClassMethod(Message message) {
  final String comment = message.description ?? 'No description provided in @${message.resourceId}';
  if (message.placeholders.isNotEmpty) {
    return baseClassMethodTemplate
      .replaceAll('@(comment)', comment)
      .replaceAll('@(name)', message.resourceId)
      .replaceAll('@(parameters)', generateMethodParameters(message).join(', '));
  }
  return baseClassGetterTemplate
    .replaceAll('@(comment)', comment)
    .replaceAll('@(name)', message.resourceId);
}

String _generateLookupByAllCodes(AppResourceBundleCollection allBundles, String className) {
  final Iterable<LocaleInfo> localesWithAllCodes = allBundles.locales.where((LocaleInfo locale) {
    return locale.scriptCode != null && locale.countryCode != null;
  });

  if (localesWithAllCodes.isEmpty) {
    return '';
  }

  final Iterable<String> switchClauses = localesWithAllCodes.map<String>((LocaleInfo locale) {
    return switchClauseTemplate
      .replaceAll('@(case)', locale.toString())
      .replaceAll('@(class)', '$className${locale.camelCase()}');
  });

  return allCodesLookupTemplate.replaceAll(
    '@(allCodesSwitchClauses)',
    switchClauses.join('\n    '),
  );
}

String _generateLookupByScriptCode(AppResourceBundleCollection allBundles, String className) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithScriptCodes = locales.where((LocaleInfo locale) {
      return locale.scriptCode != null && locale.countryCode == null;
    });

    if (localesWithScriptCodes.isEmpty)
      return null;

    return nestedSwitchTemplate
      .replaceAll('@(languageCode)', language)
      .replaceAll('@(code)', 'scriptCode')
      .replaceAll('@(class)', '$className${LocaleInfo.fromString(language).camelCase()}')
      .replaceAll('@(switchClauses)', localesWithScriptCodes.map((LocaleInfo locale) {
          return switchClauseTemplate
            .replaceAll('@(case)', locale.scriptCode)
            .replaceAll('@(class)', '$className${locale.camelCase()}');
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

String _generateLookupByCountryCode(AppResourceBundleCollection allBundles, String className) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithCountryCodes = locales.where((LocaleInfo locale) {
      return locale.countryCode != null && locale.scriptCode == null;
    });

    if (localesWithCountryCodes.isEmpty)
      return null;

    return nestedSwitchTemplate
      .replaceAll('@(languageCode)', language)
      .replaceAll('@(code)', 'countryCode')
      .replaceAll('@(class)', '$className${LocaleInfo.fromString(language).camelCase()}')
      .replaceAll('@(switchClauses)', localesWithCountryCodes.map((LocaleInfo locale) {
          return switchClauseTemplate
            .replaceAll('@(case)', locale.countryCode)
            .replaceAll('@(class)', '$className${locale.camelCase()}');
        }).join('\n        '));
  }).where((String switchClause) => switchClause != null);

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when language+country codes are specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n    '));
}

String _generateLookupByLanguageCode(AppResourceBundleCollection allBundles, String className) {
  final Iterable<String> switchClauses = allBundles.languages.map((String language) {
    final Iterable<LocaleInfo> locales = allBundles.localesForLanguage(language);
    final Iterable<LocaleInfo> localesWithLanguageCode = locales.where((LocaleInfo locale) {
      return locale.countryCode == null && locale.scriptCode == null;
    });

    if (localesWithLanguageCode.isEmpty)
      return null;

    return localesWithLanguageCode.map((LocaleInfo locale) {
      return switchClauseTemplate
        .replaceAll('@(case)', locale.languageCode)
        .replaceAll('@(class)', '$className${locale.camelCase()}');
    }).join('\n        ');
  }).where((String switchClause) => switchClause != null);

  if (switchClauses.isEmpty) {
    return '';
  }

  return languageCodeSwitchTemplate
    .replaceAll('@(comment)', '// Lookup logic when only language code is specified.')
    .replaceAll('@(switchClauses)', switchClauses.join('\n    '));
}

String _generateLookupBody(AppResourceBundleCollection allBundles, String className) {
  return lookupBodyTemplate
    .replaceAll('@(lookupAllCodesSpecified)', _generateLookupByAllCodes(allBundles, className))
    .replaceAll('@(lookupScriptCodeSpecified)', _generateLookupByScriptCode(allBundles, className))
    .replaceAll('@(lookupCountryCodeSpecified)', _generateLookupByCountryCode(allBundles, className))
    .replaceAll('@(lookupLanguageCodeSpecified)', _generateLookupByLanguageCode(allBundles, className));
}

class LocalizationsGenerator {
  /// Creates an instance of the localizations generator class.
  ///
  /// It takes in a [FileSystem] representation that the class will act upon.
  LocalizationsGenerator(this._fs);

  final file.FileSystem _fs;
  Iterable<Message> _allMessages;
  AppResourceBundleCollection _allBundles;
  LocaleInfo _templateArbLocale;

  /// The reference to the project's l10n directory.
  ///
  /// It is assumed that all input files (e.g. [templateArbFile], arb files
  /// for translated messages) and output files (e.g. The localizations
  /// [outputFile], `messages_<locale>.dart` and `messages_all.dart`)
  /// will reside here.
  ///
  /// This directory is specified with the [initialize] method.
  Directory l10nDirectory;

  /// The input arb file which defines all of the messages that will be
  /// exported by the generated class that's written to [outputFile].
  ///
  /// This file is specified with the [initialize] method.
  File templateArbFile;

  /// The file to write the generated localizations and localizations delegate
  /// classes to.
  ///
  /// This file is specified with the [initialize] method.
  File outputFile;

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

  /// The list of all arb path strings in [l10nDirectory].
  List<String> get arbPathStrings {
    return _allBundles.bundles.map((AppResourceBundle bundle) => bundle.file.path).toList();
  }

  /// The supported language codes as found in the arb files located in
  /// [l10nDirectory].
  final Set<String> supportedLanguageCodes = <String>{};

  /// The supported locales as found in the arb files located in
  /// [l10nDirectory].
  final Set<LocaleInfo> supportedLocales = <LocaleInfo>{};

  /// The header to be prepended to the generated Dart localization file.
  String header = '';

  final Map<LocaleInfo, List<String>> _unimplementedMessages = <LocaleInfo, List<String>>{};

  /// Initializes [l10nDirectory], [templateArbFile], [outputFile] and [className].
  ///
  /// Throws an [L10nException] when a provided configuration is not allowed
  /// by [LocalizationsGenerator].
  ///
  /// Throws a [FileSystemException] when a file operation necessary for setting
  /// up the [LocalizationsGenerator] cannot be completed.
  void initialize({
    String l10nDirectoryPath,
    String templateArbFileName,
    String outputFileString,
    String classNameString,
    String preferredSupportedLocaleString,
    String headerString,
    String headerFile,
  }) {
    setL10nDirectory(l10nDirectoryPath);
    setTemplateArbFile(templateArbFileName);
    setOutputFile(outputFileString);
    setPreferredSupportedLocales(preferredSupportedLocaleString);
    _setHeader(headerString, headerFile);
    className = classNameString;
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

  /// Sets the reference [Directory] for [l10nDirectory].
  @visibleForTesting
  void setL10nDirectory(String arbPathString) {
    if (arbPathString == null)
      throw L10nException('arbPathString argument cannot be null');
    l10nDirectory = _fs.directory(arbPathString);
    if (!l10nDirectory.existsSync())
      throw FileSystemException(
        "The 'arb-dir' directory, $l10nDirectory, does not exist.\n"
        'Make sure that the correct path was provided.'
      );

    final FileStat fileStat = l10nDirectory.statSync();
    if (_isNotReadable(fileStat) || _isNotWritable(fileStat))
      throw FileSystemException(
        "The 'arb-dir' directory, $l10nDirectory, doesn't allow reading and writing.\n"
        'Please ensure that the user has read and write permissions.'
      );
  }

  /// Sets the reference [File] for [templateArbFile].
  @visibleForTesting
  void setTemplateArbFile(String templateArbFileName) {
    if (templateArbFileName == null)
      throw L10nException('templateArbFileName argument cannot be null');
    if (l10nDirectory == null)
      throw L10nException('l10nDirectory cannot be null when setting template arb file');

    templateArbFile = _fs.file(path.join(l10nDirectory.path, templateArbFileName));
    final String templateArbFileStatModeString = templateArbFile.statSync().modeString();
    if (templateArbFileStatModeString[0] == '-' && templateArbFileStatModeString[3] == '-')
      throw FileSystemException(
        "The 'template-arb-file', $templateArbFile, is not readable.\n"
        'Please ensure that the user has read permissions.'
      );
  }

  /// Sets the reference [File] for the localizations delegate [outputFile].
  @visibleForTesting
  void setOutputFile(String outputFileString) {
    if (outputFileString == null)
      throw L10nException('outputFileString argument cannot be null');
    outputFile = _fs.file(path.join(l10nDirectory.path, outputFileString));
  }

  static bool _isValidClassName(String className) {
    // Public Dart class name cannot begin with an underscore
    if (className[0] == '_')
      return false;
    // Dart class name cannot contain non-alphanumeric symbols
    if (className.contains(RegExp(r'[^a-zA-Z_\d]')))
      return false;
    // Dart class name must start with upper case character
    if (className[0].contains(RegExp(r'[a-z]')))
      return false;
    // Dart class name cannot start with a number
    if (className[0].contains(RegExp(r'\d')))
      return false;
    return true;
  }

  /// Sets the [className] for the localizations and localizations delegate
  /// classes.
  @visibleForTesting
  set className(String classNameString) {
    if (classNameString == null || classNameString.isEmpty)
      throw L10nException('classNameString argument cannot be null or empty');
    if (!_isValidClassName(classNameString))
      throw L10nException(
        "The 'output-class', $classNameString, is not a valid public Dart class name.\n"
      );
    _className = classNameString;
  }

  /// Sets [preferredSupportedLocales] so that this particular list of locales
  /// will take priority over the other locales.
  @visibleForTesting
  void setPreferredSupportedLocales(String inputLocales) {
    if (inputLocales == null || inputLocales.trim().isEmpty) {
      _preferredSupportedLocales = const <LocaleInfo>[];
    } else {
      final List<dynamic> preferredLocalesStringList = json.decode(inputLocales) as List<dynamic>;
      _preferredSupportedLocales = preferredLocalesStringList.map((dynamic localeString) {
        if (localeString.runtimeType != String) {
          throw L10nException('Incorrect runtime type for $localeString');
        }
        return LocaleInfo.fromString(
          localeString.toString(),
        );
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
        header = _fs.file(path.join(l10nDirectory.path, headerFile)).readAsStringSync();
      } on FileSystemException catch (error) {
        throw L10nException (
          'Failed to read header file: "$headerFile". \n'
          'FileSystemException: ${error.message}'
        );
      }
    }
  }

  static bool _isValidGetterAndMethodName(String name) {
    // Public Dart method name must not start with an underscore
    if (name[0] == '_')
      return false;
    // Dart getter and method name cannot contain non-alphanumeric symbols
    if (name.contains(RegExp(r'[^a-zA-Z_\d]')))
      return false;
    // Dart method name must start with lower case character
    if (name[0].contains(RegExp(r'[A-Z]')))
      return false;
    // Dart class name cannot start with a number
    if (name[0].contains(RegExp(r'\d')))
      return false;
    return true;
  }

  // Load _allMessages from templateArbFile and _allBundles from all of the ARB
  // files in l10nDirectory. Also initialized: supportedLocales.
  void loadResources() {
    final AppResourceBundle templateBundle = AppResourceBundle(templateArbFile);
    _templateArbLocale = templateBundle.locale;
    _allMessages = templateBundle.resourceIds.map((String id) => Message(templateBundle.resources, id));
    for (final String resourceId in templateBundle.resourceIds)
      if (!_isValidGetterAndMethodName(resourceId)) {
        throw L10nException(
          'Invalid ARB resource name "$resourceId" in $templateArbFile.\n'
          'Resources names must be valid Dart method names: they have to be '
          'camel case, cannot start with a number or underscore, and cannot '
          'contain non-alphanumeric characters.'
        );
      }

    _allBundles = AppResourceBundleCollection(l10nDirectory);

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
      .replaceAll('@(methods)', methods.join('\n\n'));
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
  // and all AppLocalizations subclasses for every locale.
  String generateCode() {
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

    final String directory = path.basename(l10nDirectory.path);
    final String outputFileName = path.basename(outputFile.path);

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
        final File localeMessageFile = _fs.file(
          path.join(l10nDirectory.path, '${fileName}_$locale.dart'),
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

        localeMessageFile.writeAsStringSync(
          languageBaseClassFile.replaceAll('@(subclasses)', subclasses.join()),
        );
      }
    }

    final Iterable<String> localeImports = supportedLocales
      .where((LocaleInfo locale) => isBaseClassLocale(locale, locale.languageCode))
      .map((LocaleInfo locale) {
        return "import '${fileName}_${locale.toString()}.dart';";
      });

    final String lookupBody = _generateLookupBody(_allBundles, className);

    return fileTemplate
      .replaceAll('@(header)', header)
      .replaceAll('@(class)', className)
      .replaceAll('@(methods)', _allMessages.map(generateBaseClassMethod).join('\n'))
      .replaceAll('@(importFile)', '$directory/$outputFileName')
      .replaceAll('@(supportedLocales)', supportedLocalesCode.join(',\n    '))
      .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.join(', '))
      .replaceAll('@(messageClassImports)', localeImports.join('\n'))
      .replaceAll('@(lookupName)', '_lookup$className')
      .replaceAll('@(lookupBody)', lookupBody);
  }

  void writeOutputFile() {
    outputFile.writeAsStringSync(generateCode());
  }

  void outputUnimplementedMessages(String untranslatedMessagesFile) {
    if (untranslatedMessagesFile == null || untranslatedMessagesFile == '') {
      _unimplementedMessages.forEach((LocaleInfo locale, List<String> messages) {
        stdout.writeln('"$locale": ${messages.length} untranslated message(s).');
      });
      stdout.writeln(
        'To see a detailed report, use the --unimplemented-messages-file \n'
        'option in the tool to generate a JSON format file containing \n'
        'all messages that need to be translated.'
      );
    } else {
      _writeUnimplementedMessagesFile(untranslatedMessagesFile);
    }
  }

  void _writeUnimplementedMessagesFile(String untranslatedMessagesFile) {
    if (_unimplementedMessages.isEmpty) {
      return;
    }

    final File unimplementedMessageTranslationsFile = _fs.file(untranslatedMessagesFile);

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
    unimplementedMessageTranslationsFile.writeAsStringSync(resultingFile);
  }
}
