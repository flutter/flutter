// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../base/process.dart';
import '../../build_info.dart';
import '../../cache.dart';
import '../../convert.dart';
import '../../dart/language_version.dart';
import '../../dart/package_map.dart';
import '../../flutter_plugins.dart';
import '../../globals.dart' as globals;
import '../../isolated/native_assets/dart_hook_result.dart';
import '../../project.dart';
import '../../web/bootstrap.dart';
import '../../web/compile.dart';
import '../../web/file_generators/flutter_service_worker_js.dart';
import '../../web/file_generators/main_dart.dart' as main_dart;
import '../../web_template.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'localizations.dart';
import 'native_assets.dart';

/// Generates an entry point for a web target.
// Keep this in sync with build_runner/resident_web_runner.dart
class WebEntrypointTarget extends Target {
  const WebEntrypointTarget();

  @override
  String get name => 'web_entrypoint';

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/web.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{BUILD_DIR}/main.dart')];

  @override
  Future<void> build(Environment environment) async {
    final String? targetFile = environment.defines[kTargetFile];
    final Uri importUri = environment.fileSystem.file(targetFile).absolute.uri;
    final File packageConfigFile = findPackageConfigFileOrDefault(environment.projectDir);

    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: environment.logger,
    );
    final FlutterProject flutterProject = FlutterProject.current();
    final LanguageVersion languageVersion = determineLanguageVersion(
      environment.fileSystem.file(targetFile),
      packageConfig[flutterProject.manifest.appName],
      Cache.flutterRoot!,
    );

    // Use the PackageConfig to find the correct package-scheme import path
    // for the user application. If the application has a mix of package-scheme
    // and relative imports for a library, then importing the entrypoint as a
    // file-scheme will cause said library to be recognized as two distinct
    // libraries. This can cause surprising behavior as types from that library
    // will be considered distinct from each other.
    //
    // By construction, this will only be null if the package_config.json file
    // does not have an entry for the user's application or if the main file is
    // outside of the lib/ directory.
    final String importedEntrypoint =
        packageConfig.toPackageUri(importUri)?.toString() ?? importUri.toString();

    await injectBuildTimePluginFilesForWebPlatform(
      flutterProject,
      destination: environment.buildDir,
    );
    // The below works because `injectBuildTimePluginFiles` is configured to write
    // the web_plugin_registrant.dart file alongside the generated main.dart
    const generatedImport = 'web_plugin_registrant.dart';

    final String contents = main_dart.generateMainDartFile(
      importedEntrypoint,
      languageVersion: languageVersion,
      pluginRegistrantEntrypoint: generatedImport,
    );

    environment.buildDir.childFile('main.dart').writeAsStringSync(contents);
  }
}

abstract class Dart2WebTarget extends Target {
  const Dart2WebTarget();

  WebCompilerConfig get compilerConfig;

  Map<String, Object?> get buildConfig;
  Iterable<File> buildFiles(Environment environment);
  Iterable<String> get buildPatternStems;

  List<String> computeDartDefines(Environment environment) {
    final List<String> dartDefines = compilerConfig.renderer.updateDartDefines(
      decodeDartDefines(environment.defines, kDartDefines),
    );
    if (environment.defines[kUseLocalCanvasKitFlag] != 'true') {
      final bool canvasKitUrlAlreadySet = dartDefines.any(
        (String define) => define.startsWith('FLUTTER_WEB_CANVASKIT_URL='),
      );
      if (!canvasKitUrlAlreadySet) {
        dartDefines.add(
          'FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/${globals.flutterVersion.engineRevision}/',
        );
      }
    }
    return dartDefines;
  }

  @override
  List<Target> get dependencies => const <Target>[
    WebEntrypointTarget(),
    GenerateLocalizationsTarget(),
  ];

  @override
  List<Source> get inputs => <Source>[
    const Source.hostArtifact(HostArtifact.flutterWebSdk),
    const Source.artifact(Artifact.engineDartBinary),
    const Source.pattern('{BUILD_DIR}/main.dart'),
    const Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
  ];

  @override
  List<Source> get outputs => <Source>[
    for (final String stem in buildPatternStems) Source.pattern('{BUILD_DIR}/$stem'),
  ];

  @override
  String get buildKey => compilerConfig.buildKey;
}

/// Compiles a web entry point with dart2js.
class Dart2JSTarget extends Dart2WebTarget {
  Dart2JSTarget(this.compilerConfig);

