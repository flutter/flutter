// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:package_config/package_config.dart';

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
import '../../html_utils.dart';
import '../../project.dart';
import '../../web/compile.dart';
import '../../web/file_generators/flutter_service_worker_js.dart';
import '../../web/file_generators/main_dart.dart' as main_dart;
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'localizations.dart';

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
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/main.dart'),
  ];

  @override
  Future<void> build(Environment environment) async {
    final String? targetFile = environment.defines[kTargetFile];
    final Uri importUri = environment.fileSystem.file(targetFile).absolute.uri;
    // TODO(zanderso): support configuration of this file.
    const String packageFile = '.packages';
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      environment.fileSystem.file(packageFile),
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
    // By construction, this will only be null if the .packages file does not
    // have an entry for the user's application or if the main file is
    // outside of the lib/ directory.
    final String importedEntrypoint = packageConfig.toPackageUri(importUri)?.toString()
      ?? importUri.toString();

    await injectBuildTimePluginFiles(flutterProject, webPlatform: true, destination: environment.buildDir);
    // The below works because `injectBuildTimePluginFiles` is configured to write
    // the web_plugin_registrant.dart file alongside the generated main.dart
    const String generatedImport = 'web_plugin_registrant.dart';

    final String contents = main_dart.generateMainDartFile(importedEntrypoint,
      languageVersion: languageVersion,
      pluginRegistrantEntrypoint: generatedImport,
    );

    environment.buildDir.childFile('main.dart').writeAsStringSync(contents);
  }
}

/// Compiles a web entry point with dart2js.
abstract class Dart2WebTarget extends Target {
  const Dart2WebTarget();

  Source get compilerSnapshot;

  WebCompilerConfig get compilerConfig;

  Map<String, Object?> get buildConfig;
  List<String> get buildFiles;

  @override
  List<Target> get dependencies => const <Target>[
    WebEntrypointTarget(),
    GenerateLocalizationsTarget(),
  ];

  @override
  List<Source> get inputs => <Source>[
    const Source.hostArtifact(HostArtifact.flutterWebSdk),
    compilerSnapshot,
    const Source.artifact(Artifact.engineDartBinary),
    const Source.pattern('{BUILD_DIR}/main.dart'),
    const Source.pattern('{PROJECT_DIR}/.dart_tool/package_config_subset'),
  ];

  @override
  List<Source> get outputs => buildFiles.map(
    (String file) => Source.pattern('{BUILD_DIR}/$file')
  ).toList();

  @override
  String get buildKey => compilerConfig.buildKey;
}

class Dart2JSTarget extends Dart2WebTarget {
  Dart2JSTarget(this.compilerConfig);

  @override
  final JsCompilerConfig compilerConfig;

  @override
  String get name => 'dart2js';

  @override
  Source get compilerSnapshot => const Source.artifact(Artifact.dart2jsSnapshot);

  @override
  List<String> get depfiles => const <String>[
    'dart2js.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final Artifacts artifacts = environment.artifacts;
    final String platformBinariesPath = artifacts.getHostArtifact(HostArtifact.webPlatformKernelFolder).path;
    final List<String> dartDefines = compilerConfig.renderer.updateDartDefines(
      decodeDartDefines(environment.defines, kDartDefines),
    );
    final List<String> sharedCommandOptions = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary, platform: TargetPlatform.web_javascript),
      '--disable-dart-dev',
      artifacts.getArtifactPath(Artifact.dart2jsSnapshot, platform: TargetPlatform.web_javascript),
      '--platform-binaries=$platformBinariesPath',
      '--invoker=flutter_tool',
      ...decodeCommaSeparated(environment.defines, kExtraFrontEndOptions),
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      for (final String dartDefine in dartDefines)
        '-D$dartDefine',
    ];

    final List<String> compilationArgs = <String>[
      ...sharedCommandOptions,
      ...compilerConfig.toSharedCommandOptions(),
      '-o',
      environment.buildDir.childFile('app.dill').path,
      '--packages=.dart_tool/package_config.json',
      '--cfe-only',
      environment.buildDir.childFile('main.dart').path, // dartfile
    ];

    final ProcessUtils processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    // Run the dart2js compilation in two stages, so that icon tree shaking can
    // parse the kernel file for web builds.
    await processUtils.run(compilationArgs, throwOnError: true);

    final File outputJSFile = environment.buildDir.childFile('main.dart.js');

    await processUtils.run(
      throwOnError: true,
      <String>[
        ...sharedCommandOptions,
        ...compilerConfig.toCommandOptions(buildMode),
        '-o',
        outputJSFile.path,
        environment.buildDir.childFile('app.dill').path, // dartfile
      ],
    );
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
    depFileService.writeToFile(
      depFile,
      environment.buildDir.childFile('dart2js.d'),
    );
  }

  @override
  Map<String, Object?> get buildConfig => <String, Object?>{
    'compileTarget': 'dart2js',
    'renderer': compilerConfig.renderer.name,
    'mainJsPath': 'main.dart.js',
  };

  @override
  List<String> get buildFiles => <String>[
    'main.dart.js',
    if (compilerConfig.sourceMaps) 'main.dart.js.map',
  ];
}

