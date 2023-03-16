// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:process/process.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/os.dart';
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
  flutterXcframework,
  /// The framework directory of the macOS desktop.
  flutterMacOSFramework,
  vmSnapshotData,
  isolateSnapshotData,
  icuData,
  platformKernelDill,
  platformLibrariesJson,
  flutterPatchedSdkPath,
  frontendServerSnapshotForEngineDartSdk,
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

  // Fuchsia artifacts from the engine prebuilts.
  fuchsiaKernelCompiler,
  fuchsiaFlutterRunner,

  /// Tools related to subsetting or icon font files.
  fontSubset,
  constFinder,
}

/// A subset of [Artifact]s that are platform and build mode independent
enum HostArtifact {
  /// The root directory of the dart SDK.
  engineDartSdkPath,
  /// The dart binary used to execute any of the required snapshots.
  engineDartBinary,
  /// The dart snapshot of the dart2js compiler.
  dart2jsSnapshot,
  /// The dart snapshot of the dartdev compiler.
  dartdevcSnapshot,
  /// The dart snapshot of the kernel worker compiler.
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
  webPrecompiledCanvaskitAndHtmlSdk,
  webPrecompiledCanvaskitAndHtmlSdkSourcemaps,
  webPrecompiledSoundSdk,
  webPrecompiledSoundSdkSourcemaps,
  webPrecompiledCanvaskitSoundSdk,
  webPrecompiledCanvaskitSoundSdkSourcemaps,
  webPrecompiledCanvaskitAndHtmlSoundSdk,
  webPrecompiledCanvaskitAndHtmlSoundSdkSourcemaps,

  iosDeploy,
  idevicesyslog,
  idevicescreenshot,
  iproxy,

  /// The root of the sky_engine package.
  skyEnginePath,

  // The Impeller shader compiler.
  impellerc,
  // Impeller's tessellation library.
  libtessellator,
}

// TODO(knopp): Remove once darwin artifacts are universal and moved out of darwin-x64
String _enginePlatformDirectoryName(TargetPlatform platform) {
  if (platform == TargetPlatform.darwin) {
    return 'darwin-x64';
  }
  return getNameForTargetPlatform(platform);
}

// Remove android target platform type.
TargetPlatform? _mapTargetPlatform(TargetPlatform? targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.android:
      return TargetPlatform.android_arm64;
    case TargetPlatform.ios:
    case TargetPlatform.darwin:
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.windows_x64:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
    case null:
      return targetPlatform;
  }
}

bool _isWindows(TargetPlatform? platform) {
  switch (platform) {
    case TargetPlatform.windows_x64:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
    case TargetPlatform.darwin:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.ios:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case null:
      return false;
  }
}

String? _artifactToFileName(Artifact artifact, [ TargetPlatform? platform, BuildMode? mode ]) {
  final String exe = _isWindows(platform) ? '.exe' : '';
  switch (artifact) {
    case Artifact.genSnapshot:
      return 'gen_snapshot';
    case Artifact.flutterTester:
      return 'flutter_tester$exe';
    case Artifact.flutterFramework:
      return 'Flutter.framework';
    case Artifact.flutterXcframework:
      return 'Flutter.xcframework';
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
    case Artifact.frontendServerSnapshotForEngineDartSdk:
      return 'frontend_server.dart.snapshot';
    case Artifact.linuxDesktopPath:
      return '';
    case Artifact.linuxHeaders:
      return 'flutter_linux';
    case Artifact.windowsCppClientWrapper:
      return 'cpp_client_wrapper';
    case Artifact.windowsDesktopPath:
      return '';
    case Artifact.skyEnginePath:
      return 'sky_engine';
    case Artifact.fuchsiaKernelCompiler:
      return 'kernel_compiler.snapshot';
    case Artifact.fuchsiaFlutterRunner:
      final String jitOrAot = mode!.isJit ? '_jit' : '_aot';
      final String productOrNo = mode.isRelease ? '_product' : '';
      return 'flutter$jitOrAot${productOrNo}_runner-0.far';
    case Artifact.fontSubset:
      return 'font-subset$exe';
    case Artifact.constFinder:
      return 'const_finder.dart.snapshot';
  }
}

