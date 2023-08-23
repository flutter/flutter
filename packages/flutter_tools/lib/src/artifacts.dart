// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/user_messages.dart';
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

  /// The root directory of the dart SDK.
  engineDartSdkPath,
  /// The dart binary used to execute any of the required snapshots.
  engineDartBinary,
  /// The dart binary for running aot snapshots
  engineDartAotRuntime,
  /// The snapshot of frontend_server compiler.
  frontendServerSnapshotForEngineDartSdk,
  /// The dart snapshot of the dart2js compiler.
  dart2jsSnapshot,
  /// The dart snapshot of the dart2wasm compiler.
  dart2wasmSnapshot,
  /// The wasm-opt binary that ships with the dart-sdk
  wasmOptBinary,

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

  /// The location of file generators.
  flutterToolsFileGenerators,
}

/// A subset of [Artifact]s that are platform and build mode independent
enum HostArtifact {
  /// The root of the web implementation of the dart SDK.
  flutterWebSdk,
  /// The libraries JSON file for web release builds.
  flutterWebLibrariesJson,

  /// Folder that contains platform dill files for the web sdk.
  webPlatformKernelFolder,

  /// The summary dill for the dartdevc target.
  webPlatformDDCKernelDill,
  /// The summary dill with null safety enabled for the dartdevc target.g
  webPlatformDDCSoundKernelDill,
  /// The summary dill for the dartdevc target.
  webPlatformDart2JSKernelDill,
  /// The summary dill with null safety enabled for the dartdevc target.
  webPlatformDart2JSSoundKernelDill,

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
  // The Impeller Scene 3D model importer.
  scenec,
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

String? _artifactToFileName(Artifact artifact, Platform hostPlatform, [ BuildMode? mode ]) {
  final String exe = hostPlatform.isWindows ? '.exe' : '';
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
    case Artifact.engineDartSdkPath:
      return 'dart-sdk';
    case Artifact.engineDartBinary:
      return 'dart$exe';
    case Artifact.engineDartAotRuntime:
      return 'dartaotruntime$exe';
    case Artifact.dart2jsSnapshot:
      return 'dart2js.dart.snapshot';
    case Artifact.dart2wasmSnapshot:
      return 'dart2wasm_product.snapshot';
    case Artifact.wasmOptBinary:
      return 'wasm-opt$exe';
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
    case Artifact.flutterToolsFileGenerators:
      return '';
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
    case HostArtifact.webPlatformKernelFolder:
      return 'kernel';
    case HostArtifact.webPlatformDDCKernelDill:
      return 'ddc_outline.dill';
    case HostArtifact.webPlatformDDCSoundKernelDill:
      return 'ddc_outline_sound.dill';
    case HostArtifact.webPlatformDart2JSKernelDill:
      return 'dart2js_platform_unsound.dill';
    case HostArtifact.webPlatformDart2JSSoundKernelDill:
      return 'dart2js_platform.dill';
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
    case HostArtifact.scenec:
      return 'scenec$exe';
    case HostArtifact.libtessellator:
      return 'libtessellator$dll';
  }
}

class EngineBuildPaths {
  const EngineBuildPaths({
    required this.targetEngine,
    required this.hostEngine,
    required this.webSdk,
  });

  final String? targetEngine;
  final String? hostEngine;
  final String? webSdk;
}

/// Information about a local engine build (i.e. `--local-engine[-host]=...`).
///
/// See https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool
/// for more information about local engine builds.
class LocalEngineInfo {
  /// Creates a reference to a local engine build.
  ///
  /// The [targetOutPath] and [hostOutPath] are assumed to be resolvable
  /// paths to the built engine artifacts for the target (device) and host
  /// (build) platforms, respectively.
  const LocalEngineInfo({
    required this.targetOutPath,
    required this.hostOutPath,
  });

  /// The path to the engine artifacts for the target (device) platform.
  ///
  /// For example, if the target platform is Android debug, this would be a path
  /// like `/path/to/engine/src/out/android_debug_unopt`. To retrieve just the
  /// name (platform), see [localTargetName].
  final String targetOutPath;

