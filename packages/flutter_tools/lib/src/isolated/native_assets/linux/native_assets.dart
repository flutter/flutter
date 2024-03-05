// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_builder/native_assets_builder.dart'
    hide NativeAssetsBuildRunner;
import 'package:native_assets_cli/native_assets_cli_internal.dart'
    hide BuildMode;

import '../../../base/common.dart';
import '../../../base/file_system.dart';
import '../../../base/io.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;
import '../native_assets.dart';

/// Dry run the native builds.
///
/// This does not build native assets, it only simulates what the final paths
/// of all assets will be so that this can be embedded in the kernel file.
Future<Uri?> dryRunNativeAssetsLinux({
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
    os: OS.linux,
  );
}

Future<Iterable<KernelAsset>> dryRunNativeAssetsLinuxInternal(
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
    OS.linux,
  );
}

Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)> buildNativeAssetsLinux({
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

/// Flutter expects `clang++` to be on the path on Linux hosts.
///
/// Search for the accompanying `clang`, `ar`, and `ld`.
Future<CCompilerConfig> cCompilerConfigLinux() async {
  const String kClangPlusPlusBinary = 'clang++';
  const String kClangBinary = 'clang';
  const String kArBinary = 'llvm-ar';
  const String kLdBinary = 'ld.lld';

  final ProcessResult whichResult = await globals.processManager.run(<String>['which', kClangPlusPlusBinary]);
  if (whichResult.exitCode != 0) {
    throwToolExit('Failed to find $kClangPlusPlusBinary on PATH.');
  }
  File clangPpFile = globals.fs.file((whichResult.stdout as String).trim());
  clangPpFile = globals.fs.file(await clangPpFile.resolveSymbolicLinks());

  final Directory clangDir = clangPpFile.parent;
  final Map<String, Uri> binaryPaths = <String, Uri>{};
  for (final String binary in <String>[kClangBinary, kArBinary, kLdBinary]) {
    final File binaryFile = clangDir.childFile(binary);
    if (!await binaryFile.exists()) {
      throwToolExit("Failed to find $binary relative to $clangPpFile: $binaryFile doesn't exist.");
    }
    binaryPaths[binary] = binaryFile.uri;
  }
  return CCompilerConfig(
    ar: binaryPaths[kArBinary],
    cc: binaryPaths[kClangBinary],
    ld: binaryPaths[kLdBinary],
  );
}
