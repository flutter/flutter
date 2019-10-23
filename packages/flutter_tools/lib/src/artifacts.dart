// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/platform.dart';
import 'base/process_manager.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'dart/sdk.dart';
import 'globals.dart';

enum Artifact {
  /// The tool which compiles a dart kernel file into native code.
  genSnapshot,
  /// The flutter tester binary.
  flutterTester,
  snapshotDart,
  flutterFramework,
  /// The framework directory of the macOS desktop.
  flutterMacOSFramework,
  vmSnapshotData,
  isolateSnapshotData,
  platformKernelDill,
  platformLibrariesJson,
  flutterPatchedSdkPath,
  frontendServerSnapshotForEngineDartSdk,
  /// The root directory of the dartk SDK.
  engineDartSdkPath,
  /// The dart binary used to execute any of the required snapshots.
  engineDartBinary,
  /// The dart snapshot of the dart2js compiler.
  dart2jsSnapshot,
  /// The dart snapshot of the dartdev compiler.
  dartdevcSnapshot,
  /// The dart snpashot of the kernel worker compiler.
  kernelWorkerSnapshot,
  /// The root of the web implementation of the dart SDK.
  flutterWebSdk,
  /// The summary dill for the dartdevc target.
  webPlatformKernelDill,
  iosDeploy,
  ideviceinfo,
  ideviceId,
  idevicename,
  idevicesyslog,
  idevicescreenshot,
  ideviceinstaller,
  iproxy,
  /// The root of the Linux desktop sources.
  linuxDesktopPath,
  /// The root of the Windows desktop sources.
  windowsDesktopPath,
  /// The root of the sky_engine package
  skyEnginePath,
  /// The location of the macOS engine podspec file.
  flutterMacOSPodspec,
}

String _artifactToFileName(Artifact artifact, [ TargetPlatform platform, BuildMode mode ]) {
  switch (artifact) {
    case Artifact.genSnapshot:
      return 'gen_snapshot';
    case Artifact.flutterTester:
      if (platform == TargetPlatform.windows_x64) {
        return 'flutter_tester.exe';
      }
      return 'flutter_tester';
    case Artifact.snapshotDart:
      return 'snapshot.dart';
    case Artifact.flutterFramework:
      return 'Flutter.framework';
    case Artifact.flutterMacOSFramework:
      return 'FlutterMacOS.framework';
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
    case Artifact.flutterWebSdk:
      assert(false, 'No filename for web sdk path, should not be invoked');
      return null;
    case Artifact.engineDartSdkPath:
      return 'dart-sdk';
    case Artifact.frontendServerSnapshotForEngineDartSdk:
      return 'frontend_server.dart.snapshot';
    case Artifact.engineDartBinary:
      if (platform == TargetPlatform.windows_x64) {
        return 'dart.exe';
      }
      return 'dart';
    case Artifact.dart2jsSnapshot:
      return 'dart2js.dart.snapshot';
    case Artifact.dartdevcSnapshot:
      return 'dartdevc.dart.snapshot';
    case Artifact.kernelWorkerSnapshot:
      return 'kernel_worker.dart.snapshot';
    case Artifact.iosDeploy:
      return 'ios-deploy';
    case Artifact.ideviceinfo:
      return 'ideviceinfo';
    case Artifact.ideviceId:
      return 'idevice_id';
    case Artifact.idevicename:
      return 'idevicename';
    case Artifact.idevicesyslog:
      return 'idevicesyslog';
    case Artifact.idevicescreenshot:
      return 'idevicescreenshot';
    case Artifact.ideviceinstaller:
      return 'ideviceinstaller';
    case Artifact.iproxy:
      return 'iproxy';
    case Artifact.linuxDesktopPath:
      return '';
    case Artifact.windowsDesktopPath:
      return '';
    case Artifact.skyEnginePath:
      return 'sky_engine';
    case Artifact.flutterMacOSPodspec:
      return 'FlutterMacOS.podspec';
    case Artifact.webPlatformKernelDill:
      return 'flutter_ddc_sdk.dill';
  }
  assert(false, 'Invalid artifact $artifact.');
  return null;
}

