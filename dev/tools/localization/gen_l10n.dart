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

// The set of date formats that can be automatically localized.
//
// The localizations generation tool makes use of the intl library's
// DateFormat class to properly format dates based on the locale, the
// desired format, as well as the passed in [DateTime]. For example, using
// DateFormat.yMMMMd("en_US").format(DateTime.utc(1996, 7, 10)) results
// in the string "July 10, 1996".
//
// Since the tool generates code that uses DateFormat's constructor, it is
// necessary to verify that the constructor exists, or the
// tool will generate code that may cause a compile-time error.
//
// See also:
//
// * <https://pub.dev/packages/intl>
// * <https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html>
// * <https://api.dartlang.org/stable/2.7.0/dart-core/DateTime-class.html>
const Set<String> allowableDateFormats = <String>{
  'd',
  'E',
  'EEEE',
  'LLL',
  'LLLL',
  'M',
  'Md',
  'MEd',
  'MMM',
  'MMMd',
  'MMMEd',
  'MMMM',
  'MMMMd',
  'MMMMEEEEd',
  'QQQ',
  'QQQQ',
  'y',
  'yM',
  'yMd',
  'yMEd',
  'yMMM',
  'yMMMd',
  'yMMMEd',
  'yMMMM',
  'yMMMMd',
  'yMMMMEEEEd',
  'yQQQ',
  'yQQQQ',
  'H',
  'Hm',
  'Hms',
  'j',
  'jm',
  'jms',
  'jmv',
  'jmz',
  'jv',
  'jz',
  'm',
  'ms',
  's',
};

// The set of number formats that can be automatically localized.
//
// The localizations generation tool makes use of the intl library's
// NumberFormat class to properly format numbers based on the locale, the
// desired format, as well as the passed in number. For example, using
// DateFormat.compactLong("en_US").format(1200000) results
// in the string "1.2 million".
//
// Since the tool generates code that uses NumberFormat's constructor, it is
// necessary to verify that the constructor exists, or the
// tool will generate code that may cause a compile-time error.
//
// See also:
//
// * <https://pub.dev/packages/intl>
// * <https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html>
const Set<String> allowableNumberFormats = <String>{
  'compact',
  'compactCurrency',
  'compactSimpleCurrency',
  'compactLong',
  'currency',
  'decimalPattern',
  'decimalPercentPattern',
  'percentPattern',
  'scientificPattern',
  'simpleCurrency',
};

// The names of the NumberFormat factory constructors which have named
// parameters rather than positional parameters.
//
// This helps the tool correctly generate number formmatting code correctly.
//
// Example of code that uses named parameters:
// final NumberFormat format = NumberFormat.compact(
//   locale: _localeName,
// );
//
// Example of code that uses positional parameters:
// final NumberFormat format = NumberFormat.scientificPattern(_localeName);
const Set<String> numberFormatsWithNamedParameters = <String>{
  'compact',
  'compactCurrency',
  'compactSimpleCurrency',
  'compactLong',
  'currency',
  'decimalPercentPattern',
  'simpleCurrency',
};

List<String> generateIntlMethodArgs(Message message) {
  final List<String> methodArgs = <String>["name: '${message.resourceId}'"];
  if (message.description != null)
    methodArgs.add('desc: ${generateString(message.description)}');
  if (message.placeholders.isNotEmpty) {
    final String args = message.placeholders.map<String>((Placeholder placeholder) {
      return placeholder.name;
    }).join(', ');
    methodArgs.add('args: <Object>[$args]');
  }
  return methodArgs;
}

List<String> generateInnerMethodArgs(Message message) {
  return message.placeholders.map((Placeholder placeholder) {
    final String arg = placeholder.name;
    return placeholder.requiresFormatting ? '${arg}String' : arg;
  }).toList();
}

String generateDateFormattingLogic(Message message) {
  if (message.placeholders.isEmpty)
    return '';

  final StringBuffer result = StringBuffer();
  for (final Placeholder placeholder in message.placeholders) {
    if (!placeholder.isDate)
      continue;
    if (placeholder.format == null) {
      throw L10nException(
        'The placeholder, ${placeholder.name}, has its "type" resource attribute set to '
        'the "${placeholder.type}" type. To properly resolve for the right '
        '${placeholder.type} format, the "format" attribute needs to be set '
        'to determine which DateFormat to use. \n'
        "Check the intl library's DateFormat class constructors for allowed "
        'date formats.'
      );
    }
    if (!allowableDateFormats.contains(placeholder.format)) {
      throw L10nException(
        'Date format "${placeholder.format}" for placeholder '
        '${placeholder.name} does not have a corresponding DateFormat '
        "constructor\n. Check the intl library's DateFormat class "
        'constructors for allowed date formats.'
      );
    }
    result.write('''

    final DateFormat ${placeholder.name}DateFormat = DateFormat.${placeholder.format}(_localeName);
    final String ${placeholder.name}String = ${placeholder.name}DateFormat.format(${placeholder.name});
''');
  }
  return result.toString();
}