  @override
  final JsCompilerConfig compilerConfig;

  @override
  String get name => 'dart2js';

  @override
  List<String> get depfiles => const <String>['dart2js.d'];

  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final Artifacts artifacts = environment.artifacts;
    final String platformBinariesPath = artifacts
        .getHostArtifact(HostArtifact.webPlatformKernelFolder)
        .path;
    final sharedCommandOptions = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary, platform: TargetPlatform.web_javascript),
      'compile',
      'js',
      '--platform-binaries=$platformBinariesPath',
      '--invoker=flutter_tool',
      ...decodeCommaSeparated(environment.defines, kExtraFrontEndOptions),
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else if (buildMode == BuildMode.release)
        '-Ddart.vm.product=true',
      for (final String dartDefine in computeDartDefines(environment)) '-D$dartDefine',
    ];

    // NOTE: most args should be populated in [toSharedCommandOptions].
    final cfeCompilationArgs = <String>[
      ...sharedCommandOptions,
      ...compilerConfig.toSharedCommandOptions(buildMode),
      '-o',
      environment.buildDir.childFile('app.dill').path,
      '--packages=${findPackageConfigFileOrDefault(environment.projectDir).path}',
      '--cfe-only',
      environment.buildDir.childFile('main.dart').path, // dartfile
    ];

    final processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    // Run the dart2js compilation in two stages, so that icon tree shaking can
    // parse the kernel file for web builds.
    await processUtils.run(cfeCompilationArgs, throwOnError: true);

    final File outputJSFile = environment.buildDir.childFile('main.dart.js');

    await processUtils.run(throwOnError: true, <String>[
      ...sharedCommandOptions,
      ...compilerConfig.toCommandOptions(buildMode),
      '-o',
      outputJSFile.path,
      environment.buildDir.childFile('app.dill').path, // dartfile
    ]);
    final File dart2jsDeps = environment.buildDir.childFile('app.dill.deps');
    if (!dart2jsDeps.existsSync()) {
      environment.logger.printWarning(
        'Warning: dart2js did not produce expected deps list at '
        '${dart2jsDeps.path}',
      );
      return;
    }
    final DepfileService depFileService = environment.depFileService;
    final Depfile depFile = depFileService.parseDart2js(
      environment.buildDir.childFile('app.dill.deps'),
      outputJSFile,
    );
    depFileService.writeToFile(depFile, environment.buildDir.childFile('dart2js.d'));
  }

  @override
  Map<String, Object?> get buildConfig => <String, Object?>{
    'compileTarget': 'dart2js',
    'renderer': compilerConfig.renderer.name,
    'mainJsPath': 'main.dart.js',
  };

  @override
  Iterable<File> buildFiles(Environment environment) =>
      environment.buildDir.listSync(recursive: true).whereType<File>().where((File file) {
        if (file.basename == 'main.dart.js') {
          return true;
        }
        if (file.basename == 'main.dart.js.map') {
          return compilerConfig.sourceMaps;
        }
        final partFileRegex = RegExp(r'main\.dart\.js_[0-9].*\.part\.js');
        if (partFileRegex.hasMatch(file.basename)) {
          return true;
        }

        if (compilerConfig.sourceMaps) {
          final partFileSourceMapRegex = RegExp(r'main\.dart\.js_[0-9].*.part\.js\.map');
          if (partFileSourceMapRegex.hasMatch(file.basename)) {
            return true;
          }
        }

        if (compilerConfig.dumpInfo) {
          if (file.basename == 'main.dart.js.info.json') {
            return true;
          }
        }
        return false;
      });

  @override
  Iterable<String> get buildPatternStems => <String>[
    'main.dart.js',
    'main.dart.js_*.part.js',
    if (compilerConfig.sourceMaps) ...<String>['main.dart.js.map', 'main.dart.js_*.part.js.map'],
  ];
}

/// Compiles a web entry point with dart2wasm.
class Dart2WasmTarget extends Dart2WebTarget {
  Dart2WasmTarget(this.compilerConfig, this._analytics);

  @override
  final WasmCompilerConfig compilerConfig;

  final Analytics _analytics;

