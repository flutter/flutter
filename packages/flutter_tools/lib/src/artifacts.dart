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

//////////////////////////////////////////////////////////////////////
//                                                                  //
//  ✨ THINKING OF MOVING/REFACTORING THIS FILE? READ ME FIRST! ✨  //
//                                                                  //
//  There is a link to this file in //docs/tool/Engine-artfiacts.md //
//  and it would be very kind of you to update the link, if needed. //
//                                                                  //
//////////////////////////////////////////////////////////////////////

/// Defines what engine artifacts are available (not necessarily on each platform).
enum Artifact {
  /// The tool which compiles a dart kernel file into native code.
  genSnapshot('gen_snapshot'),
  genSnapshotArm64('gen_snapshot_arm64'),
  genSnapshotRiscv64('gen_snapshot_riscv64'),
  genSnapshotX64('gen_snapshot_x64'),

  /// The flutter tester binary.
  flutterTester('flutter_tester', isExecutable: true),
  flutterFramework('Flutter.framework'),
  flutterFrameworkDsym('Flutter.framework.dSYM'),
  flutterXcframework('Flutter.xcframework'),

  /// The framework directory of the macOS desktop.
  flutterMacOSFramework('FlutterMacOS.framework'),
  flutterMacOSFrameworkDsym('FlutterMacOS.framework.dSYM'),
  flutterMacOSXcframework('FlutterMacOS.xcframework'),
  vmSnapshotData('vm_isolate_snapshot.bin'),
  isolateSnapshotData('isolate_snapshot.bin'),
  icuData('icudtl.dat'),
  platformKernelDill('platform_strong.dill'),
  platformLibrariesJson('libraries.json'),
  flutterPatchedSdkPath('', isPatchedSdk: true),

  /// The root directory of the dart SDK.
  engineDartSdkPath('dart-sdk'),

  /// The dart binary used to execute any of the required snapshots.
  engineDartBinary('dart', isExecutable: true),

  /// The dart binary for running aot snapshots
  engineDartAotRuntime('dartaotruntime', isExecutable: true),

  /// The snapshot of frontend_server compiler.
  frontendServerSnapshotForEngineDartSdk('frontend_server_aot.dart.snapshot'),

  /// The root of the Linux desktop sources.
  linuxDesktopPath.directory(),
  // The root of the cpp headers for Linux desktop.
  linuxHeaders('flutter_linux'),

  /// The root of the Windows desktop sources.
  windowsDesktopPath.directory(),

  /// The root of the cpp client code for Windows desktop.
  windowsCppClientWrapper('cpp_client_wrapper'),

  /// The root of the sky_engine package.
  skyEnginePath('sky_engine'),

  // Fuchsia artifacts from the engine prebuilts.
  fuchsiaKernelCompiler('kernel_compiler.snapshot'),
  fuchsiaFlutterRunner('', isFuchsiaRunner: true),

  /// Tools related to subsetting or icon font files.
  fontSubset('font-subset', isExecutable: true),
  constFinder('const_finder.dart.snapshot'),

  /// The location of file generators.
  flutterToolsFileGenerators.directory();

  const Artifact(
    this._fileName, {
    this.isExecutable = false,
    this.isPatchedSdk = false,
    this.isFuchsiaRunner = false,
  });

  const Artifact.directory()
    : _fileName = '',
      isExecutable = false,
      isPatchedSdk = false,
      isFuchsiaRunner = false;

  final String _fileName;
  final bool isExecutable;
  final bool isPatchedSdk;
  final bool isFuchsiaRunner;

  String getFileName(Platform hostPlatform, [BuildMode? mode]) {
    if (isPatchedSdk) {
      throw StateError('No filename for sdk path, should not be invoked');
    }
    if (isFuchsiaRunner) {
      if (mode == null) {
        throw ArgumentError('BuildMode is required for fuchsiaFlutterRunner');
      }
      final jitOrAot = mode.isJit ? '_jit' : '_aot';
      final productOrNo = mode.isRelease ? '_product' : '';
      return 'flutter$jitOrAot${productOrNo}_runner-0.far';
    }
    final exe = (isExecutable && hostPlatform.isWindows) ? '.exe' : '';
    return '$_fileName$exe';
  }
}

/// A subset of [Artifact]s that are platform and build mode independent
enum HostArtifact {
  /// The root of the web implementation of the dart SDK.
  flutterWebSdk.directory(),

  /// The libraries JSON file for web release builds.
  flutterWebLibrariesJson('libraries.json'),

  // The flutter.js bootstrapping file provided by the engine.
  flutterJsDirectory('flutter_js'),

  /// Folder that contains platform dill files for the web sdk.
  webPlatformKernelFolder('kernel'),

  // **NOTE**: All of the precompiled SDKs, summaries, and source maps are
  // strictly with sound null-safety, there is no longer support for unsound
  // null-safety within the Flutter tool or SDK.
  //
  // See https://github.com/flutter/flutter/issues/162846.

  /// The summary dill for the dartdevc target.
  webPlatformDDCKernelDill('ddc_outline.dill'),