class Dart2WasmTarget extends Dart2WebTarget {
  Dart2WasmTarget(this.compilerConfig);

  @override
  final WasmCompilerConfig compilerConfig;

  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final Artifacts artifacts = environment.artifacts;
    final File outputWasmFile =
        environment.buildDir.childFile('main.dart.wasm');
    final File depFile = environment.buildDir.childFile('dart2wasm.d');
    final String dartSdkPath = artifacts.getArtifactPath(Artifact.engineDartSdkPath, platform: TargetPlatform.web_javascript);
    final String platformBinariesPath = artifacts.getHostArtifact(HostArtifact.webPlatformKernelFolder).path;
    final String platformFilePath = environment.fileSystem.path.join(platformBinariesPath, 'dart2wasm_platform.dill');
    final List<String> dartDefines = compilerConfig.renderer.updateDartDefines(
      decodeDartDefines(environment.defines, kDartDefines),
    );

    assert(buildMode == BuildMode.release || buildMode == BuildMode.profile);
    final List<String> compilationArgs = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary, platform: TargetPlatform.web_javascript),
      'compile',
      'wasm',
      '--packages=.dart_tool/package_config.json',
      '--extra-compiler-option=--dart-sdk=$dartSdkPath',
      '--extra-compiler-option=--platform=$platformFilePath',
      '--extra-compiler-option=--delete-tostring-package-uri=dart:ui',
      '--extra-compiler-option=--delete-tostring-package-uri=package:flutter',
      if (compilerConfig.renderer == WebRendererMode.skwasm) ...<String>[
        '--extra-compiler-option=--import-shared-memory',
        '--extra-compiler-option=--shared-memory-max-pages=32768',
        ],
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      ...decodeCommaSeparated(environment.defines, kExtraFrontEndOptions),
      for (final String dartDefine in dartDefines)
        '-D$dartDefine',
      '--extra-compiler-option=--depfile=${depFile.path}',

      ...compilerConfig.toCommandOptions(buildMode),
      '-o',
      outputWasmFile.path,
      environment.buildDir.childFile('main.dart').path, // dartfile
    ];

    final ProcessUtils processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    await processUtils.run(
      throwOnError: true,
      compilationArgs,
    );
  }

  @override
  Source get compilerSnapshot => const Source.artifact(Artifact.dart2wasmSnapshot);

  @override
  String get name => 'dart2wasm';

  @override
  List<String> get depfiles => const <String>[
    'dart2wasm.d',
  ];

  @override
  Map<String, Object?> get buildConfig => <String, Object?>{
    'compileTarget': 'dart2wasm',
    'renderer': compilerConfig.renderer.name,
    'mainWasmPath': 'main.dart.wasm',
    'jsSupportRuntimePath': 'main.dart.mjs',
  };

  @override
  List<String> get buildFiles => <String>[
    'main.dart.wasm',
    'main.dart.mjs',
  ];
}