  /// The path to the engine artifacts for the host (build) platform.
  ///
  /// For example, if the host platform is debug, this would be a path like
  /// `/path/to/engine/src/out/host_debug_unopt`. To retrieve just the name
  /// (platform), see [localHostName].
  final String hostOutPath;

  /// The name of the target (device) platform, i.e. `android_debug_unopt`.
  String get localTargetName => globals.fs.path.basename(targetOutPath);

  /// The name of the host (build) platform, e.g. `host_debug_unopt`.
  String get localHostName => globals.fs.path.basename(hostOutPath);
}

// Manages the engine artifacts of Flutter.
abstract class Artifacts {
  /// A test-specific implementation of artifacts that returns stable paths for
  /// all artifacts.
  ///
  /// If a [fileSystem] is not provided, creates a new [MemoryFileSystem] instance.
  ///
  /// Creates a [LocalEngineArtifacts] if `localEngine` is non-null
  @visibleForTesting
  factory Artifacts.test({FileSystem? fileSystem}) {
    return _TestArtifacts(fileSystem ?? MemoryFileSystem.test());
  }

  /// A test-specific implementation of artifacts that returns stable paths for
  /// all artifacts, and uses a local engine.
  ///
  /// If a [fileSystem] is not provided, creates a new [MemoryFileSystem] instance.
  @visibleForTesting
  factory Artifacts.testLocalEngine({
    required String localEngine,
    required String localEngineHost,
    FileSystem? fileSystem,
  }) {
    return _TestLocalEngine(
        localEngine, localEngineHost, fileSystem ?? MemoryFileSystem.test());
  }

