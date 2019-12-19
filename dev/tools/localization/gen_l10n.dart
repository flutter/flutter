// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart' as file;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'localizations_utils.dart';

const String defaultFileTemplate = '''
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

/// Callers can lookup localized strings with an instance of @className returned
/// by `@className.of(context)`.
///
/// Applications need to include `@className.delegate()` in their app\'s
/// localizationDelegates list, and the locales they support in the app\'s
/// supportedLocales list. For example:
///
/// ```
/// import '@importFile';
///
/// return MaterialApp(
///   localizationsDelegates: @className.localizationsDelegates,
///   supportedLocales: @className.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: 0.16.0
///   intl_translation: 0.17.7
///
///   # rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the @className.supportedLocales
/// property.
class @className {
  @className(Locale locale) : _localeName = Intl.canonicalizedLocale(locale.toString());

  final String _localeName;

  static Future<@className> load(Locale locale) {
    return initializeMessages(locale.toString())
      .then<@className>((_) => @className(locale));
  }

  static @className of(BuildContext context) {
    return Localizations.of<@className>(context, @className);
  }

  static const LocalizationsDelegate<@className> delegate = _@classNameDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  @supportedLocales

@classMethods
}

class _@classNameDelegate extends LocalizationsDelegate<@className> {
  const _@classNameDelegate();

  @override
  Future<@className> load(Locale locale) => @className.load(locale);

  @override
  bool isSupported(Locale locale) => <String>[@supportedLanguageCodes].contains(locale.languageCode);

  @override
  bool shouldReload(_@classNameDelegate old) => false;
}
''';

const String getterMethodTemplate = '''
  String get @methodName {
    return Intl.message(
      @message,
      locale: _localeName,
      @intlMethodArgs
    );
  }
''';

const String simpleMethodTemplate = '''
  String @methodName(@methodParameters) {@dateFormatting
    return Intl.message(
      @message,
      locale: _localeName,
      @intlMethodArgs
    );
  }
''';

const String pluralMethodTemplate = '''
  String @methodName(@methodParameters) {
    return Intl.plural(
      @intlMethodArgs
    );
  }
''';

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

bool _isDateParameter(dynamic placeholderValue) {
  return placeholderValue is Map<String, dynamic> &&
    placeholderValue['type'] == 'DateTime';
}

bool _dateParameterIsValid(Map<String, dynamic> placeholderValue, String placeholder) {
  if (allowableDateFormats.contains(placeholderValue['format']))
    return true;
  throw L10nException(
    'Date format ${placeholderValue['format']} for the $placeholder \n'
    'placeholder does not have a corresponding DateFormat \n'
    'constructor. Check the intl library\'s DateFormat class \n'
    'constructors for allowed date formats.'
  );
}

bool _containsFormatKey(Map<String, dynamic> placeholderValue, String placeholder) {
  if (placeholderValue.containsKey('format'))
    return true;
  throw L10nException(
    'The placeholder, $placeholder, has its "type" resource attribute set to '
    'the "DateTime" type. To properly resolve for the right DateTime format, '
    'the "format" attribute needs to be set to determine which DateFormat to '
    'use. \n'
    'Check the intl library\'s DateFormat class constructors for allowed '
    'date formats.'
  );
}

List<String> genMethodParameters(Map<String, dynamic> bundle, String key, String type) {
  final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    return placeholders.keys.map((String parameter) => '$type $parameter').toList();
  }
  return <String>[];
}

String generateDateFormattingLogic(Map<String, dynamic> bundle, String key) {
  String result = '';
  final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    for (String placeholder in placeholders.keys) {
      final dynamic value = placeholders[placeholder];
      if (
        _isDateParameter(value) &&
        _containsFormatKey(value, placeholder) &&
        _dateParameterIsValid(value, placeholder)
      ) {
        result += '''

    final DateFormat ${placeholder}DateFormat = DateFormat.${value['format']}(_localeName);
    final String ${placeholder}String = ${placeholder}DateFormat.format($placeholder);
''';
      }
    }
  }

  return result;
}

