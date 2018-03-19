// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'base/process_manager.dart';
import 'build_info.dart';
import 'dart/sdk.dart';
import 'globals.dart';

enum Artifact {
  dartIoEntriesTxt,
  dartVmEntryPointsTxt,
  entryPointsJson,
  entryPointsExtraJson,
  genSnapshot,
  flutterTester,
  snapshotDart,
  flutterFramework,
  vmSnapshotData,
  isolateSnapshotData,
  platformKernelDill,
  platformLibrariesJson,
  flutterPatchedSdkPath,
  frontendServerSnapshotForEngineDartSdk,
  engineDartSdkPath,
  engineDartBinary,
}

String _artifactToFileName(Artifact artifact) {
  switch (artifact) {
    case Artifact.dartIoEntriesTxt:
      return 'dart_io_entries.txt';
    case Artifact.dartVmEntryPointsTxt:
      return 'dart_vm_entry_points.txt';
    case Artifact.entryPointsJson:
      return 'entry_points.json';
    case Artifact.entryPointsExtraJson:
      return 'entry_points_extra.json';
    case Artifact.genSnapshot:
      return 'gen_snapshot';
    case Artifact.flutterTester:
      return 'flutter_tester';
    case Artifact.snapshotDart:
      return 'snapshot.dart';
    case Artifact.flutterFramework:
      return 'Flutter.framework';
    case Artifact.vmSnapshotData:
      return 'vm_isolate_snapshot.bin';
    case Artifact.isolateSnapshotData:
      return 'isolate_snapshot.bin';
    case Artifact.platformKernelDill:
      return 'platform_strong.dill';
    case Artifact.platformLibrariesJson:
      return 'libraries.json';
    case Artifact.flutterPatchedSdkPath:
      assert(false, 'No filename for sdk path, should not be invoked');
      return null;
    case Artifact.engineDartSdkPath:
      return 'dart-sdk';
    case Artifact.frontendServerSnapshotForEngineDartSdk:
      return 'frontend_server.dart.snapshot';
    case Artifact.engineDartBinary:
      return 'dart';
  }
  assert(false, 'Invalid artifact $artifact.');
  return null;
}

class EngineBuildPaths {
  const EngineBuildPaths({ @required this.targetEngine, @required this.hostEngine }):
      assert(targetEngine != null),
      assert(hostEngine != null);

  final String targetEngine;
  final String hostEngine;
}

// Manages the engine artifacts of Flutter.
abstract class Artifacts {
  static Artifacts get instance => context[Artifacts];

  static void useLocalEngine(String engineSrcPath, EngineBuildPaths engineBuildPaths) {
    context.setVariable(Artifacts, new LocalEngineArtifacts(engineSrcPath, engineBuildPaths.targetEngine, engineBuildPaths.hostEngine));
  }

  // Returns the requested [artifact] for the [platform] and [mode] combination.
  String getArtifactPath(Artifact artifact, [TargetPlatform platform, BuildMode mode]);

  // Returns which set of engine artifacts is currently used for the [platform]
  // and [mode] combination.
  String getEngineType(TargetPlatform platform, [BuildMode mode]);
}

/// Manages the engine artifacts downloaded to the local cache.
class CachedArtifacts extends Artifacts {

  @override
  String getArtifactPath(Artifact artifact, [TargetPlatform platform, BuildMode mode]) {
    platform ??= _currentHostPlatform;
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        return _getAndroidArtifactPath(artifact, platform, mode);
      case TargetPlatform.ios:
        return _getIosArtifactPath(artifact, platform, mode);
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia:
        return _getHostArtifactPath(artifact, platform);
    }
    assert(false, 'Invalid platform $platform.');
    return null;
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode mode]) {
    return fs.path.basename(_getEngineArtifactsPath(platform, mode));
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode);
    switch (artifact) {
      case Artifact.dartIoEntriesTxt:
      case Artifact.dartVmEntryPointsTxt:
      case Artifact.entryPointsJson:
      case Artifact.entryPointsExtraJson:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        return fs.path.join(engineDir, _artifactToFileName(artifact));
      case Artifact.genSnapshot:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        return fs.path.join(engineDir, hostPlatform, _artifactToFileName(artifact));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getIosArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode);
    switch (artifact) {
      case Artifact.dartIoEntriesTxt:
      case Artifact.dartVmEntryPointsTxt:
      case Artifact.entryPointsJson:
      case Artifact.entryPointsExtraJson:
      case Artifact.genSnapshot:
      case Artifact.snapshotDart:
      case Artifact.flutterFramework:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return fs.path.join(engineDir, _artifactToFileName(artifact));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getFlutterPatchedSdkPath() {
    final String engineArtifactsPath = cache.getArtifactDirectory('engine').path;
    return fs.path.join(engineArtifactsPath, 'common', 'flutter_patched_sdk');
  }

  String _getHostArtifactPath(Artifact artifact, TargetPlatform platform) {
    switch (artifact) {
      case Artifact.genSnapshot:
        // For script snapshots any gen_snapshot binary will do. Returning gen_snapshot for
        // android_arm in profile mode because it is available on all supported host platforms.
        return _getAndroidArtifactPath(artifact, TargetPlatform.android_arm, BuildMode.profile);
      case Artifact.flutterTester:
      case Artifact.vmSnapshotData:
      case Artifact.isolateSnapshotData:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        final String engineArtifactsPath = cache.getArtifactDirectory('engine').path;
        final String platformDirName = getNameForTargetPlatform(platform);
        return fs.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact));
      case Artifact.engineDartSdkPath:
        return dartSdkPath;
      case Artifact.engineDartBinary:
        return fs.path.join(dartSdkPath,'bin', _artifactToFileName(artifact));
      case Artifact.platformKernelDill:
        return fs.path.join(_getFlutterPatchedSdkPath(), _artifactToFileName(artifact));
      case Artifact.platformLibrariesJson:
        return fs.path.join(_getFlutterPatchedSdkPath(), 'lib', _artifactToFileName(artifact));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath();
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getEngineArtifactsPath(TargetPlatform platform, [BuildMode mode]) {
    final String engineDir = cache.getArtifactDirectory('engine').path;
    final String platformName = getNameForTargetPlatform(platform);
    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia:
        assert(mode == null, 'Platform $platform does not support different build modes.');
        return fs.path.join(engineDir, platformName);
      case TargetPlatform.ios:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        assert(mode != null, 'Need to specify a build mode for platform $platform.');
        final String suffix = mode != BuildMode.debug ? '-${getModeName(mode)}' : '';
        return fs.path.join(engineDir, platformName + suffix);
    }
    assert(false, 'Invalid platform $platform.');
    return null;
  }

  TargetPlatform get _currentHostPlatform {
    if (platform.isMacOS)
      return TargetPlatform.darwin_x64;
    if (platform.isLinux)
      return TargetPlatform.linux_x64;
    if (platform.isWindows)
      return TargetPlatform.windows_x64;
    throw new UnimplementedError('Host OS not supported.');
  }
}

