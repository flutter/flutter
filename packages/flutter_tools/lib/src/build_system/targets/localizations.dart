// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../globals.dart' as globals;
import '../build_system.dart';
import '../depfile.dart';

Future<void> generateLocalizations({
  @required LocalizationOptions options,
  @required String flutterRoot,
  @required FileSystem fileSystem,
  @required ProcessManager processManager,
  @required Artifacts artifacts,
  @required Logger logger,
}) async {
  final String genL10nPath = fileSystem.path.join(
    flutterRoot,
    'dev',
    'tools',
    'localization',
    'bin',
    'gen_l10n.dart',
  );
  final ProcessResult result = await processManager.run(<String>[
    artifacts.getArtifactPath(Artifact.engineDartBinary),
    genL10nPath,
    if (options.arbDirectory != null)
      '--arb-dir=${options.arbDirectory}',
    if (options.templateArbFile != null)
      '--template-arb-file=${options.templateArbFile}',
    if (options.outputLocalizationsFile != null)
      '--output-localization-file=${options.outputLocalizationsFile}',
    if (options.untranslatedMessagesFile != null)
      '--untranslated-messages-file=${options.untranslatedMessagesFile}',
    if (options.outputClass != null)
      '--output-class=${options.outputClass}',
    if (options.headerFile != null)
      '--header=${options.headerFile}',
    if (options.header != null)
      '--header-file=${options.header}',
    if (options.deferredLoading != null)
      '--use-deferred-loading',
    if (options.preferredSupportedLocales != null)
      '--preferred-supported-locales=${options.preferredSupportedLocales}',
  ]);
  if (result.exitCode != 0) {
    logger.printError(result.stdout + result.stderr as String);
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
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/localizations.dart')
  ];

  @override
  String get name => 'gen_localizations';

  @override
  List<Source> get outputs => <Source>[];

  @override
  List<String> get depfiles => <String>['gen_localizations.d'];

  @override
  Future<void> build(Environment environment) async {
    final File configFile = environment.projectDir.childFile('l10n.yaml');

    // If the config file does not exist, exit immediately.
    if (!configFile.existsSync()) {
      return;
    }
    final LocalizationOptions options = parseLocalizationsOptions(
      file: configFile,
      logger: globals.logger,
    );
    final DepfileService depfileService = DepfileService(
      logger: environment.logger,
      fileSystem: environment.fileSystem,
    );

    // Setup project inputs and outputs. This currently makes some
    // guess about the output and does not include all files.
    final Directory inputArb = environment.fileSystem.directory(
      options.arbDirectory ?? environment.projectDir
        .childDirectory('lib')
        .childFile('l10n').uri,
    );
    final File outputLocalizations = environment.fileSystem.file(
      options.outputLocalizationsFile ?? environment.projectDir
      .childDirectory('lib')
      .childFile('app_localizations.dart').uri,
    );

    final List<File> inputs = <File>[
      configFile,
      if (options.headerFile != null)
        environment.fileSystem.file(options.headerFile).absolute,
      // Include all arb files as build inputs.
      for (final File file in inputArb.listSync().whereType<File>())
        if (environment.fileSystem.path.extension(file.path) == '.arb')
          file,
    ];
    final List<File> outputs = <File>[
      if (options.untranslatedMessagesFile != null)
        environment.fileSystem.file(options.untranslatedMessagesFile).absolute,
      outputLocalizations,
    ];

    final Depfile depfile = Depfile(inputs, outputs);

    await generateLocalizations(
      artifacts: environment.artifacts,
      fileSystem: environment.fileSystem,
      flutterRoot: environment.flutterRootDir.path,
      logger: environment.logger,
      processManager: environment.processManager,
      options: options,
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
    @required this.arbDirectory,
    @required this.templateArbFile,
    @required this.outputLocalizationsFile,
    @required this.untranslatedMessagesFile,
    @required this.header,
    @required this.outputClass,
    @required this.preferredSupportedLocales,
    @required this.headerFile,
    @required this.deferredLoading,
  });

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
  /// The header to prepend to the generated Dart localizations
  final String header;

  /// The `--output-class` argument.
  final String outputClass;

  /// The `--preferred-supported-locales` argument.
  final String preferredSupportedLocales;

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
}

/// Parse the localizations configuration options from [file].
///
/// Throws [Exception] if any of the contents are invalid.
LocalizationOptions parseLocalizationsOptions({
  @required File file,
  @required Logger logger,
}) {
  final YamlNode yamlNode = loadYamlNode(file.readAsStringSync());
  if (yamlNode is! YamlMap) {
    logger.printError('Expected ${file.path} to contain a map, instead was $yamlNode');
    throw Exception();
  }
  final YamlMap yamlMap = yamlNode as YamlMap;
  return LocalizationOptions(
    arbDirectory: tryReadUri(yamlMap, 'arb-dir', logger),
    templateArbFile: tryReadUri(yamlMap, 'template-arb-file', logger),
    outputLocalizationsFile: tryReadUri(yamlMap, 'output-localization-file', logger),
    untranslatedMessagesFile: tryReadUri(yamlMap, 'untranslated-messages-file', logger),
    header: tryReadString(yamlMap, 'header', logger),
    outputClass: tryReadString(yamlMap, 'output-class', logger),
    preferredSupportedLocales: tryReadString(yamlMap, 'preferred-supported-locales', logger),
    headerFile: tryReadUri(yamlMap, 'header-file', logger),
    deferredLoading: tryReadBool(yamlMap, 'use-deferred-loading', logger),
  );
}

/// Try to read a `bool` value or null from `yamlMap`, otherwise throw.
@visibleForTesting
bool tryReadBool(YamlMap yamlMap, String key, Logger logger) {
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

/// Try to read a `String` value or null from `yamlMap`, otherwise throw.
@visibleForTesting
String tryReadString(YamlMap yamlMap, String key, Logger logger) {
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

/// Try to read a valid `Uri` or null from `yamlMap`, otherwise throw.
@visibleForTesting
Uri tryReadUri(YamlMap yamlMap, String key, Logger logger) {
  final String value = tryReadString(yamlMap, key, logger);
  if (value == null) {
    return null;
  }
  final Uri uri = Uri.tryParse(value);
  if (uri == null) {
    logger.printError('"$value" must be a relative file URI');
  }
  return uri;
}
