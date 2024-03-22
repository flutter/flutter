// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    hide NativeAssetsBuildRunner;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide BuildMode;

import '../../../base/file_system.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;
import '../../../windows/visual_studio.dart';
import '../native_assets.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file.
Future<Uri?> dryRunNativeAssetsWindows({
  required NativeAssetsBuildRunner buildRunner,
  required Uri projectUri,
  bool flutterTester = false,
  required FileSystem fileSystem,
}) {
  return dryRunNativeAssetsSingleArchitecture(
    buildRunner: buildRunner,
    projectUri: projectUri,
    flutterTester: flutterTester,
    fileSystem: fileSystem,
    os: OS.windows,
  );
}

Future<Iterable<KernelAsset>> dryRunNativeAssetsWindowsInternal(
  FileSystem fileSystem,
  Uri projectUri,
  bool flutterTester,
  NativeAssetsBuildRunner buildRunner,
) {
  return dryRunNativeAssetsSingleArchitectureInternal(
    fileSystem,
    projectUri,
    flutterTester,
    buildRunner,
    OS.windows,
  );
}

Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)>
    buildNativeAssetsWindows({
  required NativeAssetsBuildRunner buildRunner,
  TargetPlatform? targetPlatform,
  required Uri projectUri,
  required BuildMode buildMode,
  bool flutterTester = false,
  Uri? yamlParentDirectory,
  required FileSystem fileSystem,
}) {
  return buildNativeAssetsSingleArchitecture(
    buildRunner: buildRunner,
    targetPlatform: targetPlatform,
    projectUri: projectUri,
    buildMode: buildMode,
    flutterTester: flutterTester,
    yamlParentDirectory: yamlParentDirectory,
    fileSystem: fileSystem,
  );
}

Future<CCompilerConfig> cCompilerConfigWindows() async {
  final VisualStudio visualStudio = VisualStudio(
    fileSystem: globals.fs,
    platform: globals.platform,
    logger: globals.logger,
    processManager: globals.processManager,
    osUtils: globals.os,
  );

  return CCompilerConfig(
    cc: _toOptionalFileUri(visualStudio.clPath),
    ld: _toOptionalFileUri(visualStudio.linkPath),
    ar: _toOptionalFileUri(visualStudio.libPath),
    envScript: _toOptionalFileUri(visualStudio.vcvarsPath),
    envScriptArgs: <String>[],
  );
}

Uri? _toOptionalFileUri(String? string) {
  if (string == null) {
    return null;
  }
  return Uri.file(string);
}
