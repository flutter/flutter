// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../convert.dart';
import '../../globals.dart' as globals;
import '../../localizations/gen_l10n.dart';
import '../../localizations/gen_l10n_types.dart';
import '../../localizations/localizations_utils.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';

const String _kDependenciesFileName = 'gen_l10n_inputs_and_outputs.json';

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

  final String inputPathString = options?.arbDirectory?.toFilePath() ?? globals.fs.path.join('lib', 'l10n');
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
        classNameString: options.outputClass ?? 'AppLocalizations',
        preferredSupportedLocale: options.preferredSupportedLocales,
        headerString: options.header,
        headerFile: options?.headerFile?.toFilePath(),
        useDeferredLoading: options.deferredLoading ?? false,
        useSyntheticPackage: options.useSyntheticPackage ?? true,
      )
      ..loadResources()
      ..writeOutputFiles()
      ..outputUnimplementedMessages(
        options?.untranslatedMessagesFile?.toFilePath(),
        logger,
      );
  } on L10nException catch (e) {
    logger.printError(e.message);
    throw Exception();
  }
}

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

/// Typed configuration from the localizations config file.
class LocalizationOptions {
  const LocalizationOptions({
    this.arbDirectory,
    this.templateArbFile,
    this.outputLocalizationsFile,
    this.untranslatedMessagesFile,
    this.header,
    this.outputClass,
    this.preferredSupportedLocales,
    this.headerFile,
    this.deferredLoading,
    this.useSyntheticPackage = true,
  }) : assert(useSyntheticPackage != null);

  /// The `--arb-dir` argument.
  ///
  /// The directory where all localization files should reside.
  final Uri arbDirectory;

  /// The `--template-arb-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri templateArbFile;

  /// The `--output-localization-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri outputLocalizationsFile;

  /// The `--untranslated-messages-file` argument.
  ///
  /// This URI is relative to [arbDirectory].
  final Uri untranslatedMessagesFile;

  /// The `--header` argument.
  ///
  /// The header to prepend to the generated Dart localizations.
  final String header;

  /// The `--output-class` argument.
  final String outputClass;

  /// The `--preferred-supported-locales` argument.
  final List<String> preferredSupportedLocales;

  /// The `--header-file` argument.
  ///
  /// A file containing the header to preprend to the generated
  /// Dart localizations.
  final Uri headerFile;

  /// The `--use-deferred-loading` argument.
  ///
  /// Whether to generate the Dart localization file with locales imported
  /// as deferred.
  final bool deferredLoading;

  /// The `--synthetic-package` argument.
  ///
  /// Whether to generate the Dart localization files in a synthetic package
  /// or in a custom directory.
  final bool useSyntheticPackage;
}

/// Parse the localizations configuration options from [file].
///
/// Throws [Exception] if any of the contents are invalid. Returns a
/// [LocalizationOptions] with all fields as `null` if the config file exists
/// but is empty.
LocalizationOptions parseLocalizationsOptions({
  @required File file,
  @required Logger logger,
}) {
  final String contents = file.readAsStringSync();
  if (contents.trim().isEmpty) {
    return const LocalizationOptions();
  }
  final YamlNode yamlNode = loadYamlNode(file.readAsStringSync());
  if (yamlNode is! YamlMap) {
    logger.printError('Expected ${file.path} to contain a map, instead was $yamlNode');
    throw Exception();
  }
  final YamlMap yamlMap = yamlNode as YamlMap;
  return LocalizationOptions(
    arbDirectory: _tryReadUri(yamlMap, 'arb-dir', logger),
    templateArbFile: _tryReadUri(yamlMap, 'template-arb-file', logger),
    outputLocalizationsFile: _tryReadUri(yamlMap, 'output-localization-file', logger),
    untranslatedMessagesFile: _tryReadUri(yamlMap, 'untranslated-messages-file', logger),
    header: _tryReadString(yamlMap, 'header', logger),
    outputClass: _tryReadString(yamlMap, 'output-class', logger),
    preferredSupportedLocales: _tryReadStringList(yamlMap, 'preferred-supported-locales', logger),
    headerFile: _tryReadUri(yamlMap, 'header-file', logger),
    deferredLoading: _tryReadBool(yamlMap, 'use-deferred-loading', logger),
    useSyntheticPackage: _tryReadBool(yamlMap, 'synthetic-package', logger) ?? true,
  );
}

// Try to read a `bool` value or null from `yamlMap`, otherwise throw.
bool _tryReadBool(YamlMap yamlMap, String key, Logger logger) {
  final Object value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    logger.printError('Expected "$key" to have a bool value, instead was "$value"');
    throw Exception();
  }
  return value as bool;
}

// Try to read a `String` value or null from `yamlMap`, otherwise throw.
String _tryReadString(YamlMap yamlMap, String key, Logger logger) {
  final Object value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    logger.printError('Expected "$key" to have a String value, instead was "$value"');
    throw Exception();
  }
  return value as String;
}

List<String> _tryReadStringList(YamlMap yamlMap, String key, Logger logger) {
  final Object value = yamlMap[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return <String>[value];
  }
  if (value is Iterable) {
    return value.map((dynamic e) => e.toString()).toList();
  }
  logger.printError('"$value" must be String or List.');
  throw Exception();
}

// Try to read a valid `Uri` or null from `yamlMap`, otherwise throw.
Uri _tryReadUri(YamlMap yamlMap, String key, Logger logger) {
  final String value = _tryReadString(yamlMap, key, logger);
  if (value == null) {
    return null;
  }
  final Uri uri = Uri.tryParse(value);
  if (uri == null) {
    logger.printError('"$value" must be a relative file URI');
  }
  return uri;
}
