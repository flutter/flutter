// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The build mode and target architecture can be changed from the
/// native build project (Xcode etc.), so only `flutter assemble` has the
/// information about build-mode and target architecture.
///
/// Also, only `flutter assemble` has access to the code sign identity.
///
/// Hence running the build hooks for code assets and the installation steps
/// need to be run in the `Target`s in `flutter assemble`.
library;

import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../convert.dart';
import '../../dart/package_map.dart';
import '../../isolated/native_assets/dart_hook_result.dart';
import '../../isolated/native_assets/native_assets.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart' show MissingDefineException;

/// Runs the dart build of the app.
class DartBuild extends Target {
  const DartBuild({
    @visibleForTesting FlutterNativeAssetsBuildRunner? buildRunner,
    this.specifiedTargetPlatform,
  }) : _buildRunner = buildRunner;

  final FlutterNativeAssetsBuildRunner? _buildRunner;

  /// The target OS and architecture that we are building for.
  final TargetPlatform? specifiedTargetPlatform;

  @override
  Future<void> build(Environment environment) async {
    final FileSystem fileSystem = environment.fileSystem;
    final DartHooksResult result;

    final TargetPlatform targetPlatform =
        specifiedTargetPlatform ?? _getTargetPlatformFromEnvironment(environment, name);
    final Uri projectUri = environment.projectDir.uri;

    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final FlutterNativeAssetsBuildRunner buildRunner =
        _buildRunner ?? await createFlutterNativeAssetsBuildRunner(environment);
    result = await runFlutterSpecificHooks(
      environmentDefines: environment.defines,
      buildRunner: buildRunner,
      targetPlatform: targetPlatform,
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildCodeAssets: true,
      buildDataAssets: true,
    );
    final File dartHookResultJsonFile = environment.buildDir.childFile(dartHookResultFilename);
    if (!dartHookResultJsonFile.parent.existsSync()) {
      dartHookResultJsonFile.parent.createSync(recursive: true);
    }
    dartHookResultJsonFile.writeAsStringSync(json.encode(result.toJson()));

    final depfile = Depfile(
      <File>[for (final Uri dependency in result.dependencies) fileSystem.file(dependency)],
      <File>[
        fileSystem.file(dartHookResultJsonFile),
        for (final Uri uri in result.filesToBeBundled) fileSystem.file(uri),
      ],
    );
    final File outputDepfile = environment.buildDir.childFile(depFilename);
    if (!outputDepfile.parent.existsSync()) {
      outputDepfile.parent.createSync(recursive: true);
    }
    environment.depFileService.writeToFile(depfile, outputDepfile);
    if (!await outputDepfile.exists()) {
      throw StateError("${outputDepfile.path} doesn't exist.");
    }
  }

  @override
  List<String> get depfiles => const <String>[depFilename];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/native_assets.dart',
    ),
    // If different packages are resolved, different native assets might need to
    // be built.
    Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
    // TODO(mosuem): Should consume resources.json. https://github.com/flutter/flutter/issues/146263
  ];

  @override
  String get name => 'dart_build';

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{BUILD_DIR}/$dartHookResultFilename')];

  /// Dependent build [Target]s can use this to consume the result of the
  /// [DartBuild] target.
  static Future<DartHooksResult> loadHookResult(Environment environment) async {
    final File dartHookResultJsonFile = environment.buildDir.childFile(
      DartBuild.dartHookResultFilename,
    );
    if (!dartHookResultJsonFile.existsSync()) {
      return DartHooksResult.empty();
    }
    return DartHooksResult.fromJson(
      json.decode(dartHookResultJsonFile.readAsStringSync()) as Map<String, Object?>,
    );
  }

  @override
  List<Target> get dependencies => <Target>[];

  static const dartHookResultFilename = 'dart_build_result.json';
  static const depFilename = 'dart_build.d';
}

class DartBuildForNative extends DartBuild {
  const DartBuildForNative({@visibleForTesting super.buildRunner});

  // TODO(dcharkes): Add `KernelSnapshot()` for AOT builds only when adding tree-shaking information. https://github.com/dart-lang/native/issues/153
  @override
  List<Target> get dependencies => const <Target>[];
}

/// Installs the code assets from a [DartBuild] Flutter app.
class InstallCodeAssets extends Target {
  const InstallCodeAssets();