List<String> genIntlMethodArgs(Map<String, dynamic> bundle, String key) {
  final List<String> attributes = <String>['name: \'$key\''];
  final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
  if (attributesMap != null) {
    if (attributesMap.containsKey('description')) {
      final String description = attributesMap['description'] as String;
      attributes.add('desc: ${generateString(description)}');
    }
    if (attributesMap.containsKey('placeholders')) {
      final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
      if (placeholders.isNotEmpty) {
        final List<String> argumentList = <String>[];
        for (String placeholder in placeholders.keys) {
          final dynamic value = placeholders[placeholder];
          if (
            _isDateParameter(value) &&
            _containsFormatKey(value, placeholder) &&
            _dateParameterIsValid(value, placeholder)
          ) {
            argumentList.add('${placeholder}String');
          } else {
            argumentList.add(placeholder);
          }
        }
        final String args = argumentList.join(', ');
        attributes.add('args: <Object>[$args]');
      }
    }
  }
  return attributes;
}

String genSimpleMethod(Map<String, dynamic> bundle, String key) {
  String genSimpleMethodMessage(Map<String, dynamic> bundle, String key) {
    String message = bundle[key] as String;
    final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    for (String placeholder in placeholders.keys) {
      final dynamic value = placeholders[placeholder];
      if (_isDateParameter(value)) {
        message = message.replaceAll('{$placeholder}', '\$${placeholder}String');
      } else {
        message = message.replaceAll('{$placeholder}', '\$$placeholder');
      }
    }
    return generateString(message);
  }

  final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
  if (attributesMap == null)
    throw L10nException(
      'Resource attribute "@$key" was not found. Please ensure that each '
      'resource id has a corresponding resource attribute.'
    );

  if (attributesMap.containsKey('placeholders')) {
    return simpleMethodTemplate
      .replaceAll('@methodName', key)
      .replaceAll('@methodParameters', genMethodParameters(bundle, key, 'Object').join(', '))
      .replaceAll('@dateFormatting', generateDateFormattingLogic(bundle, key))
      .replaceAll('@message', '${genSimpleMethodMessage(bundle, key)}')
      .replaceAll('@intlMethodArgs', genIntlMethodArgs(bundle, key).join(',\n      '));
  }

  return getterMethodTemplate
    .replaceAll('@methodName', key)
    .replaceAll('@message', '${generateString(bundle[key] as String)}')
    .replaceAll('@intlMethodArgs', genIntlMethodArgs(bundle, key).join(',\n      '));
}

String genPluralMethod(Map<String, dynamic> bundle, String key) {
  final Map<String, dynamic> attributesMap = bundle['@$key'] as Map<String, dynamic>;
  assert(attributesMap != null && attributesMap.containsKey('placeholders'));
  final Iterable<String> placeholders = attributesMap['placeholders'].keys as Iterable<String>;

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String message = bundle[key] as String;
  for (String placeholder in placeholders)
    message = message.replaceAll('{$placeholder}', '#$placeholder#');

  final Map<String, String> pluralIds = <String, String>{
    '=0': 'zero',
    '=1': 'one',
    '=2': 'two',
    'few': 'few',
    'many': 'many',
    'other': 'other'
  };

  final List<String> methodArgs = <String>[
    ...placeholders,
    'locale: _localeName',
    ...genIntlMethodArgs(bundle, key),
  ];

  for (String pluralKey in pluralIds.keys) {
    final RegExp expRE = RegExp('($pluralKey){([^}]+)}');
    final RegExpMatch match = expRE.firstMatch(message);
    if (match != null && match.groupCount == 2) {
      String argValue = match.group(2);
      for (String placeholder in placeholders)
        argValue = argValue.replaceAll('#$placeholder#', '\$$placeholder');

      methodArgs.add("${pluralIds[pluralKey]}: '$argValue'");
    }
  }

  return pluralMethodTemplate
    .replaceAll('@methodName', key)
    .replaceAll('@methodParameters', genMethodParameters(bundle, key, 'int').join(', '))
    .replaceAll('@intlMethodArgs', methodArgs.join(',\n      '));
}

String genSupportedLocaleProperty(Set<LocaleInfo> supportedLocales) {
  const String prefix = 'static const List<Locale> supportedLocales = <Locale>[\n    Locale(''';
  const String suffix = '),\n  ];';

  String resultingProperty = prefix;
  for (LocaleInfo locale in supportedLocales) {
    final String languageCode = locale.languageCode;
    final String countryCode = locale.countryCode;

    resultingProperty += '\'$languageCode\'';
    if (countryCode != null)
      resultingProperty += ', \'$countryCode\'';
    resultingProperty += '),\n    Locale(';
  }
  resultingProperty = resultingProperty.substring(0, resultingProperty.length - '),\n    Locale('.length);
  resultingProperty += suffix;

  return resultingProperty;
}