  static Artifacts getLocalEngine(EngineBuildPaths engineBuildPaths) {
    Artifacts artifacts = CachedArtifacts(
      fileSystem: globals.fs,
      platform: globals.platform,
      cache: globals.cache,
      operatingSystemUtils: globals.os
    );
    if (engineBuildPaths.hostEngine != null && engineBuildPaths.targetEngine != null) {
      artifacts = CachedLocalEngineArtifacts(
        engineBuildPaths.hostEngine!,
        engineOutPath: engineBuildPaths.targetEngine!,
        cache: globals.cache,
        fileSystem: globals.fs,
        processManager: globals.processManager,
        platform: globals.platform,
        operatingSystemUtils: globals.os,
        parent: artifacts,
      );
    }
    if (engineBuildPaths.webSdk != null) {
      artifacts = CachedLocalWebSdkArtifacts(
        parent: artifacts,
        webSdkPath: engineBuildPaths.webSdk!,
        fileSystem: globals.fs,
        platform: globals.platform,
        operatingSystemUtils: globals.os
      );
    }
    return artifacts;
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

  /// If these artifacts are bound to a local engine build, returns info about
  /// the location and name of the local engine, otherwise returns null.
  LocalEngineInfo? get localEngineInfo;
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
  LocalEngineInfo? get localEngineInfo => null;

  @override
  FileSystemEntity getHostArtifact(
    HostArtifact artifact,
  ) {
    switch (artifact) {
      case HostArtifact.flutterWebSdk:
        final String path = _getFlutterWebSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.flutterWebLibrariesJson:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformKernelFolder:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel');
        return _fileSystem.file(path);
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDDCSoundKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPlatformDart2JSSoundKernelDill:
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
      case HostArtifact.scenec:
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
      return _fileSystem.path.join(engineDir, _artifactToFileName(artifact, _platform));
    }
    return _getHostArtifactPath(artifact, platform ?? _currentHostPlatform(_platform, _operatingSystemUtils), mode);
  }

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode)!;
    switch (artifact) {
      case Artifact.genSnapshot:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        return _fileSystem.path.join(engineDir, hostPlatform, _artifactToFileName(artifact, _platform));
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.dart2jsSnapshot:
      case Artifact.dart2wasmSnapshot:
      case Artifact.wasmOptBinary:
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
      case Artifact.flutterToolsFileGenerators:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getIosArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode? mode, EnvironmentType? environmentType) {
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.flutterXcframework:
        final String artifactFileName = _artifactToFileName(artifact, _platform)!;
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _fileSystem.path.join(engineDir, artifactFileName);
      case Artifact.flutterFramework:
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _getIosEngineArtifactPath(engineDir, environmentType, _fileSystem, _platform);
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.dart2jsSnapshot:
      case Artifact.dart2wasmSnapshot:
      case Artifact.wasmOptBinary:
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
      case Artifact.flutterToolsFileGenerators:
        return _getHostArtifactPath(artifact, platform, mode);
    }
  }

  String _getFuchsiaArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String root = _fileSystem.path.join(
      _cache.getArtifactDirectory('flutter_runner').path,
      'flutter',
      platform.fuchsiaArchForTargetPlatform,
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
        final String artifactFileName = _artifactToFileName(artifact, _platform, mode)!;
        return _fileSystem.path.join(root, runtime, 'flutter_runner_patched_sdk', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String artifactFileName = _artifactToFileName(artifact, _platform, mode)!;
        return _fileSystem.path.join(root, runtime, 'dart_binaries', artifactFileName);
      case Artifact.fuchsiaFlutterRunner:
        final String artifactFileName = _artifactToFileName(artifact, _platform, mode)!;
        return _fileSystem.path.join(root, runtime, artifactFileName);
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterTester:
      case Artifact.flutterXcframework:
      case Artifact.fontSubset:
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.dart2jsSnapshot:
      case Artifact.dart2wasmSnapshot:
      case Artifact.wasmOptBinary:
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
      case Artifact.flutterToolsFileGenerators:
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
    switch (artifact) {
      case Artifact.genSnapshot:
        // For script snapshots any gen_snapshot binary will do. Returning gen_snapshot for
        // android_arm in profile mode because it is available on all supported host platforms.
        return _getAndroidArtifactPath(artifact, TargetPlatform.android_arm, BuildMode.profile);
      case Artifact.dart2jsSnapshot:
      case Artifact.dart2wasmSnapshot:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(
          _dartSdkPath(_cache), 'bin', 'snapshots',
          _artifactToFileName(artifact, _platform),
        );
      case Artifact.wasmOptBinary:
        return _fileSystem.path.join(
          _dartSdkPath(_cache), 'bin', 'utils',
          _artifactToFileName(artifact, _platform),
        );
      case Artifact.flutterTester:
      case Artifact.vmSnapshotData:
      case Artifact.isolateSnapshotData:
      case Artifact.icuData:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        final String platformDirName = _enginePlatformDirectoryName(platform);
        return _fileSystem.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, _platform, mode));
      case Artifact.platformKernelDill:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), _artifactToFileName(artifact, _platform));
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', _artifactToFileName(artifact, _platform));
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath(mode);
      case Artifact.engineDartSdkPath:
        return _dartSdkPath(_cache);
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
        return _fileSystem.path.join(_dartSdkPath(_cache), 'bin', _artifactToFileName(artifact, _platform));
      case Artifact.flutterMacOSFramework:
      case Artifact.linuxDesktopPath:
      case Artifact.windowsDesktopPath:
      case Artifact.linuxHeaders:
        // TODO(zanderso): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        String platformDirName = _enginePlatformDirectoryName(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${mode!.cliName}';
        }
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _fileSystem.path.join(engineArtifactsPath, platformDirName, _artifactToFileName(artifact, _platform, mode));
      case Artifact.windowsCppClientWrapper:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _fileSystem.path.join(engineArtifactsPath, 'windows-x64', _artifactToFileName(artifact, _platform, mode));
      case Artifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        return _fileSystem.path.join(dartPackageDirectory.path,  _artifactToFileName(artifact, _platform));
      case Artifact.fontSubset:
      case Artifact.constFinder:
        return _cache.getArtifactDirectory('engine')
                     .childDirectory(_enginePlatformDirectoryName(platform))
                     .childFile(_artifactToFileName(artifact, _platform, mode)!)
                     .path;
      case Artifact.flutterFramework:
      case Artifact.flutterXcframework:
      case Artifact.fuchsiaFlutterRunner:
      case Artifact.fuchsiaKernelCompiler:
        throw StateError('Artifact $artifact not available for platform $platform.');
      case Artifact.flutterToolsFileGenerators:
        return _getFileGeneratorsPath();
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
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(mode.cliName, '-')}' : '';
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
        final String suffix = mode != BuildMode.debug ? '-${snakeCase(mode!.cliName, '-')}' : '';
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
    EnvironmentType? environmentType, FileSystem fileSystem, Platform hostPlatform) {
  final Directory xcframeworkDirectory = fileSystem
      .directory(engineDirectory)
      .childDirectory(_artifactToFileName(Artifact.flutterXcframework, hostPlatform)!);

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
      .childDirectory(_artifactToFileName(Artifact.flutterFramework, hostPlatform)!)
      .path;
}

