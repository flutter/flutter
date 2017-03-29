// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'build_info.dart';
import 'globals.dart';

enum Artifact {
  icudtlDat,
  libskyShellSo,
  dartIoEntriesTxt,
  dartVmEntryPointsTxt,
  dartVmEntryPointsAndroidTxt,
  genSnapshot,
  skyShell,
  snapshotDart,
  flutterFramework,
  vmSnapshotData,
  isolateSnapshotData
}

String _artifactToFileName(Artifact artifact) {
  switch (artifact) {
    case Artifact.icudtlDat:
      return 'icudtl.dat';
    case Artifact.libskyShellSo:
      return 'libsky_shell.so';
    case Artifact.dartIoEntriesTxt:
      return 'dart_io_entries.txt';
    case Artifact.dartVmEntryPointsTxt:
      return 'dart_vm_entry_points.txt';
    case Artifact.dartVmEntryPointsAndroidTxt:
      return 'dart_vm_entry_points_android.txt';
    case Artifact.genSnapshot:
      return 'gen_snapshot';
    case Artifact.skyShell:
      return 'flutter_tester';
    case Artifact.snapshotDart:
      return 'snapshot.dart';
    case Artifact.flutterFramework:
      return 'Flutter.framework';
    case Artifact.vmSnapshotData:
      return 'vm_isolate_snapshot.bin';
    case Artifact.isolateSnapshotData:
      return 'isolate_snapshot.bin';
  }
  assert(false, 'Invalid artifact $artifact.');
  return null;
}

// Manages the engine artifacts of Flutter.
abstract class Artifacts {
  static Artifacts get instance => context[Artifacts];

  static void useLocalEngine(String engineSrcPath, String engineOutPath) {
    context.setVariable(Artifacts, new LocalEngineArtifacts(engineSrcPath, engineOutPath));
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
  String getEngineType(TargetPlatform platform, [BuildMode mode]){
    return fs.path.basename(_getEngineArtifactsPath(platform, mode));
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode);
    switch (artifact) {
      case Artifact.icudtlDat:
      case Artifact.libskyShellSo:
        return fs.path.join(engineDir, _artifactToFileName(artifact));
      case Artifact.dartIoEntriesTxt:
      case Artifact.dartVmEntryPointsTxt:
      case Artifact.dartVmEntryPointsAndroidTxt:
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
      case Artifact.genSnapshot:
      case Artifact.snapshotDart:
      case Artifact.flutterFramework:
        return fs.path.join(engineDir, _artifactToFileName(artifact));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getHostArtifactPath(Artifact artifact, TargetPlatform platform) {
    switch (artifact) {
      case Artifact.genSnapshot:
        // For script snapshots any gen_snapshot binary will do. Returning gen_snapshot for
        // android_arm in profile mode because it is available on all supported host platforms.
        return _getAndroidArtifactPath(artifact, TargetPlatform.android_arm, BuildMode.profile);
      case Artifact.skyShell:
        if (platform == TargetPlatform.windows_x64)
          throw new UnimplementedError('Artifact $artifact not available on platfrom $platform.');
        continue fallThrough;
      fallThrough:
      case Artifact.vmSnapshotData:
      case Artifact.isolateSnapshotData:
      case Artifact.icudtlDat:
        final String engineArtifactsPath = cache.getArtifactDirectory('engine').path;
        final String platformDirName = getNameForTargetPlatform(platform);
        return fs.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
    assert(false, 'Artifact $artifact not available for platform $platform.');
    return null;
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

  LocalEngineArtifacts(this._engineSrcPath, this.engineOutPath);

  @override
  String getArtifactPath(Artifact artifact, [TargetPlatform platform, BuildMode mode]) {
    switch (artifact) {
      case Artifact.dartIoEntriesTxt:
        return fs.path.join(_engineSrcPath, 'dart', 'runtime', 'bin', _artifactToFileName(artifact));
      case Artifact.dartVmEntryPointsTxt:
      case Artifact.dartVmEntryPointsAndroidTxt:
        return fs.path.join(_engineSrcPath, 'flutter', 'runtime', _artifactToFileName(artifact));
      case Artifact.snapshotDart:
        return fs.path.join(_engineSrcPath, 'flutter', 'lib', 'snapshot', _artifactToFileName(artifact));
      case Artifact.libskyShellSo:
        final String abi = _getAbiDirectory(platform);
        return fs.path.join(engineOutPath, 'gen', 'flutter', 'shell', 'platform', 'android', 'android', fs.path.join('android', 'libs', abi, _artifactToFileName(artifact)));
      case Artifact.genSnapshot:
        return _genSnapshotPath(platform, mode);
      case Artifact.skyShell:
        return _skyShellPath(platform);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return fs.path.join(engineOutPath, 'gen', 'flutter', 'lib', 'snapshot', _artifactToFileName(artifact));
      case Artifact.icudtlDat:
      case Artifact.flutterFramework:
        return fs.path.join(engineOutPath, _artifactToFileName(artifact));
    }
    assert(false, 'Invalid artifact $artifact.');
    return null;
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode mode]) {
    return fs.path.basename(engineOutPath);
  }

  String _genSnapshotPath(TargetPlatform platform, BuildMode mode) {
    String clang;
    if (platform == TargetPlatform.ios || mode == BuildMode.debug) {
      clang = 'clang_x64';
    } else {
      clang = getCurrentHostPlatform() == HostPlatform.darwin_x64 ? 'clang_i386' : 'clang_x86';
    }
    return fs.path.join(engineOutPath, clang, _artifactToFileName(Artifact.genSnapshot));
  }

  String _skyShellPath(TargetPlatform platform) {
    if (getCurrentHostPlatform() == HostPlatform.linux_x64) {
      return fs.path.join(engineOutPath, _artifactToFileName(Artifact.skyShell));
    } else if (getCurrentHostPlatform() == HostPlatform.darwin_x64) {
      return fs.path.join(engineOutPath, 'SkyShell.app', 'Contents', 'MacOS', 'SkyShell');
    }
    throw new Exception('Unsupported platform $platform.');
  }

  String _getAbiDirectory(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android_arm:
        return 'armeabi-v7a';
      case TargetPlatform.android_x64:
        return 'x86_64';
      case TargetPlatform.android_x86:
        return 'x86';
      default:
        throw new Exception('Unsupported platform $platform.');
    }
  }
}