  /// List the preconfigured build options for a given build mode.
  List<String> buildModeOptions(BuildMode mode, List<String> dartDefines) => switch (mode) {
    BuildMode.debug => <String>[
      // These checks allow the CLI to override the value of this define for unit
      // testing the framework.
      if (!dartDefines.any((String define) => define.startsWith('dart.vm.profile')))
        '-Ddart.vm.profile=false',
      if (!dartDefines.any((String define) => define.startsWith('dart.vm.product')))
        '-Ddart.vm.product=false',
    ],
    BuildMode.profile => <String>[
      // These checks allow the CLI to override the value of this define for
      // benchmarks with most timeline traces disabled.
      if (!dartDefines.any((String define) => define.startsWith('dart.vm.profile')))
        '-Ddart.vm.profile=true',
      if (!dartDefines.any((String define) => define.startsWith('dart.vm.product')))
        '-Ddart.vm.product=false',
      '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
      '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
    ],
    BuildMode.release => <String>[
      '-Ddart.vm.profile=false',
      '-Ddart.vm.product=true',
      '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
      '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
    ],
    _ => throw Exception('Unknown BuildMode: $mode'),
  };

  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final Artifacts artifacts = environment.artifacts;
    final File outputWasmFile = environment.buildDir.childFile('main.dart.wasm');
    final File depFile = environment.buildDir.childFile('dart2wasm.d');
    final String platformBinariesPath = artifacts
        .getHostArtifact(HostArtifact.webPlatformKernelFolder)
        .path;
    final String platformFilePath = environment.fileSystem.path.join(
      platformBinariesPath,
      'dart2wasm_platform.dill',
    );
    final List<String> dartDefines = computeDartDefines(environment);

    final compilationArgs = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary, platform: TargetPlatform.web_javascript),
      'compile',
      'wasm',
      '--packages=${findPackageConfigFileOrDefault(environment.projectDir).path}',
      '--extra-compiler-option=--platform=$platformFilePath',
      ...buildModeOptions(buildMode, dartDefines),
      if (compilerConfig.renderer == WebRendererMode.skwasm) ...<String>[
        '--extra-compiler-option=--import-shared-memory',
        '--extra-compiler-option=--shared-memory-max-pages=32768',
      ],
      ...decodeCommaSeparated(environment.defines, kExtraFrontEndOptions),
      for (final String dartDefine in dartDefines) '-D$dartDefine',
      '--extra-compiler-option=--depfile=${depFile.path}',
      ...compilerConfig.toCommandOptions(buildMode),
      '-o',
      outputWasmFile.path,
      environment.buildDir.childFile('main.dart').path, // dartfile
    ];

    final processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    final RunResult runResult = await processUtils.run(
      throwOnError: !compilerConfig.dryRun,
      compilationArgs,
    );
    if (compilerConfig.dryRun) {
      _handleDryRunResult(environment, runResult);
    }
  }

  @override
  String get name => 'dart2wasm';

  @override
  List<String> get depfiles => const <String>['dart2wasm.d'];

  @override
  Map<String, Object?> get buildConfig => compilerConfig.dryRun
      ? const <String, Object?>{}
      : <String, Object?>{
          'compileTarget': 'dart2wasm',
          'renderer': compilerConfig.renderer.name,
          'mainWasmPath': 'main.dart.wasm',
          'jsSupportRuntimePath': 'main.dart.mjs',
        };

  @override
  Iterable<File> buildFiles(Environment environment) => compilerConfig.dryRun
      ? const <File>[]
      : environment.buildDir
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (File file) => switch (file.basename) {
                'main.dart.wasm' || 'main.dart.mjs' => true,
                'main.dart.wasm.map' => compilerConfig.sourceMaps,
                _ => false,
              },
            );

  @override
  Iterable<String> get buildPatternStems => compilerConfig.dryRun
      ? const <String>[]
      : <String>[
          'main.dart.wasm',
          'main.dart.mjs',
          if (compilerConfig.sourceMaps) 'main.dart.wasm.map',
        ];

  void _handleDryRunResult(Environment environment, RunResult runResult) {
    final int exitCode = runResult.exitCode;
    final String stdout = runResult.stdout;
    final String stderr = runResult.stderr;
    final String result;
    String? findingsSummary;

    if (exitCode != 0 && exitCode != 254) {
      environment.logger.printWarning('Unexpected wasm dry run failure ($exitCode):');
      if (stderr.isNotEmpty) {
        environment.logger.printWarning(stdout);
        environment.logger.printWarning(stderr);
      }
      result = 'crash';
    } else if (exitCode == 0) {
      environment.logger.printWarning(
        'Wasm dry run succeeded. Consider building and testing your application with the '
        '`--wasm` flag. See docs for more info: '
        'https://docs.flutter.dev/platform-integration/web/wasm',
      );
      result = 'success';
    } else if (stderr.isNotEmpty) {
      environment.logger.printWarning('Wasm dry run failed:');
      environment.logger.printWarning(stdout);
      environment.logger.printWarning(stderr);
      result = 'failure';
    } else if (stdout.isNotEmpty) {
      environment.logger.printWarning('Wasm dry run findings:');
      environment.logger.printWarning(stdout);
      environment.logger.printWarning(
        'Consider addressing these issues to enable wasm builds. See docs for more info: '
        'https://docs.flutter.dev/platform-integration/web/wasm\n',
      );
      result = 'findings';
      findingsSummary = RegExp(
        r'\(([0-9]+)\)',
      ).allMatches(stdout).map((RegExpMatch f) => f.group(1)).join(',');
    } else {
      result = 'unknown';
    }
    environment.logger.printWarning('Use --no-wasm-dry-run to disable these warnings.');

    _analytics.send(
      Event.flutterWasmDryRun(result: result, exitCode: exitCode, findingsSummary: findingsSummary),
    );
  }
}