/// Unpacks the dart2js or dart2wasm compilation and resources to a given
/// output directory.
class WebReleaseBundle extends Target {
  WebReleaseBundle(List<WebCompilerConfig> configs) : this._withTargets(
    configs.map((WebCompilerConfig config) =>
      switch (config) {
        WasmCompilerConfig() => Dart2WasmTarget(config),
        JsCompilerConfig() => Dart2JSTarget(config),
      }
    ).toList()
  );

  const WebReleaseBundle._withTargets(this.compileTargets);

  final List<Dart2WebTarget> compileTargets;

  List<String> get buildFiles => compileTargets.fold(
    const Iterable<String>.empty(),
    (Iterable<String> current, Dart2WebTarget target) => current.followedBy(target.buildFiles)
  ).toList();

  @override
  String get name => 'web_release_bundle';

  @override
  List<Target> get dependencies => compileTargets;

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    ...buildFiles.map((String file) => Source.pattern('{BUILD_DIR}/$file'))
  ];

  @override
  List<Source> get outputs => <Source>[
    ...buildFiles.map((String file) => Source.pattern('{OUTPUT_DIR}/$file'))
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
    'web_resources.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    for (final File outputFile in environment.buildDir.listSync(recursive: true).whereType<File>()) {
      final String basename = environment.fileSystem.path.basename(outputFile.path);
      if (buildFiles.contains(basename)) {
        outputFile.copySync(
          environment.outputDir.childFile(environment.fileSystem.path.basename(outputFile.path)).path
        );
      }
    }

    createVersionFile(environment, environment.defines);
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    outputDirectory.createSync(recursive: true);
    final Depfile depfile = await copyAssets(
      environment,
      environment.outputDir.childDirectory('assets'),
      targetPlatform: TargetPlatform.web_javascript,
    );
    final DepfileService depfileService = environment.depFileService;
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );

    final Directory webResources = environment.projectDir
      .childDirectory('web');
    final List<File> inputResourceFiles = webResources
      .listSync(recursive: true)
      .whereType<File>()
      .toList();

    // Copy other resource files out of web/ directory.
    final List<File> outputResourcesFiles = <File>[];
    for (final File inputFile in inputResourceFiles) {
      final File outputFile = environment.fileSystem.file(environment.fileSystem.path.join(
        environment.outputDir.path,
        environment.fileSystem.path.relative(inputFile.path, from: webResources.path)));
      if (!outputFile.parent.existsSync()) {
        outputFile.parent.createSync(recursive: true);
      }
      outputResourcesFiles.add(outputFile);
      // insert a random hash into the requests for service_worker.js. This is not a content hash,
      // because it would need to be the hash for the entire bundle and not just the resource
      // in question.
      if (environment.fileSystem.path.basename(inputFile.path) == 'index.html') {
        final List<Map<String, Object?>> buildDescriptions = compileTargets.map(
          (Dart2WebTarget target) => target.buildConfig
        ).toList();
        final Map<String, Object?> buildConfig = <String, Object?>{
          'engineRevision': globals.flutterVersion.engineRevision,
          'builds': buildDescriptions,
        };
        final String buildConfigString = '_flutter.buildConfig = ${jsonEncode(buildConfig)};';
        final IndexHtml indexHtml = IndexHtml(inputFile.readAsStringSync());
        indexHtml.applySubstitutions(
          baseHref: environment.defines[kBaseHref] ?? '/',
          serviceWorkerVersion: Random().nextInt(4294967296).toString(),
          buildConfig: buildConfigString,
        );
        outputFile.writeAsStringSync(indexHtml.content);
        continue;
      }
      inputFile.copySync(outputFile.path);
    }
    final Depfile resourceFile = Depfile(inputResourceFiles, outputResourcesFiles);
    depfileService.writeToFile(
      resourceFile,
      environment.buildDir.childFile('web_resources.d'),
    );
  }

  /// Create version.json file that contains data about version for package_info
  void createVersionFile(Environment environment, Map<String, String> defines) {
    final Map<String, dynamic> versionInfo =
        jsonDecode(FlutterProject.current().getVersionInfo())
            as Map<String, dynamic>;

    if (defines.containsKey(kBuildNumber)) {
      versionInfo['build_number'] = defines[kBuildNumber];
    }

    if (defines.containsKey(kBuildName)) {
      versionInfo['version'] = defines[kBuildName];
    }

    environment.outputDir
        .childFile('version.json')
        .writeAsStringSync(jsonEncode(versionInfo));
  }
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
  List<Source> get inputs => const <Source>[
    Source.hostArtifact(HostArtifact.flutterWebSdk),
  ];

  Directory get _canvasKitDirectory =>
    globals.fs.directory(
      fileSystem.path.join(
        globals.artifacts!.getHostArtifact(HostArtifact.flutterWebSdk).path,
        'canvaskit',
      )
    );

  List<File> get _canvasKitFiles => _canvasKitDirectory.listSync(recursive: true).whereType<File>().toList();

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
      final String targetPath = fileSystem.path.join(environment.outputDir.path, 'canvaskit', relativePath);
      file.copySync(targetPath);
    }

    // Write the flutter.js file
    final String flutterJsOut = fileSystem.path.join(environment.outputDir.path, 'flutter.js');
    final File flutterJsFile = fileSystem.file(fileSystem.path.join(
      globals.artifacts!.getHostArtifact(HostArtifact.flutterJsDirectory).path,
      'flutter.js',
    ));
    flutterJsFile.copySync(flutterJsOut);
  }
}

