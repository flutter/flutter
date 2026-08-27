// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:standard_message_codec/standard_message_codec.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/process.dart';
import '../../build_info.dart';
import '../../cache.dart';
import '../../convert.dart';
import '../../dart/language_version.dart';
import '../../dart/package_map.dart';
import '../../features.dart';
import '../../flutter_plugins.dart';
import '../../globals.dart' as globals;
import '../../isolated/native_assets/dart_hook_result.dart';
import '../../project.dart';
import '../../web/bootstrap.dart';
import '../../web/compile.dart';
import '../../web/file_generators/flutter_service_worker_js.dart';
import '../../web/file_generators/main_dart.dart' as main_dart;
import '../../web/web_constants.dart';
import '../../web_template.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'common.dart';
import 'localizations.dart';
import 'native_assets.dart';

const String _kBundledFallbackRobotoFamily = 'Roboto';
const String _kBundledFallbackRobotoAsset = 'fonts/fallback/Roboto-Regular.ttf';
const String _kFontManifestJsonFile = 'FontManifest.json';

const Set<String> _kUnhashedAssetBasenames = <String>{
  'AssetManifest.json',
  'AssetManifest.bin',
  'AssetManifest.bin.json',
  'FontManifest.json',
  'NOTICES',
  'NOTICES.Z',
};

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
    Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.pattern('{PROJECT_DIR}/.flutter-plugins-dependencies', optional: true),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/main.dart'),
    Source.pattern('{BUILD_DIR}/web_plugin_registrant.dart'),
  ];

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
        packageConfig.toPackageUriForWorkspace(importUri)?.toString() ?? importUri.toString();

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

@visibleForTesting
String hashAndRenameWebOutput({required File file, File? sourceMapFile}) =>
    _hashAndRenameWebOutput(file: file, sourceMapFile: sourceMapFile);

const List<String> _kKnownHashedExtensions = <String>[
  '.js.map',
  '.wasm.map',
  '.mjs.map',
  '.js',
  '.wasm',
  '.mjs',
];

String _computeHashedBasename(String oldBasename, String contentHash) {
  for (final String ext in _kKnownHashedExtensions) {
    if (oldBasename.endsWith(ext)) {
      final String stem = oldBasename.substring(0, oldBasename.length - ext.length);
      return '$stem.$contentHash$ext';
    }
  }
  final int extensionIndex = oldBasename.lastIndexOf('.');
  if (extensionIndex != -1) {
    return '${oldBasename.substring(0, extensionIndex)}.$contentHash${oldBasename.substring(extensionIndex)}';
  }
  return '$oldBasename.$contentHash';
}

String _hashAndRenameWebOutput({required File file, File? sourceMapFile}) {
  if (!file.existsSync()) {
    return file.basename;
  }

  // The hash is computed before the sourceMappingURL comment is rewritten
  // below; deriving the map name from the hashed binary name would otherwise
  // be circular. The compiler emits the binary and its map from the same
  // compilation, so identical binaries imply identical maps.
  final String contentHash = crypto.sha256
      .convert(file.readAsBytesSync())
      .toString()
      .substring(0, 8);
  final String newBasename = _computeHashedBasename(file.basename, contentHash);

  // The source map shares the binary's hash so the pair stays discoverable as
  // '<binary>.map'. A `.wasm` binary embeds its map name in a binary custom
  // section that cannot be rewritten here, so its map keeps the unhashed name.
  final bool isWasm = file.path.endsWith('.wasm');
  if (sourceMapFile != null && sourceMapFile.existsSync() && !isWasm) {
    final String oldMapBasename = sourceMapFile.basename;
    final newMapBasename = '$newBasename.map';
    sourceMapFile.renameSync(sourceMapFile.parent.childFile(newMapBasename).path);

    final String content = file.readAsStringSync();
    final mapDirectiveRegex = RegExp(
      r'//[#@]\s*sourceMappingURL=' + RegExp.escape(oldMapBasename) + r'\s*$',
      multiLine: true,
    );
    if (mapDirectiveRegex.hasMatch(content)) {
      file.writeAsStringSync(
        content.replaceFirst(mapDirectiveRegex, '//# sourceMappingURL=$newMapBasename'),
      );
    }
  }

  file.renameSync(file.parent.childFile(newBasename).path);
  return newBasename;
}

abstract class Dart2WebTarget extends Target {
  const Dart2WebTarget();

  WebCompilerConfig get compilerConfig;

  Map<String, Object?> get buildConfig;
  Map<String, Object?> getBuildConfig(Environment environment) => buildConfig;
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

  static final RegExp _mainJsRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.js$');
  static final RegExp _mainJsMapRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.js\.map$');
  static final RegExp _partFileRegex = RegExp(r'main\.dart\.js_[0-9].*\.part\.js');

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

    if (compilerConfig.webContentHash && environment.buildDir.existsSync()) {
      for (final File file in environment.buildDir.listSync().whereType<File>()) {
        if (_mainJsRegex.hasMatch(file.basename) || _mainJsMapRegex.hasMatch(file.basename)) {
          file.deleteSync();
        }
      }
    }
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
      if (featureFlags.isRecordUseEnabled) '--write-resources',
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