/// Unpacks the dart2js or dart2wasm compilation and resources to a given
/// output directory.
class WebReleaseBundle extends Target {
  WebReleaseBundle(List<WebCompilerConfig> configs, Analytics analytics)
    : this._(
        compileTargets: configs
            .map(
              (WebCompilerConfig config) => switch (config) {
                WasmCompilerConfig() => Dart2WasmTarget(config, analytics),
                JsCompilerConfig() => Dart2JSTarget(config),
              },
            )
            .toList(),
      );

  WebReleaseBundle._({required this.compileTargets})
    : templatedFilesTarget = WebTemplatedFiles(
        compileTargets.map((Dart2WebTarget target) => target.buildConfig).toList(),
      );

  final List<Dart2WebTarget> compileTargets;
  final WebTemplatedFiles templatedFilesTarget;

  @override
  String get name => 'web_release_bundle';

  @override
  List<Target> get dependencies => <Target>[
    ...compileTargets,
    templatedFilesTarget,
    const DartBuild(specifiedTargetPlatform: TargetPlatform.web_javascript),
  ];

  Iterable<String> get buildPatternStems =>
      compileTargets.expand((Dart2WebTarget target) => target.buildPatternStems);

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...buildPatternStems.map((String file) => Source.pattern('{BUILD_DIR}/$file')),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...buildPatternStems.map((String file) => Source.pattern('{OUTPUT_DIR}/$file')),
  ];

  @override
  List<String> get depfiles => const <String>['flutter_assets.d', 'web_resources.d'];

  @override
  Future<void> build(Environment environment) async {
    final FileSystem fileSystem = environment.fileSystem;
    for (final Dart2WebTarget target in compileTargets) {
      for (final File outputFile in target.buildFiles(environment)) {
        outputFile.copySync(
          environment.outputDir.childFile(fileSystem.path.basename(outputFile.path)).path,
        );
      }
    }

    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final buildMode = BuildMode.fromCliName(buildModeEnvironment);

    createVersionFile(environment, environment.defines);
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    outputDirectory.createSync(recursive: true);

    final DartHooksResult dartHookResult = await DartBuild.loadHookResult(environment);
    final Depfile depfile = await copyAssets(
      environment,
      environment.outputDir.childDirectory('assets'),
      dartHookResult: dartHookResult,
      targetPlatform: TargetPlatform.web_javascript,
      buildMode: buildMode,
    );
    final DepfileService depfileService = environment.depFileService;
    depfileService.writeToFile(depfile, environment.buildDir.childFile('flutter_assets.d'));

    final Directory webResources = environment.projectDir.childDirectory('web');
    final List<File> inputResourceFiles = webResources
        .listSync(recursive: true)
        .whereType<File>()
        .toList();

    // Copy other resource files out of web/ directory.
    final outputResourcesFiles = <File>[];
    for (final inputFile in inputResourceFiles) {
      final String relativePath = fileSystem.path.relative(inputFile.path, from: webResources.path);
      if (relativePath == 'index.html' || relativePath == 'flutter_bootstrap.js') {
        // Skip these, these are handled by the templated file target.
        continue;
      }
      final File outputFile = fileSystem.file(
        fileSystem.path.join(environment.outputDir.path, relativePath),
      );
      if (!outputFile.parent.existsSync()) {
        outputFile.parent.createSync(recursive: true);
      }
      outputResourcesFiles.add(outputFile);
      inputFile.copySync(outputFile.path);
    }
    final resourceFile = Depfile(inputResourceFiles, outputResourcesFiles);
    depfileService.writeToFile(resourceFile, environment.buildDir.childFile('web_resources.d'));
  }

  /// Create version.json file that contains data about version for package_info
  void createVersionFile(Environment environment, Map<String, String> defines) {
    final versionInfo =
        jsonDecode(FlutterProject.current().getVersionInfo()) as Map<String, dynamic>;

    if (defines.containsKey(kBuildNumber)) {
      versionInfo['build_number'] = defines[kBuildNumber];
    }

    if (defines.containsKey(kBuildName)) {
      versionInfo['version'] = defines[kBuildName];
    }

    environment.outputDir.childFile('version.json').writeAsStringSync(jsonEncode(versionInfo));
  }
}

