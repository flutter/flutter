// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'base/file_system.dart';
import 'base/platform.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'cache.dart';
import 'globals.dart' as globals;

enum Artifact {
  /// The tool which compiles a dart kernel file into native code.
  genSnapshot,
  /// The flutter tester binary.
  flutterTester,
  flutterFramework,
  /// The framework directory of the macOS desktop.
  flutterMacOSFramework,
  vmSnapshotData,
  isolateSnapshotData,
  icuData,
  platformKernelDill,
  platformLibrariesJson,
  flutterPatchedSdkPath,
  frontendServerSnapshotForEngineDartSdk,
  /// The root directory of the dart SDK.
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
  /// The libraries JSON file for web release builds.
  flutterWebLibrariesJson,
  /// The summary dill for the dartdevc target.
  webPlatformKernelDill,
  /// The summary dill with null safety enabled for the dartdevc target.
  webPlatformSoundKernelDill,
  /// The precompiled SDKs and sourcemaps for web debug builds.
  webPrecompiledSdk,
  webPrecompiledSdkSourcemaps,
  webPrecompiledCanvaskitSdk,
  webPrecompiledCanvaskitSdkSourcemaps,
  webPrecompiledSoundSdk,
  webPrecompiledSoundSdkSourcemaps,
  webPrecompiledCanvaskitSoundSdk,
  webPrecompiledCanvaskitSoundSdkSourcemaps,

  iosDeploy,
  idevicesyslog,
  idevicescreenshot,
  iproxy,
  /// The root of the Linux desktop sources.
  linuxDesktopPath,
  // The root of the cpp headers for Linux desktop.
  linuxHeaders,
  /// The root of the Windows desktop sources.
  windowsDesktopPath,
  /// The root of the cpp client code for Windows desktop.
  windowsCppClientWrapper,
  /// The root of the sky_engine package.
  skyEnginePath,
  /// The location of the macOS engine podspec file.
  flutterMacOSPodspec,

  // Fuchsia artifacts from the engine prebuilts.
  fuchsiaKernelCompiler,
  fuchsiaFlutterRunner,

  /// Tools related to subsetting or icon font files.
  fontSubset,
  constFinder,
}

String _artifactToFileName(Artifact artifact, [ TargetPlatform platform, BuildMode mode ]) {
  final String exe = platform == TargetPlatform.windows_x64 ? '.exe' : '';
  switch (artifact) {
    case Artifact.genSnapshot:
      return 'gen_snapshot';
    case Artifact.flutterTester:
      return 'flutter_tester$exe';
    case Artifact.flutterFramework:
      return 'Flutter.framework';
    case Artifact.flutterMacOSFramework:
      return 'FlutterMacOS.framework';
    case Artifact.vmSnapshotData:
      return 'vm_isolate_snapshot.bin';
    case Artifact.isolateSnapshotData:
      return 'isolate_snapshot.bin';
    case Artifact.icuData:
      return 'icudtl.dat';
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
      return 'dart$exe';
    case Artifact.dart2jsSnapshot:
      return 'dart2js.dart.snapshot';
    case Artifact.dartdevcSnapshot:
      return 'dartdevc.dart.snapshot';
    case Artifact.kernelWorkerSnapshot:
      return 'kernel_worker.dart.snapshot';
    case Artifact.iosDeploy:
      return 'ios-deploy';
    case Artifact.idevicesyslog:
      return 'idevicesyslog';
    case Artifact.idevicescreenshot:
      return 'idevicescreenshot';
    case Artifact.iproxy:
      return 'iproxy';
    case Artifact.linuxDesktopPath:
      return '';
    case Artifact.linuxHeaders:
      return 'flutter_linux';
    case Artifact.windowsDesktopPath:
      return '';
    case Artifact.windowsCppClientWrapper:
      return 'cpp_client_wrapper';
    case Artifact.skyEnginePath:
      return 'sky_engine';
    case Artifact.flutterMacOSPodspec:
      return 'FlutterMacOS.podspec';
    case Artifact.webPlatformKernelDill:
      return 'flutter_ddc_sdk.dill';
    case Artifact.webPlatformSoundKernelDill:
      return 'flutter_ddc_sdk_sound.dill';
    case Artifact.fuchsiaKernelCompiler:
      return 'kernel_compiler.snapshot';
    case Artifact.fuchsiaFlutterRunner:
      final String jitOrAot = mode.isJit ? '_jit' : '_aot';
      final String productOrNo = mode.isRelease ? '_product' : '';
      return 'flutter$jitOrAot${productOrNo}_runner-0.far';
    case Artifact.fontSubset:
      return 'font-subset$exe';
    case Artifact.constFinder:
      return 'const_finder.dart.snapshot';
    case Artifact.flutterWebLibrariesJson:
      return 'libraries.json';
    case Artifact.webPrecompiledSdk:
    case Artifact.webPrecompiledCanvaskitSdk:
    case Artifact.webPrecompiledSoundSdk:
    case Artifact.webPrecompiledCanvaskitSoundSdk:
      return 'dart_sdk.js';
    case Artifact.webPrecompiledSdkSourcemaps:
    case Artifact.webPrecompiledCanvaskitSdkSourcemaps:
    case Artifact.webPrecompiledSoundSdkSourcemaps:
    case Artifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
      return 'dart_sdk.js.map';
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
  /// A test-specific implementation of artifacts that returns stable paths for
  /// all artifacts.
  @visibleForTesting
  factory Artifacts.test() = _TestArtifacts;

  static LocalEngineArtifacts getLocalEngine(EngineBuildPaths engineBuildPaths) {
    return LocalEngineArtifacts(
      engineBuildPaths.targetEngine,
      engineBuildPaths.hostEngine,
      cache: globals.cache,
      fileSystem: globals.fs,
      processManager: globals.processManager,
      platform: globals.platform,
    );
  }

  // Returns the requested [artifact] for the [platform] and [mode] combination.
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode });

  // Returns which set of engine artifacts is currently used for the [platform]
  // and [mode] combination.
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]);

  /// Whether these artifacts correspond to a non-versioned local engine.
  bool get isLocalEngine;
}