    final File resourcesFile = environment.buildDir.childFile('main.dart.js.resources.json');
    final File recordedUsesFile = environment.buildDir.childFile(LinkHooks.recordedUsesJsFileName);
    if (resourcesFile.existsSync()) {
      resourcesFile.renameSync(recordedUsesFile.path);
    } else if (featureFlags.isRecordUseEnabled) {
      recordedUsesFile.writeAsStringSync(KernelSnapshot.recordedUsesEmptyContent);
    }
    final File dart2jsDeps = environment.buildDir.childFile('app.dill.deps');
    if (!dart2jsDeps.existsSync()) {
      environment.logger.printWarning(
        'Warning: dart2js did not produce expected deps list at '
        '${dart2jsDeps.path}',
      );
      return;
    }
    var finalOutputFile = outputJSFile;
    if (compilerConfig.webContentHash) {
      final bool hasDeferredParts = environment.buildDir.listSync().whereType<File>().any(
        (File file) => _partFileRegex.hasMatch(file.basename),
      );
      if (hasDeferredParts) {
        throwToolExit(
          '"--web-content-hash" does not yet support deferred imports: '
          'deferred part files keep unhashed names and can be served stale '
          'from the browser cache alongside a new entrypoint. Remove the '
          'deferred imports or build without "--web-content-hash".',
        );
      }
      final String newBasename = _hashAndRenameWebOutput(
        file: outputJSFile,
        sourceMapFile: compilerConfig.sourceMaps
            ? environment.buildDir.childFile('main.dart.js.map')
            : null,
      );
      finalOutputFile = environment.buildDir.childFile(newBasename);
    }
    final DepfileService depFileService = environment.depFileService;
    final Depfile depFile = depFileService.parseDart2js(
      environment.buildDir.childFile('app.dill.deps'),
      finalOutputFile,
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
  Map<String, Object?> getBuildConfig(Environment environment) {
    var mainJsPath = 'main.dart.js';
    if (compilerConfig.webContentHash) {
      final List<File> candidates = environment.buildDir
          .listSync()
          .whereType<File>()
          .where((File f) => _mainJsRegex.hasMatch(f.basename))
          .toList();
      if (candidates.isNotEmpty) {
        final File match = candidates.firstWhere(
          (File f) => f.basename != 'main.dart.js',
          orElse: () => candidates.first,
        );
        mainJsPath = match.basename;
      }
    }
    return <String, Object?>{
      'compileTarget': 'dart2js',
      'renderer': compilerConfig.renderer.name,
      'mainJsPath': mainJsPath,
    };
  }

  @override
  Iterable<File> buildFiles(Environment environment) {
    final String mainJsName =
        (getBuildConfig(environment)['mainJsPath'] as String?) ?? 'main.dart.js';
    final mainJsMapName = '$mainJsName.map';
    return environment.buildDir.listSync(recursive: true).whereType<File>().where((File file) {
      if (file.basename == mainJsName) {
        return true;
      }
      if (compilerConfig.sourceMaps && file.basename == mainJsMapName) {
        return true;
      }
      if (_partFileRegex.hasMatch(file.basename)) {
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
  }

  @override
  Iterable<String> get buildPatternStems => <String>[
    if (compilerConfig.webContentHash) 'main.dart.*.js' else 'main.dart.js',
    'main.dart.js_*.part.js',
    if (compilerConfig.sourceMaps) ...<String>[
      if (compilerConfig.webContentHash) 'main.dart.*.js.map' else 'main.dart.js.map',
      'main.dart.js_*.part.js.map',
    ],
    if (featureFlags.isRecordUseEnabled) LinkHooks.recordedUsesJsFileName,
  ];
}

/// The classification of a wasm dry-run compile, derived from the compiler's
/// exit code and output in [Dart2WasmTarget._logAndClassifyDryRunResult].
///
/// dart2wasm exits with code 254 when dry-run analysis completes with issues;
/// any other non-zero exit code is unexpected.
enum _DryRunOutcome {
  /// The compiler exited with an unexpected exit code (anything other than 0
  /// or 254), e.g. an internal compiler error.
  crash,

  /// The compiler exited with code 0: the app is wasm-compatible.
  success,

  /// The compiler exited with code 254 and wrote to stderr: compilation
  /// failed for reasons other than dry-run findings (e.g. invalid Dart code
  /// that does not compile for any web target).
  failure,

  /// The compiler exited with code 254 and wrote only to stdout: the
  /// expected dry-run report of wasm-incompatible API usages, one finding
  /// per line, e.g.:
  ///
  ///     package:bar/some/path.dart 120:5 - dart:js unsupported (1)
  findings,

  /// The compiler exited with code 254 but produced no output at all.
  unknown,
}

/// Compiles a web entry point with dart2wasm.
class Dart2WasmTarget extends Dart2WebTarget {
  Dart2WasmTarget(this.compilerConfig, this._analytics);

  static final RegExp _mainWasmRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.wasm$');
  static final RegExp _mainWasmMapRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.wasm\.map$');
  static final RegExp _mainMjsRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.mjs$');
  static final RegExp _mainMjsMapRegex = RegExp(r'^main\.dart(\.[a-f0-9]+)?\.mjs\.map$');

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

    if (compilerConfig.webContentHash && environment.buildDir.existsSync()) {
      for (final File file in environment.buildDir.listSync().whereType<File>()) {
        if (_mainWasmRegex.hasMatch(file.basename) ||
            _mainWasmMapRegex.hasMatch(file.basename) ||
            _mainMjsRegex.hasMatch(file.basename) ||
            _mainMjsMapRegex.hasMatch(file.basename)) {
          file.deleteSync();
        }
      }
    }
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
      if (featureFlags.isRecordUseEnabled)
        '--recorded-uses=${environment.buildDir.childFile(LinkHooks.recordedUsesWasmFileName).path}',
      ...compilerConfig.toCommandOptions(buildMode),
      '-o',
      outputWasmFile.path,
      environment.buildDir.childFile('main.dart').path, // dartfile
    ];

    final processUtils = ProcessUtils(
      logger: environment.logger,
      processManager: environment.processManager,
    );

    final RunResult runResult = await processUtils.run(compilationArgs);
    if (compilerConfig.dryRun) {
      await _handleDryRunResult(environment, runResult);
    } else if (runResult.exitCode != 0) {
      environment.logger.printStatus(runResult.stdout);
      environment.logger.printError(runResult.stderr);
      _checkForLegacyWebImports(environment, runResult.stdout, runResult.stderr);
      throwToolExit('Failed to compile application for the Web.');
    } else if (compilerConfig.webContentHash) {
      final String newWasmBasename = _hashAndRenameWebOutput(
        file: outputWasmFile,
        sourceMapFile: compilerConfig.sourceMaps
            ? environment.buildDir.childFile('main.dart.wasm.map')
            : null,
      );
      final String newMjsBasename = _hashAndRenameWebOutput(
        file: environment.buildDir.childFile('main.dart.mjs'),
        sourceMapFile: compilerConfig.sourceMaps
            ? environment.buildDir.childFile('main.dart.mjs.map')
            : null,
      );
      final File depFile = environment.buildDir.childFile('dart2wasm.d');
      if (depFile.existsSync()) {
        final Depfile parsed = environment.depFileService.parse(depFile);
        final List<File> newOutputs = parsed.outputs.map((File f) {
          if (f.basename == 'main.dart.wasm') {
            return f.parent.childFile(newWasmBasename);
          }
          if (f.basename == 'main.dart.mjs') {
            return f.parent.childFile(newMjsBasename);
          }
          return f;
        }).toList();
        final updatedDepfile = Depfile(parsed.inputs, newOutputs);
        environment.depFileService.writeToFile(updatedDepfile, depFile);
      }
    }
    final File recordedUsesFile = environment.buildDir.childFile(
      LinkHooks.recordedUsesWasmFileName,
    );
    if (!recordedUsesFile.existsSync() && featureFlags.isRecordUseEnabled) {
      recordedUsesFile.writeAsStringSync(KernelSnapshot.recordedUsesEmptyContent);
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
  Map<String, Object?> getBuildConfig(Environment environment) {
    if (compilerConfig.dryRun) {
      return const <String, Object?>{};
    }
    var mainWasmPath = 'main.dart.wasm';
    var jsSupportRuntimePath = 'main.dart.mjs';
    if (compilerConfig.webContentHash) {
      final List<File> files = environment.buildDir.listSync().whereType<File>().toList();
      final List<File> wasmCandidates = files
          .where((File f) => _mainWasmRegex.hasMatch(f.basename))
          .toList();
      if (wasmCandidates.isNotEmpty) {
        final File match = wasmCandidates.firstWhere(
          (File f) => f.basename != 'main.dart.wasm',
          orElse: () => wasmCandidates.first,
        );
        mainWasmPath = match.basename;
      }
      final List<File> mjsCandidates = files
          .where((File f) => _mainMjsRegex.hasMatch(f.basename))
          .toList();
      if (mjsCandidates.isNotEmpty) {
        final File match = mjsCandidates.firstWhere(
          (File f) => f.basename != 'main.dart.mjs',
          orElse: () => mjsCandidates.first,
        );
        jsSupportRuntimePath = match.basename;
      }
    }
    return <String, Object?>{
      'compileTarget': 'dart2wasm',
      'renderer': compilerConfig.renderer.name,
      'mainWasmPath': mainWasmPath,
      'jsSupportRuntimePath': jsSupportRuntimePath,
    };
  }

  static final RegExp _partWasmRegex = RegExp(r'^main\.dart_module[0-9].*\.wasm$');
  static final RegExp _partWasmMapRegex = RegExp(r'^main\.dart_module[0-9].*\.wasm\.map$');

  @override
  Iterable<File> buildFiles(Environment environment) {
    if (compilerConfig.dryRun) {
      return const <File>[];
    }
    final Map<String, Object?> config = getBuildConfig(environment);
    final String mainWasmName = (config['mainWasmPath'] as String?) ?? 'main.dart.wasm';
    final String jsSupportName = (config['jsSupportRuntimePath'] as String?) ?? 'main.dart.mjs';
    const mainWasmMapName = 'main.dart.wasm.map';
    final jsSupportMapName = '$jsSupportName.map';

    return environment.buildDir.listSync(recursive: true).whereType<File>().where((File file) {
      if (file.basename == mainWasmName || file.basename == jsSupportName) {
        return true;
      }
      if (compilerConfig.sourceMaps &&
          (file.basename == mainWasmMapName || file.basename == jsSupportMapName)) {
        return true;
      }
      if (_partWasmRegex.hasMatch(file.basename)) {
        return true;
      }
      if (compilerConfig.sourceMaps && _partWasmMapRegex.hasMatch(file.basename)) {
        return true;
      }
      return false;
    });
  }

  @override
  Iterable<String> get buildPatternStems => compilerConfig.dryRun
      ? const <String>[]
      : <String>[
          if (compilerConfig.webContentHash) 'main.dart.*.wasm' else 'main.dart.wasm',
          'main.dart_module*.wasm',
          if (compilerConfig.webContentHash) 'main.dart.*.mjs' else 'main.dart.mjs',
          if (compilerConfig.sourceMaps) ...<String>[
            'main.dart.wasm.map',
            if (compilerConfig.webContentHash) 'main.dart.*.mjs.map' else 'main.dart.mjs.map',
            'main.dart_module*.wasm.map',
          ],
          if (featureFlags.isRecordUseEnabled) LinkHooks.recordedUsesWasmFileName,
        ];

  @visibleForTesting
  Random? dryRunRandom;

  /// Logs the outcome of a dry-run compile to the user and reports it to
  /// analytics, including per-error-code package findings when the dry run
  /// produced them.
  Future<void> _handleDryRunResult(Environment environment, RunResult runResult) async {
    final int exitCode = runResult.exitCode;
    final String stdout = runResult.stdout;
    final String stderr = runResult.stderr;

    final _DryRunOutcome outcome = _logAndClassifyDryRunResult(
      logger: environment.logger,
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
    );

    final Map<String, String> findingsInfo;
    if (outcome == _DryRunOutcome.findings) {
      final Map<String, String>? findings = await _collectFindingsInfo(
        environment: environment,
        stdout: stdout,
        exitCode: exitCode,
        result: outcome.name,
      );
      if (findings == null) {
        return;
      }
      findingsInfo = findings;
    } else {
      findingsInfo = const <String, String>{};
    }

    _checkForLegacyWebImports(environment, stdout, stderr);

    environment.logger.printWarning('Use --no-wasm-dry-run to disable these warnings.');

    _analytics.send(
      Event.flutterWasmDryRunPackage(
        result: outcome.name,
        exitCode: exitCode,
        findingsInfo: findingsInfo,
      ),
    );
  }

  /// Classifies the dry-run compile result into a [_DryRunOutcome] (see the
  /// enum values for the classification rules) and logs the corresponding
  /// warning output to [logger].
  static _DryRunOutcome _logAndClassifyDryRunResult({
    required Logger logger,
    required int exitCode,
    required String stdout,
    required String stderr,
  }) {
    if (exitCode != 0 && exitCode != 254) {
      logger.printWarning('Unexpected wasm dry run failure ($exitCode):');
      if (stdout.isNotEmpty) {
        logger.printWarning('stdout:');
        logger.printWarning(stdout);
      }
      if (stderr.isNotEmpty) {
        logger.printWarning('stderr:');
        logger.printWarning(stderr);
      }
      return _DryRunOutcome.crash;
    }
    if (exitCode == 0) {
      logger.printWarning(
        'Wasm dry run succeeded. Consider building and testing your application with the '
        '`--wasm` flag. See docs for more info: '
        'https://docs.flutter.dev/platform-integration/web/wasm',
      );
      return _DryRunOutcome.success;
    }
    if (stderr.isNotEmpty) {
      logger.printWarning('Wasm dry run failed:');
      if (stdout.isNotEmpty) {
        logger.printWarning('stdout:');
        logger.printWarning(stdout);
      }
      logger.printWarning('stderr:');
      logger.printWarning(stderr);
      return _DryRunOutcome.failure;
    }
    if (stdout.isNotEmpty) {
      logger.printWarning('Wasm dry run findings:');
      logger.printWarning(stdout);
      logger.printWarning(
        'Consider addressing these issues to enable wasm builds. See docs for more info: '
        'https://docs.flutter.dev/platform-integration/web/wasm\n',
      );
      return _DryRunOutcome.findings;
    }
    return _DryRunOutcome.unknown;
  }

  /// Builds the per-error-code analytics payload for a dry run that produced
  /// findings, mapping each error code (keyed as `E<code>`) to a formatted,
  /// truncated summary of the pub-hosted packages it was found in.
  ///
  /// Returns null if the project's package config could not be loaded; in
  /// that case an error event is sent to analytics instead.
  Future<Map<String, String>?> _collectFindingsInfo({
    required Environment environment,
    required String stdout,
    required int exitCode,
    required String result,
  }) async {
    final Map<String, Set<Uri>> errorCodeToImportUris = _parseWasmFindings(stdout);

    final PackageConfig packageConfigPackages;
    try {
      packageConfigPackages = await loadPackageConfigWithLogging(
        findPackageConfigFileOrDefault(environment.projectDir),
        logger: environment.logger,
      );
    } on ToolExit {
      _analytics.send(
        Event.flutterWasmDryRunPackage(
          result: result,
          exitCode: exitCode,
          findingsInfo: {
            'error': 'packageConfigNotLoaded',
            'findings': errorCodeToImportUris.keys.join(','),
          },
        ),
      );
      return null;
    }

    final (:Map<String, String> hosted, :Set<String> private) = _categorizePackages(
      packageConfigPackages,
    );
    final findingsInfo = <String, String>{};
    for (final MapEntry(key: errorCode, value: uris) in errorCodeToImportUris.entries) {
      findingsInfo['E$errorCode'] = _formatFindingsBuffer(
        uris: uris,
        hostedPackages: hosted,
        privatePackages: private,
        random: dryRunRandom,
      );
    }
    return findingsInfo;
  }

  /// Matches the trailing error code of a dry-run finding line, e.g. the
  /// `(1)` in:
  ///
  ///     package:bar/some/path.dart 120:5 - dart:js unsupported (1)
  static final RegExp _wasmErrorCodePattern = RegExp(r'\(([0-9]+)\)\s*$');

  /// Parses the dry-run findings printed to [stdout], one finding per line
  /// in the form `<uri> <location> - <message> (<errorCode>)`, e.g.:
  ///
  ///     package:bar/some/path.dart 120:5 - dart:js unsupported (1)
  ///
  /// Returns a map from error code (`'1'` above) to the set of URIs that
  /// triggered it (`package:bar/some/path.dart` above). Lines without a
  /// trailing error code are ignored.
  static Map<String, Set<Uri>> _parseWasmFindings(String stdout) {
    final errorCodeToImportUris = <String, Set<Uri>>{};
    for (final String line in stdout.split('\n')) {
      final String? errorCode = _wasmErrorCodePattern.firstMatch(line)?.group(1);
      if (errorCode != null) {
        final Uri uri = Uri.parse(line.split(' ')[0]);
        (errorCodeToImportUris[errorCode] ??= {}).add(uri);
      }
    }
    return errorCodeToImportUris;
  }

  /// Splits the packages in the project's package config into pub-hosted
  /// packages (mapped to their resolved version, which is safe to report to
  /// analytics) and private packages (path/git dependencies and the like,
  /// whose names must not be reported).
  static ({Map<String, String> hosted, Set<String> private}) _categorizePackages(
    PackageConfig packageConfigPackages,
  ) {
    final hostedPackages = <String, String>{};
    final privatePackages = <String>{};
    for (final Package package in packageConfigPackages.packages) {
      final String packageName = package.name;
      if (package.root.pathSegments.where((String s) => s.isNotEmpty).toList() case [
        ...,
        'hosted',
        _,
        final packageFolder,
      ] when packageFolder.startsWith('$packageName-')) {
        // Hosted package directories in .pub-cache follow '<packageName>-<version>'.
        // Substring past the package name and hyphen to extract the version.
        hostedPackages[packageName] = packageFolder.substring(packageName.length + 1);
      } else {
        privatePackages.add(packageName);
      }
    }
    return (hosted: hostedPackages, private: privatePackages);
  }

  /// Formats the [uris] associated with a single error code into the
  /// analytics value string: an optional leading hint (`-h` if the host app
  /// itself had findings, `-p` if a private package did, `-hp` for both)
  /// followed by a truncated, comma-separated list of `name:version` entries
  /// for the affected pub-hosted packages.
  static String _formatFindingsBuffer({
    required Set<Uri> uris,
    required Map<String, String> hostedPackages,
    required Set<String> privatePackages,
    Random? random,
  }) {
    // Shuffle the URIs so that, when the analytics buffer is truncated to
    // [_truncateAnalyticsBuffer]'s character limit below, the reported
    // packages are a random sample rather than always the first few in
    // iteration order.
    final urisList = <Uri>[...uris]..shuffle(random);
    final (:Set<String> hostedFindings, :bool hostApp, :bool privatePackage) = _classifyUris(
      urisList,
      hostedPackages,
      privatePackages,
    );
    final String hpHint = switch ((hostApp, privatePackage)) {
      (true, true) => '-hp',
      (true, false) => '-h',
      (false, true) => '-p',
      (false, false) => '',
    };
    return _truncateAnalyticsBuffer(hpHint, hostedFindings);
  }

  /// Buckets the [uris] from a set of findings by where they came from:
  /// `name:version` strings for each affected pub-hosted package
  /// (`hostedFindings`), whether any URI belonged to a private package
  /// (`privatePackage`), and whether any URI came from outside a package
  /// entirely, i.e. from the host app itself (`hostApp`).
  ///
  /// Only pub-hosted package names are collected; private package names and
  /// host app paths are reduced to booleans so nothing identifying is
  /// reported to analytics.
  static ({Set<String> hostedFindings, bool hostApp, bool privatePackage}) _classifyUris(
    Iterable<Uri> uris,
    Map<String, String> hostedPackages,
    Set<String> privatePackages,
  ) {
    final hostedFindings = <String>{};
    var hostApp = false;
    var privatePackage = false;
    for (final uri in uris) {
      if (uri.scheme == 'package' && uri.pathSegments.isNotEmpty) {
        final String packageName = uri.pathSegments.first;
        if (hostedPackages.containsKey(packageName)) {
          hostedFindings.add('$packageName:${hostedPackages[packageName]}');
          continue;
        }
        if (privatePackages.contains(packageName)) {
          privatePackage = true;
          continue;
        }
      }
      hostApp = true;
    }
    return (hostedFindings: hostedFindings, hostApp: hostApp, privatePackage: privatePackage);
  }

  /// Joins [prefix] and as many comma-separated [findings] as fit within
  /// [maxLength] characters, silently dropping the rest.
  static String _truncateAnalyticsBuffer(
    String prefix,
    Iterable<String> findings, {
    int maxLength = 100,
  }) {
    final findingsBuffer = StringBuffer(prefix);
    for (final finding in findings) {
      // Try to fit as many findings as we can into the character limit imposed
      // by google analytics.
      final pendingString = '${findingsBuffer.isNotEmpty ? ',' : ''}$finding';
      if (findingsBuffer.length + pendingString.length <= maxLength) {
        findingsBuffer.write(pendingString);
      }
    }
    return findingsBuffer.toString();
  }

  static final RegExp _kLegacyImportErrorPattern = RegExp(
    "(?:Dart library|The unavailable library) '(${kLegacyWebLibraries.join('|')})'|"
    '(${kLegacyWebLibraries.join('|')}) unsupported',
  );

  void _checkForLegacyWebImports(Environment environment, String stdout, String stderr) {
    if (_kLegacyImportErrorPattern.hasMatch(stdout) ||
        _kLegacyImportErrorPattern.hasMatch(stderr)) {
      environment.logger.printStatus(
        'Note: WebAssembly compilation failed due to legacy web imports.\n'
        'Migrate your project from dart:html and package:js to package:web and dart:js_interop.\n'
        '$kWasmErrorsMoreInfo',
      );
    }
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
        compileTargets: compileTargets,
      );

  final List<Dart2WebTarget> compileTargets;
  final WebTemplatedFiles templatedFilesTarget;

  @override
  String get name => 'web_release_bundle';

  @override
  List<Target> get dependencies => <Target>[
    ...compileTargets,
    templatedFilesTarget,
    LinkHooks(platform: HookPlatform.web, extraDependencies: compileTargets),
  ];

  Iterable<String> get buildPatternStems =>
      compileTargets.expand((Dart2WebTarget target) => target.buildPatternStems);

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    const Source.pattern('{BUILD_DIR}/${LinkHooks.resultFilename}'),
    ...buildPatternStems.map((String file) => Source.pattern('{BUILD_DIR}/$file')),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...buildPatternStems.map((String file) => Source.pattern('{OUTPUT_DIR}/$file')),
  ];

  @override
  List<String> get depfiles => const <String>['flutter_assets.d', 'web_resources.d'];

  /// Matches the compiled entrypoint files (hashed or not) that this bundle
  /// copies into the output directory.
  static final RegExp _entrypointFileRegex = RegExp(
    r'^main\.dart(\.[a-f0-9]+)?\.(js|wasm|mjs)(\.map)?$',
  );

  @override
  Future<void> build(Environment environment) async {
    final FileSystem fileSystem = environment.fileSystem;
    final compiledFiles = <File>[
      for (final Dart2WebTarget target in compileTargets) ...target.buildFiles(environment),
    ];

    // Entrypoint filenames change when compiling with content hashes or when
    // toggling between build modes, and glob-based [outputs] patterns match
    // previous builds' files too. Delete outdated entrypoints before copying
    // the current ones so that build/web does not accumulate dead files or
    // pollute the service worker cache.
    final currentBasenames = <String>{for (final File file in compiledFiles) file.basename};
    if (environment.outputDir.existsSync()) {
      for (final File file in environment.outputDir.listSync().whereType<File>()) {
        if (_entrypointFileRegex.hasMatch(file.basename) &&
            !currentBasenames.contains(file.basename)) {
          file.deleteSync();
        }
      }
    }

    for (final outputFile in compiledFiles) {
      outputFile.copySync(
        environment.outputDir.childFile(fileSystem.path.basename(outputFile.path)).path,
      );
    }

    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final buildMode = BuildMode.fromCliName(buildModeEnvironment);

    createVersionFile(environment, environment.defines);
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }
    outputDirectory.createSync(recursive: true);

    final DartHooksResult dartHookResult = await LinkHooks.loadHookResult(environment);
    final Depfile depfile = await copyAssets(
      environment,
      environment.outputDir.childDirectory('assets'),
      dartHookResult: dartHookResult,
      targetPlatform: TargetPlatform.web_javascript,
      buildMode: buildMode,
    );
    final Depfile bundledDepfile = _bundleLocalRobotoFallback(environment, depfile);
    final DepfileService depfileService = environment.depFileService;

    final bool webContentHash = compileTargets.any(
      (Dart2WebTarget t) => t.compilerConfig.webContentHash,
    );
    if (webContentHash) {
      final Map<String, File> renamedOutputs = _hashWebAssets(outputDirectory);
      final List<File> updatedOutputs = bundledDepfile.outputs.map((File f) {
        return renamedOutputs[f.path] ?? f;
      }).toList();
      depfileService.writeToFile(
        Depfile(bundledDepfile.inputs, updatedOutputs),
        environment.buildDir.childFile('flutter_assets.d'),
      );
    } else {
      depfileService.writeToFile(
        bundledDepfile,
        environment.buildDir.childFile('flutter_assets.d'),
      );
    }

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

  Depfile _bundleLocalRobotoFallback(Environment environment, Depfile depfile) {
    if (environment.defines[kUseLocalCanvasKitFlag] != 'true') {
      return depfile;
    }

    final File fontManifestFile = environment.outputDir
        .childDirectory('assets')
        .childFile(_kFontManifestJsonFile);
    final manifestJson = fontManifestFile.existsSync()
        ? (jsonDecode(fontManifestFile.readAsStringSync()) as List<Object?>)
        : <Object?>[];

    final bool hasRobotoFamily = manifestJson.any((Object? entry) {
      return entry is Map<String, dynamic> && entry['family'] == _kBundledFallbackRobotoFamily;
    });
    if (hasRobotoFamily) {
      return depfile;
    }

    final File sourceRobotoFont = environment.fileSystem.file(
      environment.fileSystem.path.join(
        Cache.flutterRoot!,
        'engine',
        'src',
        'flutter',
        'txt',
        'third_party',
        'fonts',
        'Roboto-Regular.ttf',
      ),
    );
    if (!sourceRobotoFont.existsSync()) {
      throwToolExit('Failed to find the bundled Roboto font at ${sourceRobotoFont.path}.');
    }

    manifestJson.add(<String, Object>{
      'family': _kBundledFallbackRobotoFamily,
      'fonts': <Map<String, String>>[
        <String, String>{'asset': _kBundledFallbackRobotoAsset},
      ],
    });
    fontManifestFile.parent.createSync(recursive: true);
    fontManifestFile.writeAsStringSync(jsonEncode(manifestJson));

    final File bundledRobotoFont = environment.outputDir
        .childDirectory('assets')
        .childFile(_kBundledFallbackRobotoAsset);
    bundledRobotoFont.parent.createSync(recursive: true);
    sourceRobotoFont.copySync(bundledRobotoFont.path);

    return Depfile(
      <File>[...depfile.inputs, sourceRobotoFont],
      <File>[...depfile.outputs, fontManifestFile, bundledRobotoFont],
    );
  }
}

class WebTemplatedFiles extends Target {
  WebTemplatedFiles(this.buildDescriptions, {this.compileTargets});

  final List<Map<String, Object?>> buildDescriptions;
  final List<Dart2WebTarget>? compileTargets;

  @override
  String get buildKey => compileTargets != null
      ? jsonEncode(compileTargets!.map((Dart2WebTarget target) => target.buildKey).toList())
      : jsonEncode(buildDescriptions);

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
    // Calculate SHA-256 hashes for WASM assets to support Cross-Origin Storage
    // (https://wicg.github.io/cross-origin-storage/). This assumes that the files will exist in
    // the output directory at this point.
    final wasmHashes = <String, String>{};
    final String canvasKitPath = globals.artifacts!
        .getHostArtifact(HostArtifact.flutterWebSdk)
        .path;
    final Directory canvasKitDirectory = globals.fs.directory(
      globals.fs.path.join(canvasKitPath, 'canvaskit'),
    );
    if (canvasKitDirectory.existsSync()) {
      for (final File file in canvasKitDirectory.listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.wasm')) {
          final String relativePath = globals.fs.path
              .relative(file.path, from: canvasKitDirectory.path)
              .replaceAll(r'\', '/');
          wasmHashes[relativePath] = crypto.sha256.convert(file.readAsBytesSync()).toString();
        }
      }
    }

    if (compileTargets != null) {
      for (final Dart2WebTarget target in compileTargets!) {
        for (final File file in target.buildFiles(environment)) {
          if (file.path.endsWith('.wasm') && !file.path.contains('canvaskit/')) {
            if (file.existsSync()) {
              wasmHashes[file.basename] = crypto.sha256.convert(file.readAsBytesSync()).toString();
            }
          }
        }
      }
    } else {
      final Directory outputDirectory = environment.outputDir;
      if (outputDirectory.existsSync()) {
        for (final File file in outputDirectory.listSync(recursive: true).whereType<File>()) {
          if (file.path.endsWith('.wasm')) {
            final String relativePath = globals.fs.path
                .relative(file.path, from: outputDirectory.path)
                .replaceAll(r'\', '/');
            // Skip files under the canvaskit/ subdirectory — they are already
            // covered by the canvasKit SDK directory scan above with keys that
            // match what the JS lookup code actually uses.
            if (relativePath.startsWith('canvaskit/')) {
              continue;
            }
            wasmHashes[relativePath] = crypto.sha256.convert(file.readAsBytesSync()).toString();
          }
        }
      }
    }

    final List<Map<String, Object?>> descriptions = compileTargets != null
        ? compileTargets!
              .map((Dart2WebTarget target) => target.getBuildConfig(environment))
              .toList()
        : buildDescriptions;
    final buildConfig = <String, Object>{
      'engineRevision': globals.flutterVersion.engineRevision,
      'wasmHashes': wasmHashes,
      'builds': descriptions,
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
    if (inputFlutterBootstrapJs.existsSync()) {
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

    // Extract web-define variables from the environment. These are stored with
    // the [kWebDefinePrefix] prefix by [WebBuilder.buildWeb].
    final webDefines = <String, String>{
      for (final MapEntry(:key, :value) in environment.defines.entries)
        if (key.startsWith(kWebDefinePrefix)) key.substring(kWebDefinePrefix.length): value,
    };

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
      logger: environment.logger,
      webDefines: webDefines,
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
          logger: environment.logger,
          webDefines: webDefines,
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
  List<Target> get dependencies =>
      compileTargets != null ? <Target>[...compileTargets!] : <Target>[];

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/web/*/index.html'),
    const Source.pattern('{PROJECT_DIR}/web/flutter_bootstrap.js'),
    const Source.hostArtifact(HostArtifact.flutterWebSdk),
    if (compileTargets != null)
      for (final Dart2WebTarget target in compileTargets!)
        for (final String stem in target.buildPatternStems) Source.pattern('{BUILD_DIR}/$stem'),
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

Map<String, File> _hashWebAssets(Directory assetsDir) {
  final Map<String, File> renamedFileMap = <String, File>{};
  if (!assetsDir.existsSync()) {
    return renamedFileMap;
  }

  final FileSystem fileSystem = assetsDir.fileSystem;
  final List<File> files = assetsDir.listSync(recursive: true).whereType<File>().toList();
  final Map<String, String> renamedAssets = <String, String>{};

  for (final File file in files) {
    final String basename = file.basename;
    if (_kUnhashedAssetBasenames.contains(basename)) {
      continue;
    }

    final String contentHash = crypto.sha256
        .convert(file.readAsBytesSync())
        .toString()
        .substring(0, 8);
    final String newBasename = _computeHashedBasename(basename, contentHash);

    final String relativePath = fileSystem.path.relative(file.path, from: assetsDir.path);
    final String newRelativePath = fileSystem.path.join(
      fileSystem.path.dirname(relativePath),
      newBasename,
    );

    // Rename the file
    final String newPath = fileSystem.path.join(assetsDir.path, newRelativePath);
    final String oldPath = file.path;
    file.renameSync(newPath);
    renamedFileMap[oldPath] = fileSystem.file(newPath);

    // Note: use forward slashes for mapping since the manifest uses them.
    final String posixOldPath = relativePath.replaceAll(fileSystem.path.separator, '/');
    final String posixNewPath = newRelativePath.replaceAll(fileSystem.path.separator, '/');
    renamedAssets[posixOldPath] = posixNewPath;
    renamedAssets[Uri.decodeFull(posixOldPath)] = posixNewPath;
  }

  // Now update the manifests if they exist
  final File assetManifestBin = assetsDir.childFile('AssetManifest.bin');
  if (assetManifestBin.existsSync()) {
    final Uint8List rawBytes = assetManifestBin.readAsBytesSync();
    final ByteData message = ByteData.sublistView(rawBytes);
    final Object? decoded = const StandardMessageCodec().decodeMessage(message);
    if (decoded is Map<Object?, Object?>) {
      final Map<String, dynamic> newManifest = <String, dynamic>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final String key = entry.key.toString();
        final Object? variantsVal = entry.value;
        if (variantsVal is! List<Object?>) {
          continue;
        }
        final List<dynamic> newVariants = <dynamic>[];
        for (final Object? variantObj in variantsVal) {
          if (variantObj is! Map<Object?, Object?>) {
            continue;
          }
          final Map<String, dynamic> newVariantMap = <String, dynamic>{};
          for (final MapEntry<Object?, Object?> vEntry in variantObj.entries) {
            final String vKey = vEntry.key.toString();
            if (vKey == 'asset') {
              final String vValue = vEntry.value.toString();
              newVariantMap[vKey] = renamedAssets[vValue] ?? vValue;
            } else {
              newVariantMap[vKey] = vEntry.value;
            }
          }
          newVariants.add(newVariantMap);
        }
        newManifest[key] = newVariants;
      }
      final ByteData encoded = const StandardMessageCodec().encodeMessage(newManifest)!;
      final Uint8List encodedBytes = Uint8List.sublistView(encoded);
      assetManifestBin.writeAsBytesSync(encodedBytes);

      // Update AssetManifest.bin.json
      final File assetManifestBinJson = assetsDir.childFile('AssetManifest.bin.json');
      if (assetManifestBinJson.existsSync()) {
        assetManifestBinJson.writeAsStringSync(json.encode(base64.encode(encodedBytes)));
      }
    }
  }

  final File fontManifest = assetsDir.childFile('FontManifest.json');
  if (fontManifest.existsSync()) {
    final Object? decodedJson = json.decode(fontManifest.readAsStringSync());
    if (decodedJson is List<dynamic>) {
      for (final Object? font in decodedJson) {
        if (font is Map<String, dynamic>) {
          final Object? fonts = font['fonts'];
          if (fonts is List<dynamic>) {
            for (final Object? fontAsset in fonts) {
              if (fontAsset is Map<String, dynamic>) {
                final Object? asset = fontAsset['asset'];
                if (asset is String && renamedAssets.containsKey(asset)) {
                  fontAsset['asset'] = renamedAssets[asset];
                }
              }
            }
          }
        }
      }
      fontManifest.writeAsStringSync(json.encode(decodedJson));
    }
  }

  return renamedFileMap;
}