String _hostArtifactToFileName(HostArtifact artifact, Platform platform) {
  final String exe = platform.isWindows ? '.exe' : '';
  String dll = '.so';
  if (platform.isWindows) {
    dll = '.dll';
  } else if (platform.isMacOS) {
    dll = '.dylib';
  }
  switch (artifact) {
    case HostArtifact.flutterWebSdk:
      return '';
    case HostArtifact.engineDartSdkPath:
      return 'dart-sdk';
    case HostArtifact.engineDartBinary:
      return 'dart$exe';
    case HostArtifact.dart2jsSnapshot:
      return 'dart2js.dart.snapshot';
    case HostArtifact.dartdevcSnapshot:
      return 'dartdevc.dart.snapshot';
    case HostArtifact.kernelWorkerSnapshot:
      return 'kernel_worker.dart.snapshot';
    case HostArtifact.iosDeploy:
      return 'ios-deploy';
    case HostArtifact.idevicesyslog:
      return 'idevicesyslog';
    case HostArtifact.idevicescreenshot:
      return 'idevicescreenshot';
    case HostArtifact.iproxy:
      return 'iproxy';
    case HostArtifact.skyEnginePath:
      return 'sky_engine';
    case HostArtifact.webPlatformKernelDill:
      return 'flutter_ddc_sdk.dill';
    case HostArtifact.webPlatformSoundKernelDill:
      return 'flutter_ddc_sdk_sound.dill';
    case HostArtifact.flutterWebLibrariesJson:
      return 'libraries.json';
    case HostArtifact.webPrecompiledSdk:
    case HostArtifact.webPrecompiledCanvaskitSdk:
    case HostArtifact.webPrecompiledCanvaskitAndHtmlSdk:
    case HostArtifact.webPrecompiledSoundSdk:
    case HostArtifact.webPrecompiledCanvaskitSoundSdk:
    case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdk:
      return 'dart_sdk.js';
    case HostArtifact.webPrecompiledSdkSourcemaps:
    case HostArtifact.webPrecompiledCanvaskitSdkSourcemaps:
    case HostArtifact.webPrecompiledCanvaskitAndHtmlSdkSourcemaps:
    case HostArtifact.webPrecompiledSoundSdkSourcemaps:
    case HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
    case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdkSourcemaps:
      return 'dart_sdk.js.map';
    case HostArtifact.impellerc:
      return 'impellerc$exe';
    case HostArtifact.libtessellator:
      return 'libtessellator$dll';
  }
}

class EngineBuildPaths {
  const EngineBuildPaths({
    required this.targetEngine,
    required this.hostEngine,
  }) : assert(targetEngine != null),
       assert(hostEngine != null);

  final String targetEngine;
  final String hostEngine;
}

// Manages the engine artifacts of Flutter.
abstract class Artifacts {
  /// A test-specific implementation of artifacts that returns stable paths for
  /// all artifacts.
  ///
  /// If a [fileSystem] is not provided, creates a new [MemoryFileSystem] instance.
  ///
  /// Creates a [LocalEngineArtifacts] if `localEngine` is non-null
  factory Artifacts.test({String? localEngine, FileSystem? fileSystem}) {
    fileSystem ??= MemoryFileSystem.test();
    if (localEngine != null) {
      return _TestLocalEngine(localEngine, fileSystem);
    }
    return _TestArtifacts(fileSystem);
  }

  static LocalEngineArtifacts getLocalEngine(EngineBuildPaths engineBuildPaths) {
    return LocalEngineArtifacts(
      engineBuildPaths.targetEngine,
      engineBuildPaths.hostEngine,
      cache: globals.cache,
      fileSystem: globals.fs,
      processManager: globals.processManager,
      platform: globals.platform,
      operatingSystemUtils: globals.os,
    );
  }

  /// Returns the requested [artifact] for the [platform], [mode], and [environmentType] combination.
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  });

  /// Retrieve a host specific artifact that does not depend on the
  /// current build mode or environment.
  FileSystemEntity getHostArtifact(
    HostArtifact artifact,
  );

  // Returns which set of engine artifacts is currently used for the [platform]
  // and [mode] combination.
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]);

  /// Whether these artifacts correspond to a non-versioned local engine.
  bool get isLocalEngine;
}

