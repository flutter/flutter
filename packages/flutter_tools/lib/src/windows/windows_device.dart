// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:unified_analytics/unified_analytics.dart';

import '../base/file_system.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_windows.dart';
import 'windows_workflow.dart';

/// A device that represents a desktop Windows target.
class WindowsDevice extends DesktopDevice {
  WindowsDevice({required this._analytics, required super.toolContext})
    : _operatingSystemUtils = toolContext.os,
      _toolContext = toolContext,
      super('windows', platformType: PlatformType.windows, ephemeral: false);

  final Analytics _analytics;
  final OperatingSystemUtils _operatingSystemUtils;
  final ToolContext _toolContext;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool get supportsFlavors => true;

  @override
  String get name => 'Windows';

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  TargetPlatform get _targetPlatform => switch (_operatingSystemUtils.hostPlatform) {
    HostPlatform.windows_arm64 => TargetPlatform.windows_arm64,
    _ => TargetPlatform.windows_x64,
  };

  @override
  Future<CpuArch> get cpuArch async => CpuArch.fromHostPlatform(_operatingSystemUtils.hostPlatform);

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.windows.existsSync();
  }

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
    bool usingCISystem = false,
  }) async {
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = _toolContext;
    await buildWindows(
      projectFactory.fromDirectory(fs.currentDirectory).windows,
      buildInfo,
      _targetPlatform,
      analytics: _analytics,
      target: mainPath,
      toolContext: _toolContext,
    );
  }

  @override
  String executablePathForDevice(covariant WindowsApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo.mode, _targetPlatform, buildInfo.flavor);
  }
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices({
    required this._analytics,
    required this._toolContext,
    required this._windowsWorkflow,
  }) : super('windows devices');

  final Analytics _analytics;
  final ToolContext _toolContext;
  final WindowsWorkflow _windowsWorkflow;

  @override
  bool get supportsPlatform => _windowsWorkflow.appliesToHostPlatform;

  @override
  bool get canListAnything => _windowsWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[WindowsDevice(analytics: _analytics, toolContext: _toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['windows'];
}
