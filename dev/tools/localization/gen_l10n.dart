// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String defaultFileTemplate = '''
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'messages_all.dart';
/// Callers can lookup localized strings with an instance of @className returned
/// by `@className.of(context)`.
///
/// Applications need to include `@className.delegate()` in their app\'s
/// loclalizationDelegates list, and the locales they support in the app\'s
/// supportedLocales list. For example:
///
/// ```
/// return MaterialApp(
///   localizationsDelegates: <LocalizationsDelegate<dynamic>>[
///     @className.delegate(),
///     GlobalMaterialLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///   ],
///   supportedLocales: const <Locale>[
///     Locale('en', 'US'),
///     Locale('es', 'ES'),
///   ],
///   home: MyApplicationHome(),
/// );
/// ```
class @className {
  @className(Locale locale) : _localeName = locale.toString();
  final String _localeName;
  static Future<@className> load(Locale locale) {
    return initializeMessages(locale.toString())
      .then<@className>((void _) => @className(locale));
  }
  static @className of(BuildContext context) {
    return Localizations.of<@className>(context, @className);
  }
  static const LocalizationsDelegate<@className> delegate = _@classNameDelegate();
@classMethods
}
class _@classNameDelegate extends LocalizationsDelegate<@className> {
  const _@classNameDelegate();
  @override
  Future<@className> load(Locale locale) => @className.load(locale);
  @override
  bool isSupported(Locale locale) => [@supportedLanguageCodes].contains(locale.languageCode);
  @override
  bool shouldReload(_@classNameDelegate old) => false;
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
      attributes.add('desc: \'$description\'');
    }
    if (attributesMap.containsKey('placeholders')) {
      final Map<String, dynamic> placeholders = attributesMap['placeholders'];
      final String args = placeholders.keys.join(', ');
      attributes.add('args: [$args]');
    }
  }
  return attributes;
}

String genSimpleMethod(Map<String, dynamic> bundle, String key) {
  String genMessage(Map<String, dynamic> bundle, String key) {
    String message = bundle[key];
    final Map<String, dynamic> attributesMap = bundle['@$key'];
    if (attributesMap != null && attributesMap.containsKey('placeholders')) {
      final Map<String, dynamic> placeholders = attributesMap['placeholders'];
      for (String placeholder in placeholders.keys)
        message = message.replaceAll('{$placeholder}', '\$$placeholder');
    }
    return message;
  }

  return simpleMethodTemplate
    .replaceAll('@methodName', key)
    .replaceAll('@methodParameters', genMethodParameters(bundle, key, 'Object').join(', '))
    .replaceAll('@message', "'${genMessage(bundle, key)}'")
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
    if (match.groupCount == 2) {
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

Future<void> main(List<String> args) async {
  final Directory l10nDirectory = Directory(path.join('lib', 'l10n'));
  final File inputArbFile = File(path.join(l10nDirectory.path, 'demo_en.arb'));
  final File outputFile = File(path.join(l10nDirectory.path, 'demo_localizations.dart'));
  const String stringsClassName = 'DemoLocalizations';

  final RegExp arbFilenameRE = RegExp(r'\w+_(\w+)\.arb$');
  final List<String> arbFilenames = <String>[];
  final Set<String> supportedLanguageCodes = <String>{};

  for (FileSystemEntity entity in l10nDirectory.listSync()) {
    final String entityPath = entity.path;
    if (FileSystemEntity.isFileSync(entityPath) && arbFilenameRE.hasMatch(entityPath)) {
      arbFilenames.add(entityPath);
      final String localeString = arbFilenameRE.firstMatch(entityPath)[1];
      final List<String> codes = localeString.split('_'); // [language, script, country]
      supportedLanguageCodes.add('\'${codes[0]}\'');
    }
  }

  final List<String> classMethods = <String>[];
  final Map<String, dynamic> bundle = json.decode(inputArbFile.readAsStringSync());
  final RegExp pluralValueRE = RegExp(r'^\s*\{[\w\s,]*,\s*plural\s*,');

  for (String key in bundle.keys) {
    if (key.startsWith('@'))
      continue;
    if (pluralValueRE.hasMatch(bundle[key]))
      classMethods.add(genPluralMethod(bundle, key));
    else
      classMethods.add(genSimpleMethod(bundle, key));
  }

  outputFile.writeAsStringSync(
    defaultFileTemplate
      .replaceAll('@className', stringsClassName)
      .replaceAll('@classMethods', classMethods.join('\n'))
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