  /// The summary dill for the dart2js target.
  webPlatformDart2JSKernelDill('dart2js_platform.dill'),

  /// The precompiled SDKs and sourcemaps for web debug builds with the AMD module system.
  // TODO(markzipan): delete these when DDC's AMD module system is deprecated, https://github.com/flutter/flutter/issues/142060.
  webPrecompiledAmdCanvaskitSdk('dart_sdk.js'),
  webPrecompiledAmdCanvaskitSdkSourcemaps('dart_sdk.js.map'),

  /// The precompiled SDKs and sourcemaps for web debug builds with the DDC
  /// library bundle module system. Only SDKs built with sound null-safety are
  /// provided here.
  webPrecompiledDdcLibraryBundleCanvaskitSdk('dart_sdk.js'),
  webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps('dart_sdk.js.map'),

  iosDeploy('ios-deploy'),
  idevicesyslog('idevicesyslog'),
  idevicescreenshot('idevicescreenshot'),
  iproxy('iproxy'),

  /// The root of the sky_engine package.
  skyEnginePath('sky_engine'),

  // The Impeller shader compiler.
  impellerc('impellerc', isExecutable: true),
  // Impeller's tessellation library.
  libtessellator('libtessellator', isDll: true);

  const HostArtifact(this._fileName, {this.isExecutable = false, this.isDll = false});

  const HostArtifact.directory() : _fileName = '', isExecutable = false, isDll = false;

  final String _fileName;
  final bool isExecutable;
  final bool isDll;

  String getFileName(Platform platform) {
    if (isDll) {
      var dll = '.so';
      if (platform.isWindows) {
        dll = '.dll';
      } else if (platform.isMacOS) {
        dll = '.dylib';
      }
      return '$_fileName$dll';
    }
    final exe = (isExecutable && platform.isWindows) ? '.exe' : '';
    return '$_fileName$exe';
  }
}

// TODO(knopp): Remove once darwin artifacts are universal and moved out of darwin-x64
String _enginePlatformDirectoryName(TargetPlatform platform) {
  if (platform == TargetPlatform.darwin) {
    return 'darwin-x64';
  }
  return platform.getName();
}

