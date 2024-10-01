// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:native_assets_builder/native_assets_builder.dart'
    as native_assets_builder;
import 'package:native_assets_cli/native_assets_cli_internal.dart';
import 'package:package_config/package_config_types.dart';

/// Mocks all logic instead of using `package:native_assets_builder`, which
/// relies on doing process calls to `pub` and the local file system.
class FakeFlutterNativeAssetsBuildRunner
    implements FlutterNativeAssetsBuildRunner {
  FakeFlutterNativeAssetsBuildRunner({
    this.hasPackageConfigResult = true,
    this.packagesWithNativeAssetsResult = const <Package>[],
    this.onBuild,
    this.buildDryRunResult = const FakeFlutterNativeAssetsBuilderResult(),
    this.buildResult = const FakeFlutterNativeAssetsBuilderResult(),
    this.linkResult = const FakeFlutterNativeAssetsBuilderResult(),
    CCompilerConfigImpl? cCompilerConfigResult,
    CCompilerConfigImpl? ndkCCompilerConfigImplResult,
  })  : cCompilerConfigResult = cCompilerConfigResult ?? CCompilerConfigImpl(),
        ndkCCompilerConfigImplResult =
            ndkCCompilerConfigImplResult ?? CCompilerConfigImpl();

  final native_assets_builder.BuildResult Function(Target)? onBuild;
  final native_assets_builder.BuildResult buildResult;
  final native_assets_builder.LinkResult linkResult;
  final native_assets_builder.BuildDryRunResult buildDryRunResult;
  final bool hasPackageConfigResult;
  final List<Package> packagesWithNativeAssetsResult;
  final CCompilerConfigImpl cCompilerConfigResult;
  final CCompilerConfigImpl ndkCCompilerConfigImplResult;

  int buildInvocations = 0;
  int buildDryRunInvocations = 0;
  int linkInvocations = 0;
  int hasPackageConfigInvocations = 0;
  int packagesWithNativeAssetsInvocations = 0;
  BuildModeImpl? lastBuildMode;

  @override
  Future<native_assets_builder.BuildResult> build({
    required bool includeParentEnvironment,
    required BuildModeImpl buildMode,
    required LinkModePreferenceImpl linkModePreference,
    required Target target,
    required Uri workingDirectory,
    CCompilerConfigImpl? cCompilerConfig,
    int? targetAndroidNdkApi,
    int? targetIOSVersion,
    int? targetMacOSVersion,
    IOSSdkImpl? targetIOSSdkImpl,
    required bool linkingEnabled,
  }) async {
    buildInvocations++;
    lastBuildMode = buildMode;
    return onBuild?.call(target) ?? buildResult;
  }

  @override
  Future<native_assets_builder.LinkResult> link({
    required bool includeParentEnvironment,
    required BuildModeImpl buildMode,
    required LinkModePreferenceImpl linkModePreference,
    required Target target,
    required Uri workingDirectory,
    required native_assets_builder.BuildResult buildResult,
    CCompilerConfigImpl? cCompilerConfig,
    int? targetAndroidNdkApi,
    int? targetIOSVersion,
    int? targetMacOSVersion,
    IOSSdkImpl? targetIOSSdkImpl,
  }) async {
    linkInvocations++;
    lastBuildMode = buildMode;
    return linkResult;
  }

  @override
  Future<native_assets_builder.BuildDryRunResult> buildDryRun({
    required bool includeParentEnvironment,
    required LinkModePreferenceImpl linkModePreference,
    required OSImpl targetOS,
    required Uri workingDirectory,
  }) async {
    buildDryRunInvocations++;
    return buildDryRunResult;
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

  @override
  Future<CCompilerConfigImpl> get cCompilerConfig async =>
      cCompilerConfigResult;

  @override
  Future<CCompilerConfigImpl> get ndkCCompilerConfigImpl async =>
      cCompilerConfigResult;
}

final class FakeFlutterNativeAssetsBuilderResult
    implements
        native_assets_builder.BuildResult,
        native_assets_builder.BuildDryRunResult,
        native_assets_builder.LinkResult {
  const FakeFlutterNativeAssetsBuilderResult({
    this.assets = const <AssetImpl>[],
    this.assetsForLinking = const <String, List<AssetImpl>>{},
    this.dependencies = const <Uri>[],
    this.success = true,
  });

  @override
  final List<AssetImpl> assets;

  @override
  final Map<String, List<AssetImpl>> assetsForLinking;

  @override
  final List<Uri> dependencies;

  @override
  final bool success;
}

class FakeHotRunnerNativeAssetsBuilder implements HotRunnerNativeAssetsBuilder {
  FakeHotRunnerNativeAssetsBuilder(this.buildRunner);

  final FlutterNativeAssetsBuildRunner buildRunner;

  @override
  Future<Uri?> dryRun({
    required Uri projectUri,
    required FileSystem fileSystem,
    required List<FlutterDevice> flutterDevices,
    required String packageConfigPath,
    required PackageConfig packageConfig,
    required Logger logger,
  }) {
    final List<TargetPlatform> targetPlatforms = flutterDevices
        .map((FlutterDevice d) => d.targetPlatform)
        .nonNulls
        .toList();
    return runFlutterSpecificDartDryRunOnPlatforms(
      projectUri: projectUri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
      targetPlatforms: targetPlatforms,
    );
  }
}