/// Manages the artifacts of a locally built engine.
class CachedLocalEngineArtifacts implements Artifacts {
  CachedLocalEngineArtifacts(
    this._hostEngineOutPath, {
    required String engineOutPath,
    required FileSystem fileSystem,
    required Cache cache,
    required ProcessManager processManager,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
    Artifacts? parent,
  }) : _fileSystem = fileSystem,
       localEngineInfo =
         LocalEngineInfo(
           targetOutPath: engineOutPath,
           hostOutPath: _hostEngineOutPath,
         ),
       _cache = cache,
       _processManager = processManager,
       _platform = platform,
       _operatingSystemUtils = operatingSystemUtils,
       _backupCache = parent ??
         CachedArtifacts(
           fileSystem: fileSystem,
           platform: platform,
           cache: cache,
           operatingSystemUtils: operatingSystemUtils
         );

  @override
  final LocalEngineInfo localEngineInfo;

  final String _hostEngineOutPath;
  final FileSystem _fileSystem;
  final Cache _cache;
  final ProcessManager _processManager;
  final Platform _platform;
  final OperatingSystemUtils _operatingSystemUtils;
  final Artifacts _backupCache;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.flutterWebSdk:
        final String path = _getFlutterWebSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.flutterWebLibrariesJson:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformKernelFolder:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel');
        return _fileSystem.file(path);
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDDCSoundKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPlatformDart2JSSoundKernelDill:
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
      case HostArtifact.scenec:
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
    final String? artifactFileName = isDirectoryArtifact ? null : _artifactToFileName(artifact, _platform, mode);
    switch (artifact) {
      case Artifact.genSnapshot:
        return _genSnapshotPath();
      case Artifact.flutterTester:
        return _flutterTesterPath(platform!);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return _fileSystem.path.join(localEngineInfo.targetOutPath, 'gen', 'flutter', 'lib', 'snapshot', artifactFileName);
      case Artifact.icuData:
      case Artifact.flutterXcframework:
      case Artifact.flutterMacOSFramework:
        return _fileSystem.path.join(localEngineInfo.targetOutPath, artifactFileName);
      case Artifact.platformKernelDill:
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter_runner_patched_sdk', artifactFileName);
        }
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), artifactFileName);
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', artifactFileName);
      case Artifact.flutterFramework:
        return _getIosEngineArtifactPath(
            localEngineInfo.targetOutPath, environmentType, _fileSystem, _platform);
      case Artifact.flutterPatchedSdkPath:
        // When using local engine always use [BuildMode.debug] regardless of
        // what was specified in [mode] argument because local engine will
        // have only one flutter_patched_sdk in standard location, that
        // is happen to be what debug(non-release) mode is using.
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter_runner_patched_sdk');
        }
        return _getFlutterPatchedSdkPath(BuildMode.debug);
      case Artifact.skyEnginePath:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', 'dart-pkg', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String hostPlatform = getNameForHostPlatform(getCurrentHostPlatform());
        final String modeName = mode!.isRelease ? 'release' : mode.toString();
        final String dartBinaries = 'dart_binaries-$modeName-$hostPlatform';
        return _fileSystem.path.join(localEngineInfo.targetOutPath, 'host_bundle', dartBinaries, 'kernel_compiler.dart.snapshot');
      case Artifact.fuchsiaFlutterRunner:
        final String jitOrAot = mode!.isJit ? '_jit' : '_aot';
        final String productOrNo = mode.isRelease ? '_product' : '';
        return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter$jitOrAot${productOrNo}_runner-0.far');
      case Artifact.fontSubset:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.constFinder:
        return _fileSystem.path.join(_hostEngineOutPath, 'gen', artifactFileName);
      case Artifact.linuxDesktopPath:
      case Artifact.linuxHeaders:
      case Artifact.windowsDesktopPath:
      case Artifact.windowsCppClientWrapper:
        return _fileSystem.path.join(_hostEngineOutPath, artifactFileName);
      case Artifact.engineDartSdkPath:
        return _getDartSdkPath();
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
        return _fileSystem.path.join(_getDartSdkPath(), 'bin', artifactFileName);
      case Artifact.dart2jsSnapshot:
      case Artifact.dart2wasmSnapshot:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(_getDartSdkPath(), 'bin', 'snapshots', artifactFileName);
      case Artifact.wasmOptBinary:
        return _fileSystem.path.join(_getDartSdkPath(), 'bin', 'utils', artifactFileName);
      case Artifact.flutterToolsFileGenerators:
        return _getFileGeneratorsPath();
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [ BuildMode? mode ]) {
    return _fileSystem.path.basename(localEngineInfo.targetOutPath);
  }

  String _getFlutterPatchedSdkPath(BuildMode? buildMode) {
    return _fileSystem.path.join(localEngineInfo.targetOutPath,
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
    return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter_web_sdk');
  }

  String _genSnapshotPath() {
    const List<String> clangDirs = <String>['.', 'clang_x64', 'clang_x86', 'clang_i386', 'clang_arm64'];
    final String genSnapshotName = _artifactToFileName(Artifact.genSnapshot, _platform)!;
    for (final String clangDir in clangDirs) {
      final String genSnapshotPath = _fileSystem.path.join(localEngineInfo.targetOutPath, clangDir, genSnapshotName);
      if (_processManager.canRun(genSnapshotPath)) {
        return genSnapshotPath;
      }
    }
    throw Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    if (_platform.isLinux) {
      return _fileSystem.path.join(localEngineInfo.targetOutPath, _artifactToFileName(Artifact.flutterTester, _platform));
    } else if (_platform.isMacOS) {
      return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter_tester');
    } else if (_platform.isWindows) {
      return _fileSystem.path.join(localEngineInfo.targetOutPath, 'flutter_tester.exe');
    }
    throw Exception('Unsupported platform $platform.');
  }

  @override
  bool get isLocalEngine => true;
}

