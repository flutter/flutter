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
    required final ProcessManager processManager,
    required final Logger logger,
    required final FileSystem fileSystem,
    required final OperatingSystemUtils operatingSystemUtils,
  })  : _operatingSystemUtils = operatingSystemUtils,
        super(
          'designed-for-ipad',
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
  bool isSupportedForProject(final FlutterProject flutterProject) {
    return flutterProject.ios.existsSync() && _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64;
  }

  @override
  String? executablePathForDevice(final ApplicationPackage package, final BuildInfo buildInfo) => null;

  @override
  Future<LaunchResult> startApp(
    final ApplicationPackage? package, {
    final String? mainPath,
    final String? route,
    required final DebuggingOptions debuggingOptions,
    final Map<String, Object?> platformArgs = const <String, Object>{},
    final bool prebuiltApplication = false,
    final bool ipv6 = false,
    final String? userIdentifier,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }

  @override
  Future<bool> stopApp(
    final ApplicationPackage? app, {
    final String? userIdentifier,
  }) async => false;

  @override
  Future<void> buildForDevice({
    final String? mainPath,
    required final BuildInfo buildInfo,
  }) async {
    // Only attaching to a running app launched from Xcode is supported.
    throw UnimplementedError('Building for "$name" is not supported.');
  }
}

class MacOSDesignedForIPadDevices extends PollingDeviceDiscovery {
  MacOSDesignedForIPadDevices({
    required final Platform platform,
    required final IOSWorkflow iosWorkflow,
    required final ProcessManager processManager,
    required final Logger logger,
    required final FileSystem fileSystem,
    required final OperatingSystemUtils operatingSystemUtils,
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
      _iosWorkflow.canListDevices && _operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64 && allowDiscovery;

  /// Set to show ARM macOS as an iOS device target.
  static bool allowDiscovery = false;

  @override
  Future<List<Device>> pollingGetDevices({final Duration? timeout}) async {
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
  List<String> get wellKnownIds => const <String>['designed-for-ipad'];
}