bool _isValidClassName(String className) {
  // Dart class name cannot contain non-alphanumeric symbols
  if (className.contains(RegExp(r'[^a-zA-Z\d]')))
    return false;
  // Dart class name must start with upper case character
  if (className[0].contains(RegExp(r'[a-z]')))
    return false;
  // Dart class name cannot start with a number
  if (className[0].contains(RegExp(r'\d')))
    return false;
  return true;
}

bool _isNotReadable(FileStat fileStat) {
  final String rawStatString = fileStat.modeString();
  // Removes potential prepended permission bits, such as '(suid)' and '(guid)'.
  final String statString = rawStatString.substring(rawStatString.length - 9);
  return !(statString[0] == 'r' || statString[3] == 'r' || statString[6] == 'r');
}
bool _isNotWritable(FileStat fileStat) {
  final String rawStatString = fileStat.modeString();
  // Removes potential prepended permission bits, such as '(suid)' and '(guid)'.
  final String statString = rawStatString.substring(rawStatString.length - 9);
  return !(statString[1] == 'w' || statString[4] == 'w' || statString[7] == 'w');
}

bool _isValidGetterAndMethodName(String name) {
  // Dart getter and method name cannot contain non-alphanumeric symbols
  if (name.contains(RegExp(r'[^a-zA-Z\d]')))
    return false;
  // Dart class name must start with lower case character
  if (name[0].contains(RegExp(r'[A-Z]')))
    return false;
  // Dart class name cannot start with a number
  if (name[0].contains(RegExp(r'\d')))
    return false;
  return true;
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
  static RegExp pluralValueRE = RegExp(r'^\s*\{[\w\s,]*,\s*plural\s*,');

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
  /// Sets the [className] for the localizations and localizations delegate
  /// classes.

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
  }) {
    setL10nDirectory(l10nDirectoryPath);
    setTemplateArbFile(templateArbFileName);
    setOutputFile(outputFileString);
    className = classNameString;
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

  @visibleForTesting
  set className(String classNameString) {
    if (classNameString == null)
      throw L10nException('classNameString argument cannot be null');
    if (!_isValidClassName(classNameString))
      throw L10nException(
        "The 'output-class', $classNameString, is not a valid Dart class name.\n"
      );
    _className = classNameString;
  }

  /// Scans [l10nDirectory] for arb files and parses them for language and locale
  /// information.
  void parseArbFiles() {
    final List<File> fileSystemEntityList = l10nDirectory
      .listSync()
      .whereType<File>()
      .toList();
    final List<LocaleInfo> localeInfoList = <LocaleInfo>[];

    for (File file in fileSystemEntityList) {
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
    supportedLocales.addAll(localeInfoList);
    supportedLanguageCodes.addAll(localeInfoList.map((LocaleInfo localeInfo) {
      return '\'${localeInfo.languageCode}\'';
    }));
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
    for (String key in sortedArbKeys) {
      if (key.startsWith('@'))
        continue;
      if (!_isValidGetterAndMethodName(key))
        throw L10nException(
          'Invalid key format: $key \n It has to be in camel case, cannot start '
          'with a number, and cannot contain non-alphanumeric characters.'
        );
      if (pluralValueRE.hasMatch(bundle[key] as String))
        classMethods.add(genPluralMethod(bundle, key));
      else
        classMethods.add(genSimpleMethod(bundle, key));
    }
  }

  /// Generates a file that contains the localizations class and the
  /// LocalizationsDelegate class.
  void generateOutputFile() {
    final String directory = path.basename(l10nDirectory.path);
    final String outputFileName = path.basename(outputFile.path);
    outputFile.writeAsStringSync(
      defaultFileTemplate
        .replaceAll('@className', className)
        .replaceAll('@classMethods', classMethods.join('\n'))
        .replaceAll('@importFile', '$directory/$outputFileName')
        .replaceAll('@supportedLocales', genSupportedLocaleProperty(supportedLocales))
        .replaceAll('@supportedLanguageCodes', supportedLanguageCodes.toList().join(', '))
    );
  }
}

class L10nException implements Exception {
  L10nException(this.message);

  final String message;
}
