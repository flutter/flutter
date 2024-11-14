// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart' hide BuildMode;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_cli/code_assets_builder.dart';
import 'package:package_config/package_config_types.dart';

export 'package:native_assets_cli/code_assets_builder.dart' show CodeAsset, DynamicLoadingBundled;

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
    CCompilerConfig? cCompilerConfigResult,
    CCompilerConfig? ndkCCompilerConfigResult,
  })  : cCompilerConfigResult = cCompilerConfigResult ?? CCompilerConfig(),
        ndkCCompilerConfigResult =
            ndkCCompilerConfigResult ?? CCompilerConfig();

  final BuildResult? Function(BuildConfig)? onBuild;
  final BuildResult? buildResult;
  final LinkResult? linkResult;
  final BuildDryRunResult? buildDryRunResult;
  final bool hasPackageConfigResult;
  final List<Package> packagesWithNativeAssetsResult;
  final CCompilerConfig cCompilerConfigResult;
  final CCompilerConfig ndkCCompilerConfigResult;

  int buildInvocations = 0;
  int buildDryRunInvocations = 0;
  int linkInvocations = 0;
  int hasPackageConfigInvocations = 0;
  int packagesWithNativeAssetsInvocations = 0;
  BuildMode? lastBuildMode;

  @override
  Future<BuildResult?> build({
    required List<String> supportedAssetTypes,
    required BuildConfigValidator configValidator,
    required BuildConfigCreator configCreator,
    required BuildValidator buildValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required OS targetOS,
    required Uri workingDirectory,
    required bool linkingEnabled,
  }) async {
    BuildResult? result = buildResult;
    for (final Package package in packagesWithNativeAssetsResult) {
      final BuildConfigBuilder configBuilder = configCreator()
          ..setupHookConfig(
            packageRoot: package.root,
            packageName: package.name,
            targetOS: targetOS,
            supportedAssetTypes: supportedAssetTypes,
            buildMode: buildMode,
          )
          ..setupBuildConfig(
            dryRun: false,
            linkingEnabled: linkingEnabled,
            )
          ..setupBuildRunConfig(
            outputDirectory: Uri.parse('build-out-dir'),
            outputDirectoryShared: Uri.parse('build-out-dir-shared'),
            );
      final BuildConfig buildConfig = BuildConfig(configBuilder.json);
      if (onBuild != null) {
        result = onBuild!(buildConfig);
      }
      lastBuildMode = buildConfig.buildMode;
      buildInvocations++;
    }
    return result;
  }

  @override
  Future<LinkResult?> link({
    required List<String> supportedAssetTypes,
    required LinkConfigCreator configCreator,
    required LinkConfigValidator configValidator,
    required LinkValidator linkValidator,
    required ApplicationAssetValidator applicationAssetValidator,
    required bool includeParentEnvironment,
    required BuildMode buildMode,
    required OS targetOS,
    required Uri workingDirectory,
    required BuildResult buildResult,
  }) async {
    for (final Package _ in packagesWithNativeAssetsResult) {
      lastBuildMode = buildMode;
      linkInvocations++;
    }
    return linkResult;
  }

  @override
  Future<BuildDryRunResult?> buildDryRun({
    required List<String> supportedAssetTypes,
    required ConfigCreator configCreator,
    required BuildValidator buildValidator,
    required bool includeParentEnvironment,
    required OS targetOS,
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
  Future<CCompilerConfig> get cCompilerConfig async => cCompilerConfigResult;

  @override
  Future<CCompilerConfig> get ndkCCompilerConfig async => cCompilerConfigResult;
}

final class FakeFlutterNativeAssetsBuilderResult
    implements BuildResult, BuildDryRunResult, LinkResult {
  const FakeFlutterNativeAssetsBuilderResult({
    this.encodedAssets = const <EncodedAsset>[],
    this.encodedAssetsForLinking = const <String, List<EncodedAsset>>{},
    this.dependencies = const <Uri>[],
  });

  factory FakeFlutterNativeAssetsBuilderResult.fromAssets({
    List<CodeAsset> codeAssets = const <CodeAsset>[],
    Map<String, List<CodeAsset>> codeAssetsForLinking = const <String, List<CodeAsset>>{},
    List<Uri> dependencies = const <Uri>[],
  }) {
    return FakeFlutterNativeAssetsBuilderResult(
      encodedAssets: <EncodedAsset>[
        for (final CodeAsset codeAsset in codeAssets) codeAsset.encode(),
      ],
      encodedAssetsForLinking: <String, List<EncodedAsset>>{
        for (final String linkerName in codeAssetsForLinking.keys)
          linkerName: <EncodedAsset>[
            for (final CodeAsset codeAsset in codeAssetsForLinking[linkerName]!)
              codeAsset.encode(),
          ],
      },
      dependencies: dependencies,
    );
  }

  @override
  final List<EncodedAsset> encodedAssets;

  @override
  final Map<String, List<EncodedAsset>> encodedAssetsForLinking;

  @override
  final List<Uri> dependencies;
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
