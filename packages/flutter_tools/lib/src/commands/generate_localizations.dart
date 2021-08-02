// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals_null_migrated.dart' as globals;
import '../localizations/gen_l10n.dart';
import '../localizations/gen_l10n_types.dart';
import '../localizations/localizations_utils.dart';
import '../runner/flutter_command.dart';

/// A command to generate localizations source files for a Flutter project.
///
/// It generates Dart localization source files from arb files.
///
/// For a more comprehensive tutorial on the tool, please see the
/// [internationalization user guide](flutter.dev/go/i18n-user-guide).
class GenerateLocalizationsCommand extends FlutterCommand {
  GenerateLocalizationsCommand({
    FileSystem fileSystem,
    Logger logger,
  }) :
    _fileSystem = fileSystem,
    _logger = logger {
    argParser.addOption(
      'arb-dir',
      defaultsTo: globals.fs.path.join('lib', 'l10n'),
      help: 'The directory where the template and translated arb files are located.',
    );
    argParser.addOption(
      'output-dir',
      help: 'The directory where the generated localization classes will be written '
            'if the synthetic-package flag is set to false.\n'
            '\n'
            'If output-dir is specified and the synthetic-package flag is enabled, '
            'this option will be ignored by the tool.\n'
            '\n'
            'The app must import the file specified in the "--output-localization-file" '
            'option from this directory. If unspecified, this defaults to the same '
            'directory as the input directory specified in "--arb-dir".',
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
      'untranslated-messages-file',
      help: 'The location of a file that describes the localization '
            'messages have not been translated yet. Using this option will create '
            'a JSON file at the target location, in the following format:\n'
            '\n'
            '    "locale": ["message_1", "message_2" ... "message_n"]\n'
            '\n'
            'If this option is not specified, a summary of the messages that '
            'have not been translated will be printed on the command line.',
    );
    argParser.addOption(
      'output-class',
      defaultsTo: 'AppLocalizations',
      help: 'The Dart class name to use for the output localization and '
            'localizations delegate classes.',
    );
    argParser.addMultiOption(
      'preferred-supported-locales',
      valueHelp: 'locale',
      help: 'The list of preferred supported locales for the application. '
            'By default, the tool will generate the supported locales list in '
            'alphabetical order. Use this flag if you would like to default to '
            'a different locale. '
            'For example, pass in "en_US" if you would like your app to '
            'default to American English on devices that support it. '
            'Pass this option multiple times to define multiple items.',
    );
    argParser.addOption(
      'header',
      help: 'The header to prepend to the generated Dart localizations '
            'files. This option takes in a string.\n'
            '\n'
            'For example, pass in "/// All localized files." if you would '
            'like this string prepended to the generated Dart file.\n'
            '\n'
            'Alternatively, see the "--header-file" option to pass in a text '
            'file for longer headers.'
    );
    argParser.addOption(
      'header-file',
      help: 'The header to prepend to the generated Dart localizations '
            'files. The value of this option is the name of the file that '
            'contains the header text which will be inserted at the top '
            'of each generated Dart file.\n'
            '\n'
            'Alternatively, see the "--header" option to pass in a string '
            'for a simpler header.\n'
            '\n'
            'This file should be placed in the directory specified in "--arb-dir".'
    );
    argParser.addFlag(
      'use-deferred-loading',
      defaultsTo: false,
      help: 'Whether to generate the Dart localization file with locales imported '
            'as deferred, allowing for lazy loading of each locale in Flutter web.\n'
            '\n'
            'This can reduce a web app’s initial startup time by decreasing the '
            'size of the JavaScript bundle. When this flag is set to true, the '
            'messages for a particular locale are only downloaded and loaded by the '
            'Flutter app as they are needed. For projects with a lot of different '
            'locales and many localization strings, it can be an performance '
            'improvement to have deferred loading. For projects with a small number '
            'of locales, the difference is negligible, and might slow down the start '
            'up compared to bundling the localizations with the rest of the '
            'application.\n'
            '\n'
            'This flag does not affect other platforms such as mobile or desktop.',
    );
    argParser.addOption(
      'gen-inputs-and-outputs-list',
      valueHelp: 'path-to-output-directory',
      help: 'When specified, the tool generates a JSON file containing the '
            "tool's inputs and outputs named gen_l10n_inputs_and_outputs.json.\n"
            '\n'
            'This can be useful for keeping track of which files of the Flutter '
            'project were used when generating the latest set of localizations. '
            "For example, the Flutter tool's build system uses this file to "
            'keep track of when to call gen_l10n during hot reload.\n'
            '\n'
            'The value of this option is the directory where the JSON file will be '
            'generated.\n'
            '\n'
            'When null, the JSON file will not be generated.'
    );
    argParser.addFlag(
      'synthetic-package',
      defaultsTo: true,
      help: 'Determines whether or not the generated output files will be '
            'generated as a synthetic package or at a specified directory in '
            'the Flutter project.\n'
            '\n'
            'This flag is set to true by default.\n'
            '\n'
            'When synthetic-package is set to false, it will generate the '
            'localizations files in the directory specified by arb-dir by default.\n'
            '\n'
            'If output-dir is specified, files will be generated there.',
    );
    argParser.addOption(
      'project-dir',
      valueHelp: 'absolute/path/to/flutter/project',
      help: 'When specified, the tool uses the path passed into this option '
            'as the directory of the root Flutter project.\n'
            '\n'
            'When null, the relative path to the present working directory will be used.'
    );
    argParser.addFlag(
      'required-resource-attributes',
      help: 'Requires all resource ids to contain a corresponding resource attribute.\n'
            '\n'
            'By default, simple messages will not require metadata, but it is highly '
            'recommended as this provides context for the meaning of a message to '
            'readers.\n'
            '\n'
            'Resource attributes are still required for plural messages.'
    );
    argParser.addFlag(
      'nullable-getter',
      help: 'Whether or not the localizations class getter is nullable.\n'
            '\n'
            'By default, this value is set to true so that '
            'Localizations.of(context) returns a nullable value '
            'for backwards compatibility. If this value is set to true, then '
            'a null check is performed on the returned value of '
            'Localizations.of(context), removing the need for null checking in '
            'user code.'
    );
  }

