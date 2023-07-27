// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart' as logging;
import 'package:native_assets_builder/native_assets_builder.dart'
    as native_assets_builder;
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:package_config/package_config_types.dart';

import 'base/file_system.dart';
import 'cache.dart';
import 'globals.dart' as globals;

/// Programmatic API to be used by Dart launchers to invoke native builds.
abstract class NativeAssetsBuildRunner {
  /// Whether the project has a `.dart_tools/package_config.json`.
  ///
  /// If there is no package config, [packagesWithNativeAssets], [build], and
  /// [dryRun] must not be invoked.
  Future<bool> hasPackageConfig();

  /// All packages in the transitive dependencies that have a `build.dart`.
  Future<List<Package>> packagesWithNativeAssets();

  /// Runs all [packagesWithNativeAssets] `build.dart` in dry run.
  Future<List<Asset>> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
  });

  /// Runs all [packagesWithNativeAssets] `build.dart`.
  Future<List<Asset>> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  });
}

/// Uses `package:native_assets_builder` for its implementation.
class NativeAssetsBuildRunnerImpl implements NativeAssetsBuildRunner {
  NativeAssetsBuildRunnerImpl(this.projectUri, this.fileSystem);

  final Uri projectUri;
  final FileSystem fileSystem;

  final logging.Logger _logger = logging.Logger('')
    ..onRecord.listen((logging.LogRecord record) {
      final int levelValue = record.level.value;
      final String message = record.message;
      if (levelValue >= logging.Level.SEVERE.value) {
        globals.logger.printError(message);
      } else if (levelValue >= logging.Level.WARNING.value) {
        globals.logger.printWarning(message);
      } else if (levelValue >= logging.Level.INFO.value) {
        globals.logger.printTrace(message);
      } else {
        globals.logger.printTrace(message);
      }
    });

  late final Uri _dartExecutable =
      fileSystem.directory(Cache.flutterRoot).uri.resolve('bin/dart');

  // TODO(dacoharkes): Reuse once we can.
  // https://github.com/dart-lang/native/issues/102
  native_assets_builder.NativeAssetsBuildRunner _buildRunner() =>
      native_assets_builder.NativeAssetsBuildRunner(
          logger: _logger, dartExecutable: _dartExecutable);

  native_assets_builder.PackageLayout? _packageLayout;

  @override
  Future<bool> hasPackageConfig() {
    final File packageConfigJson = fileSystem
        .directory(projectUri.toFilePath())
        .childFile('.dart_tool/package_config.json');
    return packageConfigJson.exists();
  }

  @override
  Future<List<Package>> packagesWithNativeAssets() async {
    _packageLayout ??=
        await native_assets_builder.PackageLayout.fromRootPackageRoot(
            projectUri);
    return _packageLayout!.packagesWithNativeAssets;
  }

  @override
  Future<List<Asset>> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
  }) {
    return _buildRunner().dryRun(
      includeParentEnvironment: includeParentEnvironment,
      linkModePreference: linkModePreference,
      targetOs: targetOs,
      workingDirectory: workingDirectory,
    );
  }

  @override
  Future<List<Asset>> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  }) {
    return _buildRunner().build(
      buildMode: buildMode,
      cCompilerConfig: cCompilerConfig,
      includeParentEnvironment: includeParentEnvironment,
      linkModePreference: linkModePreference,
      target: target,
      targetAndroidNdkApi: targetAndroidNdkApi,
      targetIOSSdk: targetIOSSdk,
      workingDirectory: workingDirectory,
    );
  }
}

/// Mocks all logic instead of using `package:native_assets_builder`, which
/// relies on doing process calls to `pub` and the local file system.
class FakeNativeAssetsBuildRunner implements NativeAssetsBuildRunner {
  FakeNativeAssetsBuildRunner({
    this.hasPackageConfigResult = true,
    this.packagesWithNativeAssetsResult = const <Package>[],
    this.dryRunResult = const <Asset>[],
    this.buildResult = const <Asset>[],
  });

  final List<Asset> buildResult;
  final List<Asset> dryRunResult;
  final bool hasPackageConfigResult;
  final List<Package> packagesWithNativeAssetsResult;

  int buildInvocations = 0;
  int dryRunInvocations = 0;
  int hasPackageConfigInvocations = 0;
  int packagesWithNativeAssetsInvocations = 0;

  @override
  Future<List<Asset>> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  }) async {
    buildInvocations++;
    return buildResult;
  }

  @override
  Future<List<Asset>> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
  }) async {
    dryRunInvocations++;
    return dryRunResult;
  }

  @override
  Future<bool> hasPackageConfig() async {
    hasPackageConfigInvocations++;
    return hasPackageConfigResult;
  }

  @override
  Future<List<Package>> packagesWithNativeAssets() async {
    packagesWithNativeAssetsInvocations++;
    return packagesWithNativeAssetsResult;
  }
}
