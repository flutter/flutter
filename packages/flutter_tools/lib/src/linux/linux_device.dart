// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/file_system.dart';
import '../base/os.dart';
import '../build_info.dart';
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
  LinuxDevice({required this._analytics, required super.toolContext})
    : _operatingSystemUtils = toolContext.os,
      _toolContext = toolContext,
      super('linux', platformType: PlatformType.linux, ephemeral: false);

  final Analytics _analytics;
  final OperatingSystemUtils _operatingSystemUtils;
  final ToolContext _toolContext;

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
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = _toolContext;
    await buildLinux(
      projectFactory.fromDirectory(fs.currentDirectory).linux,
      buildInfo,
      analytics: _analytics,
      target: mainPath,
      targetPlatform: await targetPlatform,
      toolContext: _toolContext,
    );
  }

  @override
  String executablePathForDevice(covariant LinuxApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo.mode, buildInfo.flavor);
  }
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices({
    required this._analytics,
    required FeatureFlags featureFlags,
    required ToolContext toolContext,
  }) : _toolContext = toolContext,
       _linuxWorkflow = LinuxWorkflow(platform: toolContext.platform, featureFlags: featureFlags),
       super('linux devices');

  final Analytics _analytics;
  final ToolContext _toolContext;
  final LinuxWorkflow _linuxWorkflow;

  @override
  bool get supportsPlatform => _toolContext.platform.isLinux;

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
    return <Device>[LinuxDevice(analytics: _analytics, toolContext: _toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['linux'];
}
