// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';
import 'package:hooks/hooks.dart';
import 'package:hooks_runner/hooks_runner.dart';

export 'package:code_assets/code_assets.dart' show CodeAsset, DynamicLoadingBundled;

/// Mocks all logic instead of using `package:hooks_runner`, which
/// relies on doing process calls to `pub` and the local file system.
class FakeFlutterNativeAssetsBuildRunner implements FlutterNativeAssetsBuildRunner {
  FakeFlutterNativeAssetsBuildRunner({
    this.packagesWithNativeAssetsResult = const <String>[],
    this.onBuild,
    this.onLink,
    this.buildResult = const FakeFlutterNativeAssetsBuilderResult(),
    this.linkResult = const FakeFlutterNativeAssetsBuilderResult(),
  });

  // TODO(dcharkes): Cleanup this fake https://github.com/flutter/flutter/issues/162061
  final BuildResult? Function(BuildInput)? onBuild;
  final LinkResult? Function(LinkInput)? onLink;
  final BuildResult? buildResult;
  final LinkResult? linkResult;
  final List<String> packagesWithNativeAssetsResult;

  int buildInvocations = 0;
  int linkInvocations = 0;
  int packagesWithNativeAssetsInvocations = 0;

  @override
  Future<BuildResult?> build({
    required List<ProtocolExtension> extensions,
    required bool linkingEnabled,
  }) async {
    BuildResult? result = buildResult;
    for (final String package in packagesWithNativeAssetsResult) {
      final input = BuildInputBuilder()
        ..setupShared(
          packageRoot: Uri.parse('$package/'),
          packageName: package,
          outputDirectoryShared: Uri.parse('build-out-dir-shared'),
          outputFile: Uri.file('output.json'),
        )
        ..setupBuildInput()
        ..config.setupBuild(linkingEnabled: linkingEnabled);
      for (final extension in extensions) {
        extension.setupBuildInput(input);
      }
      final buildConfig = BuildInput(input.json);
      if (onBuild != null) {
        result = onBuild!(buildConfig);
      }
      buildInvocations++;
    }
    return result;
  }

  @override
  Future<LinkResult?> link({
    required List<ProtocolExtension> extensions,
    required BuildResult buildResult,
  }) async {
    LinkResult? result = linkResult;
    for (final String package in packagesWithNativeAssetsResult) {
      final input = LinkInputBuilder()
        ..setupShared(
          packageRoot: Uri.parse('$package/'),
          packageName: package,
          outputDirectoryShared: Uri.parse('build-out-dir-shared'),
          outputFile: Uri.file('output.json'),
        )
        ..setupLink(
          assets: buildResult.encodedAssets,
          recordedUsesFile: null,
          assetsFromLinking: [],
        );
      for (final extension in extensions) {
        extension.setupLinkInput(input);
      }
      final buildConfig = LinkInput(input.json);
      if (onLink != null) {
        result = onLink!(buildConfig);
      }
      linkInvocations++;
    }
    return result;
  }

  @override
  Future<List<String>> packagesWithNativeAssets() async {
    packagesWithNativeAssetsInvocations++;
    return packagesWithNativeAssetsResult;
  }

  CCompilerConfig? get cCompilerConfigResult => null;
  CCompilerConfig? get ndkCCompilerConfigResult => null;

  @override
  Future<void> setCCompilerConfig(CodeAssetTarget target) async {
    if (target is AndroidAssetTarget) {
      target.cCompilerConfigSync = ndkCCompilerConfigResult;
    } else if (target is FlutterTesterAssetTarget) {
      target.subtarget.cCompilerConfigSync = cCompilerConfigResult;
    } else {
      target.cCompilerConfigSync = cCompilerConfigResult;
    }
  }
}

final class FakeFlutterNativeAssetsBuilderResult implements BuildResult, LinkResult {
  const FakeFlutterNativeAssetsBuilderResult({
    this.encodedAssets = const <EncodedAsset>[],
    this.encodedAssetsForLinking = const <String, List<EncodedAsset>>{},
    this.dependencies = const <Uri>[],
  });

  factory FakeFlutterNativeAssetsBuilderResult.fromAssets({
    List<CodeAsset> codeAssets = const <CodeAsset>[],
    List<DataAsset> dataAssets = const <DataAsset>[],
    Map<String, List<CodeAsset>> codeAssetsForLinking = const <String, List<CodeAsset>>{},
    Map<String, List<DataAsset>> dataAssetsForLinking = const <String, List<DataAsset>>{},
    List<Uri> dependencies = const <Uri>[],
  }) {
    return FakeFlutterNativeAssetsBuilderResult(
      encodedAssets: <EncodedAsset>[
        for (final CodeAsset codeAsset in codeAssets) codeAsset.encode(),
        for (final DataAsset dataAsset in dataAssets) dataAsset.encode(),
      ],
      encodedAssetsForLinking: <String, List<EncodedAsset>>{
        for (final String linkerName in codeAssetsForLinking.keys)
          linkerName: <EncodedAsset>[
            for (final CodeAsset codeAsset in codeAssetsForLinking[linkerName]!) codeAsset.encode(),
          ],
        for (final String linkerName in dataAssetsForLinking.keys)
          linkerName: <EncodedAsset>[
            for (final DataAsset dataAsset in dataAssetsForLinking[linkerName]!) dataAsset.encode(),
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
