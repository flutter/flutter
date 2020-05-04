// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:file/local.dart' as local;
import 'package:path/path.dart' as path;

import '../gen_l10n.dart';
import '../gen_l10n_types.dart';
import '../localizations_utils.dart';

void main(List<String> arguments) {
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
    help: 'The directory where the template and translated arb files are located.',
  );
  parser.addOption(
    'output-dir',
    help: 'The directory where the generated localization classes will be written. '
      'The app must import the file specified in the \'output-localization-file\' '
      'option from this directory. If unspecified, this defaults to the same '
      'directory as the input directory specified in \'arb-dir\'.'
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
    'untranslated-messages-file',
    help: 'The location of a file that describes the localization\n'
      'messages have not been translated yet. Using this option will create\n'
      'a JSON file at the target location, in the following format:\n\n'
      '"locale": ["message_1", "message_2" ... "message_n"]\n\n'
      'If this option is not specified, a summary of the messages that\n'
      'have not been translated will be printed on the command line.'
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
      "For example, pass in ['en_US'] if you would like your app to "
      'default to American English if a device supports it.',
  );
  parser.addOption(
    'header',
    help: 'The header to prepend to the generated Dart localizations '
      'files. This option takes in a string. \n\n'
      'For example, pass in "/// All localized files." if you would '
      'like this string prepended to the generated Dart file. \n\n'
      'Alternatively, see the `header-file` option to pass in a text '
      'file for longer headers.'
  );
  parser.addOption(
    'header-file',
    help: 'The header to prepend to the generated Dart localizations '
      'files. The value of this option is the name of the file that '
      'contains the header text which will be inserted at the top '
      'of each generated Dart file. \n\n'
      'Alternatively, see the `header` option to pass in a string '
      'for a simpler header. \n\n'
      'This file should be placed in the directory specified in \'arb-dir\'.'
  );
  parser.addFlag(
    'use-deferred-loading',
    defaultsTo: false,
    help: 'Whether to generate the Dart localization file with locales imported'
      ' as deferred, allowing for lazy loading of each locale in Flutter web.\n'
      '\n'
      'This can reduce a web app’s initial startup time by decreasing the '
      'size of the JavaScript bundle. When this flag is set to true, the '
      'messages for a particular locale are only downloaded and loaded by the '
      'Flutter app as they are needed. For projects with a lot of different '
      'locales and many localization strings, it can be an performance '
      'improvement to have deferred loading. For projects with a small number '
      'of locales, the difference is negligible, and might slow down the start '
      'up compared to bundling the localizations with the rest of the '
      'application.\n\n'
      'Note that this flag does not affect other platforms such as mobile or '
      'desktop.',
  );

  final argslib.ArgResults results = parser.parse(arguments);
  if (results['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  precacheLanguageAndRegionTags();

  final String inputPathString = results['arb-dir'] as String;
  final String outputPathString = results['output-dir'] as String;
  final String outputFileString = results['output-localization-file'] as String;
  final String templateArbFileName = results['template-arb-file'] as String;
  final String untranslatedMessagesFile = results['untranslated-messages-file'] as String;
  final String classNameString = results['output-class'] as String;
  final String preferredSupportedLocaleString = results['preferred-supported-locales'] as String;
  final String headerString = results['header'] as String;
  final String headerFile = results['header-file'] as String;
  final bool useDeferredLoading = results['use-deferred-loading'] as bool;

  const local.LocalFileSystem fs = local.LocalFileSystem();
  final LocalizationsGenerator localizationsGenerator = LocalizationsGenerator(fs);

  try {
    localizationsGenerator
      ..initialize(
        inputPathString: inputPathString,
        outputPathString: outputPathString,
        templateArbFileName: templateArbFileName,
        outputFileString: outputFileString,
        classNameString: classNameString,
        preferredSupportedLocaleString: preferredSupportedLocaleString,
        headerString: headerString,
        headerFile: headerFile,
        useDeferredLoading: useDeferredLoading,
      )
      ..loadResources()
      ..writeOutputFile()
      ..outputUnimplementedMessages(untranslatedMessagesFile);
  } on FileSystemException catch (e) {
    exitWithError(e.message);
  } on FormatException catch (e) {
    exitWithError(e.message);
  } on L10nException catch (e) {
    exitWithError(e.message);
  }
}
