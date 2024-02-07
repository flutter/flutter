// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../ios/ios_workflow.dart';
import '../project.dart';

/// Represents an ARM macOS target that can run iPad apps.
///
/// https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-on-macos
class MacOSDesignedForIPadDevice extends DesktopDevice {
  MacOSDesignedForIPadDevice({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
  })  : _operatingSystemUtils = operatingSystemUtils,
        super(
          'mac-designed-for-ipad',
          platformType: PlatformType.macos,
          ephemeral: false,
          processManager: processManager,
          logger: logger,
          fileSystem: fileSystem,
          operatingSystemUtils: operatingSystemUtils,
        );

  final OperatingSystemUtils _operatingSystemUtils;

  @override
  String get name => 'Mac Designed for iPad';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  @override
  bool isSupported() => _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;

  @override
  bool get supportsFlavors => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync() && _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;
  }

  @override
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) => null;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }

  @override
  Future<bool> stopApp(
    ApplicationPackage? app, {
    String? userIdentifier,
  }) async => false;

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }
}

class MacOSDesignedForIPadDevices extends PollingDeviceDiscovery {
  MacOSDesignedForIPadDevices({
    required Platform platform,
    required IOSWorkflow iosWorkflow,
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
  })  : _logger = logger,
        _platform = platform,
        _iosWorkflow = iosWorkflow,
        _processManager = processManager,
        _fileSystem = fileSystem,
        _operatingSystemUtils = operatingSystemUtils,
        super('Mac designed for iPad devices');

  final IOSWorkflow _iosWorkflow;
  final Platform _platform;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  /// iOS (not desktop macOS) development is enabled, the host is an ARM Mac,
  /// and discovery is allowed for this command.
  @override
  bool get canListAnything =>
      _iosWorkflow.canListDevices && _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;

  @override
  Future<List<Device>> pollingGetDevices({Duration? timeout}) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      MacOSDesignedForIPadDevice(
        processManager: _processManager,
        logger: _logger,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['mac-designed-for-ipad'];
}
