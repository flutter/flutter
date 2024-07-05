// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logic for native assets shared between all host OSes.

import '../../../base/os.dart';
import '../../../base/platform.dart';
import '../../../build_info.dart';
import '../../../globals.dart' as globals;
import '../../../native_assets.dart';
import '../../../project.dart';
import '../linux/native_assets.dart';
import '../macos/native_assets.dart';
import '../native_assets.dart';
import '../windows/native_assets.dart';

class TestCompilerNativeAssetsBuilderImpl
    implements TestCompilerNativeAssetsBuilder {
  const TestCompilerNativeAssetsBuilderImpl();

  @override
  Future<Uri?> build(BuildInfo buildInfo) =>
      testCompilerBuildNativeAssets(buildInfo);
}

Future<Uri?> testCompilerBuildNativeAssets(BuildInfo buildInfo) async {
  Uri? nativeAssetsYaml;
  if (!buildInfo.buildNativeAssets) {
    nativeAssetsYaml = null;
  } else {
    final Uri projectUri = FlutterProject.current().directory.uri;
    final NativeAssetsBuildRunner buildRunner = NativeAssetsBuildRunnerImpl(
      projectUri,
      buildInfo.packageConfig,
      globals.fs,
      globals.logger,
    );
    if (globals.platform.isMacOS) {
      (nativeAssetsYaml, _) = await buildNativeAssetsMacOS(
        buildMode: buildInfo.mode,
        projectUri: projectUri,
        flutterTester: true,
        fileSystem: globals.fs,
        buildRunner: buildRunner,
      );
    } else if (globals.platform.isLinux) {
      (nativeAssetsYaml, _) = await buildNativeAssetsLinux(
        buildMode: buildInfo.mode,
        projectUri: projectUri,
        flutterTester: true,
        fileSystem: globals.fs,
        buildRunner: buildRunner,
      );
    } else if (globals.platform.isWindows) {
      final TargetPlatform targetPlatform;
      if (globals.os.hostPlatform == HostPlatform.windows_x64) {
        targetPlatform = TargetPlatform.windows_x64;
      } else {
        targetPlatform = TargetPlatform.windows_arm64;
      }
      (nativeAssetsYaml, _) = await buildNativeAssetsWindows(
        buildMode: buildInfo.mode,
        targetPlatform: targetPlatform,
        projectUri: projectUri,
        flutterTester: true,
        fileSystem: globals.fs,
        buildRunner: buildRunner,
      );
    } else {
      await ensureNoNativeAssetsOrOsIsSupported(
        projectUri,
        const LocalPlatform().operatingSystem,
        globals.fs,
        buildRunner,
      );
    }
  }
  return nativeAssetsYaml;
}
