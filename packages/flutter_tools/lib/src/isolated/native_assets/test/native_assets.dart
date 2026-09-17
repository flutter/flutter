// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import 'package:code_assets/code_assets.dart' show OS;
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';

import '../../../base/platform.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;
import '../../../native_assets.dart';
import '../../../project.dart';
import '../dart_hook_result.dart';
import '../native_assets.dart';

class TestCompilerNativeAssetsBuilderImpl implements TestCompilerNativeAssetsBuilder {
  const TestCompilerNativeAssetsBuilderImpl({@visibleForTesting this.buildRunner});

  @visibleForTesting
  final FlutterNativeAssetsBuildRunner? buildRunner;

  @override
  Future<Uri?> build(BuildInfo buildInfo) =>
      testCompilerBuildNativeAssets(buildInfo, buildRunner: buildRunner);

  @override
  String windowsBuildDirectory(FlutterProject project) {
    final String buildDir = getBuildDirectory();
    return project.directory.uri.resolve('$buildDir/native_assets/windows/').toFilePath();
  }
}

Future<Uri?> testCompilerBuildNativeAssets(
  BuildInfo buildInfo, {
  @visibleForTesting FlutterNativeAssetsBuildRunner? buildRunner,
}) async {
  if (!buildInfo.buildNativeAssets) {
    return null;
  }
  final FlutterProject project = FlutterProject.current();
  final Uri projectUri = project.directory.uri;
  final String? runPackageName = _findRunPackageName(
    fileSystem: globals.fs,
    packageConfig: buildInfo.packageConfig,
    project: project,
  );
  if (runPackageName == null) {
    globals.logger.printTrace('Could not determine run package name for native assets testing.');
    return null;
  }
  final File pubspecFromPackageConfig = globals.fs.file(
    Uri.file(buildInfo.packageConfigPath).resolve('../pubspec.yaml'),
  );
  final String pubspecPath = pubspecFromPackageConfig.existsSync()
      ? pubspecFromPackageConfig.path
      : project.directory.childFile('pubspec.yaml').path;
  final FlutterNativeAssetsBuildRunner runner =
      buildRunner ??
      FlutterNativeAssetsBuildRunnerImpl(
        buildInfo.packageConfigPath,
        buildInfo.packageConfig,
        globals.fs,
        globals.logger,
        globals.platform,
        runPackageName,
        pubspecPath,
        includeDevDependencies: true,
      );

  if (!globals.platform.isMacOS && !globals.platform.isLinux && !globals.platform.isWindows) {
    await ensureNoNativeAssetsOrOsIsSupported(
      projectUri,
      const LocalPlatform().operatingSystem,
      globals.fs,
      runner,
    );
    return null;
  }

  // Only `flutter test` uses the
  // `build/native_assets/<os>/native_assets.json` file which uses absolute
  // paths to the shared libraries.
  final OS targetOS = getNativeOSFromTargetPlatform(TargetPlatform.tester);
  final String buildDir = getBuildDirectory();
  final String osName = targetOS.name;
  final Uri buildUri = projectUri.resolve('$buildDir/native_assets/$osName/');
  final Uri nativeAssetsFileUri = buildUri.resolve('native_assets.json');

  final environmentDefines = <String, String>{kBuildMode: buildInfo.mode.cliName};

  // First perform the dart build.
  final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
    environmentDefines: environmentDefines,
    buildRunner: runner,
    targetPlatform: TargetPlatform.tester,
    projectUri: projectUri,
    fileSystem: globals.fs,
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
    fileSystem: globals.fs,
    nativeAssetsFileUri: nativeAssetsFileUri,
    targetUri: projectUri.resolve('${getBuildDirectory()}/native_assets/$osName/'),
  );
  assert(globals.fs.file(nativeAssetsFileUri).existsSync());

  return nativeAssetsFileUri;
}

String? _findRunPackageName({
  required FileSystem fileSystem,
  required PackageConfig packageConfig,
  required FlutterProject project,
}) {
  final Uri projectUri = project.directory.uri;

  // 1. Direct match on package root URI.
  final Package? directMatch = packageConfig.packages
      .where((Package p) => p.root == projectUri)
      .firstOrNull;
  if (directMatch != null) {
    return directMatch.name;
  }

  // 2. Canonicalized path match (handles symlinks, trailing slashes, etc.).
  if (projectUri.isScheme('file')) {
    final String canonicalProjectDir = fileSystem.path.canonicalize(project.directory.path);
    final Package? pathMatch = packageConfig.packages.where((Package p) {
      if (!p.root.isScheme('file')) {
        return false;
      }
      return fileSystem.path.canonicalize(fileSystem.directory(p.root).path) == canonicalProjectDir;
    }).firstOrNull;
    if (pathMatch != null) {
      return pathMatch.name;
    }
  }

  // 3. Match against project manifest app name if it exists in package config.
  final String manifestAppName = project.manifest.appName;
  if (manifestAppName.isNotEmpty && packageConfig[manifestAppName] != null) {
    return manifestAppName;
  }

  // 4. Fallback to the first package in the package config, if any.
  final String? firstPackageName = packageConfig.packages.firstOrNull?.name;
  if (firstPackageName != null) {
    return firstPackageName;
  }

  // 5. Fallback to project manifest app name if non-empty.
  if (manifestAppName.isNotEmpty) {
    return manifestAppName;
  }

  return null;
}
