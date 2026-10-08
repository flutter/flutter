// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    required this._appleContext,
    required this._featureFlags,
    required ToolContext toolContext,
  }) : _logger = toolContext.logger,
       _operatingSystemUtils = toolContext.os,
       _processManager = toolContext.processManager,
       _toolContext = toolContext,
       super(
         'macos',
         fileSystem: toolContext.fs,
         logger: toolContext.logger,
         operatingSystemUtils: toolContext.os,
         platformType: PlatformType.macos,
         processManager: toolContext.processManager,
         ephemeral: false,
       );

  final AppleContext _appleContext;
  final FeatureFlags _featureFlags;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessManager _processManager;
  final ToolContext _toolContext;

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
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = _toolContext;
    await buildMacOS(
      appleContext: _appleContext,
      buildInfo: buildInfo,
      featureFlags: _featureFlags,
      flutterProject: projectFactory.fromDirectory(fs.currentDirectory),
      targetOverride: mainPath,
      toolContext: _toolContext,
      usingCISystem: usingCISystem,
      verboseLogging: _logger.isVerbose,
    );
  }

  @override
  String? executablePathForDevice(covariant MacOSApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo);
  }

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
    _processManager.run(<String>['open', applicationBundle]).then((ProcessResult result) {
      if (result.exitCode != 0) {
        _logger.printError('Failed to foreground app; open returned ${result.exitCode}');
      }
    });
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    required this._appleContext,
    required this._featureFlags,
    required this._macOSWorkflow,
    required this._toolContext,
  }) : super('macOS devices');

  final AppleContext _appleContext;
  final FeatureFlags _featureFlags;
  final MacOSWorkflow _macOSWorkflow;
  final ToolContext _toolContext;

  @override
  bool get supportsPlatform => _toolContext.platform.isMacOS;

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
        appleContext: _appleContext,
        featureFlags: _featureFlags,
        toolContext: _toolContext,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
