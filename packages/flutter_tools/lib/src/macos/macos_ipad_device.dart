// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../device_vm_service_discovery_for_attach.dart';
import '../ios/ios_workflow.dart';
import '../project.dart';

/// Represents an ARM macOS target that can run iPad apps.
///
/// https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-on-macos
class MacOSDesignedForIPadDevice extends DesktopDevice {
  MacOSDesignedForIPadDevice({required super.toolContext})
    : _operatingSystemUtils = toolContext.os,
      super('mac-designed-for-ipad', platformType: PlatformType.macos, ephemeral: false);

  final OperatingSystemUtils _operatingSystemUtils;

  @override
  String get name => 'Mac Designed for iPad';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  // "Designed for iPad" apps are only supported on Apple Silicon Macs.
  @override
  Future<CpuArch> get cpuArch async => CpuArch.arm64;

  @override
  Future<bool> isSupported() async =>
      _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;

  @override
  bool get supportsFlavors => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync() &&
        _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;
  }

  @override
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) => null;

  @override
  VMServiceDiscoveryForAttach getVMServiceDiscoveryForAttach({
    String? appId,
    String? fuchsiaModule,
    int? filterDevicePort,
    int? expectedHostPort,
    required bool ipv6,
    required Logger logger,
  }) {
    final mdnsVMServiceDiscoveryForAttach = MdnsVMServiceDiscoveryForAttach(
      device: this,
      appId: appId,
      deviceVmservicePort: filterDevicePort,
      hostVmservicePort: expectedHostPort,
      // Do not throw on error since DelegateVMServiceDiscoveryForAttach falls
      // back to log-based protocol discovery.
      throwOnError: false,
      useDeviceIPAsHost: false,
      usesIpv6: ipv6,
    );

    return DelegateVMServiceDiscoveryForAttach(<VMServiceDiscoveryForAttach>[
      mdnsVMServiceDiscoveryForAttach,
      super.getVMServiceDiscoveryForAttach(
        appId: appId,
        fuchsiaModule: fuchsiaModule,
        filterDevicePort: filterDevicePort,
        expectedHostPort: expectedHostPort,
        ipv6: ipv6,
        logger: logger,
      ),
    ]);
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object>{},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async => false;

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
    bool usingCISystem = false,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }
}

class MacOSDesignedForIPadDevices extends PollingDeviceDiscovery {
  MacOSDesignedForIPadDevices({required this._iosWorkflow, required this._toolContext})
    : super('Mac designed for iPad devices');

  final IOSWorkflow _iosWorkflow;
  final ToolContext _toolContext;

  @override
  bool get supportsPlatform => _toolContext.platform.isMacOS;

  /// iOS (not desktop macOS) development is enabled, the host is an ARM Mac,
  /// and discovery is allowed for this command.
  @override
  bool get canListAnything =>
      _iosWorkflow.canListDevices &&
      _toolContext.os.hostPlatform == HostPlatform.darwin_arm64 &&
      allowDiscovery;

  /// Set to show ARM macOS as an iOS device target.
  static bool allowDiscovery = false;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[MacOSDesignedForIPadDevice(toolContext: _toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['mac-designed-for-ipad'];
}