// Remove android target platform type.
TargetPlatform? _mapTargetPlatform(TargetPlatform? targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.android:
      return TargetPlatform.android_arm64;
    case TargetPlatform.ios:
    case TargetPlatform.darwin:
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.linux_riscv64:
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.unsupported:
    case null:
      return targetPlatform;
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
/// See https://github.com/flutter/flutter/blob/main/docs/tool/README.md#using-a-locally-built-engine-with-the-flutter-tool
/// for more information about local engine builds.
class LocalEngineInfo {
  /// Creates a reference to a local engine build.
  ///
  /// The [targetOutPath] and [hostOutPath] are assumed to be resolvable
  /// paths to the built engine artifacts for the target (device) and host
  /// (build) platforms, respectively.
  const LocalEngineInfo({required this.targetOutPath, required this.hostOutPath});

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
    return _TestLocalEngine(localEngine, localEngineHost, fileSystem ?? MemoryFileSystem.test());
  }

  static Artifacts getLocalEngine(EngineBuildPaths engineBuildPaths) {
    Artifacts artifacts = CachedArtifacts(
      fileSystem: globals.fs,
      platform: globals.platform,
      cache: globals.cache,
      operatingSystemUtils: globals.os,
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
        operatingSystemUtils: globals.os,
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
  FileSystemEntity getHostArtifact(HostArtifact artifact);

  // Returns which set of engine artifacts is currently used for the [platform]
  // and [mode] combination.
  String getEngineType(TargetPlatform platform, [BuildMode? mode]);

  /// Whether these artifacts use any locally built files that are not part of
  /// a versioned engine.
  bool get usesLocalArtifacts;

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
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.flutterWebSdk:
      case HostArtifact.flutterWebLibrariesJson:
      case HostArtifact.flutterJsDirectory:
      case HostArtifact.webPlatformKernelFolder:
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPrecompiledAmdCanvaskitSdk:
      case HostArtifact.webPrecompiledAmdCanvaskitSdkSourcemaps:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdk:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps:
        return _resolveWebArtifact(artifact, _getFlutterWebSdkPath(), _fileSystem, _platform);
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
        final String artifactFileName = artifact.getFileName(_platform);
        return _cache.getArtifactDirectory('libimobiledevice').childFile(artifactFileName);
      case HostArtifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        final String path = _fileSystem.path.join(
          dartPackageDirectory.path,
          artifact.getFileName(_platform),
        );
        return _fileSystem.directory(path);
      case HostArtifact.iosDeploy:
        final String artifactFileName = artifact.getFileName(_platform);
        return _cache.getArtifactDirectory('ios-deploy').childFile(artifactFileName);
      case HostArtifact.iproxy:
        final String artifactFileName = artifact.getFileName(_platform);
        return _cache.getArtifactDirectory('libusbmuxd').childFile(artifactFileName);
      case HostArtifact.impellerc:
      case HostArtifact.libtessellator:
        final String artifactFileName = artifact.getFileName(_platform);
        final String engineDir = _getEngineArtifactsPath(
          _currentHostPlatform(_platform, _operatingSystemUtils),
        )!;
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
        assert(platform != TargetPlatform.android);
        return _getAndroidArtifactPath(artifact, platform!, mode!);
      case TargetPlatform.ios:
        return _getIosArtifactPath(artifact, platform!, mode, environmentType);
      case TargetPlatform.darwin:
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_riscv64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.windows_arm64:
        return _getDesktopArtifactPath(artifact, platform!, mode);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
        return _getFuchsiaArtifactPath(artifact, platform!, mode!);
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case null:
        return _getHostArtifactPath(
          artifact,
          platform ?? _currentHostPlatform(_platform, _operatingSystemUtils),
          mode,
        );
      case TargetPlatform.unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) {
    return _fileSystem.path.basename(_getEngineArtifactsPath(platform, mode)!);
  }

  String _getDesktopArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode? mode) {
    // When platform is null, a generic host platform artifact is being requested
    // and not the gen_snapshot for darwin as a target platform.
    final String engineDir = _getEngineArtifactsPath(platform, mode)!;
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
        return _fileSystem.path.join(engineDir, artifact.getFileName(_platform));
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterFrameworkDsym:
      case Artifact.flutterMacOSFramework:
        return _getMacOSFrameworkPath(engineDir, _fileSystem, _platform);
      case Artifact.flutterMacOSFrameworkDsym:
        return _getMacOSFrameworkDsymPath(engineDir, _fileSystem, _platform);
      case Artifact.flutterMacOSXcframework:
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

  String _getAndroidArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String engineDir = _getEngineArtifactsPath(platform, mode)!;
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
        assert(mode != BuildMode.debug, 'Artifact $artifact only available in non-debug mode.');

        // TODO(cbracken): Build Android gen_snapshot as Arm64 binary to run
        // natively on Apple Silicon. See:
        // https://github.com/flutter/flutter/issues/152281
        HostPlatform hostPlatform = getCurrentHostPlatform();
        if (hostPlatform == HostPlatform.darwin_arm64) {
          hostPlatform = HostPlatform.darwin_x64;
        }

        final String hostPlatformName = hostPlatform.cliName;
        return _fileSystem.path.join(engineDir, hostPlatformName, artifact.getFileName(_platform));
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterFrameworkDsym:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterMacOSFrameworkDsym:
      case Artifact.flutterMacOSXcframework:
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

  String _getIosArtifactPath(
    Artifact artifact,
    TargetPlatform platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  ) {
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
      case Artifact.flutterXcframework:
        final String artifactFileName = artifact.getFileName(_platform);
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _fileSystem.path.join(engineDir, artifactFileName);
      case Artifact.flutterFramework:
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _getIosFrameworkPath(engineDir, environmentType, _fileSystem, _platform);
      case Artifact.flutterFrameworkDsym:
        final String engineDir = _getEngineArtifactsPath(platform, mode)!;
        return _getIosFrameworkDsymPath(engineDir, environmentType, _fileSystem, _platform);
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
      case Artifact.frontendServerSnapshotForEngineDartSdk:
      case Artifact.constFinder:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterMacOSFrameworkDsym:
      case Artifact.flutterMacOSXcframework:
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
    final runtime = mode.isJit ? 'jit' : 'aot';
    switch (artifact) {
      case Artifact.genSnapshot:
        final genSnapshot = mode.isRelease ? 'gen_snapshot_product' : 'gen_snapshot';
        return _fileSystem.path.join(root, runtime, 'dart_binaries', genSnapshot);
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
        throw ArgumentError('$artifact is not available on this platform');
      case Artifact.flutterPatchedSdkPath:
        const artifactFileName = 'flutter_runner_patched_sdk';
        return _fileSystem.path.join(root, runtime, artifactFileName);
      case Artifact.platformKernelDill:
        final String artifactFileName = artifact.getFileName(_platform, mode);
        return _fileSystem.path.join(root, runtime, 'flutter_runner_patched_sdk', artifactFileName);
      case Artifact.fuchsiaKernelCompiler:
        final String artifactFileName = artifact.getFileName(_platform, mode);
        return _fileSystem.path.join(root, runtime, 'dart_binaries', artifactFileName);
      case Artifact.fuchsiaFlutterRunner:
        final String artifactFileName = artifact.getFileName(_platform, mode);
        return _fileSystem.path.join(root, runtime, artifactFileName);
      case Artifact.constFinder:
      case Artifact.flutterFramework:
      case Artifact.flutterFrameworkDsym:
      case Artifact.flutterMacOSFramework:
      case Artifact.flutterMacOSFrameworkDsym:
      case Artifact.flutterMacOSXcframework:
      case Artifact.flutterTester:
      case Artifact.flutterXcframework:
      case Artifact.fontSubset:
      case Artifact.engineDartSdkPath:
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
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
    return _fileSystem.path.join(
      engineArtifactsPath,
      'common',
      mode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk',
    );
  }

  String _getFlutterWebSdkPath() {
    return _cache.getWebSdkDirectory().path;
  }

  String _getHostArtifactPath(Artifact artifact, TargetPlatform platform, BuildMode? mode) {
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
        // For script snapshots any gen_snapshot binary will do. Returning gen_snapshot for
        // android_arm in profile mode because it is available on all supported host platforms.
        return _getAndroidArtifactPath(artifact, TargetPlatform.android_arm, BuildMode.profile);
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(
          _dartSdkPath(_cache),
          'bin',
          'snapshots',
          artifact.getFileName(_platform),
        );
      case Artifact.flutterTester:
      case Artifact.vmSnapshotData:
      case Artifact.isolateSnapshotData:
      case Artifact.icuData:
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        final String platformDirName = _enginePlatformDirectoryName(platform);
        return _fileSystem.path.join(
          engineArtifactsPath,
          platformDirName,
          artifact.getFileName(_platform, mode),
        );
      case Artifact.platformKernelDill:
        return _fileSystem.path.join(
          _getFlutterPatchedSdkPath(mode),
          artifact.getFileName(_platform),
        );
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(
          _getFlutterPatchedSdkPath(mode),
          'lib',
          artifact.getFileName(_platform),
        );
      case Artifact.flutterPatchedSdkPath:
        return _getFlutterPatchedSdkPath(mode);
      case Artifact.engineDartSdkPath:
        return _dartSdkPath(_cache);
      case Artifact.engineDartBinary:
      case Artifact.engineDartAotRuntime:
        return _fileSystem.path.join(_dartSdkPath(_cache), 'bin', artifact.getFileName(_platform));
      case Artifact.flutterMacOSFramework:
        String platformDirName = _enginePlatformDirectoryName(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${mode!.cliName}';
        }
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _getMacOSFrameworkPath(
          _fileSystem.path.join(engineArtifactsPath, platformDirName),
          _fileSystem,
          _platform,
        );
      case Artifact.flutterMacOSFrameworkDsym:
        String platformDirName = _enginePlatformDirectoryName(platform);
        if (mode == BuildMode.profile || mode == BuildMode.release) {
          platformDirName = '$platformDirName-${mode!.cliName}';
        }
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _getMacOSFrameworkDsymPath(
          _fileSystem.path.join(engineArtifactsPath, platformDirName),
          _fileSystem,
          _platform,
        );
      case Artifact.flutterMacOSXcframework:
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
        return _fileSystem.path.join(
          engineArtifactsPath,
          platformDirName,
          artifact.getFileName(_platform, mode),
        );
      case Artifact.windowsCppClientWrapper:
        final String platformDirName = _enginePlatformDirectoryName(platform);
        final String engineArtifactsPath = _cache.getArtifactDirectory('engine').path;
        return _fileSystem.path.join(
          engineArtifactsPath,
          platformDirName,
          artifact.getFileName(_platform, mode),
        );
      case Artifact.skyEnginePath:
        final Directory dartPackageDirectory = _cache.getCacheDir('pkg');
        return _fileSystem.path.join(dartPackageDirectory.path, artifact.getFileName(_platform));
      case Artifact.fontSubset:
      case Artifact.constFinder:
        return _cache
            .getArtifactDirectory('engine')
            .childDirectory(_enginePlatformDirectoryName(platform))
            .childFile(artifact.getFileName(_platform, mode))
            .path;
      case Artifact.flutterFramework:
      case Artifact.flutterFrameworkDsym:
      case Artifact.flutterXcframework:
      case Artifact.fuchsiaFlutterRunner:
      case Artifact.fuchsiaKernelCompiler:
        throw StateError('Artifact $artifact not available for platform $platform.');
      case Artifact.flutterToolsFileGenerators:
        return _getFileGeneratorsPath();
    }
  }

  String? _getEngineArtifactsPath(TargetPlatform platform, [BuildMode? mode]) {
    final String engineDir = _cache.getArtifactDirectory('engine').path;
    final String platformName = _enginePlatformDirectoryName(platform);
    switch (platform) {
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_riscv64:
      case TargetPlatform.darwin:
      case TargetPlatform.windows_x64:
      case TargetPlatform.windows_arm64:
        // TODO(zanderso): remove once debug desktop artifacts are uploaded
        // under a separate directory from the host artifacts.
        // https://github.com/flutter/flutter/issues/38935
        if (mode == BuildMode.debug || mode == null) {
          return _fileSystem.path.join(engineDir, platformName);
        }
        final suffix = mode != BuildMode.debug ? '-${kebabCase(mode.cliName)}' : '';
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
        assert(mode != null, 'Need to specify a build mode for platform $platform.');
        final suffix = mode != BuildMode.debug ? '-${kebabCase(mode!.cliName)}' : '';
        return _fileSystem.path.join(engineDir, platformName + suffix);
      case TargetPlatform.android:
        assert(false, 'cannot use TargetPlatform.android to look up artifacts');
        return null;
      case TargetPlatform.unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }

  @override
  bool get usesLocalArtifacts => false;
}

TargetPlatform _currentHostPlatform(Platform platform, OperatingSystemUtils operatingSystemUtils) {
  if (platform.isMacOS) {
    return TargetPlatform.darwin;
  }
  if (platform.isLinux) {
    return switch (operatingSystemUtils.hostPlatform) {
      HostPlatform.linux_x64 => TargetPlatform.linux_x64,
      HostPlatform.linux_riscv64 => TargetPlatform.linux_riscv64,
      _ => TargetPlatform.linux_arm64,
    };
  }
  if (platform.isWindows) {
    return operatingSystemUtils.hostPlatform == HostPlatform.windows_arm64
        ? TargetPlatform.windows_arm64
        : TargetPlatform.windows_x64;
  }
  throw UnimplementedError('Host OS not supported.');
}

/// Returns the Flutter.xcframework platform directory for the specified environment type.
///
/// `Flutter.xcframework` contains target environment/architecture-specific
/// subdirectories containing the appropriate `Flutter.framework` and
/// `dSYMs/Flutter.framework.dSYMs` bundles for that target architecture.
Directory _getIosFlutterFrameworkPlatformDirectory(
  String engineDirectory,
  EnvironmentType? environmentType,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory xcframeworkDirectory = fileSystem
      .directory(engineDirectory)
      .childDirectory(Artifact.flutterXcframework.getFileName(hostPlatform));

  if (!xcframeworkDirectory.existsSync()) {
    throwToolExit(
      'No xcframework found at ${xcframeworkDirectory.path}. Try running "flutter precache --ios".',
    );
  }

  // NOTE: If you modify this function, you should likely also update the equivalent implementation in
  // packages/flutter_tools/templates/add_to_app/darwin/Tools/FlutterToolHelper/FlutterAssembleToolHelper.swift.tmpl
  for (final Directory platformDirectory
      in xcframeworkDirectory.listSync().whereType<Directory>()) {
    if (!platformDirectory.basename.startsWith('ios-')) {
      continue;
    }
    // ios-x86_64-simulator, ios-arm64_x86_64-simulator, or ios-arm64.
    final bool simulatorDirectory = platformDirectory.basename.endsWith('-simulator');
    if ((environmentType == EnvironmentType.simulator && simulatorDirectory) ||
        (environmentType == EnvironmentType.physical && !simulatorDirectory)) {
      return platformDirectory;
    }
  }
  throwToolExit('No iOS frameworks found in ${xcframeworkDirectory.path}');
}

/// Returns the path to Flutter.framework.
String _getIosFrameworkPath(
  String engineDirectory,
  EnvironmentType? environmentType,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory platformDir = _getIosFlutterFrameworkPlatformDirectory(
    engineDirectory,
    environmentType,
    fileSystem,
    hostPlatform,
  );
  return platformDir.childDirectory(Artifact.flutterFramework.getFileName(hostPlatform)).path;
}

/// Returns the path to Flutter.framework.dSYM.
String _getIosFrameworkDsymPath(
  String engineDirectory,
  EnvironmentType? environmentType,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory platformDir = _getIosFlutterFrameworkPlatformDirectory(
    engineDirectory,
    environmentType,
    fileSystem,
    hostPlatform,
  );
  return platformDir
      .childDirectory('dSYMs')
      .childDirectory(Artifact.flutterFrameworkDsym.getFileName(hostPlatform))
      .path;
}

/// Returns the Flutter.xcframework platform directory for the specified environment type.
///
/// `FlutterMacOS.xcframework` contains target environment/architecture-specific
/// subdirectories containing the appropriate `FlutterMacOS.framework` and
/// `FlutterMacOS.framework.dSYM` bundles for that target architecture. At present,
/// there is only one such directory: `macos-arm64_x86_64`.
Directory _getMacOSFrameworkPlatformDirectory(
  String engineDirectory,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory xcframeworkDirectory = fileSystem
      .directory(engineDirectory)
      .childDirectory(Artifact.flutterMacOSXcframework.getFileName(hostPlatform));

  if (!xcframeworkDirectory.existsSync()) {
    throwToolExit(
      'No xcframework found at ${xcframeworkDirectory.path}. Try running "flutter precache --macos".',
    );
  }
  // NOTE: If you modify this function, you should likely also update the equivalent implementation in
  // packages/flutter_tools/templates/add_to_app/darwin/Tools/FlutterToolHelper/FlutterAssembleToolHelper.swift.tmpl
  final Directory? platformDirectory = xcframeworkDirectory
      .listSync()
      .whereType<Directory>()
      .where((Directory platformDirectory) => platformDirectory.basename.startsWith('macos-'))
      .firstOrNull;
  if (platformDirectory == null) {
    throwToolExit('No macOS frameworks found in ${xcframeworkDirectory.path}');
  }
  return platformDirectory;
}

/// Returns the path to `FlutterMacOS.framework`.
String _getMacOSFrameworkPath(
  String engineDirectory,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory platformDirectory = _getMacOSFrameworkPlatformDirectory(
    engineDirectory,
    fileSystem,
    hostPlatform,
  );
  return platformDirectory
      .childDirectory(Artifact.flutterMacOSFramework.getFileName(hostPlatform))
      .path;
}

/// Returns the path to `FlutterMacOS.framework`.
String _getMacOSFrameworkDsymPath(
  String engineDirectory,
  FileSystem fileSystem,
  Platform hostPlatform,
) {
  final Directory platformDirectory = _getMacOSFrameworkPlatformDirectory(
    engineDirectory,
    fileSystem,
    hostPlatform,
  );
  return platformDirectory
      .childDirectory('dSYMs')
      .childDirectory(Artifact.flutterMacOSFrameworkDsym.getFileName(hostPlatform))
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
       localEngineInfo = LocalEngineInfo(
         targetOutPath: engineOutPath,
         hostOutPath: _hostEngineOutPath,
       ),
       _processManager = processManager,
       _platform = platform,
       _operatingSystemUtils = operatingSystemUtils,
       _backupCache =
           parent ??
           CachedArtifacts(
             fileSystem: fileSystem,
             platform: platform,
             cache: cache,
             operatingSystemUtils: operatingSystemUtils,
           );

  @override
  final LocalEngineInfo localEngineInfo;

  final String _hostEngineOutPath;
  final FileSystem _fileSystem;
  final ProcessManager _processManager;
  final Platform _platform;
  final OperatingSystemUtils _operatingSystemUtils;
  final Artifacts _backupCache;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.impellerc:
      case HostArtifact.libtessellator:
        final String artifactFileName = artifact.getFileName(_platform);
        final File file = _fileSystem.file(
          _fileSystem.path.join(_hostEngineOutPath, artifactFileName),
        );
        if (!file.existsSync()) {
          return _backupCache.getHostArtifact(artifact);
        }
        return file;
      case HostArtifact.flutterWebSdk:
      case HostArtifact.flutterWebLibrariesJson:
      case HostArtifact.flutterJsDirectory:
      case HostArtifact.webPlatformKernelFolder:
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPrecompiledAmdCanvaskitSdk:
      case HostArtifact.webPrecompiledAmdCanvaskitSdkSourcemaps:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdk:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps:
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
      case HostArtifact.skyEnginePath:
      case HostArtifact.iosDeploy:
      case HostArtifact.iproxy:
        return _backupCache.getHostArtifact(artifact);
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
    final isDirectoryArtifact = artifact == Artifact.flutterPatchedSdkPath;
    final String? artifactFileName = isDirectoryArtifact
        ? null
        : artifact.getFileName(_platform, mode);
    switch (artifact) {
      case Artifact.genSnapshot:
      case Artifact.genSnapshotArm64:
      case Artifact.genSnapshotRiscv64:
      case Artifact.genSnapshotX64:
        return _genSnapshotPath(artifact);
      case Artifact.flutterTester:
        return _flutterTesterPath(platform!);
      case Artifact.isolateSnapshotData:
      case Artifact.vmSnapshotData:
        return _fileSystem.path.join(
          localEngineInfo.targetOutPath,
          'gen',
          'flutter',
          'lib',
          'snapshot',
          artifactFileName,
        );
      case Artifact.icuData:
      case Artifact.flutterXcframework:
      case Artifact.flutterMacOSXcframework:
        return _fileSystem.path.join(localEngineInfo.targetOutPath, artifactFileName);
      case Artifact.platformKernelDill:
        if (platform == TargetPlatform.fuchsia_x64 || platform == TargetPlatform.fuchsia_arm64) {
          return _fileSystem.path.join(
            localEngineInfo.targetOutPath,
            'flutter_runner_patched_sdk',
            artifactFileName,
          );
        }
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), artifactFileName);
      case Artifact.platformLibrariesJson:
        return _fileSystem.path.join(_getFlutterPatchedSdkPath(mode), 'lib', artifactFileName);
      case Artifact.flutterFramework:
        return _getIosFrameworkPath(
          localEngineInfo.targetOutPath,
          environmentType,
          _fileSystem,
          _platform,
        );
      case Artifact.flutterFrameworkDsym:
        return _getIosFrameworkDsymPath(
          localEngineInfo.targetOutPath,
          environmentType,
          _fileSystem,
          _platform,
        );
      case Artifact.flutterMacOSFramework:
        return _getMacOSFrameworkPath(localEngineInfo.targetOutPath, _fileSystem, _platform);
      case Artifact.flutterMacOSFrameworkDsym:
        return _getMacOSFrameworkDsymPath(localEngineInfo.targetOutPath, _fileSystem, _platform);
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
        final String hostPlatform = getCurrentHostPlatform().cliName;
        final modeName = mode!.isRelease ? 'release' : mode.toString();
        final dartBinaries = 'dart_binaries-$modeName-$hostPlatform';
        return _fileSystem.path.join(
          localEngineInfo.targetOutPath,
          'host_bundle',
          dartBinaries,
          'kernel_compiler.dart.snapshot',
        );
      case Artifact.fuchsiaFlutterRunner:
        final jitOrAot = mode!.isJit ? '_jit' : '_aot';
        final productOrNo = mode.isRelease ? '_product' : '';
        return _fileSystem.path.join(
          localEngineInfo.targetOutPath,
          'flutter$jitOrAot${productOrNo}_runner-0.far',
        );
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
      case Artifact.frontendServerSnapshotForEngineDartSdk:
        return _fileSystem.path.join(_getDartSdkPath(), 'bin', 'snapshots', artifactFileName);
      case Artifact.flutterToolsFileGenerators:
        return _getFileGeneratorsPath();
    }
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) {
    return _fileSystem.path.basename(localEngineInfo.targetOutPath);
  }

  String _getFlutterPatchedSdkPath(BuildMode? buildMode) {
    return _fileSystem.path.join(
      localEngineInfo.targetOutPath,
      buildMode == BuildMode.release ? 'flutter_patched_sdk_product' : 'flutter_patched_sdk',
    );
  }

  String _getDartSdkPath() {
    final String builtPath = _fileSystem.path.join(_hostEngineOutPath, 'dart-sdk');
    if (_fileSystem.isDirectorySync(_fileSystem.path.join(builtPath, 'bin'))) {
      return builtPath;
    }

    // If we couldn't find a built dart sdk, let's look for a prebuilt one.
    final String prebuiltPath = _fileSystem.path.join(
      _getFlutterPrebuiltsPath(_hostEngineOutPath, _fileSystem),
      _getPrebuiltTarget(_platform, _operatingSystemUtils),
      'dart-sdk',
    );
    if (_fileSystem.isDirectorySync(prebuiltPath)) {
      return prebuiltPath;
    }

    throwToolExit(
      'Unable to find a built dart sdk at: "$builtPath" or a prebuilt dart sdk at: "$prebuiltPath"',
    );
  }

  String _genSnapshotPath(Artifact artifact) {
    const clangDirs = <String>[
      '.',
      'universal',
      'clang_x64',
      'clang_x86',
      'clang_i386',
      'clang_arm64',
      'clang_riscv64',
    ];
    final String genSnapshotName = artifact.getFileName(_platform);
    for (final clangDir in clangDirs) {
      final String genSnapshotPath = _fileSystem.path.join(
        localEngineInfo.targetOutPath,
        clangDir,
        genSnapshotName,
      );
      if (_processManager.canRun(genSnapshotPath)) {
        return genSnapshotPath;
      }
    }
    throw Exception('Unable to find $genSnapshotName');
  }

  String _flutterTesterPath(TargetPlatform platform) {
    return _fileSystem.path.join(
      localEngineInfo.hostOutPath,
      Artifact.flutterTester.getFileName(_platform),
    );
  }

  @override
  bool get usesLocalArtifacts => true;
}

