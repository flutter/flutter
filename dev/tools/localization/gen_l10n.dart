// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as argslib;
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
  String @methodName(@methodParameters) {
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

int sortFilesByPath (FileSystemEntity a, FileSystemEntity b) {
  return a.path.compareTo(b.path);
}

List<String> genMethodParameters(Map<String, dynamic> bundle, String key, String type) {
  final Map<String, dynamic> attributesMap = bundle['@$key'];
  if (attributesMap != null && attributesMap.containsKey('placeholders')) {
    final Map<String, dynamic> placeholders = attributesMap['placeholders'];
    return placeholders.keys.map((String parameter) => '$type $parameter').toList();
  }
  return <String>[];
}

List<String> genIntlMethodArgs(Map<String, dynamic> bundle, String key) {
  final List<String> attributes = <String>['name: \'$key\''];
  final Map<String, dynamic> attributesMap = bundle['@$key'];
  if (attributesMap != null) {
    if (attributesMap.containsKey('description')) {
      final String description = attributesMap['description'];
      attributes.add('desc: ${generateString(description)}');
    }
    if (attributesMap.containsKey('placeholders')) {
      final Map<String, dynamic> placeholders = attributesMap['placeholders'];
      if (placeholders.isNotEmpty) {
        final String args = placeholders.keys.join(', ');
        attributes.add('args: <Object>[$args]');
      }
    }
  }
  return attributes;
}

String genSimpleMethod(Map<String, dynamic> bundle, String key) {
  String genSimpleMethodMessage(Map<String, dynamic> bundle, String key) {
    String message = bundle[key];
    final Map<String, dynamic> attributesMap = bundle['@$key'];
    final Map<String, dynamic> placeholders = attributesMap['placeholders'];
    for (String placeholder in placeholders.keys)
      message = message.replaceAll('{$placeholder}', '\$$placeholder');
    return generateString(message);
  }

  final Map<String, dynamic> attributesMap = bundle['@$key'];
  if (attributesMap == null)
    exitWithError(
      'Resource attribute "@$key" was not found. Please ensure that each '
      'resource id has a corresponding resource attribute.'
    );

  if (attributesMap.containsKey('placeholders')) {
    return simpleMethodTemplate
      .replaceAll('@methodName', key)
      .replaceAll('@methodParameters', genMethodParameters(bundle, key, 'Object').join(', '))
      .replaceAll('@message', '${genSimpleMethodMessage(bundle, key)}')
      .replaceAll('@intlMethodArgs', genIntlMethodArgs(bundle, key).join(',\n      '));
  }

  return getterMethodTemplate
    .replaceAll('@methodName', key)
    .replaceAll('@message', '${generateString(bundle[key])}')
    .replaceAll('@intlMethodArgs', genIntlMethodArgs(bundle, key).join(',\n      '));
}

String genPluralMethod(Map<String, dynamic> bundle, String key) {
  final Map<String, dynamic> attributesMap = bundle['@$key'];
  assert(attributesMap != null && attributesMap.containsKey('placeholders'));
  final Iterable<String> placeholders = attributesMap['placeholders'].keys;

  // To make it easier to parse the plurals message, temporarily replace each
  // "{placeholder}" parameter with "#placeholder#".
  String message = bundle[key];
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

  for(String pluralKey in pluralIds.keys) {
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

bool _isDirectoryReadableAndWritable(String statString) {
  if (statString[0] == '-' || statString[1] == '-')
    return false;
  return true;
}

String _importFilePath(String path, String fileName) {
  final String replaceLib = path.replaceAll('lib/', '');
  return '$replaceLib/$fileName';
}

Future<void> main(List<String> arguments) async {
  final argslib.ArgParser parser = argslib.ArgParser();
  parser.addFlag(
    'help',
    defaultsTo: false,
    negatable: false,
    help: 'Print this help message.',
  );
  parser.addOption(
    'arb-dir',
    defaultsTo: path.join('lib', 'l10n'),
    help: 'The directory where all localization files should reside. For '
      'example, the template and translated arb files should be located here. '
      'Also, the generated output messages Dart files for each locale and the '
      'generated localizations classes will be created here.',
  );
  parser.addOption(
    'template-arb-file',
    defaultsTo: 'app_en.arb',
    help: 'The template arb file that will be used as the basis for '
      'generating the Dart localization and messages files.',
  );
  parser.addOption(
    'output-localization-file',
    defaultsTo: 'app_localizations.dart',
    help: 'The filename for the output localization and localizations '
      'delegate classes.',
  );
  parser.addOption(
    'output-class',
    defaultsTo: 'AppLocalizations',
    help: 'The Dart class name to use for the output localization and '
      'localizations delegate classes.',
  );

  final argslib.ArgResults results = parser.parse(arguments);
  if (results['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  final String arbPathString = results['arb-dir'];
  final String outputFileString = results['output-localization-file'];

  final Directory l10nDirectory = Directory(arbPathString);
  final File templateArbFile = File(path.join(l10nDirectory.path, results['template-arb-file']));
  final File outputFile = File(path.join(l10nDirectory.path, outputFileString));
  final String stringsClassName = results['output-class'];

  if (!l10nDirectory.existsSync())
    exitWithError(
      "The 'arb-dir' directory, $l10nDirectory, does not exist.\n"
      'Make sure that the correct path was provided.'
    );
  final String l10nDirectoryStatModeString = l10nDirectory.statSync().modeString();
  if (!_isDirectoryReadableAndWritable(l10nDirectoryStatModeString))
    exitWithError(
      "The 'arb-dir' directory, $l10nDirectory, doesn't allow reading and writing.\n"
      'Please ensure that the user has read and write permissions.'
    );
  final String templateArbFileStatModeString = templateArbFile.statSync().modeString();
  if (templateArbFileStatModeString[0] == '-')
    exitWithError(
      "The 'template-arb-file', $templateArbFile, is not readable.\n"
      'Please ensure that the user has read permissions.'
    );
  if (!_isValidClassName(stringsClassName))
    exitWithError(
      "The 'output-class', $stringsClassName, is not valid Dart class name.\n"
    );

  final List<String> arbFilenames = <String>[];
  final Set<String> supportedLanguageCodes = <String>{};
  final Set<LocaleInfo> supportedLocales = <LocaleInfo>{};

  for (FileSystemEntity entity in l10nDirectory.listSync().toList()..sort(sortFilesByPath)) {
    final String entityPath = entity.path;

    if (FileSystemEntity.isFileSync(entityPath)) {
      final RegExp arbFilenameRE = RegExp(r'(\w+)\.arb$');
      if (arbFilenameRE.hasMatch(entityPath)) {
        final File arbFile = File(entityPath);
        final Map<String, dynamic> arbContents = json.decode(arbFile.readAsStringSync());
        String localeString = arbContents['@@locale'];

        if (localeString == null) {
          final RegExp arbFilenameLocaleRE = RegExp(r'^[^_]*_(\w+)\.arb$');
          final RegExpMatch arbFileMatch = arbFilenameLocaleRE.firstMatch(entityPath);
          if (arbFileMatch == null) {
            exitWithError(
              "The following .arb file's locale could not be determined: \n"
              '$entityPath \n'
              "Make sure that the locale is specified in the '@@locale' "
              'property or as part of the filename (ie. file_en.arb)'
            );
          }

          localeString = arbFilenameLocaleRE.firstMatch(entityPath)[1];
        }

        arbFilenames.add(entityPath);
        final LocaleInfo localeInfo = LocaleInfo.fromString(localeString);
        if (supportedLocales.contains(localeInfo))
          exitWithError(
            'Multiple arb files with the same locale detected. \n'
            'Ensure that there is exactly one arb file for each locale.'
          );
        supportedLocales.add(localeInfo);
        supportedLanguageCodes.add('\'${localeInfo.languageCode}\'');
      }
    }
  }

  final List<String> classMethods = <String>[];

  Map<String, dynamic> bundle;
  try {
    bundle = json.decode(templateArbFile.readAsStringSync());
  } on FileSystemException catch (e) {
    exitWithError('Unable to read input arb file: $e');
  } on FormatException catch (e) {
    exitWithError('Unable to parse arb file: $e');
  }

  final RegExp pluralValueRE = RegExp(r'^\s*\{[\w\s,]*,\s*plural\s*,');

  for (String key in bundle.keys.toList()..sort()) {
    if (key.startsWith('@'))
      continue;
    if (!_isValidGetterAndMethodName(key))
      exitWithError(
        'Invalid key format: $key \n It has to be in camel case, cannot start '
        'with a number, and cannot contain non-alphanumeric characters.'
      );
    if (pluralValueRE.hasMatch(bundle[key]))
      classMethods.add(genPluralMethod(bundle, key));
    else
      classMethods.add(genSimpleMethod(bundle, key));
  }

  outputFile.writeAsStringSync(
    defaultFileTemplate
      .replaceAll('@className', stringsClassName)
      .replaceAll('@classMethods', classMethods.join('\n'))
      .replaceAll('@importFile', _importFilePath(arbPathString, outputFileString))
      .replaceAll('@supportedLocales', genSupportedLocaleProperty(supportedLocales))
      .replaceAll('@supportedLanguageCodes', supportedLanguageCodes.toList().join(', '))
  );

  final ProcessResult pubGetResult = await Process.run('flutter', <String>['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    stderr.write(pubGetResult.stderr);
    exit(1);
  }

  final ProcessResult generateFromArbResult = await Process.run('flutter', <String>[
    'pub',
    'pub',
    'run',
    'intl_translation:generate_from_arb',
    '--output-dir=${l10nDirectory.path}',
    '--no-use-deferred-loading',
    outputFile.path,
    ...arbFilenames,
  ]);
  if (generateFromArbResult.exitCode != 0) {
    stderr.write(generateFromArbResult.stderr);
    exit(1);
  }
}
