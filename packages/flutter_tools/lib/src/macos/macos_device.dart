// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    required super.fileSystem,
    required super.logger,
    required super.operatingSystemUtils,
    required super.processManager,
  }) : _logger = logger,
       _operatingSystemUtils = operatingSystemUtils,
       _processManager = processManager,
       super('macos', platformType: PlatformType.macos, ephemeral: false);

  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessManager _processManager;

  @override
  Future<bool> isSupported() async => true;

  @override
  String get name => 'macOS';

  @override
  bool get supportsFlavors => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.fromHostPlatform(_operatingSystemUtils.hostPlatform);

  @override
  Future<String> get targetPlatformDisplayName async {
    if (_operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64) {
      return 'darwin-arm64';
    }
    return 'darwin-x64';
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.macos.existsSync();
  }

  @override
  Future<void> buildForDevice({
    required BuildInfo buildInfo,
    String? mainPath,
    bool usingCISystem = false,
  }) async {
    await buildMacOS(
      flutterProject: FlutterProject.current(),
      buildInfo: buildInfo,
      targetOverride: mainPath,
      verboseLogging: _logger.isVerbose,
      usingCISystem: usingCISystem,
    );
  }

  @override
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) =>
      switch (package) {
        final MacOSApp macosApp => macosApp.executable(buildInfo),
        _ => null,
      };

  @override
  void onAttached(covariant MacOSApp package, BuildInfo buildInfo, Process process) {
    // Bring app to foreground. Ideally this would be done post-launch rather
    // than post-attach, since this won't run for release builds, but there's
    // no general-purpose way of knowing when a process is far enough along in
    // the launch process for 'open' to foreground it.
    final String? applicationBundle = package.applicationBundle(buildInfo);
    if (applicationBundle == null) {
      _logger.printError('Failed to foreground app; application bundle not found');
      return;
    }
    unawaited(
      _processManager.run(<String>['open', applicationBundle]).then((ProcessResult result) {
        if (result.exitCode != 0) {
          _logger.printError('Failed to foreground app; open returned ${result.exitCode}');
        }
      }),
    );
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    required FileSystem fileSystem,
    required Logger logger,
    required MacOSWorkflow macOSWorkflow,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
    required ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _macOSWorkflow = macOSWorkflow,
       _operatingSystemUtils = operatingSystemUtils,
       _platform = platform,
       _processManager = processManager,
       super('macOS devices');

  final FileSystem _fileSystem;
  final Logger _logger;
  final MacOSWorkflow _macOSWorkflow;
  final OperatingSystemUtils _operatingSystemUtils;
  final Platform _platform;
  final ProcessManager _processManager;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything => _macOSWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      MacOSDevice(
        fileSystem: _fileSystem,
        logger: _logger,
        operatingSystemUtils: _operatingSystemUtils,
        processManager: _processManager,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