/// Manages the engine artifacts downloaded to the local cache.
class CachedArtifacts implements Artifacts {
  CachedArtifacts({
    @required FileSystem fileSystem,
    @required Platform platform,
    @required Cache cache,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _cache = cache;

  final FileSystem _fileSystem;
  final Platform _platform;
  final Cache _cache;

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
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
        return _getDesktopArtifactPath(artifact, platform, mode);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
        return _getFuchsiaArtifactPath(artifact, platform, mode);
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      default: // could be null, but that can't be specified as a case.
        return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform(_platform), mode);
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) {
    return _fileSystem.path.basename(_getEngineArtifactsPath(platform, mode));
  }

  String _getDesktopArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    // When platform is null, a generic host platform artifact is being requested
    // and not the gen_snapshot for darwin as a target platform.
    if (platform != null && artifact == Artifact.genSnapshot) {
      final String engineDir = _getEngineArtifactsPath(platform, mode);
      return _fileSystem.path.join(engineDir, _artifactToFileName(artifact));
    }
    return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform(_platform), mode);
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode);
    switch (artifact) {
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        return _fileSystem.path.join(engineDir, _artifactToFileName(artifact));
      case Artifact.genSnapshot:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        return _fileSystem.path.join(engineDir, hostPlatform, _artifactToFileName(artifact));
      default:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getIosArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.flutterFramework:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        final String artifactFileName = _artifactToFileName(artifact);
        final String engineDir = _getEngineArtifactsPath(platform, mode);
        return _fileSystem.path.join(engineDir, artifactFileName);
      case Artifact.idevicescreenshot:
      case Artifact.idevicesyslog:
        final String artifactFileName = _artifactToFileName(artifact);
        return _cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName).path;
      case Artifact.iosDeploy:
        final String artifactFileName = _artifactToFileName(artifact);
        return _cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName).path;
      case Artifact.iproxy:
        final String artifactFileName = _artifactToFileName(artifact);
        return _cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName).path;
      default:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getFuchsiaArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String root = _fileSystem.path.join(
      _cache.getArtifactDirectory('flutter_runner').path,
      'flutter',
      fuchsiaArchForTargetPlatform(platform),
      mode.isRelease ? 'release' : mode.toString(),
    );
    final String runtime = mode.isJit ? 'jit' : 'aot';
    switch (artifact) {
      case Artifact.genSnapshot:
        final String genSnapshot = mode.isRelease ? 'gen_snapshot_product' : 'gen_snapshot';
        return _fileSystem.path.join(root, runtime, 'dart_binaries', genSnapshot);
      case Artifact.flutterPatchedSdkPath:
        const String artifactFileName = 'flutter_runner_patched_sdk';
        return _fileSystem.path.join(root, runtime, artifactFileName);
      case Artifact.platformKernelDill:
        final String artifactFileName = _artifactToFileName(artifact, platform, mode);
        return _fileSystem.path.join(root, runtime, 'flutter_runner_patched_sdk', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String artifactFileName = _artifactToFileName(artifact, platform, mode);
        return _fileSystem.path.join(root, runtime, 'dart_binaries', artifactFileName);
      case Artifact.fuchsiaFlutterRunner:
        final String artifactFileName = _artifactToFileName(artifact, platform, mode);
        return _fileSystem.path.join(root, runtime, artifactFileName);
      default:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getFlutterPatchedSdkPath(BuildMode mode) {
    final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
    return _fileSystem.path.join(engineArtifactsPath, 'common',
        mode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getFlutterWebSdkPath() {
    return _cache.getWebSdkDirectory().path;
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
      case Artifact.icuData:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        final String platformDirName = getNameForTargetPlatform(platform);
        return _fileSystem.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, platform, mode));
      case Artifact.engineDartSdkPath:
        return _dartSdkPath(_fileSystem);
      case Artifact.engineDartBinary:
        return _fileSystem.path.join(_dartSdkPath(_fileSystem), 'bin', _artifactToFileName(artifact, platform));
      case Artifact.platformKernelDill:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), _artifactToFileName(artifact));
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', _artifactToFileName(artifact));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath(mode);
      case Artifact.flutterWebSdk:
        return _getFlutterWebSdkPath();
      case Artifact.flutterWebLibrariesJson:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), _artifactToFileName(artifact));
      case Artifact.webPlatformKernelDill:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
      case Artifact.webPlatformSoundKernelDill:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
      case Artifact.dart2jsSnapshot:
        return _fileSystem.path.join(_dartSdkPath(_fileSystem), 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.dartdevcSnapshot:
        return _fileSystem.path.join(_dartSdkPath(_fileSystem), 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.kernelWorkerSnapshot:
        return _fileSystem.path.join(_dartSdkPath(_fileSystem), 'bin', 'snapshots', _artifactToFileName(artifact));
      case Artifact.flutterMacOSFramework:
      case Artifact.linuxDesktopPath:
      case Artifact.windowsDesktopPath:
      case Artifact.flutterMacOSPodspec:
      case Artifact.linuxHeaders:
        // TODO(jonahwilliams): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        String platformDirName = getNameForTargetPlatform(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${getNameForBuildMode(mode)}';
        }
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _fileSystem.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, platform, mode));
      case Artifact.windowsCppClientWrapper:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _fileSystem.path.join(engineArtifactsPath, 'windows-x64', _artifactToFileName(artifact, platform, mode));
      case Artifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        return _fileSystem.path.join(dartPackageDirectory.path,  _artifactToFileName(artifact));
      case Artifact.fontSubset:
      case Artifact.constFinder:
        return _cache.getArtifactDirectory('engine')
                     .childDirectory(getNameForTargetPlatform(platform))
                     .childFile(_artifactToFileName(artifact, platform, mode))
                     .path;
      case Artifact.webPrecompiledSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledCanvaskitSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledCanvaskitSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledSoundSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledSoundSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledCanvaskitSoundSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', _artifactToFileName(artifact, platform, mode));
      case Artifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', _artifactToFileName(artifact, platform, mode));
      default:
        assert(false, 'Artifact $artifact not available for platform $platform.');
        return null;
    }
  }

  String _getEngineArtifactsPath(TargetPlatform platform, [ BuildMode mode ]) {
    final String engineDir = _cache.getArtifactDirectory('engine').path;
    final String platformName = getNameForTargetPlatform(platform);
    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.windows_x64:
        // TODO(jonahwilliams): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        if (mode == BuildMode.debug || mode == null) {
          return _fileSystem.path.join(engineDir, platformName);
        }
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(getModeName(mode), '-')}' : '';
        return _fileSystem.path.join(engineDir, platformName + suffix);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
        assert(mode == null, 'Platform $platform does not support different build modes.');
        return _fileSystem.path.join(engineDir, platformName);
      case TargetPlatform.ios:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        assert(mode != null, 'Need to specify a build mode for platform $platform.');
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(getModeName(mode), '-')}' : '';
        return _fileSystem.path.join(engineDir, platformName + suffix);
      case TargetPlatform.android:
        assert(false, 'cannot use TargetPlatform.android to look up artifacts');
        return null;
    }
    assert(false, 'Invalid platform $platform.');
    return null;
  }

  @override
  bool get isLocalEngine => false;
}

