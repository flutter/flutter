// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class GenerateLocalizationsCommand extends FlutterCommand {
  GenerateLocalizationsCommand() {
    argParser.addOption(
      'arb-dir',
      defaultsTo: path.join('lib', 'l10n'),
      help: 'The directory where all localization files should reside. For '
        'example, the template and translated arb files should be located here. '
        'Also, the generated output messages Dart files for each locale and the '
        'generated localizations classes will be created here.',
    );
    argParser.addOption(
      'template-arb-file',
      defaultsTo: 'app_en.arb',
      help: 'The template arb file that will be used as the basis for '
        'generating the Dart localization and messages files.',
    );
    argParser.addOption(
      'output-localization-file',
      defaultsTo: 'app_localizations.dart',
      help: 'The filename for the output localization and localizations '
        'delegate classes.',
    );
    argParser.addOption(
      'output-class',
      defaultsTo: 'AppLocalizations',
      help: 'The Dart class name to use for the output localization and '
        'localizations delegate classes.',
    );
    argParser.addOption(
      'preferred-supported-locales',
      help: 'The list of preferred supported locales for the application. '
        'By default, the tool will generate the supported locales list in '
        'alphabetical order. Use this flag if you would like to default to '
        'a different locale. \n\n'
        "For example, pass in ['en_US'] if you would like your app to "
        'default to American English if a device supports it.',
    );
  }

  @override
  String get name => 'generate-localizations';

  @override
  String get description => 'Generate Dart files from ARB files to localize a Flutter application.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String dartSdkPath = globals.fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk');
    final String root = globals.fs.path.absolute(Cache.flutterRoot);

    final List<String> options = <String>[
      '--arb-dir=${argResults['arb-dir']}',
      '--template-arb-file=${argResults['template-arb-file']}',
      '--output-localization-file=${argResults['output-localization-file']}',
      '--output-class=${argResults['output-class']}',
      if (argResults['preferred-supported-locales'] != null)
        '--preferred-supported-locales=${argResults['preferred-supported-locales']}'
    ];

    final List<String> command = <String>[
      globals.fs.path.join(dartSdkPath, 'bin', 'dart'),
      globals.fs.path.join(root, 'dev', 'tools', 'localization', 'bin', 'gen_l10n.dart'),
      ...options,
    ];

    print('starting process');
    final Process process = await globals.processManager.start(command, runInShell: true);
    print('process spawned');
    final Stream<String> errorStream =
        process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    errorStream.listen(globals.printError);

    final Stream<String> outStream =
        process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
    outStream.listen(globals.printStatus);
    if (await process.exitCode != 0) {
      //stderr.write(process.stderr);
      return FlutterCommandResult.fail();
    }
    return FlutterCommandResult.success();
  }
}
