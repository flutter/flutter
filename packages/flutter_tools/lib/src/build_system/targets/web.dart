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
import '../../web/file_generators/flutter_js.dart' as flutter_js;
import '../../web/file_generators/flutter_service_worker_js.dart';
import '../../web/file_generators/main_dart.dart' as main_dart;
import '../../web/file_generators/wasm_bootstrap.dart' as wasm_bootstrap;
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'localizations.dart';
import 'shader_compiler.dart';

/// Whether the application has web plugins.
const String kHasWebPlugins = 'HasWebPlugins';

/// Base href to set in index.html in flutter build command
const String kBaseHref = 'baseHref';

/// The caching strategy to use for service worker generation.
const String kServiceWorkerStrategy = 'ServiceWorkerStrategy';

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
  const Dart2WebTarget(this.webRenderer);

  final WebRendererMode webRenderer;
  Source get compilerSnapshot;

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
  List<Source> get outputs => const <Source>[];
}

class Dart2JSTarget extends Dart2WebTarget {
  Dart2JSTarget(super.webRenderer);

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
    final JsCompilerConfig compilerConfig = JsCompilerConfig.fromBuildSystemEnvironment(environment.defines);
    final Artifacts artifacts = environment.artifacts;
    final String platformBinariesPath = getWebPlatformBinariesDirectory(artifacts, webRenderer).path;
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
      for (final String dartDefine in decodeDartDefines(environment.defines, kDartDefines))
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
        if (buildMode == BuildMode.profile) '--no-minify',
        ...compilerConfig.toCommandOptions(),
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
}

class Dart2WasmTarget extends Dart2WebTarget {
  Dart2WasmTarget(super.webRenderer);

  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final WasmCompilerConfig compilerConfig = WasmCompilerConfig.fromBuildSystemEnvironment(environment.defines);
    final BuildMode buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final Artifacts artifacts = environment.artifacts;
    final File outputWasmFile = environment.buildDir.childFile(
      compilerConfig.runWasmOpt ? 'main.dart.unopt.wasm' : 'main.dart.wasm'
    );
    final File depFile = environment.buildDir.childFile('dart2wasm.d');
    final String dartSdkPath = artifacts.getArtifactPath(Artifact.engineDartSdkPath, platform: TargetPlatform.web_javascript);
    final String dartSdkRoot = environment.fileSystem.directory(dartSdkPath).parent.path;

    final List<String> compilationArgs = <String>[
      artifacts.getArtifactPath(Artifact.engineDartAotRuntime, platform: TargetPlatform.web_javascript),
      '--disable-dart-dev',
      artifacts.getArtifactPath(Artifact.dart2wasmSnapshot, platform: TargetPlatform.web_javascript),
      '--packages=.dart_tool/package_config.json',
      '--dart-sdk=$dartSdkPath',
      '--multi-root-scheme',
      'org-dartlang-sdk',
      '--multi-root',
      artifacts.getHostArtifact(HostArtifact.flutterWebSdk).path,
      '--multi-root',
      dartSdkRoot,
      '--libraries-spec',
      artifacts.getHostArtifact(HostArtifact.flutterWebLibrariesJson).path,
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      ...decodeCommaSeparated(environment.defines, kExtraFrontEndOptions),
      for (final String dartDefine in decodeDartDefines(environment.defines, kDartDefines))
        '-D$dartDefine',
      ...compilerConfig.toCommandOptions(),
      if (webRenderer == WebRendererMode.skwasm)
        ...<String>[
          '--import-shared-memory',
          '--shared-memory-max-pages=32768',
        ],
      '--depfile=${depFile.path}',

      environment.buildDir.childFile('main.dart').path, // dartfile
      outputWasmFile.path,
    ];

    final ProcessUtils processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    await processUtils.run(
      throwOnError: true,
      compilationArgs,
    );
    if (compilerConfig.runWasmOpt) {
      final String wasmOptBinary = artifacts.getArtifactPath(
        Artifact.wasmOptBinary,
        platform: TargetPlatform.web_javascript
      );
      final File optimizedOutput = environment.buildDir.childFile('main.dart.wasm');
      final List<String> optimizeArgs = <String>[
        wasmOptBinary,
        '--all-features',
        '--closed-world',
        '--traps-never-happen',
        '-O3',
        '--type-ssa',
        '--gufa',
        '-O3',
        '--type-merging',
        if (compilerConfig.wasmOpt == WasmOptLevel.debug)
          '--debuginfo',
        outputWasmFile.path,
        '-o',
        optimizedOutput.path,
      ];
      await processUtils.run(
        throwOnError: true,
        optimizeArgs,
      );

      // Rename the .mjs file not to have the `.unopt` bit
      final File jsRuntimeFile = environment.buildDir.childFile('main.dart.unopt.mjs');
      await jsRuntimeFile.rename(environment.buildDir.childFile('main.dart.mjs').path);
    }
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
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/main.dart.wasm'),
    Source.pattern('{OUTPUT_DIR}/main.dart.mjs'),
  ];
}

