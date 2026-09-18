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

const _fileScheme = 'file';
const _nativeAssetsJsonFileName = 'native_assets.json';
const _pubspecYamlFileName = 'pubspec.yaml';

/// Builds native assets for `flutter test` targets on the host platform.
class TestCompilerNativeAssetsBuilderImpl implements TestCompilerNativeAssetsBuilder {
  const TestCompilerNativeAssetsBuilderImpl();

  @override
  Future<Uri?> build(BuildInfo buildInfo) => testCompilerBuildNativeAssets(buildInfo);

  @override
  String windowsBuildDirectory(FlutterProject project) {
    final String buildDir = getBuildDirectory();
    return project.directory.uri.resolve('$buildDir/native_assets/windows/').toFilePath();
  }
}

/// Builds native assets for `flutter test` execution using [buildInfo].
///
/// Resolves the target package name for the current project and executes build
/// and install hooks for the host test platform ([TargetPlatform.tester]),
/// writing the generated manifest to `build/native_assets/<os>/native_assets.json`.
///
/// An optional [buildRunner] parameter may be provided for testing. Returns the
/// [Uri] to the generated `native_assets.json` file, or `null` if native assets
/// are disabled, unsupported on the host OS, or no package can be resolved.
Future<Uri?> testCompilerBuildNativeAssets(
  BuildInfo buildInfo, {
  @visibleForTesting FlutterNativeAssetsBuildRunner? buildRunner,
}) async {
  final BuildInfo(:buildNativeAssets, :mode, :packageConfig, :packageConfigPath) = buildInfo;
  if (!buildNativeAssets) {
    return null;
  }
  final FlutterProject project = FlutterProject.current();
  final Uri projectUri = project.directory.uri;
  final String? runPackageName = findRunPackageName(
    fileSystem: globals.fs,
    manifestAppName: project.manifest.appName,
    packageConfig: packageConfig,
    projectUri: projectUri,
  );
  if (runPackageName == null) {
    globals.logger.printTrace('Could not determine run package name for native assets testing.');
    return null;
  }
  final File pubspecFromPackageConfig = globals.fs.file(
    Uri.file(packageConfigPath).resolve('../$_pubspecYamlFileName'),
  );
  final String pubspecPath = pubspecFromPackageConfig.existsSync()
      ? pubspecFromPackageConfig.path
      : project.directory.childFile(_pubspecYamlFileName).path;
  final FlutterNativeAssetsBuildRunner runner =
      buildRunner ??
      FlutterNativeAssetsBuildRunnerImpl(
        packageConfigPath,
        packageConfig,
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
  final Uri nativeAssetsFileUri = buildUri.resolve(_nativeAssetsJsonFileName);

  final environmentDefines = <String, String>{kBuildMode: mode.cliName};

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
    targetUri: buildUri,
  );
  assert(globals.fs.file(nativeAssetsFileUri).existsSync());

  return nativeAssetsFileUri;
}

/// Resolves the target package name for native assets builds using the following
/// fallback order:
///
/// 1. A package in [packageConfig] whose `root` URI directly matches [projectUri].
/// 2. A package in [packageConfig] whose canonicalized `root` path matches the
///    canonicalized path of [projectUri] (handling symlinks and trailing slashes).
/// 3. [manifestAppName] if it is non-empty and exists in [packageConfig].
/// 4. The first package in [packageConfig], if any.
/// 5. [manifestAppName] if it is non-empty.
/// 6. `null` if no package name can be determined.
@visibleForTesting
String? findRunPackageName({
  required FileSystem fileSystem,
  required String manifestAppName,
  required PackageConfig packageConfig,
  required Uri projectUri,
}) {
  // 1. Direct match on package root URI.
  final Package? directMatch = packageConfig.packages
      .where((Package p) => p.root == projectUri)
      .firstOrNull;
  if (directMatch != null) {
    return directMatch.name;
  }

  // 2. Canonicalized path match (handles symlinks, trailing slashes, etc.).
  if (projectUri.isScheme(_fileScheme)) {
    final String canonicalProjectDir = _canonicalizeUriPath(fileSystem, projectUri);
    final Package? pathMatch = packageConfig.packages.where((Package p) {
      if (!p.root.isScheme(_fileScheme)) {
        return false;
      }
      return _canonicalizeUriPath(fileSystem, p.root) == canonicalProjectDir;
    }).firstOrNull;
    if (pathMatch != null) {
      return pathMatch.name;
    }
  }

  // 3. Match against project manifest app name if it exists in package config.
  if (manifestAppName.isNotEmpty && packageConfig[manifestAppName] != null) {
    return manifestAppName;
  }

  // 4. Fallback to the first package in the package config, or the project
  // manifest app name if non-empty.
  return packageConfig.packages.firstOrNull?.name ??
      (manifestAppName.isNotEmpty ? manifestAppName : null);
}

String _canonicalizeUriPath(FileSystem fileSystem, Uri uri) {
  final String path = fileSystem.path.fromUri(uri);
  final Directory directory = fileSystem.directory(path);
  final String resolvedPath = directory.existsSync() ? directory.resolveSymbolicLinksSync() : path;
  return fileSystem.path.canonicalize(resolvedPath);
}