class EngineBuildPaths {
  const EngineBuildPaths({
    @required this.targetEngine,
    @required this.hostEngine,
  }) : assert(targetEngine != null),
       assert(hostEngine != null);

  final String targetEngine;
  final String hostEngine;
}

// Manages the engine artifacts of Flutter.
abstract class Artifacts {
  static Artifacts get instance => context.get<Artifacts>();

  static LocalEngineArtifacts getLocalEngine(String engineSrcPath, EngineBuildPaths engineBuildPaths) {
    return LocalEngineArtifacts(engineSrcPath, engineBuildPaths.targetEngine, engineBuildPaths.hostEngine);
  }

  // Returns the requested [artifact] for the [platform] and [mode] combination.
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode });

  // Returns which set of engine artifacts is currently used for the [platform]
  // and [mode] combination.
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]);
}

TargetPlatform get _currentHostPlatform {
  if (platform.isMacOS) {
    return TargetPlatform.darwin_x64;
  }
  if (platform.isLinux) {
    return TargetPlatform.linux_x64;
  }
  if (platform.isWindows) {
    return TargetPlatform.windows_x64;
  }
  throw UnimplementedError('Host OS not supported.');
}

/// Manages the engine artifacts downloaded to the local cache.
class CachedArtifacts extends Artifacts {

  @override
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode }) {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        return _getAndroidArtifactPath(artifact, platform, mode);
      case TargetPlatform.ios:
        return _getIosArtifactPath(artifact, platform, mode);
      case TargetPlatform.darwin_x64:
        return _getDarwinArtifactPath(artifact, platform, mode);
      case TargetPlatform.linux_x64:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      default: // could be null, but that can't be specified as a case.
        return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform, mode);
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) {
    return fs.path.basename(_getEngineArtifactsPath(platform, mode));
  }

  String _getDarwinArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    // When platform is null, a generic host platform artifact is being requested
    // and not the gen_snapshot for darwin as a target platform.
    if (platform != null && artifact == Artifact.genSnapshot) {
      final String engineDir = _getEngineArtifactsPath(platform, mode);
      return fs.path.join(engineDir, _artifactToFileName(artifact));
    }
    return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform, mode);
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode);
    switch (artifact) {
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
    final String artifactFileName = _artifactToFileName(artifact);
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.snapshotDart:
      case Artifact.flutterFramework:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        final String engineDir = _getEngineArtifactsPath(platform, mode);
        return fs.path.join(engineDir, artifactFileName);
      case Artifact.ideviceId:
      case Artifact.ideviceinfo:
      case Artifact.idevicescreenshot:
      case Artifact.idevicesyslog:
      case Artifact.idevicename:
        return cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName).path;
      case Artifact.iosDeploy:
        return cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName).path;
      case Artifact.ideviceinstaller:
        return cache.getArtifactDirectory('ideviceinstaller').childFile(artifactFileName).path;
      case Artifact.iproxy:
        return cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName).path;
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getFlutterPatchedSdkPath(BuildMode mode) {
    final String engineArtifactsPath = cache.getArtifactDirectory('engine').path;
    return fs.path.join(engineArtifactsPath, 'common',
        mode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getFlutterWebSdkPath() {
    return cache.getWebSdkDirectory().path;
  }

  String _getHostArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    assert(platform != null);
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
        return fs.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, platform, mode));
      case Artifact.engineDartSdkPath:
        return dartSdkPath;
      case Artifact.engineDartBinary:
        return fs.path.join(dartSdkPath, 'bin', _artifactToFileName(artifact, platform));
      case Artifact.platformKernelDill:
        return fs.path.join(_getFlutterPatchedSdkPath(mode), _artifactToFileName(artifact));
      case Artifact.platformLibrariesJson:
        return fs.path.join(_getFlutterPatchedSdkPath(mode), 'lib', _artifactToFileName(artifact));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath(mode);
      case Artifact.flutterWebSdk:
        return _getFlutterWebSdkPath();
      case Artifact.webPlatformKernelDill:
        return fs.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
      case Artifact.dart2jsSnapshot:
        return fs.path.join(dartSdkPath, 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.dartdevcSnapshot:
        return fs.path.join(dartSdkPath, 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.kernelWorkerSnapshot:
        return fs.path.join(dartSdkPath, 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.flutterMacOSFramework:
      case Artifact.linuxDesktopPath:
      case Artifact.windowsDesktopPath:
      case Artifact.flutterMacOSPodspec:
        // TODO(jonahwilliams): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        String platformDirName = getNameForTargetPlatform(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${getNameForBuildMode(mode)}';
        }
        final String engineArtifactsPath = cache.getArtifactDirectory('engine').path;
        return fs.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, platform, mode));
      case Artifact.skyEnginePath:
        final Directory dartPackageDirectory = cache.getCacheDir('pkg');
        return fs.path.join(dartPackageDirectory.path,  _artifactToFileName(artifact));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getEngineArtifactsPath(TargetPlatform platform, [ BuildMode mode ]) {
    final String engineDir = cache.getArtifactDirectory('engine').path;
    final String platformName = getNameForTargetPlatform(platform);
    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.windows_x64:
        // TODO(jonahwilliams): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        if (mode == BuildMode.debug || mode == null) {
          return fs.path.join(engineDir, platformName);
        }
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(getModeName(mode), '-')}' : '';
        return fs.path.join(engineDir, platformName + suffix);
      case TargetPlatform.fuchsia:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
        assert(mode == null, 'Platform $platform does not support different build modes.');
        return fs.path.join(engineDir, platformName);
      case TargetPlatform.ios:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        assert(mode != null, 'Need to specify a build mode for platform $platform.');
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(getModeName(mode), '-')}' : '';
        return fs.path.join(engineDir, platformName + suffix);
    }
    assert(false, 'Invalid platform $platform.');
    return null;
  }
}