class CachedLocalWebSdkArtifacts implements Artifacts {
  CachedLocalWebSdkArtifacts({
    required Artifacts parent,
    required String webSdkPath,
    required FileSystem fileSystem,
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
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
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (platform == TargetPlatform.web_javascript) {
      switch (artifact) {
        case Artifact.engineDartSdkPath:
          return _getDartSdkPath();
        case Artifact.engineDartBinary:
        case Artifact.engineDartAotRuntime:
          return _fileSystem.path.join(
            _getDartSdkPath(),
            'bin',
            artifact.getFileName(_platform, mode),
          );
        case Artifact.frontendServerSnapshotForEngineDartSdk:
          return _fileSystem.path.join(
            _getDartSdkPath(),
            'bin',
            'snapshots',
            artifact.getFileName(_platform, mode),
          );
        case Artifact.genSnapshot:
        case Artifact.genSnapshotArm64:
        case Artifact.genSnapshotRiscv64:
        case Artifact.genSnapshotX64:
        case Artifact.flutterTester:
        case Artifact.flutterFramework:
        case Artifact.flutterFrameworkDsym:
        case Artifact.flutterXcframework:
        case Artifact.flutterMacOSFramework:
        case Artifact.flutterMacOSFrameworkDsym:
        case Artifact.flutterMacOSXcframework:
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
    return _parent.getArtifactPath(
      artifact,
      platform: platform,
      mode: mode,
      environmentType: environmentType,
    );
  }

  @override
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) =>
      _parent.getEngineType(platform, mode);

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    switch (artifact) {
      case HostArtifact.flutterWebSdk:
      case HostArtifact.flutterWebLibrariesJson:
      case HostArtifact.flutterJsDirectory:
      case HostArtifact.webPlatformKernelFolder:
      case HostArtifact.webPlatformDDCKernelDill:
      case HostArtifact.webPlatformDart2JSKernelDill:
      case HostArtifact.webPrecompiledAmdCanvaskitSdk:
      case HostArtifact.webPrecompiledAmdCanvaskitSdkSourcemaps:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdk:
      case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps:
        return _resolveWebArtifact(artifact, _getFlutterWebSdkPath(), _fileSystem, _platform);
      case HostArtifact.iosDeploy:
      case HostArtifact.idevicesyslog:
      case HostArtifact.idevicescreenshot:
      case HostArtifact.iproxy:
      case HostArtifact.skyEnginePath:
      case HostArtifact.impellerc:
      case HostArtifact.libtessellator:
        return _parent.getHostArtifact(artifact);
    }
  }

  String _getDartSdkPath() {
    // If the parent is a local engine, then use the locally built Dart SDK.
    if (_parent.usesLocalArtifacts) {
      return _parent.getArtifactPath(Artifact.engineDartSdkPath);
    }

    // If we couldn't find a built dart sdk, let's look for a prebuilt one.
    final String prebuiltPath = _fileSystem.path.join(
      _getFlutterPrebuiltsPath(_webSdkPath, _fileSystem),
      _getPrebuiltTarget(_platform, _operatingSystemUtils),
      'dart-sdk',
    );
    if (_fileSystem.isDirectorySync(prebuiltPath)) {
      return prebuiltPath;
    }

    throwToolExit('Unable to find a prebuilt dart sdk at: "$prebuiltPath"');
  }

  String _getFlutterWebSdkPath() {
    return _fileSystem.path.join(_webSdkPath, 'flutter_web_sdk');
  }

  @override
  bool get usesLocalArtifacts => true;

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
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) =>
      parent.getEngineType(platform, mode);

