// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart' as logging;
import 'package:native_assets_builder/native_assets_builder.dart'
    as native_assets_builder;
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:package_config/package_config_types.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'cache.dart';
import 'globals.dart' as globals;
import 'macos/native_assets.dart';

/// Programmatic API to be used by Dart launchers to invoke native builds.
///
/// It enables mocking `package:native_assets_builder` package.
/// It also enables mocking native toolchain discovery via [cCompilerConfig].
abstract class NativeAssetsBuildRunner {
  /// Whether the project has a `.dart_tools/package_config.json`.
  ///
  /// If there is no package config, [packagesWithNativeAssets], [build], and
  /// [dryRun] must not be invoked.
  Future<bool> hasPackageConfig();

  /// All packages in the transitive dependencies that have a `build.dart`.
  Future<List<Package>> packagesWithNativeAssets();

  /// Runs all [packagesWithNativeAssets] `build.dart` in dry run.
  Future<native_assets_builder.DryRunResult> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
  });

  /// Runs all [packagesWithNativeAssets] `build.dart`.
  Future<native_assets_builder.BuildResult> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  });

  /// The C compiler config to use for compilation.
  Future<CCompilerConfig> get cCompilerConfig;
}

/// Uses `package:native_assets_builder` for its implementation.
class NativeAssetsBuildRunnerImpl implements NativeAssetsBuildRunner {
  NativeAssetsBuildRunnerImpl(this.projectUri, this.fileSystem, this.logger);

  final Uri projectUri;
  final FileSystem fileSystem;
  final Logger logger;

  late final logging.Logger _logger = logging.Logger('')
    ..onRecord.listen((logging.LogRecord record) {
      final int levelValue = record.level.value;
      final String message = record.message;
      if (levelValue >= logging.Level.SEVERE.value) {
        logger.printError(message);
      } else if (levelValue >= logging.Level.WARNING.value) {
        logger.printWarning(message);
      } else if (levelValue >= logging.Level.INFO.value) {
        logger.printTrace(message);
      } else {
        logger.printTrace(message);
      }
    });

  late final Uri _dartExecutable =
      fileSystem.directory(Cache.flutterRoot).uri.resolve('bin/dart');

  late final native_assets_builder.NativeAssetsBuildRunner _buildRunner =
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
  Future<native_assets_builder.DryRunResult> dryRun({
    required bool includeParentEnvironment,
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
  }) {
    return _buildRunner.dryRun(
      includeParentEnvironment: includeParentEnvironment,
      linkModePreference: linkModePreference,
      targetOs: targetOs,
      workingDirectory: workingDirectory,
    );
  }

  @override
  Future<native_assets_builder.BuildResult> build({
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfig? cCompilerConfig,
    int? targetAndroidNdkApi,
    IOSSdk? targetIOSSdk,
  }) {
    return _buildRunner.build(
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

  @override
  late final Future<CCompilerConfig> cCompilerConfig = () {
    if (globals.platform.isMacOS || globals.platform.isIOS) {
      return cCompilerConfigMacOS();
    } 
    throwToolExit(
      'Native assets feature not yet implemented for Linux, Windows and Android.',
    );
  }();
}