TargetPlatform _currentHostPlatform(Platform platform) {
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

HostPlatform _currentHostPlatformAsHost(Platform platform) {
  if (platform.isMacOS) {
    return HostPlatform.darwin_x64;
  }
  if (platform.isLinux) {
    return HostPlatform.linux_x64;
  }
  if (platform.isWindows) {
    return HostPlatform.windows_x64;
  }
  throw UnimplementedError('Host OS not supported.');
}

/// Manages the artifacts of a locally built engine.
class LocalEngineArtifacts implements Artifacts {
  LocalEngineArtifacts(
    this.engineOutPath,
    this._hostEngineOutPath, {
    @required FileSystem fileSystem,
    @required Cache cache,
    @required ProcessManager processManager,
    @required Platform platform,
  }) : _fileSystem = fileSystem,
       _cache = cache,
       _processManager = processManager,
       _platform = platform;

  final String engineOutPath; // TODO(goderbauer): This should be private.
  final String _hostEngineOutPath;
  final FileSystem _fileSystem;
  final Cache _cache;
  final ProcessManager _processManager;
  final Platform _platform;

  @override
  String getArtifactPath(Artifact artifact, { TargetPlatform platform, BuildMode mode }) {
    platform ??= _currentHostPlatform(_platform);
    final String artifactFileName = _artifactToFileName(artifact, platform, mode);
    switch (artifact) {
      case Artifact.genSnapshot:
        return _genSnapshotPath();
      case Artifact.flutterTester:
        return _flutterTesterPath(platform);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return _fileSystem.path.join(engineOutPath, 'gen', 'flutter', 'lib', 'snapshot', artifactFileName);
      case Artifact.icuData:
        return _fileSystem.path.join(engineOutPath, artifactFileName);
      case Artifact.platformKernelDill:
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(engineOutPath, 'flutter_runner_patched_sdk', artifactFileName);
        }
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), artifactFileName);
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', artifactFileName);
      case Artifact.flutterFramework:
        return _fileSystem.path.join(engineOutPath, artifactFileName);
      case Artifact.flutterMacOSFramework:
        return _fileSystem.path.join(engineOutPath, artifactFileName);
      case Artifact.flutterPatchedSdkPath:
        // When using local engine always use [BuildMode.debug] regardless of
        // what was specified in [mode] argument because local engine will
        // have only one flutter_patched_sdk in standard location, that
        // is happen to be what debug(non-release) mode is using.
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(engineOutPath, 'flutter_runner_patched_sdk');
        }
        return _getFlutterPatchedSdkPath(BuildMode.debug);
      case Artifact.flutterWebSdk:
        return _getFlutterWebSdkPath();
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', artifactFileName);
      case Artifact.engineDartSdkPath:
        return _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk');
      case Artifact.engineDartBinary:
        return _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', artifactFileName);
      case Artifact.dart2jsSnapshot:
        return _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', 'snapshots', artifactFileName);
      case Artifact.dartdevcSnapshot:
        return _fileSystem.path.join(_dartSdkPath(_fileSystem), 'bin', 'snapshots', artifactFileName);
      case Artifact.kernelWorkerSnapshot:
        return _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk', 'bin', 'snapshots', artifactFileName);
      case Artifact.idevicescreenshot:
      case Artifact.idevicesyslog:
        return _cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName).path;
      case Artifact.iosDeploy:
        return _cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName).path;
      case Artifact.iproxy:
        return _cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName).path;
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.windowsDesktopPath:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.windowsCppClientWrapper:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.skyEnginePath:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', 'dart-pkg', artifactFileName);
      case Artifact.flutterMacOSPodspec:
        return _fileSystem.path.join(_hostEngineOutPath, _artifactToFileName(artifact));
      case Artifact.webPlatformKernelDill:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
      case Artifact.webPlatformSoundKernelDill:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _artifactToFileName(artifact));
      case Artifact.fuchsiaKernelCompiler:
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        final String modeName = mode.isRelease ? 'release' : mode.toString();
        final String dartBinaries = 'dart_binaries-$modeName-$hostPlatform';
        return _fileSystem.path.join(engineOutPath, 'host_bundle', dartBinaries, 'kernel_compiler.dart.snapshot');
      case Artifact.fuchsiaFlutterRunner:
        final String jitOrAot = mode.isJit ? '_jit' : '_aot';
        final String productOrNo = mode.isRelease ? '_product' : '';
        return _fileSystem.path.join(engineOutPath, 'flutter$jitOrAot${productOrNo}_runner-0.far');
      case Artifact.fontSubset:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.constFinder:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', artifactFileName);
      case Artifact.flutterWebLibrariesJson:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), artifactFileName);
      case Artifact.webPrecompiledSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', artifactFileName);
      case Artifact.webPrecompiledSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', artifactFileName);
      case Artifact.webPrecompiledCanvaskitSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', artifactFileName);
      case Artifact.webPrecompiledCanvaskitSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', artifactFileName);
      case Artifact.webPrecompiledSoundSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', artifactFileName);
      case Artifact.webPrecompiledSoundSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', artifactFileName);
      case Artifact.webPrecompiledCanvaskitSoundSdk:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', artifactFileName);
      case Artifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
        return _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', artifactFileName);
    }
    assert(false, 'Invalid artifact $artifact.');
    return null;
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) {
    return _fileSystem.path.basename(engineOutPath);
  }

  String _getFlutterPatchedSdkPath(BuildMode buildMode) {
    return _fileSystem.path.join(engineOutPath,
        buildMode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getFlutterWebSdkPath() {
    return _fileSystem.path.join(engineOutPath, 'flutter_web_sdk');
  }

  String _genSnapshotPath() {
    const List<String> clangDirs = <String>['.', 'clang_x64', 'clang_x86', 'clang_i386'];
    final String genSnapshotName = _artifactToFileName(Artifact.genSnapshot);
    for (final String clangDir in clangDirs) {
      final String genSnapshotPath = _fileSystem.path.join(engineOutPath, clangDir, genSnapshotName);
      if (_processManager.canRun(genSnapshotPath)) {
        return genSnapshotPath;
      }
    }
    throw Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    final HostPlatform hostPlatform = _currentHostPlatformAsHost(_platform);
    if (hostPlatform == HostPlatform.linux_x64) {
      return _fileSystem.path.join(engineOutPath, _artifactToFileName(Artifact.flutterTester));
    } else if (hostPlatform == HostPlatform.darwin_x64) {
      return _fileSystem.path.join(engineOutPath, 'flutter_tester');
    } else if (hostPlatform == HostPlatform.windows_x64) {
      return _fileSystem.path.join(engineOutPath, 'flutter_tester.exe');
    }
    throw Exception('Unsupported platform $platform.');
  }

  @override
  bool get isLocalEngine => true;
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

  @override
  bool get isLocalEngine => parent.isLocalEngine;
}

/// Locate the Dart SDK.
String _dartSdkPath(FileSystem fileSystem) {
  return fileSystem.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk');
}

class _TestArtifacts implements Artifacts {
  @override
  String getArtifactPath(Artifact artifact, {TargetPlatform platform, BuildMode mode}) {
    final StringBuffer buffer = StringBuffer();
    buffer.write(artifact);
    if (platform != null) {
      buffer.write('.$platform');
    }
    if (mode != null) {
      buffer.write('.$mode');
    }
    return buffer.toString();
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode mode ]) {
    return 'test-engine';
  }

  @override
  bool get isLocalEngine => false;
}
