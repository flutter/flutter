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
/// Returns the [Uri] to the generated `native_assets.json` file, or `null` if
/// native assets are disabled, unsupported on the host OS, or no package can
/// be resolved.
Future<Uri?> testCompilerBuildNativeAssets(BuildInfo buildInfo) async {
  final BuildInfo(
    :bool buildNativeAssets,
    :BuildMode mode,
    :PackageConfig packageConfig,
    :String packageConfigPath,
  ) = buildInfo;
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
    globals.logger.printWarning(
      'Could not determine run package name for native assets testing '
      '(projectUri: $projectUri, packageConfigPath: $packageConfigPath).',
    );
    return null;
  }
  final String pubspecPath = Uri.file(packageConfigPath)
      .resolve('../$_pubspecYamlFileName')
      .toFilePath();
  final FlutterNativeAssetsBuildRunner buildRunner = FlutterNativeAssetsBuildRunnerImpl(
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
      buildRunner,
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
    buildRunner: buildRunner,
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
/// 3. [manifestAppName] if it is non-empty.
/// 4. `null` if no package name can be determined.
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
  if (projectUri.isScheme(_fileScheme) && packageConfig.packages.isNotEmpty) {
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

  // 3. Fallback to the project manifest app name if non-empty.
  return manifestAppName.isNotEmpty ? manifestAppName : null;
}

String _canonicalizeUriPath(FileSystem fileSystem, Uri uri) {
  final String path = fileSystem.path.fromUri(uri);
  final Directory directory = fileSystem.directory(path);
  var resolvedPath = path;
  if (directory.existsSync()) {
    try {
      resolvedPath = directory.resolveSymbolicLinksSync();
    } on FileSystemException {
      // Fall back to the unresolved path if symlink resolution fails.
    }
  }
  return fileSystem.path.canonicalize(resolvedPath);
}
