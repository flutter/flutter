// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../convert.dart';
import '../../globals.dart' as globals;
import '../../localizations/gen_l10n.dart';
import '../../localizations/localizations_utils.dart';
import '../build_system.dart';
import '../depfile.dart';

const String _kDependenciesFileName = 'gen_l10n_inputs_and_outputs.json';

<<<<<<< HEAD
=======
/// Run the localizations generation script with the configuration [options].
void generateLocalizations({
  @required Directory projectDir,
  @required Directory dependenciesDir,
  @required LocalizationOptions options,
  @required LocalizationsGenerator localizationsGenerator,
  @required Logger logger,
}) {
  // If generating a synthetic package, generate a warning if
  // flutter: generate is not set.
  final FlutterProject flutterProject = FlutterProject.fromDirectory(projectDir);
  if (options.useSyntheticPackage && !flutterProject.manifest.generateSyntheticPackage) {
    logger.printError(
      'Attempted to generate localizations code without having '
      'the flutter: generate flag turned on.'
      '\n'
      'Check pubspec.yaml and ensure that flutter: generate: true has '
      'been added and rebuild the project. Otherwise, the localizations '
      'source code will not be importable.'
    );
    throw Exception();
  }

  precacheLanguageAndRegionTags();

  final String inputPathString = options?.arbDirectory?.path ?? globals.fs.path.join('lib', 'l10n');
  final String templateArbFileName = options?.templateArbFile?.toFilePath() ?? 'app_en.arb';
  final String outputFileString = options?.outputLocalizationsFile?.toFilePath() ?? 'app_localizations.dart';

  try {
    localizationsGenerator
      ..initialize(
        inputsAndOutputsListPath: dependenciesDir.path,
        projectPathString: projectDir.path,
        inputPathString: inputPathString,
        templateArbFileName: templateArbFileName,
        outputFileString: outputFileString,
        outputPathString: options?.outputDirectory?.path,
        classNameString: options.outputClass ?? 'AppLocalizations',
        preferredSupportedLocale: options.preferredSupportedLocales,
        headerString: options.header,
        headerFile: options?.headerFile?.toFilePath(),
        useDeferredLoading: options.deferredLoading ?? false,
        useSyntheticPackage: options.useSyntheticPackage ?? true,
        areResourceAttributesRequired: options.areResourceAttributesRequired ?? false,
        untranslatedMessagesFile: options?.untranslatedMessagesFile?.toFilePath(),
      )
      ..loadResources()
      ..writeOutputFiles(logger, isFromYaml: true);
  } on L10nException catch (e) {
    logger.printError(e.message);
    throw Exception();
  }
}

>>>>>>> 47e3e75b0789f615ef14ba198efad89f030debb3
/// A build step that runs the generate localizations script from
/// dev/tool/localizations.
class GenerateLocalizationsTarget extends Target {
  const GenerateLocalizationsTarget();

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    // This is added as a convenience for developing the tool.
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/localizations.dart'),
    // TODO(jonahwilliams): once https://github.com/flutter/flutter/issues/56321 is
    // complete, we should add the artifact as a dependency here. Since the tool runs
    // this code from source, looking up each dependency will be cumbersome.
  ];

  @override
  String get name => 'gen_localizations';

  @override
  List<Source> get outputs => <Source>[];

  @override
  List<String> get depfiles => <String>['gen_localizations.d'];

  @override
  bool canSkip(Environment environment) {
    final File configFile = environment.projectDir.childFile('l10n.yaml');
    return !configFile.existsSync();
  }

  @override
  Future<void> build(Environment environment) async {
    final File configFile = environment.projectDir.childFile('l10n.yaml');
    assert(configFile.existsSync());

    final LocalizationOptions options = parseLocalizationsOptions(
      file: configFile,
      logger: globals.logger,
    );
    final DepfileService depfileService = DepfileService(
      logger: environment.logger,
      fileSystem: environment.fileSystem,
    );
    generateLocalizations(
      logger: environment.logger,
      options: options,
      projectDir: environment.projectDir,
      dependenciesDir: environment.buildDir,
      localizationsGenerator: LocalizationsGenerator(environment.fileSystem),
    );

    final Map<String, Object> dependencies = json.decode(
      environment.buildDir.childFile(_kDependenciesFileName).readAsStringSync()
    ) as Map<String, Object>;
    final Depfile depfile = Depfile(
      <File>[
        configFile,
        for (dynamic inputFile in dependencies['inputs'] as List<dynamic>)
          environment.fileSystem.file(inputFile)
      ],
      <File>[
        for (dynamic outputFile in dependencies['outputs'] as List<dynamic>)
          environment.fileSystem.file(outputFile)
      ]
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('gen_localizations.d'),
    );
  }
}
