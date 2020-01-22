// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:file/local.dart' as local;
import 'package:path/path.dart' as path;

import '../gen_l10n.dart';
import '../localizations_utils.dart';

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
  parser.addOption(
    'preferred-supported-locales',
    help: 'The list of preferred supported locales for the application. '
      'By default, the tool will generate the supported locales list in '
      'alphabetical order. Use this flag if you would like to default to '
      'a different locale. \n\n'
      'For example, pass in [\'en_US\'] if you would like your app to '
      'default to American English if a device supports it.',
  );

  final argslib.ArgResults results = parser.parse(arguments);
  if (results['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  final String arbPathString = results['arb-dir'] as String;
  final String outputFileString = results['output-localization-file'] as String;
  final String templateArbFileName = results['template-arb-file'] as String;
  final String classNameString = results['output-class'] as String;
  final String preferredSupportedLocaleString = results['preferred-supported-locales'] as String;

  const local.LocalFileSystem fs = local.LocalFileSystem();
  final LocalizationsGenerator localizationsGenerator = LocalizationsGenerator(fs);
  try {
    localizationsGenerator
      ..initialize(
        l10nDirectoryPath: arbPathString,
        templateArbFileName: templateArbFileName,
        outputFileString: outputFileString,
        classNameString: classNameString,
        preferredSupportedLocaleString: preferredSupportedLocaleString,
      )
      ..parseArbFiles()
      ..generateClassMethods()
      ..generateOutputFile();
  } on FileSystemException catch (e) {
    exitWithError(e.message);
  } on FormatException catch (e) {
    exitWithError(e.message);
  } on L10nException catch (e) {
    exitWithError(e.message);
  }

  final ProcessResult pubGetResult = await Process.run('flutter', <String>['pub', 'get']);
  if (pubGetResult.exitCode != 0) {
    stderr.write(pubGetResult.stderr);
    exit(1);
  }

  final ProcessResult generateFromArbResult = await Process.run('flutter', <String>[
    'pub',
    'run',
    'intl_translation:generate_from_arb',
    '--output-dir=${localizationsGenerator.l10nDirectory.path}',
    '--no-use-deferred-loading',
    localizationsGenerator.outputFile.path,
    ...localizationsGenerator.arbPathStrings,
  ]);
  if (generateFromArbResult.exitCode != 0) {
    stderr.write(generateFromArbResult.stderr);
    exit(1);
  }
}
