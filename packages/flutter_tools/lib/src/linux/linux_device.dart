// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice({required ToolContext toolContext})
    : _toolContext = toolContext,
      super(
        'linux',
        ephemeral: false,
        fileSystem: toolContext.fs,
        logger: toolContext.logger,
        operatingSystemUtils: toolContext.os,
        platformType: PlatformType.linux,
        processManager: toolContext.processManager,
      );

  final ToolContext _toolContext;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool get supportsFlavors => true;

  @override
  String get name => 'Linux';

  @override
  late final Future<TargetPlatform> targetPlatform = () async {
    final OperatingSystemUtils os = _toolContext.os;
    if (os.hostPlatform == HostPlatform.linux_x64) {
      return TargetPlatform.linux_x64;
    } else if (os.hostPlatform == HostPlatform.linux_riscv64) {
      return TargetPlatform.linux_riscv64;
    }
    return TargetPlatform.linux_arm64;
  }();

  @override
  Future<CpuArch> get cpuArch async {
    final OperatingSystemUtils os = _toolContext.os;
    return CpuArch.fromHostPlatform(os.hostPlatform);
  }

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
    final ToolContext(:Cache cache, :Logger logger) = _toolContext;
    await buildLinux(
      FlutterProject.current().linux,
      buildInfo,
      flutterRoot: cache.flutterRoot,
      target: mainPath,
      targetPlatform: await targetPlatform,
      logger: logger,
    );
  }

  @override
  String executablePathForDevice(covariant LinuxApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo.mode, buildInfo.flavor);
  }
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices({required FeatureFlags featureFlags, required ToolContext toolContext})
    : _toolContext = toolContext,
      _linuxWorkflow = LinuxWorkflow(platform: toolContext.platform, featureFlags: featureFlags),
      super('linux devices');

  final ToolContext _toolContext;
  final LinuxWorkflow _linuxWorkflow;

  @override
  bool get supportsPlatform {
    final Platform platform = _toolContext.platform;
    return platform.isLinux;
  }

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
    return <Device>[LinuxDevice(toolContext: _toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['linux'];
}
