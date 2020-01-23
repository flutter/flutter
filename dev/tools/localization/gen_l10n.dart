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
  String @methodName(@methodParameters) {@dateFormatting@numberFormatting
    return Intl.message(
      @message,
      locale: _localeName,
      @intlMethodArgs
    );
  }
''';

const String pluralMethodTemplate = '''
  String @methodName(@methodParameters) {@dateFormatting@numberFormatting
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

bool _isDateParameter(Map<String, dynamic> placeholderValue) => placeholderValue['type'] == 'DateTime';
bool _isNumberParameter(Map<String, dynamic> placeholderValue) => placeholderValue['type'] == 'Number';
bool _containsFormatKey(Map<String, dynamic> placeholderValue, String placeholder) {
  if (placeholderValue.containsKey('format'))
    return true;
  throw L10nException(
    'The placeholder, $placeholder, has its "type" resource attribute set to '
    'the "${placeholderValue['type']}" type. To properly resolve for the right '
    '${placeholderValue['type']} format, the "format" attribute needs to be set '
    'to determine which DateFormat to use. \n'
    'Check the intl library\'s DateFormat class constructors for allowed '
    'date formats.'
  );
}

bool _isValidDateParameter(Map<String, dynamic> placeholderValue, String placeholder) {
  if (allowableDateFormats.contains(placeholderValue['format']))
    return true;
  throw L10nException(
    'Date format ${placeholderValue['format']} for $placeholder \n'
    'placeholder does not have a corresponding DateFormat \n'
    'constructor. Check the intl library\'s DateFormat class \n'
    'constructors for allowed date formats.'
  );
}

bool _isValidNumberParameter(Map<String, dynamic> placeholderValue, String placeholder) {
  if (allowableNumberFormats.contains(placeholderValue['format']))
    return true;
  throw L10nException(
    'Number format ${placeholderValue['format']} for the $placeholder \n'
    'placeholder does not have a corresponding NumberFormat \n'
    'constructor. Check the intl library\'s NumberFormat class \n'
    'constructors for allowed number formats.'
  );
}

List<String> genMethodParameters(Map<String, dynamic> bundle, String resourceId, String type) {
  final Map<String, dynamic> attributesMap = bundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    return placeholders.keys.map((String parameter) => '$type $parameter').toList();
  }
  return <String>[];
}

List<String> genPluralMethodParameters(Iterable<String> placeholderKeys, String countPlaceholder, String resourceId) {
  if (placeholderKeys.isEmpty)
    throw L10nException(
      'Placeholders map for the $resourceId message is empty.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );

  return placeholderKeys.map((String parameter) {
    if (parameter == countPlaceholder) {
      return 'int $parameter';
    }
    return 'Object $parameter';
  }).toList();
}

String generateDateFormattingLogic(Map<String, dynamic> arbBundle, String resourceId) {
  final StringBuffer result = StringBuffer();
  final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    for (final String placeholder in placeholders.keys) {
      final dynamic value = placeholders[placeholder];
      if (value is Map<String, dynamic> && _isValidDateFormat(value, placeholder)) {
        result.write('''

    final DateFormat ${placeholder}DateFormat = DateFormat.${value['format']}(_localeName);
    final String ${placeholder}String = ${placeholder}DateFormat.format($placeholder);
''');
      }
    }
  }

  return result.toString();
}

String generateNumberFormattingLogic(Map<String, dynamic> arbBundle, String resourceId) {
  final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final StringBuffer result = StringBuffer();
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    final StringBuffer optionalParametersString = StringBuffer();
    for (final String placeholder in placeholders.keys) {
      final dynamic value = placeholders[placeholder];
      if (value is Map<String, dynamic> && _isValidNumberFormat(value, placeholder)) {
        if (numberFormatsWithNamedParameters.contains(value['format'])) {
          if (value.containsKey('optionalParameters')) {
            final Map<String, dynamic> optionalParameters = value['optionalParameters'] as Map<String, dynamic>;
            for (final String parameter in optionalParameters.keys)
              optionalParametersString.write('\n      $parameter: ${optionalParameters[parameter]},');
          }

          result.write('''

    final NumberFormat ${placeholder}NumberFormat = NumberFormat.${value['format']}(
      locale: _localeName,@optionalParameters
    );
    final String ${placeholder}String = ${placeholder}NumberFormat.format($placeholder);
''');
        } else {
          result.write('''

    final NumberFormat ${placeholder}NumberFormat = NumberFormat.${value['format']}(_localeName);
    final String ${placeholder}String = ${placeholder}NumberFormat.format($placeholder);
''');
        }
      }
    }

    return result
      .toString()
      .replaceAll('@optionalParameters', optionalParametersString.toString());
  }

  return '';
}

bool _isValidDateFormat(Map<String, dynamic> value, String placeholder) {
  return _isDateParameter(value)
      && _containsFormatKey(value, placeholder)
      && _isValidDateParameter(value, placeholder);
}

bool _isValidNumberFormat(Map<String, dynamic> value, String placeholder) {
  return _isNumberParameter(value)
      && _containsFormatKey(value, placeholder)
      && _isValidNumberParameter(value, placeholder);
}

bool _isValidPlaceholder(Map<String, dynamic> value, String placeholder) {
  return _isValidDateFormat(value, placeholder) || _isValidNumberFormat(value, placeholder);
}

