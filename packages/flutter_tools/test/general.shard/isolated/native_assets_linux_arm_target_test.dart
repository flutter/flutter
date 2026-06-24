// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/187018.
//
// Before linux_arm existed, armv7 Linux cross-builds emitted a
// NativeAssetsManifest.json keyed `android_arm` instead of `linux_arm`. That
// wrong key silently disabled FFI and code-asset plugins: at load time nothing
// matched the linux/arm host, so the plugins were dropped without surfacing an
// error.
//
// The TargetPlatform -> native-assets target translation is pure and
// deterministic, so these are hermetic unit tests: they assert the resolved
// target's OS, architecture, and manifest key directly. No arm32 silicon and
// no engine artifacts are required to prove the manifest is keyed `linux_arm`.

import 'package:code_assets/code_assets.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';

import '../../src/common.dart';

List<AssetBuildTarget> _targetsFor(TargetPlatform targetPlatform) {
  return AssetBuildTarget.targetsFor(
    targetPlatform: targetPlatform,
    buildMode: BuildMode.debug,
    environmentDefines: <String, String>{},
    fileSystem: MemoryFileSystem.test(),
    supportedAssetTypes: <SupportedAssetTypes>[SupportedAssetTypes.codeAssets],
    buildDirectory: null,
  );
}

void main() {
  testWithoutContext('linux_arm maps to the linux native OS (not android)', () {
    expect(getNativeOSFromTargetPlatform(TargetPlatform.linux_arm), OS.linux);
  });

  testWithoutContext(
    'linux_arm resolves to a single linux/arm code-asset target, not android_arm',
    () {
      final List<AssetBuildTarget> targets = _targetsFor(TargetPlatform.linux_arm);

      expect(targets, hasLength(1));
      final AssetBuildTarget target = targets.single;
      expect(target, isA<LinuxAssetTarget>());

      final codeTarget = target as CodeAssetTarget;
      // The #187018 bug emitted an android_arm-keyed manifest; assert the
      // resolved target is 32-bit arm AND linux (i.e. NOT android).
      expect(codeTarget.architecture, Architecture.arm);
      expect(codeTarget.os, OS.linux);
      expect(codeTarget.os, isNot(OS.android));
      // The native-assets manifest is keyed by `${os}_${arch}`; this is the
      // key that must read `linux_arm` rather than `android_arm`.
      expect(codeTarget.targetString, 'linux_arm');
    },
  );

  testWithoutContext('linux_arm and linux_arm64 resolve to distinct linux targets', () {
    final arm = _targetsFor(TargetPlatform.linux_arm).single as CodeAssetTarget;
    final arm64 = _targetsFor(TargetPlatform.linux_arm64).single as CodeAssetTarget;

    expect(arm.architecture, Architecture.arm);
    expect(arm64.architecture, Architecture.arm64);
    expect(arm.os, OS.linux);
    expect(arm64.os, OS.linux);
    expect(arm.targetString, 'linux_arm');
    expect(arm64.targetString, 'linux_arm64');
  });
}
