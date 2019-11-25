import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:localization/gen_l10n.dart';
import 'package:localization/localizations_utils.dart';
import 'package:path/path.dart' as path;

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
  final String templateArbFileName = results['template-arb-file'];
  final String classNameString = results['output-class'];

  final LocalizationsGenerator localizationsGenerator = LocalizationsGenerator(fs);
  try {
    localizationsGenerator.initialize(
      l10nDirectoryPath: arbPathString,
      templateArbFileName: templateArbFileName,
      outputFileString: outputFileString,
      classNameString: classNameString,
    );
    localizationsGenerator.parseArbFiles();
  } on FileSystemException catch (e) {
    exitWithError(e.message);
  } on L10nException catch (e) {
    exitWithError(e.message);
  }

  // TODO(shihaohong): create a method to decode templateArbFile
  final List<String> classMethods = <String>[];
  Map<String, dynamic> bundle;
  try {
    bundle = json.decode(localizationsGenerator.templateArbFile.readAsStringSync());
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

  // TODO(shihaohong): create a method that creates the output file
  localizationsGenerator.outputFile.writeAsStringSync(
    defaultFileTemplate
      .replaceAll('@className', classNameString)
      .replaceAll('@classMethods', classMethods.join('\n'))
      .replaceAll('@importFile', _importFilePath(arbPathString, outputFileString))
      .replaceAll('@supportedLocales', genSupportedLocaleProperty(localizationsGenerator.supportedLocales))
      .replaceAll('@supportedLanguageCodes', localizationsGenerator.supportedLanguageCodes.toList().join(', '))
  );

  // TODO(shihaohong): create method that generates arb files using the intl_translation:generate_from_arb command
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
    '--output-dir=${localizationsGenerator.l10nDirectory.path}',
    '--no-use-deferred-loading',
    localizationsGenerator.outputFile.path,
    ...localizationsGenerator.arbFilenames,
  ]);
  if (generateFromArbResult.exitCode != 0) {
    stderr.write(generateFromArbResult.stderr);
    exit(1);
  }
}