List<String> genIntlMethodArgs(Map<String, dynamic> arbBundle, String resourceId) {
  final List<String> attributes = <String>['name: \'$resourceId\''];
  final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap != null) {
    if (attributesMap.containsKey('description')) {
      final String description = attributesMap['description'] as String;
      attributes.add('desc: ${generateString(description)}');
    }
    if (attributesMap.containsKey('placeholders')) {
      final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
      if (placeholders.isNotEmpty) {
        final List<String> argumentList = <String>[];
        for (final String placeholder in placeholders.keys) {
          final dynamic value = placeholders[placeholder];
          if (value is Map<String, dynamic> && _isValidPlaceholder(value, placeholder)) {
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

String genSimpleMethod(Map<String, dynamic> arbBundle, String resourceId) {
  String genSimpleMethodMessage(Map<String, dynamic> arbBundle, String resourceId) {
    String message = arbBundle[resourceId] as String;
    final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
    final Map<String, dynamic> placeholders = attributesMap['placeholders'] as Map<String, dynamic>;
    for (final String placeholder in placeholders.keys) {
      final dynamic value = placeholders[placeholder];
      if (value is Map<String, dynamic> && (_isDateParameter(value) || _isNumberParameter(value))) {
        message = message.replaceAll('{$placeholder}', '\$${placeholder}String');
      } else {
        message = message.replaceAll('{$placeholder}', '\$$placeholder');
      }
    }
    return generateString(message);
  }

  final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap == null)
    throw L10nException(
      'Resource attribute "@$resourceId" was not found. Please ensure that each '
      'resource id has a corresponding resource attribute.'
    );

  if (attributesMap.containsKey('placeholders')) {
    final String rawMessageString = genSimpleMethodMessage(arbBundle, resourceId); // "r'...'"
    return simpleMethodTemplate
      .replaceAll('@methodName', resourceId)
      .replaceAll('@methodParameters', genMethodParameters(arbBundle, resourceId, 'Object').join(', '))
      .replaceAll('@dateFormatting', generateDateFormattingLogic(arbBundle, resourceId))
      .replaceAll('@numberFormatting', generateNumberFormattingLogic(arbBundle, resourceId))
      .replaceAll('@message', '${rawMessageString.substring(1)}')
      .replaceAll('@intlMethodArgs', genIntlMethodArgs(arbBundle, resourceId).join(',\n      '));
  }

  final String rawMessageString = generateString(arbBundle[resourceId] as String); // "r'...'"
  return getterMethodTemplate
    .replaceAll('@methodName', resourceId)
    .replaceAll('@message', '${rawMessageString.substring(1)}')
    .replaceAll('@intlMethodArgs', genIntlMethodArgs(arbBundle, resourceId).join(',\n      '));
}

String genPluralMethod(Map<String, dynamic> arbBundle, String resourceId) {
  final Map<String, dynamic> attributesMap = arbBundle['@$resourceId'] as Map<String, dynamic>;
  if (attributesMap == null)
    throw L10nException('Resource attribute for $resourceId does not exist.');
  if (!attributesMap.containsKey('placeholders'))
    throw L10nException(
      'Unable to find placeholders for the plural message: $resourceId.\n'
      'Check to see if the plural message is in the proper ICU syntax format '
      'and ensure that placeholders are properly specified.'
    );
  if (attributesMap['placeholders'] is! Map<String, dynamic>)
    throw L10nException(
      'The "placeholders" resource attribute for the message, $resourceId, '
      'is not properly formatted. Ensure that it is a map with keys that are '
      'strings.'
    );

  final Map<String, dynamic> placeholdersMap = attributesMap['placeholders'] as Map<String, dynamic>;
  final Iterable<String> placeholders = placeholdersMap.keys;

  // Used to determine which placeholder is the plural count placeholder
  final String resourceValue = arbBundle[resourceId] as String;
  final String countPlaceholder = resourceValue.split(',')[0].substring(1);

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String message = arbBundle[resourceId] as String;
  for (final String placeholder in placeholders)
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
    countPlaceholder,
    'locale: _localeName',
    ...genIntlMethodArgs(arbBundle, resourceId),
  ];

  for (final String pluralKey in pluralIds.keys) {
    final RegExp expRE = RegExp('($pluralKey){([^}]+)}');
    final RegExpMatch match = expRE.firstMatch(message);
    if (match != null && match.groupCount == 2) {
      String argValue = match.group(2);
      for (final String placeholder in placeholders) {
        final dynamic value = placeholdersMap[placeholder];
        if (value is Map<String, dynamic> && (_isDateParameter(value) || _isNumberParameter(value))) {
          argValue = argValue.replaceAll('#$placeholder#', '\$${placeholder}String');
        } else {
          argValue = argValue.replaceAll('#$placeholder#', '\$$placeholder');
        }
      }
      methodArgs.add("${pluralIds[pluralKey]}: '$argValue'");
    }
  }

  return pluralMethodTemplate
    .replaceAll('@methodName', resourceId)
    .replaceAll('@methodParameters', genPluralMethodParameters(placeholders, countPlaceholder, resourceId).join(', '))
    .replaceAll('@dateFormatting', generateDateFormattingLogic(arbBundle, resourceId))
    .replaceAll('@numberFormatting', generateNumberFormattingLogic(arbBundle, resourceId))
    .replaceAll('@intlMethodArgs', methodArgs.join(',\n      '));
}

String genSupportedLocaleProperty(Set<LocaleInfo> supportedLocales) {
  const String prefix = 'static const List<Locale> supportedLocales = <Locale>[\n    Locale(';
  const String suffix = '),\n  ];';

  String resultingProperty = prefix;
  for (final LocaleInfo locale in supportedLocales) {
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

  /// Sets the [className] for the localizations and localizations delegate
  /// classes.
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
      return '\'${localeInfo.languageCode}\'';
    }));

    if (preferredSupportedLocales != null) {
      for (final LocaleInfo preferredLocale in preferredSupportedLocales) {
        if (!localeInfoList.contains(preferredLocale)) {
          throw L10nException(
            'The preferred supported locale, \'$preferredLocale\', cannot be '
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
