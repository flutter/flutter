// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../bundle_builder.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'build_rust.dart';

/// The local Linux host running an application through the Rust shell.
class RustShellDevice extends DesktopDevice {
  RustShellDevice({
    required super.processManager,
    required super.logger,
    required super.fileSystem,
    required super.operatingSystemUtils,
    BundleBuilder? bundleBuilder,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager),
       _bundleBuilder = bundleBuilder ?? BundleBuilder(),
       super('rust', platformType: PlatformType.linux, ephemeral: false);

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final BundleBuilder _bundleBuilder;

  @override
  String get name => 'Flutter Rust Shell';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.linux_x64;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.x64;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.manifest.usesRustShell &&
        flutterProject.directory.childDirectory('runner-rs').childFile('Cargo.toml').existsSync();
  }

  @override
  bool supportsRuntimeMode(BuildMode buildMode) =>
      buildMode == BuildMode.debug || buildMode == BuildMode.release;

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
    bool usingCISystem = false,
  }) async {
    await buildRust(
      FlutterProject.current(),
      buildInfo,
      mainPath: mainPath,
      bundleBuilder: _bundleBuilder,
      processUtils: _processUtils,
      logger: _logger,
      fileSystem: _fileSystem,
    );
  }

  @override
  String executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) {
    final FlutterProject project = FlutterProject.current();
    return _fileSystem.path.join(
      project.directory.path,
      'runner-rs',
      'target',
      buildInfo.mode == BuildMode.release ? 'release' : 'debug',
      project.manifest.appName,
    );
  }

  @override
  List<String> launchArgumentsForDevice(
    ApplicationPackage package,
    DebuggingOptions debuggingOptions,
  ) => <String>[getAssetBuildDirectory()];
}

/// Discovers the built-in Rust shell pseudo-device on supported hosts.
class RustShellDevices extends DeviceDiscovery {
  RustShellDevices({
    required Platform platform,
    required OperatingSystemUtils operatingSystemUtils,
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
  }) : _platform = platform,
       _operatingSystemUtils = operatingSystemUtils,
       _processManager = processManager,
       _logger = logger,
       _fileSystem = fileSystem;

  final Platform _platform;
  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;

  @override
  bool get supportsPlatform => _platform.isLinux;

  @override
  bool get canListAnything =>
      supportsPlatform && _operatingSystemUtils.hostPlatform == HostPlatform.linux_x64;

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) => _devices(filter);

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
    bool forWirelessDiscovery = false,
  }) => _devices(filter);

  Future<List<Device>> _devices(DeviceDiscoveryFilter? filter) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    final devices = <Device>[
      RustShellDevice(
        processManager: _processManager,
        logger: _logger,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
      ),
    ];
    return filter?.filterDevices(devices) ?? devices;
  }

  @override
  List<String> get wellKnownIds => const <String>['rust'];
}