class CachedLocalWebSdkArtifacts implements Artifacts {
  CachedLocalWebSdkArtifacts({
    required Artifacts parent,
    required String webSdkPath,
    required FileSystem fileSystem,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils
  }) : _parent = parent,
       _webSdkPath = webSdkPath,
       _fileSystem = fileSystem,
       _platform = platform,
       _operatingSystemUtils = operatingSystemUtils;


  final Artifacts _parent;
  final String _webSdkPath;
  final FileSystem _fileSystem;
  final Platform _platform;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  String getArtifactPath(Artifact artifact, {TargetPlatform? platform, BuildMode? mode, EnvironmentType? environmentType}) {
    if (platform == TargetPlatform.web_javascript) {
      switch (artifact) {
        case Artifact.engineDartSdkPath:
          return _getDartSdkPath();
        case Artifact.engineDartBinary:
        case Artifact.engineDartAotRuntime:
          return _fileSystem.path.join(
            _getDartSdkPath(), 'bin',
            _artifactToFileName(artifact, _platform, mode));
        case Artifact.dart2jsSnapshot:
        case Artifact.dart2wasmSnapshot:
        case Artifact.frontendServerSnapshotForEngineDartSdk:
          return _fileSystem.path.join(
            _getDartSdkPath(), 'bin', 'snapshots',
            _artifactToFileName(artifact, _platform, mode),
          );
        case Artifact.wasmOptBinary:
          return _fileSystem.path.join(
            _getDartSdkPath(), 'bin', 'utils',
            _artifactToFileName(artifact, _platform, mode),
          );
        case Artifact.genSnapshot:
        case Artifact.flutterTester:
        case Artifact.flutterFramework:
        case Artifact.flutterXcframework:
        case Artifact.flutterMacOSFramework:
        case Artifact.vmSnapshotData:
        case Artifact.isolateSnapshotData:
        case Artifact.icuData:
        case Artifact.platformKernelDill:
        case Artifact.platformLibrariesJson:
        case Artifact.flutterPatchedSdkPath:
        case Artifact.linuxDesktopPath:
        case Artifact.linuxHeaders:
        case Artifact.windowsDesktopPath:
        case Artifact.windowsCppClientWrapper:
        case Artifact.skyEnginePath:
        case Artifact.fuchsiaKernelCompiler:
        case Artifact.fuchsiaFlutterRunner:
        case Artifact.fontSubset:
        case Artifact.constFinder:
        case Artifact.flutterToolsFileGenerators:
          break;
      }
    }
    return _parent.getArtifactPath(artifact, platform: platform, mode: mode, environmentType: environmentType);
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) => _parent.getEngineType(platform, mode);

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.flutterWebSdk:
        final String path = _getFlutterWebSdkPath();
        return _fileSystem.directory(path);
      case HostArtifact.flutterWebLibrariesJson:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), _hostArtifactToFileName(artifact, _platform));
        return _fileSystem.file(path);
      case HostArtifact.webPlatformKernelFolder:
        final String path = _fileSystem.path.join(_getFlutterWebSdkPath(), 'kernel');
        return _fileSystem.file(path);
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDDCSoundKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPlatformDart2JSSoundKernelDill:
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
      case HostArtifact.iosDeploy:
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
      case HostArtifact.iproxy:
      case HostArtifact.skyEnginePath:
      case HostArtifact.impellerc:
      case HostArtifact.scenec:
      case HostArtifact.libtessellator:
        return _parent.getHostArtifact(artifact);
    }
  }

  String _getDartSdkPath() {
    // If we couldn't find a built dart sdk, let's look for a prebuilt one.
    final String prebuiltPath = _fileSystem.path.join(_getFlutterPrebuiltsPath(), _getPrebuiltTarget(), 'dart-sdk');
    if (_fileSystem.isDirectorySync(prebuiltPath)) {
      return prebuiltPath;
    }

    throw ToolExit('Unable to find a prebuilt dart sdk at: "$prebuiltPath"');
  }

  String _getFlutterPrebuiltsPath() {
    final String engineSrcPath = _fileSystem.path.dirname(_fileSystem.path.dirname(_webSdkPath));
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
    return _fileSystem.path.join(_webSdkPath, 'flutter_web_sdk');
  }

  @override
  bool get isLocalEngine => _parent.isLocalEngine;

  @override
  LocalEngineInfo? get localEngineInfo => _parent.localEngineInfo;
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
  });

  final Artifacts parent;
  final File? frontendServer;
  final File? engineDartBinary;
  final File? platformKernelDill;
  final File? flutterPatchedSdk;

  @override
  LocalEngineInfo? get localEngineInfo => parent.localEngineInfo;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (artifact == Artifact.engineDartBinary && engineDartBinary != null) {
      return engineDartBinary!.path;
    }
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
  LocalEngineInfo? get localEngineInfo => null;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    // The path to file generators is the same even in the test environment.
    if (artifact == Artifact.flutterToolsFileGenerators) {
      return _getFileGeneratorsPath();
    }

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

class _TestLocalEngine extends _TestArtifacts {
  _TestLocalEngine(
    String engineOutPath,
    String engineHostOutPath,
    super.fileSystem,
  ) : localEngineInfo = LocalEngineInfo(
        targetOutPath: engineOutPath,
        hostOutPath: engineHostOutPath,
      );

  @override
  bool get isLocalEngine => true;

  @override
  final LocalEngineInfo localEngineInfo;
}

String _getFileGeneratorsPath() {
  final String flutterRoot = Cache.defaultFlutterRoot(
    fileSystem: globals.localFileSystem,
    platform: const LocalPlatform(),
    userMessages: UserMessages(),
  );
  return globals.localFileSystem.path.join(
    flutterRoot,
    'packages',
    'flutter_tools',
    'lib',
    'src',
    'web',
    'file_generators',
  );
}