  @override
  Future<void> build(Environment environment) async {
    final Uri projectUri = environment.projectDir.uri;
    final FileSystem fileSystem = environment.fileSystem;
    final TargetPlatform targetPlatform = _getTargetPlatformFromEnvironment(environment, name);

    // We fetch the result from the [DartBuild].
    final DartHooksResult dartHookResult = await DartBuild.loadHookResult(environment);

    // And install/copy the code assets to the right place and create a
    // native_asset.yaml that can be used by the final AOT compilation.
    final Uri nativeAssetsFileUri = environment.buildDir.childFile(nativeAssetsFilename).uri;

    Uri targetUri = environment.outputDir.childDirectory('native_assets').uri;
    final String osName = targetPlatform.osName;
    if (osName == 'linux' || osName == 'windows') {
      // Avoid needing migration for CMake files, keep old directory structure.
      targetUri = targetUri.resolve('$osName/');
    }

    final List<File> installedFiles = await installCodeAssets(
      dartHookResult: dartHookResult,
      environmentDefines: environment.defines,
      targetPlatform: targetPlatform,
      projectUri: projectUri,
      fileSystem: fileSystem,
      nativeAssetsFileUri: nativeAssetsFileUri,
      targetUri: targetUri,
    );
    assert(await fileSystem.file(nativeAssetsFileUri).exists());

    final depfile = Depfile(<File>[
      for (final Uri file in dartHookResult.filesToBeBundled) fileSystem.file(file),
    ], installedFiles);
    final File outputDepfile = environment.buildDir.childFile(depFilename);
    environment.depFileService.writeToFile(depfile, outputDepfile);
    if (!await outputDepfile.exists()) {
      throwToolExit("${outputDepfile.path} doesn't exist.");
    }
  }

  @override
  List<String> get depfiles => <String>[depFilename];

  @override
  List<Target> get dependencies => const <Target>[DartBuildForNative()];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/native_assets.dart',
    ),
    Source.pattern('{BUILD_DIR}/${DartBuild.dartHookResultFilename}'),
    // If different packages are resolved, different native assets might need to
    // be built. We can't depend on the exact outputs from `DartBuild`, so
    // depend on all the same inputs.
    Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
  ];

  @override
  String get name => 'install_code_assets';

  @override
  List<Source> get outputs => const <Source>[Source.pattern('{BUILD_DIR}/$nativeAssetsFilename')];

  static const nativeAssetsFilename = 'native_assets.json';
  static const depFilename = 'install_code_assets.d';
}

TargetPlatform _getTargetPlatformFromEnvironment(Environment environment, String name) {
  final String? targetPlatformEnvironment = environment.defines[kTargetPlatform];
  if (targetPlatformEnvironment == null) {
    throw MissingDefineException(kTargetPlatform, name);
  }
  return getTargetPlatformForName(targetPlatformEnvironment);
}

Future<FlutterNativeAssetsBuildRunner> createFlutterNativeAssetsBuildRunner(
  Environment environment,
) async {
  final FileSystem fileSystem = environment.fileSystem;
  final File packageConfigFile = fileSystem.file(environment.packageConfigPath);
  final PackageConfig packageConfig = await loadPackageConfigWithLogging(
    packageConfigFile,
    logger: environment.logger,
  );
  final Uri projectUri = environment.projectDir.uri;
  final String? runPackageName = packageConfig.packages
      .where((Package p) => p.root == projectUri)
      .firstOrNull
      ?.name;
  if (runPackageName == null) {
    throw StateError(
      'Could not determine run package name. '
      'Project path "${projectUri.toFilePath()}" did not occur as package '
      'root in package config "${environment.packageConfigPath}". '
      'Please report a reproduction on '
      'https://github.com/flutter/flutter/issues/169475.',
    );
  }
  final String pubspecPath = packageConfigFile.uri.resolve('../pubspec.yaml').toFilePath();
  final String? buildModeEnvironment = environment.defines[kBuildMode];
  // If the build mode is not present in the environment, we assume that we are
  // running in a test or a task that does not require a build mode.
  // We infer the build mode to be debug in that case.
  final BuildMode buildMode = buildModeEnvironment == null
      ? BuildMode.debug
      : BuildMode.fromCliName(buildModeEnvironment);
  final bool includeDevDependencies = !buildMode.isRelease;
  return FlutterNativeAssetsBuildRunnerImpl(
    environment.packageConfigPath,
    packageConfig,
    fileSystem,
    environment.logger,
    runPackageName,
    includeDevDependencies: includeDevDependencies,
    pubspecPath,
  );
}