/// Manages the engine artifacts downloaded to the local cache.
class CachedArtifacts implements Artifacts {
  CachedArtifacts({
    required FileSystem fileSystem,
    required Platform platform,
    required Cache cache,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _cache = cache,
       _operatingSystemUtils = operatingSystemUtils;

  final FileSystem _fileSystem;
  final Platform _platform;
  final Cache _cache;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  FileSystemEntity getHostArtifact(
    HostArtifact artifact,
  ) {
    switch (artifact) {
      case HostArtifact.engineDartSdkPath:
        final String path = _dartSdkPath(_cache);
        return _fileSystem.directory(path);
      case HostArtifact.engineDartBinary:
        final String path = _fileSystem.path.join(_dartSdkPath(_cache), 'bin', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.flutterWebSdk:
        final String path = _getFlutterWebSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.flutterWebLibrariesJson:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformKernelDill:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformSoundKernelDill:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledSdk:
      case HostArtifact.webPrecompiledSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitSdk:
      case HostArtifact.webPrecompiledCanvaskitSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSdk:
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-html', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledSoundSdk:
      case HostArtifact.webPrecompiledSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitSoundSdk:
      case HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdk:
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-html-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName);
      case HostArtifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        final String path = _fileSystem.path.join(dartPackageDirectory.path,  _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.directory(path);
      case HostArtifact.dart2jsSnapshot:
      case HostArtifact.dartdevcSnapshot:
      case HostArtifact.kernelWorkerSnapshot:
        final String path = _fileSystem.path.join(_dartSdkPath(_cache), 'bin', 'snapshots', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.iosDeploy:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName);
      case HostArtifact.iproxy:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName);
      case HostArtifact.impellerc:
      case HostArtifact.libtessellator:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        final String engineDir = _getEngineArtifactsPath(_currentHostPlatform(_platform, _operatingSystemUtils))!;
        return _fileSystem.file(_fileSystem.path.join(engineDir, artifactFileName));
    }
  }

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    platform = _mapTargetPlatform(platform);
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        assert(platform != TargetPlatform.android);
        return _getAndroidArtifactPath(artifact, platform!, mode!);
      case TargetPlatform.ios:
        return _getIosArtifactPath(artifact, platform!, mode, environmentType);
      case TargetPlatform.darwin:
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.windows_x64:
        return _getDesktopArtifactPath(artifact, platform, mode);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
        return _getFuchsiaArtifactPath(artifact, platform!, mode!);
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case null:
        return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform(_platform, _operatingSystemUtils), mode);
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]) {
    return _fileSystem.path.basename(_getEngineArtifactsPath(platform, mode)!);
  }

  String _getDesktopArtifactPath(Artifact artifact, TargetPlatform? platform, BuildMode? mode) {
    // When platform is null, a generic host platform artifact is being requested
    // and not the gen_snapshot for darwin as a target platform.
    if (platform != null && artifact == Artifact.genSnapshot) {
      final String engineDir = _getEngineArtifactsPath(platform, mode)!;
      return _fileSystem.path.join(engineDir, _artifactToFileName(artifact));
    }
    return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform(_platform, _operatingSystemUtils), mode);
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode)!;
    switch (artifact) {
      case Artifact.genSnapshot:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        return _fileSystem.path.join(engineDir, hostPlatform, _artifactToFileName(artifact));
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterPatchedSdkPath:
      case Artifact.flutterTester:
      case Artifact.flutterXcframework:
      case Artifact.fontSubset:
      case Artifact.fuchsiaFlutterRunner:
      case Artifact.fuchsiaKernelCompiler:
      case Artifact.icuData:
      case Artifact.isolateSnapshotData:
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
      case Artifact.platformKernelDill:
      case Artifact.platformLibrariesJson:
      case Artifact.skyEnginePath:
      case Artifact.vmSnapshotData:
      case Artifact.windowsCppClientWrapper:
      case Artifact.windowsDesktopPath:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getIosArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode? mode, EnvironmentType? environmentType) {
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.flutterXcframework:
        final String artifactFileName = _artifactToFileName(artifact)!;
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _fileSystem.path.join(engineDir, artifactFileName);
      case Artifact.flutterFramework:
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _getIosEngineArtifactPath(engineDir, environmentType, _fileSystem);
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.constFinder:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterPatchedSdkPath:
      case Artifact.flutterTester:
      case Artifact.fontSubset:
      case Artifact.fuchsiaFlutterRunner:
      case Artifact.fuchsiaKernelCompiler:
      case Artifact.icuData:
      case Artifact.isolateSnapshotData:
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
      case Artifact.platformKernelDill:
      case Artifact.platformLibrariesJson:
      case Artifact.skyEnginePath:
      case Artifact.vmSnapshotData:
      case Artifact.windowsCppClientWrapper:
      case Artifact.windowsDesktopPath:
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
        final String artifactFileName = _artifactToFileName(artifact, platform, mode)!;
        return _fileSystem.path.join(root, runtime, 'flutter_runner_patched_sdk', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String artifactFileName = _artifactToFileName(artifact, platform, mode)!;
        return _fileSystem.path.join(root, runtime, 'dart_binaries', artifactFileName);
      case Artifact.fuchsiaFlutterRunner:
        final String artifactFileName = _artifactToFileName(artifact, platform, mode)!;
        return _fileSystem.path.join(root, runtime, artifactFileName);
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterTester:
      case Artifact.flutterXcframework:
      case Artifact.fontSubset:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.icuData:
      case Artifact.isolateSnapshotData:
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
      case Artifact.platformLibrariesJson:
      case Artifact.skyEnginePath:
      case Artifact.vmSnapshotData:
      case Artifact.windowsCppClientWrapper:
      case Artifact.windowsDesktopPath:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getFlutterPatchedSdkPath(BuildMode? mode) {
    final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
    return _fileSystem.path.join(engineArtifactsPath, 'common',
        mode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getFlutterWebSdkPath() {
    return _cache.getWebSdkDirectory().path;
  }

  String _getHostArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode? mode) {
    assert(platform != null);
    switch (artifact) {
      case Artifact.genSnapshot:
        // For script snapshots any gen_snapshot binary will do. Returning gen_snapshot for
        // android_arm in profile mode because it is available on all supported host platforms.
        return _getAndroidArtifactPath(artifact, TargetPlatform.android_arm, BuildMode.profile);
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(
          _dartSdkPath(_cache), 'bin', 'snapshots',
          _artifactToFileName(artifact),
        );
      case Artifact.flutterTester:
      case Artifact.vmSnapshotData:
      case Artifact.isolateSnapshotData:
      case Artifact.icuData:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        final String platformDirName = _enginePlatformDirectoryName(platform);
        return _fileSystem.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, platform, mode));
      case Artifact.platformKernelDill:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), _artifactToFileName(artifact));
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', _artifactToFileName(artifact));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath(mode);
      case Artifact.flutterMacOSFramework:
      case Artifact.linuxDesktopPath:
      case Artifact.windowsDesktopPath:
      case Artifact.linuxHeaders:
        // TODO(zanderso): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        String platformDirName = _enginePlatformDirectoryName(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${getNameForBuildMode(mode!)}';
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
                     .childDirectory(_enginePlatformDirectoryName(platform))
                     .childFile(_artifactToFileName(artifact, platform, mode)!)
                     .path;
      case Artifact.flutterFramework:
      case Artifact.flutterXcframework:
      case Artifact.fuchsiaFlutterRunner:
      case Artifact.fuchsiaKernelCompiler:
        throw StateError('Artifact $artifact not available for platform $platform.');
    }
  }

  String? _getEngineArtifactsPath(TargetPlatform platform, [ BuildMode? mode ]) {
    final String engineDir = _cache.getArtifactDirectory('engine').path;
    final String platformName = _enginePlatformDirectoryName(platform);
    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.darwin:
      case TargetPlatform.windows_x64:
        // TODO(zanderso): remove once debug desktop artifacts are uploaded
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
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(getModeName(mode!), '-')}' : '';
        return _fileSystem.path.join(engineDir, platformName + suffix);
      case TargetPlatform.android:
        assert(false, 'cannot use TargetPlatform.android to look up artifacts');
        return null;
    }
  }

  @override
  bool get isLocalEngine => false;
}