  final FileSystem _fileSystem;
  final Logger _logger;

  @override
  String get description => 'Generate localizations for the current project.';

  @override
  String get name => 'gen-l10n';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (_fileSystem.file('l10n.yaml').existsSync()) {
      final LocalizationOptions options = parseLocalizationsOptions(
        file: _fileSystem.file('l10n.yaml'),
        logger: _logger,
      );
      _logger.printStatus(
        'Because l10n.yaml exists, the options defined there will be used '
        'instead.\n'
        'To use the command line arguments, delete the l10n.yaml file in the '
        'Flutter project.\n\n'
      );
      generateLocalizations(
        logger: _logger,
        options: options,
        projectDir: _fileSystem.currentDirectory,
        dependenciesDir: null,
        fileSystem: _fileSystem,
      );
      return FlutterCommandResult.success();
    }

    final String inputPathString = stringArg('arb-dir');
    final String outputPathString = stringArg('output-dir');
    final String outputFileString = stringArg('output-localization-file');
    final String templateArbFileName = stringArg('template-arb-file');
    final String untranslatedMessagesFile = stringArg('untranslated-messages-file');
    final String classNameString = stringArg('output-class');
    final List<String> preferredSupportedLocales = stringsArg('preferred-supported-locales');
    final String headerString = stringArg('header');
    final String headerFile = stringArg('header-file');
    final bool useDeferredLoading = boolArg('use-deferred-loading');
    final String inputsAndOutputsListPath = stringArg('gen-inputs-and-outputs-list');
    final bool useSyntheticPackage = boolArg('synthetic-package');
    final String projectPathString = stringArg('project-dir');
    final bool areResourceAttributesRequired = boolArg('required-resource-attributes');
    final bool usesNullableGetter = boolArg('nullable-getter');

    precacheLanguageAndRegionTags();

    try {
      LocalizationsGenerator(
        fileSystem: _fileSystem,
        inputPathString: inputPathString,
        outputPathString: outputPathString,
        templateArbFileName: templateArbFileName,
        outputFileString: outputFileString,
        classNameString: classNameString,
        preferredSupportedLocales: preferredSupportedLocales,
        headerString: headerString,
        headerFile: headerFile,
        useDeferredLoading: useDeferredLoading,
        inputsAndOutputsListPath: inputsAndOutputsListPath,
        useSyntheticPackage: useSyntheticPackage,
        projectPathString: projectPathString,
        areResourceAttributesRequired: areResourceAttributesRequired,
        untranslatedMessagesFile: untranslatedMessagesFile,
        usesNullableGetter: usesNullableGetter,
      )
        ..loadResources()
        ..writeOutputFiles(_logger);
    } on L10nException catch (e) {
      throwToolExit(e.message);
    }

    return FlutterCommandResult.success();
  }
}