/// Manages the artifacts of a locally built engine.
class LocalEngineArtifacts extends Artifacts {
  final String _engineSrcPath;
  final String engineOutPath; // TODO(goderbauer): This should be private.
  String _hostEngineOutPath;

  LocalEngineArtifacts(this._engineSrcPath, this.engineOutPath, this._hostEngineOutPath);

  @override
  String getArtifactPath(Artifact artifact, [TargetPlatform platform, BuildMode mode]) {
    switch (artifact) {
      case Artifact.dartIoEntriesTxt:
        return fs.path.join(_engineSrcPath, 'third_party', 'dart', 'runtime', 'bin', _artifactToFileName(artifact));
      case Artifact.dartVmEntryPointsTxt:
        return fs.path.join(_engineSrcPath, 'flutter', 'runtime', _artifactToFileName(artifact));
      case Artifact.entryPointsJson:
      case Artifact.entryPointsExtraJson:
        return fs.path.join(engineOutPath, 'dart_entry_points', _artifactToFileName(artifact));
      case Artifact.snapshotDart:
        return fs.path.join(_engineSrcPath, 'flutter', 'lib', 'snapshot', _artifactToFileName(artifact));
      case Artifact.genSnapshot:
        return _genSnapshotPath();
      case Artifact.flutterTester:
        return _flutterTesterPath(platform);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return fs.path.join(engineOutPath, 'gen', 'flutter', 'lib', 'snapshot', _artifactToFileName(artifact));
      case Artifact.platformKernelDill:
        return fs.path.join(_getFlutterPatchedSdkPath(), _artifactToFileName(artifact));
      case Artifact.platformLibrariesJson:
        return fs.path.join(_getFlutterPatchedSdkPath(), 'lib', _artifactToFileName(artifact));
      case Artifact.flutterFramework:
        return fs.path.join(engineOutPath, _artifactToFileName(artifact));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath();
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return fs.path.join(_hostEngineOutPath, 'gen', _artifactToFileName(artifact));
      case Artifact.engineDartSdkPath:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk');
      case Artifact.engineDartBinary:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', _artifactToFileName(artifact));
    }
    assert(false, 'Invalid artifact $artifact.');
    return null;
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode mode]) {
    return fs.path.basename(engineOutPath);
  }

  String _getFlutterPatchedSdkPath() {
    return fs.path.join(engineOutPath, 'flutter_patched_sdk');
  }

  String _genSnapshotPath() {
    const List<String> clangDirs = const <String>['.', 'clang_x86', 'clang_x64', 'clang_i386'];
    final String genSnapshotName = _artifactToFileName(Artifact.genSnapshot);
    for (String clangDir in clangDirs) {
      final String genSnapshotPath = fs.path.join(engineOutPath, clangDir, genSnapshotName);
      if (processManager.canRun(genSnapshotPath))
        return genSnapshotPath;
    }
    throw new Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    if (getCurrentHostPlatform() == HostPlatform.linux_x64) {
      return fs.path.join(engineOutPath, _artifactToFileName(Artifact.flutterTester));
    } else if (getCurrentHostPlatform() == HostPlatform.darwin_x64) {
      return fs.path.join(engineOutPath, 'flutter_tester');
    }
    throw new Exception('Unsupported platform $platform.');
  }
}
