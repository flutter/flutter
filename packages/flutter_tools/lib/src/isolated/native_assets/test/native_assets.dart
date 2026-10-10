// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import 'package:code_assets/code_assets.dart' show OS;
import 'package:package_config/package_config_types.dart';
import 'package:process/process.dart';

import '../../../base/config.dart';
import '../../../base/file_system.dart';
import '../../../base/logger.dart';
import '../../../base/platform.dart';
import '../../../build_info.dart';
import '../../../native_assets.dart';
import '../../../project.dart';
import '../dart_hook_result.dart';
import '../native_assets.dart';

class TestCompilerNativeAssetsBuilderImpl implements TestCompilerNativeAssetsBuilder {
  const TestCompilerNativeAssetsBuilderImpl({
    required this._config,
    required this._fileSystem,
    required this._logger,
    required this._platform,
    required this._processManager,
    required this._projectFactory,
  });

  final Config _config;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final FlutterProjectFactory _projectFactory;

  @override
  Future<Uri?> build(BuildInfo buildInfo) async =>
      (await buildWithHookResult(buildInfo)).nativeAssetsManifest;

  @override
  Future<TestCompilerNativeAssetsBuildResult> buildWithHookResult(BuildInfo buildInfo) =>
      testCompilerBuildNativeAssets(
        buildInfo,
        config: _config,
        fileSystem: _fileSystem,
        logger: _logger,
        platform: _platform,
        processManager: _processManager,
        projectFactory: _projectFactory,
      );

  @override
  String windowsBuildDirectory(FlutterProject project) {
    final String buildDir = getBuildDirectory(_config, _fileSystem);
    return project.directory.uri.resolve('$buildDir/native_assets/windows/').toFilePath();
  }
}

Future<TestCompilerNativeAssetsBuildResult> testCompilerBuildNativeAssets(
  BuildInfo buildInfo, {
  required Config config,
  required FileSystem fileSystem,
  required Logger logger,
  required Platform platform,
  required ProcessManager processManager,
  required FlutterProjectFactory projectFactory,
}) async {
  if (!buildInfo.buildNativeAssets) {
    return (nativeAssetsManifest: null, flutterHookResult: null);
  }
  final Uri projectUri = projectFactory.fromDirectory(fileSystem.currentDirectory).directory.uri;
  final String runPackageName = buildInfo.packageConfig.packages
      .firstWhere((Package p) => p.root == projectUri)
      .name;
  final String pubspecPath = Uri.file(buildInfo.packageConfigPath)
      .resolve('../pubspec.yaml')
      .toFilePath();
  final FlutterNativeAssetsBuildRunner buildRunner = FlutterNativeAssetsBuildRunnerImpl(
    buildInfo.packageConfigPath,
    buildInfo.packageConfig,
    fileSystem,
    logger,
    platform,
    processManager,
    runPackageName,
    includeDevDependencies: true,
    pubspecPath,
  );

  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    await ensureNoNativeAssetsOrOsIsSupported(
      projectUri,
      platform.operatingSystem,
      fileSystem,
      buildRunner,
      logger: logger,
    );
    return (nativeAssetsManifest: null, flutterHookResult: null);
  }

  // Only `flutter test` uses the
  // `build/native_assets/<os>/native_assets.json` file which uses absolute
  // paths to the shared libraries.
  final OS targetOS = getNativeOSFromTargetPlatform(TargetPlatform.tester);
  final String buildDir = getBuildDirectory(config, fileSystem);
  final String osName = targetOS.name;
  final Uri buildUri = projectUri.resolve('$buildDir/native_assets/$osName/');
  final Uri nativeAssetsFileUri = buildUri.resolve('native_assets.json');

  final environmentDefines = <String, String>{kBuildMode: buildInfo.mode.cliName};

  // First perform the dart build.
  final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
    environmentDefines: environmentDefines,
    buildRunner: buildRunner,
    targetPlatform: TargetPlatform.tester,
    projectUri: projectUri,
    fileSystem: fileSystem,
    logger: logger,
    buildCodeAssets: const BuildCodeAssetsOptions(
      // We're in tests, so there is no app build directory
      appBuildDirectory: null,
    ),
    buildDataAssets: true,
    recordedUsesFile: null,
  );

  // Then "install" the code assets so they can be used at runtime.
  await installCodeAssets(
    dartHookResult: dartHookResult,
    environmentDefines: environmentDefines,
    targetPlatform: TargetPlatform.tester,
    projectUri: projectUri,
    fileSystem: fileSystem,
    logger: logger,
    processManager: processManager,
    nativeAssetsFileUri: nativeAssetsFileUri,
    targetUri: buildUri,
  );
  assert(fileSystem.file(nativeAssetsFileUri).existsSync());

  return (
    nativeAssetsManifest: nativeAssetsFileUri,
    flutterHookResult: dartHookResult.asFlutterResult,
  );
}