/// Manages the artifacts of a locally built engine.
class LocalEngineArtifacts extends Artifacts {
  LocalEngineArtifacts(this._engineSrcPath, this.engineOutPath, this._hostEngineOutPath);

  final String _engineSrcPath;
  final String engineOutPath; // TODO(goderbauer): This should be private.
  final String _hostEngineOutPath;

  @override
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode }) {
    platform ??= _currentHostPlatform;
    final String artifactFileName = _artifactToFileName(artifact, platform);
    switch (artifact) {
      case Artifact.snapshotDart:
        return fs.path.join(_engineSrcPath, 'flutter', 'lib', 'snapshot', artifactFileName);
      case Artifact.genSnapshot:
        return _genSnapshotPath();
      case Artifact.flutterTester:
        return _flutterTesterPath(platform);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return fs.path.join(engineOutPath, 'gen', 'flutter', 'lib', 'snapshot', artifactFileName);
      case Artifact.platformKernelDill:
        return fs.path.join(_getFlutterPatchedSdkPath(mode), artifactFileName);
      case Artifact.platformLibrariesJson:
        return fs.path.join(_getFlutterPatchedSdkPath(mode), 'lib', artifactFileName);
      case Artifact.flutterFramework:
        return fs.path.join(engineOutPath, artifactFileName);
      case Artifact.flutterMacOSFramework:
        return fs.path.join(engineOutPath, artifactFileName);
      case Artifact.flutterPatchedSdkPath:
        // When using local engine always use [BuildMode.debug] regardless of
        // what was specified in [mode] argument because local engine will
        // have only one flutter_patched_sdk in standard location, that
        // is happen to be what debug(non-release) mode is using.
        return _getFlutterPatchedSdkPath(BuildMode.debug);
      case Artifact.flutterWebSdk:
        return _getFlutterWebSdkPath();
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return fs.path.join(_hostEngineOutPath, 'gen', artifactFileName);
      case Artifact.engineDartSdkPath:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk');
      case Artifact.engineDartBinary:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', artifactFileName);
      case Artifact.dart2jsSnapshot:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', 'snapshots', artifactFileName);
      case Artifact.dartdevcSnapshot:
        return fs.path.join(dartSdkPath, 'bin', 'snapshots', artifactFileName);
      case Artifact.kernelWorkerSnapshot:
        return fs.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', 'snapshots', artifactFileName);
      case Artifact.ideviceId:
      case Artifact.ideviceinfo:
      case Artifact.idevicename:
      case Artifact.idevicescreenshot:
      case Artifact.idevicesyslog:
        return cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName).path;
      case Artifact.ideviceinstaller:
        return cache.getArtifactDirectory('ideviceinstaller').childFile(artifactFileName).path;
      case Artifact.iosDeploy:
        return cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName).path;
      case Artifact.iproxy:
        return cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName).path;
      case Artifact.linuxDesktopPath:
        return fs.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.windowsDesktopPath:
        return fs.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.skyEnginePath:
        return fs.path.join(_hostEngineOutPath, 'gen', 'dart-pkg', artifactFileName);
      case Artifact.flutterMacOSPodspec:
        return fs.path.join(_hostEngineOutPath, _artifactToFileName(artifact));
      case Artifact.webPlatformKernelDill:
        return fs.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
    }
    assert(false, 'Invalid artifact $artifact.');
    return null;
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) {
    return fs.path.basename(engineOutPath);
  }

  String _getFlutterPatchedSdkPath(BuildMode buildMode) {
    return fs.path.join(engineOutPath,
        buildMode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getFlutterWebSdkPath() {
    return fs.path.join(engineOutPath, 'flutter_web_sdk');
  }

  String _genSnapshotPath() {
    const List<String> clangDirs = <String>['.', 'clang_x64', 'clang_x86', 'clang_i386'];
    final String genSnapshotName = _artifactToFileName(Artifact.genSnapshot);
    for (String clangDir in clangDirs) {
      final String genSnapshotPath = fs.path.join(engineOutPath, clangDir, genSnapshotName);
      if (processManager.canRun(genSnapshotPath)) {
        return genSnapshotPath;
      }
    }
    throw Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    if (getCurrentHostPlatform() == HostPlatform.linux_x64) {
      return fs.path.join(engineOutPath, _artifactToFileName(Artifact.flutterTester));
    } else if (getCurrentHostPlatform() == HostPlatform.darwin_x64) {
      return fs.path.join(engineOutPath, 'flutter_tester');
    } else if (getCurrentHostPlatform() == HostPlatform.windows_x64) {
      return fs.path.join(engineOutPath, 'flutter_tester.exe');
    }
    throw Exception('Unsupported platform $platform.');
  }
}

/// An implementation of [Artifacts] that provides individual overrides.
///
/// If an artifact is not provided, the lookup delegates to the parent.
class OverrideArtifacts implements Artifacts {
  /// Creates a new [OverrideArtifacts].
  ///
  /// [parent] must be provided.
  OverrideArtifacts({
    @required this.parent,
    this.frontendServer,
    this.engineDartBinary,
    this.platformKernelDill,
    this.flutterPatchedSdk,
  }) : assert(parent != null);

  final Artifacts parent;
  final File frontendServer;
  final File engineDartBinary;
  final File platformKernelDill;
  final File flutterPatchedSdk;

  @override
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode }) {
    if (artifact == Artifact.frontendServerSnapshotForEngineDartSdk && frontendServer != null) {
      return frontendServer.path;
    }
    if (artifact == Artifact.engineDartBinary && engineDartBinary != null) {
      return engineDartBinary.path;
    }
    if (artifact == Artifact.platformKernelDill && platformKernelDill != null) {
      return platformKernelDill.path;
    }
    if (artifact == Artifact.flutterPatchedSdkPath && flutterPatchedSdk != null) {
      return flutterPatchedSdk.path;
    }
    return parent.getArtifactPath(artifact, platform: platform, mode: mode);
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) => parent.getEngineType(platform, mode);
}