String generateNumberFormattingLogic(Message message) {
  if (message.placeholders.isEmpty)
    return '';

  final StringBuffer result = StringBuffer();
  for (final Placeholder placeholder in message.placeholders) {
    if (!placeholder.isNumber)
      continue;
    if (!allowableNumberFormats.contains(placeholder.format)) {
      throw L10nException(
        'Number format ${placeholder.format} for the ${placeholder.name} '
        'placeholder does not have a corresponding NumberFormat constructor.\n'
        "Check the intl library's NumberFormat class constructors for allowed "
        'number formats.'
      );
    }
    if (numberFormatsWithNamedParameters.contains(placeholder.format)) {
      final StringBuffer optionalParametersString = StringBuffer();
      for (final OptionalParameter parameter in placeholder.optionalParameters)
        optionalParametersString.write('\n      ${parameter.name}: ${parameter.value},');
      result.write('''

    final NumberFormat ${placeholder.name}NumberFormat = NumberFormat.${placeholder.format}(
      locale: _localeName,${optionalParametersString.toString()}
    );
    final String ${placeholder.name}String = ${placeholder.name}NumberFormat.format(${placeholder.name});
''');

    } else {
          result.write('''

    final NumberFormat ${placeholder.name}NumberFormat = NumberFormat.${placeholder.format}(_localeName);
    final String ${placeholder.name}String = ${placeholder.name}NumberFormat.format(${placeholder.name});
''');
    }
  }
  return result.toString();
}

String genSimpleMethod(Message message) {
  String genSimpleMethodMessage() {
    String messageValue = message.value;
    for (final Placeholder placeholder in message.placeholders) {
        messageValue = messageValue.replaceAll('{${placeholder.name}}', '\${${placeholder.name}}');
    }
    final String generatedMessage = generateString(messageValue); // "r'...'"
    return generatedMessage.startsWith('r') ? generatedMessage.substring(1) : generatedMessage;
  }

  List<String> genMethodParameters([String type]) {
    return message.placeholders.map((Placeholder placeholder) {
      return '${type ?? placeholder.type} ${placeholder.name}';
    }).toList();
  }

  if (message.placeholdersRequireFormatting) {
    return formatMethodTemplate
      .replaceAll('@(methodName)', message.resourceId)
      .replaceAll('@(methodParameters)', genMethodParameters().join(', '))
      .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
      .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
      .replaceAll('@(message)', genSimpleMethodMessage())
      .replaceAll('@(innerMethodParameters)', genMethodParameters('Object').join(', '))
      .replaceAll('@(innerMethodArgs)', generateInnerMethodArgs(message).join(', '))
      .replaceAll('@(intlMethodArgs)', generateIntlMethodArgs(message).join(',\n        '));
  }

  if (message.placeholders.isNotEmpty) {
    return simpleMethodTemplate
      .replaceAll('@(methodName)', message.resourceId)
      .replaceAll('@(methodParameters)', genMethodParameters().join(', '))
      .replaceAll('@(message)', genSimpleMethodMessage())
      .replaceAll('@(intlMethodArgs)', generateIntlMethodArgs(message).join(',\n      '));
  }

  return getterMethodTemplate
    .replaceAll('@(methodName)', message.resourceId)
    .replaceAll('@(message)', genSimpleMethodMessage())
    .replaceAll('@(intlMethodArgs)', generateIntlMethodArgs(message).join(',\n      '));
}