TargetPlatform _currentHostPlatform(Platform platform, OperatingSystemUtils operatingSystemUtils) {
  if (platform.isMacOS) {
    return TargetPlatform.darwin;
  }
  if (platform.isLinux) {
    return operatingSystemUtils.hostPlatform == HostPlatform.linux_x64 ?
             TargetPlatform.linux_x64 : TargetPlatform.linux_arm64;
  }
  if (platform.isWindows) {
    return TargetPlatform.windows_x64;
  }
  throw UnimplementedError('Host OS not supported.');
}

String _getIosEngineArtifactPath(String engineDirectory,
    EnvironmentType? environmentType, FileSystem fileSystem) {
  final Directory xcframeworkDirectory = fileSystem
      .directory(engineDirectory)
      .childDirectory(_artifactToFileName(Artifact.flutterXcframework)!);

  if (!xcframeworkDirectory.existsSync()) {
    throwToolExit('No xcframework found at ${xcframeworkDirectory.path}. Try running "flutter precache --ios".');
  }
  Directory? flutterFrameworkSource;
  for (final Directory platformDirectory
      in xcframeworkDirectory.listSync().whereType<Directory>()) {
    if (!platformDirectory.basename.startsWith('ios-')) {
      continue;
    }
    // ios-x86_64-simulator, ios-arm64_x86_64-simulator, or ios-arm64.
    final bool simulatorDirectory = platformDirectory.basename.endsWith('-simulator');
    if ((environmentType == EnvironmentType.simulator && simulatorDirectory) ||
        (environmentType == EnvironmentType.physical && !simulatorDirectory)) {
      flutterFrameworkSource = platformDirectory;
    }
  }
  if (flutterFrameworkSource == null) {
    throwToolExit('No iOS frameworks found in ${xcframeworkDirectory.path}');
  }

  return flutterFrameworkSource
      .childDirectory(_artifactToFileName(Artifact.flutterFramework)!)
      .path;
}

