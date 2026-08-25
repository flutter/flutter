// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice({
    required super.fileSystem,
    required super.logger,
    required super.operatingSystemUtils,
    required super.processManager,
    super.artifacts,
  }) : _operatingSystemUtils = operatingSystemUtils,
       _logger = logger,
       super('linux', platformType: PlatformType.linux, ephemeral: false);

  final OperatingSystemUtils _operatingSystemUtils;
  final Logger _logger;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool get supportsFlavors => true;

  @override
  String get name => 'Linux';

  @override
  late final Future<TargetPlatform> targetPlatform = () async {
    if (_operatingSystemUtils.hostPlatform == HostPlatform.linux_x64) {
      return TargetPlatform.linux_x64;
    } else if (_operatingSystemUtils.hostPlatform == HostPlatform.linux_riscv64) {
      return TargetPlatform.linux_riscv64;
    }
    return TargetPlatform.linux_arm64;
  }();

  @override
  Future<CpuArch> get cpuArch async => CpuArch.fromHostPlatform(_operatingSystemUtils.hostPlatform);

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.linux.existsSync();
  }

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
    bool usingCISystem = false,
  }) async {
    await buildLinux(
      FlutterProject.current().linux,
      buildInfo,
      target: mainPath,
      targetPlatform: await targetPlatform,
      logger: _logger,
    );
  }

  @override
  String executablePathForDevice(covariant LinuxApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo.mode, buildInfo.flavor);
  }
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices({
    required FeatureFlags featureFlags,
    required FileSystem fileSystem,
    required Logger logger,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
    required ProcessManager processManager,
    Artifacts? artifacts,
  }) : _platform = platform,
       _linuxWorkflow = LinuxWorkflow(platform: platform, featureFlags: featureFlags),
       _fileSystem = fileSystem,
       _logger = logger,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       _artifacts = artifacts ?? globals.artifacts!,
       super('linux devices');

  final Platform _platform;
  final LinuxWorkflow _linuxWorkflow;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;
  final Artifacts _artifacts;

  @override
  bool get supportsPlatform => _platform.isLinux;

  @override
  bool get canListAnything => _linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(
        logger: _logger,
        processManager: _processManager,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
        artifacts: _artifacts,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['linux'];
}