String generatePluralMethod(Message message) {
  if (message.placeholders.isEmpty) {
    throw L10nException(
      'Unable to find placeholders for the plural message: ${message.resourceId}.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String easyMessage = message.value;
  for (final Placeholder placeholder in message.placeholders)
    easyMessage = easyMessage.replaceAll('{${placeholder.name}}', '#${placeholder.name}#');

  const Map<String, String> pluralIds = <String, String>{
    '=0': 'zero',
    '=1': 'one',
    '=2': 'two',
    'few': 'few',
    'many': 'many',
    'other': 'other'
  };

  final Placeholder countPlaceholder = message.getCountPlaceholder();
  if (countPlaceholder == null) {
    throw L10nException(
      'Unable to find the count placeholder for the plural message: ${message.resourceId}.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  }

  final List<String> intlMethodArgs = <String>[
    countPlaceholder.name,
    'locale: _localeName',
    ...generateIntlMethodArgs(message),
  ];

  for (final String pluralKey in pluralIds.keys) {
    final RegExp expRE = RegExp('($pluralKey){([^}]+)}');
    final RegExpMatch match = expRE.firstMatch(easyMessage);
    if (match != null && match.groupCount == 2) {
      String argValue = match.group(2);
      for (final Placeholder placeholder in message.placeholders) {
        if (placeholder.requiresFormatting) {
          argValue = argValue.replaceAll('#${placeholder.name}#', '\${${placeholder.name}String}');
        } else {
          argValue = argValue.replaceAll('#${placeholder.name}#', '\${${placeholder.name}}');
        }
      }
      intlMethodArgs.add("${pluralIds[pluralKey]}: '$argValue'");
    }
  }

  List<String> generatePluralMethodParameters([String type]) {
    return message.placeholders.map((Placeholder placeholder) {
      final String placeholderType = placeholder == countPlaceholder ? 'int' : (type ?? placeholder.type);
      return '$placeholderType ${placeholder.name}';
    }).toList();
  }

  if (message.placeholdersRequireFormatting) {
    return pluralFormatMethodTemplate
      .replaceAll('@(methodName)', message.resourceId)
      .replaceAll('@(methodParameters)', generatePluralMethodParameters().join(', '))
      .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
      .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
      .replaceAll('@(innerMethodParameters)', generatePluralMethodParameters('Object').join(', '))
      .replaceAll('@(innerMethodArgs)', generateInnerMethodArgs(message).join(', '))
      .replaceAll('@(intlMethodArgs)', intlMethodArgs.join(',\n      '));
  }

  return pluralMethodTemplate
    .replaceAll('@(methodName)', message.resourceId)
    .replaceAll('@(methodParameters)', generatePluralMethodParameters().join(', '))
    .replaceAll('@(dateFormatting)', generateDateFormattingLogic(message))
    .replaceAll('@(numberFormatting)', generateNumberFormattingLogic(message))
    .replaceAll('@(intlMethodArgs)', intlMethodArgs.join(',\n      '));
}

/// The localizations generation class used to generate the localizations
/// classes, as well as all pertinent Dart files required to internationalize a
/// Flutter application.
class LocalizationsGenerator {
  /// Creates an instance of the localizations generator class.
  ///
  /// It takes in a [FileSystem] representation that the class will act upon.
  LocalizationsGenerator(this._fs);

  static RegExp arbFilenameLocaleRE = RegExp(r'^[^_]*_(\w+)\.arb$');
  static RegExp arbFilenameRE = RegExp(r'(\w+)\.arb$');

  final file.FileSystem _fs;

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
  final List<String> arbPathStrings = <String>[];

  /// The supported language codes as found in the arb files located in
  /// [l10nDirectory].
  final Set<String> supportedLanguageCodes = <String>{};

  /// The supported locales as found in the arb files located in
  /// [l10nDirectory].
  final Set<LocaleInfo> supportedLocales = <LocaleInfo>{};

  /// The class methods that will be generated in the localizations class
  /// based on messages found in the template arb file.
  final List<String> classMethods = <String>[];

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
  }) {
    setL10nDirectory(l10nDirectoryPath);
    setTemplateArbFile(templateArbFileName);
    setOutputFile(outputFileString);
    setPreferredSupportedLocales(preferredSupportedLocaleString);
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
    if (inputLocales != null) {
      final List<dynamic> preferredLocalesStringList = json.decode(inputLocales) as List<dynamic>;
      _preferredSupportedLocales = preferredLocalesStringList.map((dynamic localeString) {
        if (localeString.runtimeType != String) {
          throw L10nException('Incorrect runtime type for $localeString');
        }
        return LocaleInfo.fromString(localeString.toString());
      }).toList();
    }
  }

  /// Scans [l10nDirectory] for arb files and parses them for language and locale
  /// information.
  void parseArbFiles() {
    final List<File> fileSystemEntityList = l10nDirectory
      .listSync()
      .whereType<File>()
      .toList();
    final List<LocaleInfo> localeInfoList = <LocaleInfo>[];

    for (final File file in fileSystemEntityList) {
      final String filePath = file.path;
      if (arbFilenameRE.hasMatch(filePath)) {
        final Map<String, dynamic> arbContents = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        String localeString = arbContents['@@locale'] as String;
        if (localeString == null) {
          final RegExpMatch arbFileMatch = arbFilenameLocaleRE.firstMatch(filePath);
          if (arbFileMatch == null) {
            throw L10nException(
              "The following .arb file's locale could not be determined: \n"
              '$filePath \n'
              "Make sure that the locale is specified in the '@@locale' "
              'property or as part of the filename (e.g. file_en.arb)'
            );
          }

          localeString = arbFilenameLocaleRE.firstMatch(filePath)[1];
        }

        arbPathStrings.add(filePath);
        final LocaleInfo localeInfo = LocaleInfo.fromString(localeString);
        if (localeInfoList.contains(localeInfo))
          throw L10nException(
            'Multiple arb files with the same locale detected. \n'
            'Ensure that there is exactly one arb file for each locale.'
          );
        localeInfoList.add(localeInfo);
      }
    }

    arbPathStrings.sort();
    localeInfoList.sort();
    supportedLanguageCodes.addAll(localeInfoList.map((LocaleInfo localeInfo) {
      return "'${localeInfo.languageCode}'";
    }));

    if (preferredSupportedLocales != null) {
      for (final LocaleInfo preferredLocale in preferredSupportedLocales) {
        if (!localeInfoList.contains(preferredLocale)) {
          throw L10nException(
            "The preferred supported locale, '$preferredLocale', cannot be "
            'added. Please make sure that there is a corresponding arb file '
            'with translations for the locale, or remove the locale from the '
            'preferred supported locale list if there is no intent to support '
            'it.'
          );
        }

        localeInfoList.removeWhere((LocaleInfo localeInfo) => localeInfo == preferredLocale);
      }
      localeInfoList.insertAll(0, preferredSupportedLocales);
    }
    supportedLocales.addAll(localeInfoList);
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

  static String _genSupportedLocaleProperty(Set<LocaleInfo> supportedLocales) {
    const String prefix = 'static const List<Locale> supportedLocales = <Locale>[\n    Locale(';
    const String suffix = '),\n  ];';

    String resultingProperty = prefix;
    for (final LocaleInfo locale in supportedLocales) {
      final String languageCode = locale.languageCode;
      final String countryCode = locale.countryCode;

      resultingProperty += "'$languageCode'";
      if (countryCode != null)
        resultingProperty += ", '$countryCode'";
      resultingProperty += '),\n    Locale(';
    }
    resultingProperty = resultingProperty.substring(0, resultingProperty.length - '),\n    Locale('.length);
    resultingProperty += suffix;

    return resultingProperty;
  }

  /// Generates the methods for the localizations class.
  ///
  /// The method parses [templateArbFile] and uses its resource ids as the
  /// Dart method and getter names. It then uses each resource id's
  /// corresponding resource value to figure out how to define these getters.
  ///
  /// For example, a message with plurals will be handled differently from
  /// a simple, singular message.
  ///
  /// Throws an [L10nException] when a provided configuration is not allowed
  /// by [LocalizationsGenerator].
  ///
  /// Throws a [FileSystemException] when a file operation necessary for setting
  /// up the [LocalizationsGenerator] cannot be completed.
  ///
  /// Throws a [FormatException] when parsing the arb file is unsuccessful.
  void generateClassMethods() {
    Map<String, dynamic> bundle;
    try {
      bundle = json.decode(templateArbFile.readAsStringSync()) as Map<String, dynamic>;
    } on FileSystemException catch (e) {
      throw FileSystemException('Unable to read input arb file: $e');
    } on FormatException catch (e) {
      throw FormatException('Unable to parse arb file: $e');
    }

    final List<String> sortedArbKeys = bundle.keys.toList()..sort();
    for (final String key in sortedArbKeys) {
      if (key.startsWith('@'))
        continue;
      if (!_isValidGetterAndMethodName(key)) {
        throw L10nException(
          'Invalid key format: $key \n It has to be in camel case, cannot start '
          'with a number or underscore, and cannot contain non-alphanumeric characters.'
        );
      }

      final Message message = Message(bundle, key);
      if (message.isPlural)
        classMethods.add(generatePluralMethod(message));
      else
        classMethods.add(genSimpleMethod(message));
    }
  }

  /// Generates a file that contains the localizations class and the
  /// LocalizationsDelegate class.
  void generateOutputFile() {
    final String directory = path.basename(l10nDirectory.path);
    final String outputFileName = path.basename(outputFile.path);
    outputFile.writeAsStringSync(
      defaultFileTemplate
        .replaceAll('@(className)', className)
        .replaceAll('@(classMethods)', classMethods.join('\n'))
        .replaceAll('@(importFile)', '$directory/$outputFileName')
        .replaceAll('@(supportedLocales)', _genSupportedLocaleProperty(supportedLocales))
        .replaceAll('@(supportedLanguageCodes)', supportedLanguageCodes.toList().join(', '))
    );
  }
}