abstract class LocalEngineArtifacts implements Artifacts {
  factory LocalEngineArtifacts(String engineOutPath, String hostEngineOutPath, {
    required FileSystem fileSystem,
    required Cache cache,
    required ProcessManager processManager,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
  }) = CachedLocalEngineArtifacts;

  String get engineOutPath;

  String get localEngineName;
}

/// Manages the artifacts of a locally built engine.
class CachedLocalEngineArtifacts implements LocalEngineArtifacts {
  CachedLocalEngineArtifacts(
    this.engineOutPath,
    this._hostEngineOutPath, {
    required FileSystem fileSystem,
    required Cache cache,
    required ProcessManager processManager,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _fileSystem = fileSystem,
       localEngineName = fileSystem.path.basename(engineOutPath),
       _cache = cache,
       _processManager = processManager,
       _platform = platform,
       _operatingSystemUtils = operatingSystemUtils,
       _backupCache = CachedArtifacts(fileSystem: fileSystem, platform: platform, cache: cache, operatingSystemUtils: operatingSystemUtils);

  @override
  final String engineOutPath;

  @override
  final String localEngineName;

  final String _hostEngineOutPath;
  final FileSystem _fileSystem;
  final Cache _cache;
  final ProcessManager _processManager;
  final Platform _platform;
  final OperatingSystemUtils _operatingSystemUtils;
  final CachedArtifacts _backupCache;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.engineDartSdkPath:
        final String path = _getDartSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.engineDartBinary:
        final String path = _fileSystem.path.join(_getDartSdkPath(), 'bin', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.dart2jsSnapshot:
        final String path = _fileSystem.path.join(_getDartSdkPath(), 'bin', 'snapshots', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.dartdevcSnapshot:
        final String path = _fileSystem.path.join(_getDartSdkPath(), 'bin', 'snapshots', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.kernelWorkerSnapshot:
        final String path = _fileSystem.path.join(_getDartSdkPath(), 'bin', 'snapshots', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.flutterWebSdk:
        final String path = _getFlutterWebSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.flutterWebLibrariesJson:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformKernelDill:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformSoundKernelDill:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledSdk:
      case HostArtifact.webPrecompiledSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitSdk:
      case HostArtifact.webPrecompiledCanvaskitSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSdk:
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-html', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledSoundSdk:
      case HostArtifact.webPrecompiledSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitSoundSdk:
      case HostArtifact.webPrecompiledCanvaskitSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdk:
      case HostArtifact.webPrecompiledCanvaskitAndHtmlSoundSdkSourcemaps:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel', 'amd-canvaskit-html-sound', _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName);
      case HostArtifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        final String path = _fileSystem.path.join(dartPackageDirectory.path,  _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.directory(path);
      case HostArtifact.iosDeploy:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName);
      case HostArtifact.iproxy:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        return _cache.getArtifactDirectory('usbmuxd').childFile(artifactFileName);
      case HostArtifact.impellerc:
      case HostArtifact.libtessellator:
        final String artifactFileName = _hostArtifactToFileName(artifact, _platform);
        final File file = _fileSystem.file(_fileSystem.path.join(_hostEngineOutPath, artifactFileName));
        if (!file.existsSync()) {
          return _backupCache.getHostArtifact(artifact);
        }
        return file;
    }
  }

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    platform ??= _currentHostPlatform(_platform, _operatingSystemUtils);
    platform = _mapTargetPlatform(platform);
    final bool isDirectoryArtifact = artifact == Artifact.flutterPatchedSdkPath;
    final String? artifactFileName = isDirectoryArtifact ? null : _artifactToFileName(artifact, platform, mode);
    switch (artifact) {
      case Artifact.genSnapshot:
        return _genSnapshotPath();
      case Artifact.flutterTester:
        return _flutterTesterPath(platform!);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return _fileSystem.path.join(engineOutPath, 'gen', 'flutter', 'lib', 'snapshot', artifactFileName);
      case Artifact.icuData:
      case Artifact.flutterXcframework:
      case Artifact.flutterMacOSFramework:
        return _fileSystem.path.join(engineOutPath, artifactFileName);
      case Artifact.platformKernelDill:
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(engineOutPath, 'flutter_runner_patched_sdk', artifactFileName);
        }
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), artifactFileName);
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', artifactFileName);
      case Artifact.flutterFramework:
        return _getIosEngineArtifactPath(
            engineOutPath, environmentType, _fileSystem);
      case Artifact.flutterPatchedSdkPath:
        // When using local engine always use [BuildMode.debug] regardless of
        // what was specified in [mode] argument because local engine will
        // have only one flutter_patched_sdk in standard location, that
        // is happen to be what debug(non-release) mode is using.
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(engineOutPath, 'flutter_runner_patched_sdk');
        }
        return _getFlutterPatchedSdkPath(BuildMode.debug);
      case Artifact.skyEnginePath:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', 'dart-pkg', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        final String modeName = mode!.isRelease ? 'release' : mode.toString();
        final String dartBinaries = 'dart_binaries-$modeName-$hostPlatform';
        return _fileSystem.path.join(engineOutPath, 'host_bundle', dartBinaries, 'kernel_compiler.dart.snapshot');
      case Artifact.fuchsiaFlutterRunner:
        final String jitOrAot = mode!.isJit ? '_jit' : '_aot';
        final String productOrNo = mode.isRelease ? '_product' : '';
        return _fileSystem.path.join(engineOutPath, 'flutter$jitOrAot${productOrNo}_runner-0.far');
      case Artifact.fontSubset:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.constFinder:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', artifactFileName);
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
      case Artifact.windowsDesktopPath:
      case Artifact.windowsCppClientWrapper:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(
          _getDartSdkPath(), 'bin', 'snapshots', artifactFileName,
        );
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]) {
    return _fileSystem.path.basename(engineOutPath);
  }

  String _getFlutterPatchedSdkPath(BuildMode? buildMode) {
    return _fileSystem.path.join(engineOutPath,
        buildMode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk');
  }

  String _getDartSdkPath() {
    final String builtPath = _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk');
    if (_fileSystem.isDirectorySync(_fileSystem.path.join(builtPath, 'bin'))) {
      return builtPath;
    }

    // If we couldn't find a built dart sdk, let's look for a prebuilt one.
    final String prebuiltPath = _fileSystem.path.join(_getFlutterPrebuiltsPath(), _getPrebuiltTarget(), 'dart-sdk');
    if (_fileSystem.isDirectorySync(prebuiltPath)) {
      return prebuiltPath;
    }

    throw ToolExit('Unable to find a built dart sdk at: "$builtPath" or a prebuilt dart sdk at: "$prebuiltPath"');
  }

  String _getFlutterPrebuiltsPath() {
    final String engineSrcPath = _fileSystem.path.dirname(_fileSystem.path.dirname(_hostEngineOutPath));
    return _fileSystem.path.join(engineSrcPath, 'flutter', 'prebuilts');
  }

  String _getPrebuiltTarget() {
    final TargetPlatform hostPlatform = _currentHostPlatform(_platform, _operatingSystemUtils);
    switch (hostPlatform) {
      case TargetPlatform.darwin:
        return 'macos-x64';
      case TargetPlatform.linux_arm64:
        return 'linux-arm64';
      case TargetPlatform.linux_x64:
        return 'linux-x64';
      case TargetPlatform.windows_x64:
        return 'windows-x64';
      case TargetPlatform.ios:
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.web_javascript:
      case TargetPlatform.tester:
        throwToolExit('Unsupported host platform: $hostPlatform');
    }
  }

  String _getFlutterWebSdkPath() {
    return _fileSystem.path.join(engineOutPath, 'flutter_web_sdk');
  }

  String _genSnapshotPath() {
    const List<String> clangDirs = <String>['.', 'clang_x64', 'clang_x86', 'clang_i386', 'clang_arm64'];
    final String genSnapshotName = _artifactToFileName(Artifact.genSnapshot)!;
    for (final String clangDir in clangDirs) {
      final String genSnapshotPath = _fileSystem.path.join(engineOutPath, clangDir, genSnapshotName);
      if (_processManager.canRun(genSnapshotPath)) {
        return genSnapshotPath;
      }
    }
    throw Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    if (_platform.isLinux) {
      return _fileSystem.path.join(engineOutPath, _artifactToFileName(Artifact.flutterTester));
    } else if (_platform.isMacOS) {
      return _fileSystem.path.join(engineOutPath, 'flutter_tester');
    } else if (_platform.isWindows) {
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
    required this.parent,
    this.frontendServer,
    this.engineDartBinary,
    this.platformKernelDill,
    this.flutterPatchedSdk,
  }) : assert(parent != null);

  final Artifacts parent;
  final File? frontendServer;
  final File? engineDartBinary;
  final File? platformKernelDill;
  final File? flutterPatchedSdk;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (artifact == Artifact.frontendServerSnapshotForEngineDartSdk && frontendServer != null) {
      return frontendServer!.path;
    }
    if (artifact == Artifact.platformKernelDill && platformKernelDill != null) {
      return platformKernelDill!.path;
    }
    if (artifact == Artifact.flutterPatchedSdkPath && flutterPatchedSdk != null) {
      return flutterPatchedSdk!.path;
    }
    return parent.getArtifactPath(
      artifact,
      platform: platform,
      mode: mode,
      environmentType: environmentType,
    );
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]) => parent.getEngineType(platform, mode);

  @override
  bool get isLocalEngine => parent.isLocalEngine;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    if (artifact == HostArtifact.engineDartBinary && engineDartBinary != null) {
      return engineDartBinary!;
    }
    return parent.getHostArtifact(
      artifact,
    );
  }
}

/// Locate the Dart SDK.
String _dartSdkPath(Cache cache) {
  return cache.getRoot().childDirectory('dart-sdk').path;
}

class _TestArtifacts implements Artifacts {
  _TestArtifacts(this.fileSystem);

  final FileSystem fileSystem;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.write(artifact);
    if (platform != null) {
      buffer.write('.$platform');
    }
    if (mode != null) {
      buffer.write('.$mode');
    }
    if (environmentType != null) {
      buffer.write('.$environmentType');
    }
    return buffer.toString();
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]) {
    return 'test-engine';
  }

  @override
  bool get isLocalEngine => false;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    return fileSystem.file(artifact.toString());
  }
}

class _TestLocalEngine extends _TestArtifacts implements LocalEngineArtifacts {
  _TestLocalEngine(this.engineOutPath, FileSystem fileSystem) : super(fileSystem);

  @override
  bool get isLocalEngine => true;

  @override
  final String engineOutPath;

  @override
  String get localEngineName => fileSystem.path.basename(engineOutPath);
}