  @override
  bool get usesLocalArtifacts => parent.usesLocalArtifacts;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    return parent.getHostArtifact(artifact);
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

    final buffer = StringBuffer();
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
  String getEngineType(TargetPlatform platform, [BuildMode? mode]) {
    return 'test-engine';
  }

  @override
  bool get usesLocalArtifacts => false;

  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    return fileSystem.file(artifact.toString());
  }
}

class _TestLocalEngine extends _TestArtifacts {
  _TestLocalEngine(String engineOutPath, String engineHostOutPath, super.fileSystem)
    : localEngineInfo = LocalEngineInfo(
        targetOutPath: engineOutPath,
        hostOutPath: engineHostOutPath,
      );

  @override
  bool get usesLocalArtifacts => true;

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

FileSystemEntity _resolveWebArtifact(
  HostArtifact artifact,
  String webSdkPath,
  FileSystem fileSystem,
  Platform platform,
) {
  switch (artifact) {
    case HostArtifact.flutterWebSdk:
      return fileSystem.directory(webSdkPath);
    case HostArtifact.flutterWebLibrariesJson:
      return fileSystem.file(fileSystem.path.join(webSdkPath, artifact.getFileName(platform)));
    case HostArtifact.flutterJsDirectory:
      return fileSystem.directory(fileSystem.path.join(webSdkPath, artifact.getFileName(platform)));
    case HostArtifact.webPlatformKernelFolder:
      return fileSystem.file(fileSystem.path.join(webSdkPath, artifact.getFileName(platform)));
    case HostArtifact.webPlatformDDCKernelDill:
    case HostArtifact.webPlatformDart2JSKernelDill:
      return fileSystem.file(
        fileSystem.path.join(webSdkPath, 'kernel', artifact.getFileName(platform)),
      );
    case HostArtifact.webPrecompiledAmdCanvaskitSdk:
    case HostArtifact.webPrecompiledAmdCanvaskitSdkSourcemaps:
      return fileSystem.file(
        fileSystem.path.join(webSdkPath, 'kernel', 'amd-canvaskit', artifact.getFileName(platform)),
      );
    case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdk:
    case HostArtifact.webPrecompiledDdcLibraryBundleCanvaskitSdkSourcemaps:
      return fileSystem.file(
        fileSystem.path.join(
          webSdkPath,
          'kernel',
          'ddcLibraryBundle-canvaskit',
          artifact.getFileName(platform),
        ),
      );
    case HostArtifact.iosDeploy:
    case HostArtifact.idevicesyslog:
    case HostArtifact.idevicescreenshot:
    case HostArtifact.iproxy:
    case HostArtifact.skyEnginePath:
    case HostArtifact.impellerc:
    case HostArtifact.libtessellator:
      throw ArgumentError('Not a web artifact: $artifact');
  }
}

String _getFlutterPrebuiltsPath(String baseOutPath, FileSystem fileSystem) {
  final String engineSrcPath = fileSystem.path.dirname(fileSystem.path.dirname(baseOutPath));
  return fileSystem.path.join(engineSrcPath, 'flutter', 'prebuilts');
}

String _getPrebuiltTarget(Platform platform, OperatingSystemUtils operatingSystemUtils) {
  final TargetPlatform hostPlatform = _currentHostPlatform(platform, operatingSystemUtils);
  switch (hostPlatform) {
    case TargetPlatform.darwin:
      return 'macos-x64';
    case TargetPlatform.linux_riscv64:
      return 'linux-riscv64';
    case TargetPlatform.linux_arm:
    case TargetPlatform.linux_arm64:
      return 'linux-arm64';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
    case TargetPlatform.windows_x64:
      return 'windows-x64';
    case TargetPlatform.windows_arm64:
      return 'windows-arm64';
    case TargetPlatform.ios:
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.web_javascript:
    case TargetPlatform.tester:
      throwToolExit('Unsupported host platform: $hostPlatform');
    case TargetPlatform.unsupported:
      TargetPlatform.throwUnsupportedTarget();
  }
}