/// Unpacks the dart2js or dart2wasm compilation and resources to a given
/// output directory.
class WebReleaseBundle extends Target {
  const WebReleaseBundle(this.webRenderer, {required this.isWasm});

  final WebRendererMode webRenderer;
  final bool isWasm;

  String get outputFileNameNoSuffix => 'main.dart';
  String get outputFileName => '$outputFileNameNoSuffix${isWasm ? '.wasm' : '.js'}';
  String get wasmJSRuntimeFileName => '$outputFileNameNoSuffix.mjs';

  @override
  String get name => 'web_release_bundle';

  @override
  List<Target> get dependencies => <Target>[
    if (isWasm) Dart2WasmTarget(webRenderer) else Dart2JSTarget(webRenderer),
  ];

  @override
  List<Source> get inputs => <Source>[
    Source.pattern('{BUILD_DIR}/$outputFileName'),
    const Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    if (isWasm) Source.pattern('{BUILD_DIR}/$wasmJSRuntimeFileName'),
  ];

  @override
  List<Source> get outputs => <Source>[
    Source.pattern('{OUTPUT_DIR}/$outputFileName'),
    if (isWasm) Source.pattern('{OUTPUT_DIR}/$wasmJSRuntimeFileName'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'dart2js.d',
    'flutter_assets.d',
    'web_resources.d',
  ];

  bool shouldCopy(String name) =>
      // Do not copy the deps file.
      (name.contains(outputFileName) && !name.endsWith('.deps')) ||
      (isWasm && name == wasmJSRuntimeFileName);

  @override
  Future<void> build(Environment environment) async {
    for (final File outputFile in environment.buildDir.listSync(recursive: true).whereType<File>()) {
      final String basename = environment.fileSystem.path.basename(outputFile.path);
      if (shouldCopy(basename)) {
        outputFile.copySync(
          environment.outputDir.childFile(environment.fileSystem.path.basename(outputFile.path)).path
        );
      }
    }

    if (isWasm) {
      // TODO(jacksongardner): Enable icon tree shaking once dart2wasm can do a two-phase compile.
      // https://github.com/flutter/flutter/issues/117248
      environment.defines[kIconTreeShakerFlag] = 'false';
    }

    createVersionFile(environment, environment.defines);
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    outputDirectory.createSync(recursive: true);
    final Depfile depfile = await copyAssets(
      environment,
      environment.outputDir.childDirectory('assets'),
      targetPlatform: TargetPlatform.web_javascript,
      shaderTarget: ShaderTarget.sksl,
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
        final IndexHtml indexHtml = IndexHtml(inputFile.readAsStringSync());
        indexHtml.applySubstitutions(
          baseHref: environment.defines[kBaseHref] ?? '/',
          serviceWorkerVersion: Random().nextInt(4294967296).toString(),
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
  const WebBuiltInAssets(this.fileSystem, this.webRenderer, {required this.isWasm});

  final FileSystem fileSystem;
  final WebRendererMode webRenderer;
  final bool isWasm;

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
    if (isWasm) const Source.pattern('{BUILD_DIR}/main.dart.js'),
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

    if (isWasm) {
      final File bootstrapFile = environment.outputDir.childFile('main.dart.js');
      bootstrapFile.writeAsStringSync(
        wasm_bootstrap.generateWasmBootstrapFile(webRenderer == WebRendererMode.skwasm)
      );
    }

    // Write the flutter.js file
    final File flutterJsFile = environment.outputDir.childFile('flutter.js');
    final String fileGeneratorsPath =
        environment.artifacts.getArtifactPath(Artifact.flutterToolsFileGenerators);
    flutterJsFile.writeAsStringSync(
        flutter_js.generateFlutterJsFile(fileGeneratorsPath));
  }
}

/// Generate a service worker for a web target.
class WebServiceWorker extends Target {
  const WebServiceWorker(this.fileSystem, this.webRenderer, {required this.isWasm});

  final FileSystem fileSystem;
  final WebRendererMode webRenderer;
  final bool isWasm;

  @override
  String get name => 'web_service_worker';

  @override
  List<Target> get dependencies => <Target>[
    if (isWasm) Dart2WasmTarget(webRenderer) else Dart2JSTarget(webRenderer),
    WebReleaseBundle(webRenderer, isWasm: isWasm),
    WebBuiltInAssets(fileSystem, webRenderer, isWasm: isWasm),
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
      if (environment.fileSystem.path.basename(url) == 'index.html') {
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
        'index.html',
        if (urlToHash.containsKey('assets/AssetManifest.json'))
          'assets/AssetManifest.json',
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