class WebTemplatedFiles extends Target {
  WebTemplatedFiles(this.buildDescriptions);

  final List<Map<String, Object?>> buildDescriptions;

  @override
  String get buildKey => jsonEncode(buildDescriptions);

  void _emitWebTemplateWarning(
    Environment environment,
    String filePath,
    WebTemplateWarning warning,
  ) {
    environment.logger.printWarning(
      'Warning: In $filePath:${warning.lineNumber}: ${warning.warningText}',
    );
  }

  String buildConfigString(Environment environment) {
    final buildConfig = <String, Object>{
      'engineRevision': globals.flutterVersion.engineRevision,
      'builds': buildDescriptions,
      if (environment.defines[kUseLocalCanvasKitFlag] == 'true') 'useLocalCanvasKit': true,
    };
    return '''
if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = ${jsonEncode(buildConfig)};
''';
  }

  @override
  Future<void> build(Environment environment) async {
    final Directory webResources = environment.projectDir.childDirectory('web');
    final includeServiceWorkerSettings =
        environment.serviceWorkerStrategy == ServiceWorkerStrategy.offlineFirst;
    final File inputFlutterBootstrapJs = webResources.childFile('flutter_bootstrap.js');
    final String inputBootstrapContent;
    if (await inputFlutterBootstrapJs.exists()) {
      inputBootstrapContent = await inputFlutterBootstrapJs.readAsString();
    } else {
      inputBootstrapContent = generateDefaultFlutterBootstrapScript(
        includeServiceWorkerSettings: includeServiceWorkerSettings,
      );
    }
    final bootstrapTemplate = WebTemplate(inputBootstrapContent);
    for (final WebTemplateWarning warning in bootstrapTemplate.getWarnings()) {
      _emitWebTemplateWarning(environment, 'flutter_bootstrap.js', warning);
    }

    final FileSystem fileSystem = environment.fileSystem;
    final File flutterJsFile = fileSystem.file(
      fileSystem.path.join(
        globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
        'flutter.js',
      ),
    );

    final String buildConfig = buildConfigString(environment);

    // Insert a random hash into the requests for service_worker.js. This is not a content hash,
    // because it would need to be the hash for the entire bundle and not just the resource
    // in question.
    final String? serviceWorkerVersion = includeServiceWorkerSettings
        ? Random().nextInt(1 << 32).toString()
        : null;
    final String bootstrapContent = bootstrapTemplate.withSubstitutions(
      baseHref: '',
      serviceWorkerVersion: serviceWorkerVersion,
      flutterJsFile: flutterJsFile,
      buildConfig: buildConfig,
    );

    final File outputFlutterBootstrapJs = fileSystem.file(
      fileSystem.path.join(environment.outputDir.path, 'flutter_bootstrap.js'),
    );
    await outputFlutterBootstrapJs.writeAsString(bootstrapContent);

    await for (final FileSystemEntity file in webResources.list(recursive: true)) {
      if (file is File && file.basename == 'index.html') {
        final indexHtmlTemplate = WebTemplate(file.readAsStringSync());
        final String relativePath = fileSystem.path.relative(file.path, from: webResources.path);

        for (final WebTemplateWarning warning in indexHtmlTemplate.getWarnings()) {
          _emitWebTemplateWarning(environment, relativePath, warning);
        }

        final String indexHtmlContent = indexHtmlTemplate.withSubstitutions(
          baseHref: environment.defines[kBaseHref] ?? '/',
          staticAssetsUrl: environment.defines[kStaticAssetsUrl] ?? '/',
          serviceWorkerVersion: serviceWorkerVersion,
          flutterJsFile: flutterJsFile,
          buildConfig: buildConfig,
          flutterBootstrapJs: bootstrapContent,
        );
        final File outputIndexHtml = fileSystem.file(
          fileSystem.path.join(environment.outputDir.path, relativePath),
        );
        await outputIndexHtml.create(recursive: true);
        await outputIndexHtml.writeAsString(indexHtmlContent);
      }
    }
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/web/*/index.html'),
    Source.pattern('{PROJECT_DIR}/web/flutter_bootstrap.js'),
    Source.hostArtifact(HostArtifact.flutterWebSdk),
  ];

  @override
  String get name => 'web_templated_files';

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/*/index.html'),
    Source.pattern('{OUTPUT_DIR}/flutter_bootstrap.js'),
  ];
}