/// Generate a service worker for a web target.
class WebServiceWorker extends Target {
  const WebServiceWorker(this.fileSystem, this.compileConfigs);

  final FileSystem fileSystem;
  final List<WebCompilerConfig> compileConfigs;

  @override
  String get name => 'web_service_worker';

  @override
  List<Target> get dependencies => <Target>[
    WebReleaseBundle(compileConfigs),
    WebBuiltInAssets(fileSystem),
  ];

  @override
  List<String> get depfiles => const <String>[
    'service_worker.d',
  ];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  Future<void> build(Environment environment) async {
    final List<File> contents = environment.outputDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => !file.path.endsWith('flutter_service_worker.js')
        && !environment.fileSystem.path.basename(file.path).startsWith('.'))
      .toList();

    final Map<String, String> urlToHash = <String, String>{};
    for (final File file in contents) {
      // Do not force caching of source maps.
      if (file.path.endsWith('main.dart.js.map') ||
        file.path.endsWith('.part.js.map')) {
        continue;
      }
      final String url = environment.fileSystem.path.toUri(
        environment.fileSystem.path.relative(
          file.path,
          from: environment.outputDir.path),
        ).toString();
      final String hash = md5.convert(await file.readAsBytes()).toString();
      urlToHash[url] = hash;
      // Add an additional entry for the base URL.
      if (url == 'index.html') {
        urlToHash['/'] = hash;
      }
    }

    final File serviceWorkerFile = environment.outputDir
      .childFile('flutter_service_worker.js');
    final Depfile depfile = Depfile(contents, <File>[serviceWorkerFile]);
    final ServiceWorkerStrategy serviceWorkerStrategy =
        ServiceWorkerStrategy.fromCliName(environment.defines[kServiceWorkerStrategy]);
    final String fileGeneratorsPath =
        environment.artifacts.getArtifactPath(Artifact.flutterToolsFileGenerators);
    final String serviceWorker = generateServiceWorker(
      fileGeneratorsPath,
      urlToHash,
      <String>[
        'main.dart.js',
        if (compileConfigs.any((WebCompilerConfig config) => config is WasmCompilerConfig)) ...<String>[
          'main.dart.wasm',
          'main.dart.mjs',
        ],
        'index.html',
        if (urlToHash.containsKey('assets/AssetManifest.bin.json'))
          'assets/AssetManifest.bin.json',
        if (urlToHash.containsKey('assets/FontManifest.json'))
          'assets/FontManifest.json',
      ],
      serviceWorkerStrategy: serviceWorkerStrategy,
    );
    serviceWorkerFile
      .writeAsStringSync(serviceWorker);
    environment.depFileService.writeToFile(
      depfile,
      environment.buildDir.childFile('service_worker.d'),
    );
  }
}