/// Static assets provided by the Flutter SDK that do not change, such as
/// CanvasKit.
///
/// These assets can be cached until a new version of the flutter web sdk is
/// downloaded.
class WebBuiltInAssets extends Target {
  const WebBuiltInAssets(this.fileSystem);

  final FileSystem fileSystem;

  @override
  String get name => 'web_static_assets';

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<String> get depfiles => const <String>[];

  @override
  List<Source> get inputs => const <Source>[Source.hostArtifact(HostArtifact.flutterWebSdk)];

  Directory get _canvasKitDirectory => globals.fs.directory(
    fileSystem.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path,
      'canvaskit',
    ),
  );

  List<File> get _canvasKitFiles =>
      _canvasKitDirectory.listSync(recursive: true).whereType<File>().toList();

  String _filePathRelativeToCanvasKitDirectory(File file) =>
      fileSystem.path.relative(file.path, from: _canvasKitDirectory.path);

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{BUILD_DIR}/flutter.js'),
    for (final File file in _canvasKitFiles)
      Source.pattern('{BUILD_DIR}/canvaskit/${_filePathRelativeToCanvasKitDirectory(file)}'),
  ];

  @override
  Future<void> build(Environment environment) async {
    for (final File file in _canvasKitFiles) {
      final String relativePath = _filePathRelativeToCanvasKitDirectory(file);
      final String targetPath = fileSystem.path.join(
        environment.outputDir.path,
        'canvaskit',
        relativePath,
      );
      file.copySync(targetPath);
    }

    // Write the flutter.js file
    final String flutterJsOut = fileSystem.path.join(environment.outputDir.path, 'flutter.js');
    final File flutterJsFile = fileSystem.file(
      fileSystem.path.join(
        globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
        'flutter.js',
      ),
    );
    flutterJsFile.copySync(flutterJsOut);
  }
}

/// Generate a service worker for a web target.
class WebServiceWorker extends Target {
  const WebServiceWorker(this.fileSystem, this.compileConfigs, this.analytics);

  final FileSystem fileSystem;
  final List<WebCompilerConfig> compileConfigs;
  final Analytics analytics;

  @override
  String get name => 'web_service_worker';

  @override
  List<Target> get dependencies => <Target>[
    WebReleaseBundle(compileConfigs, analytics),
    WebBuiltInAssets(fileSystem),
  ];

  @override
  List<String> get depfiles => const <String>['service_worker.d'];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  Future<void> build(Environment environment) async {
    final List<File> contents = environment.outputDir
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (File file) =>
              !file.path.endsWith('flutter_service_worker.js') &&
              !environment.fileSystem.path.basename(file.path).startsWith('.'),
        )
        .toList();

    final File serviceWorkerFile = environment.outputDir.childFile('flutter_service_worker.js');
    final depfile = Depfile(contents, <File>[serviceWorkerFile]);
    final String fileGeneratorsPath = environment.artifacts.getArtifactPath(
      Artifact.flutterToolsFileGenerators,
    );
    final String serviceWorker = generateServiceWorker(
      fileGeneratorsPath,
      serviceWorkerStrategy: environment.serviceWorkerStrategy,
    );
    serviceWorkerFile.writeAsStringSync(serviceWorker);
    environment.depFileService.writeToFile(
      depfile,
      environment.buildDir.childFile('service_worker.d'),
    );
  }
}

extension on Environment {
  ServiceWorkerStrategy get serviceWorkerStrategy =>
      ServiceWorkerStrategy.fromCliName(defines[kServiceWorkerStrategy]) ??
      ServiceWorkerStrategy.offlineFirst;
}
