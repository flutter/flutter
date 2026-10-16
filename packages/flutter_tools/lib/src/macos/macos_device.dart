// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({required ToolContext toolContext})
    : _toolContext = toolContext,
      super(
        'macos',
        ephemeral: false,
        fileSystem: toolContext.fs,
        logger: toolContext.logger,
        operatingSystemUtils: toolContext.os,
        platformType: PlatformType.macos,
        processManager: toolContext.processManager,
      );

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
  Future<CpuArch> get cpuArch async {
    final OperatingSystemUtils os = _toolContext.os;
    return CpuArch.fromHostPlatform(os.hostPlatform);
  }

  @override
  Future<String> get targetPlatformDisplayName async {
    final OperatingSystemUtils os = _toolContext.os;
    if (os.hostPlatform == HostPlatform.darwin_arm64) {
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
    final ToolContext(:Cache cache, :Logger logger) = _toolContext;
    await buildMacOS(
      flutterProject: FlutterProject.current(),
      buildInfo: buildInfo,
      flutterRoot: cache.flutterRoot,
      targetOverride: mainPath,
      verboseLogging: logger.isVerbose,
      usingCISystem: usingCISystem,
    );
  }

  @override
  String? executablePathForDevice(covariant MacOSApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo);
  }

  @override
  void onAttached(covariant MacOSApp package, BuildInfo buildInfo, Process process) {
    final ToolContext(:Logger logger, :ProcessManager processManager) = _toolContext;
    // Bring app to foreground. Ideally this would be done post-launch rather
    // than post-attach, since this won't run for release builds, but there's
    // no general-purpose way of knowing when a process is far enough along in
    // the launch process for 'open' to foreground it.
    final String? applicationBundle = package.applicationBundle(buildInfo);
    if (applicationBundle == null) {
      logger.printError('Failed to foreground app; application bundle not found');
      return;
    }
    processManager.run(<String>['open', applicationBundle]).then((ProcessResult result) {
      if (result.exitCode != 0) {
        logger.printError('Failed to foreground app; open returned ${result.exitCode}');
      }
    });
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({required this._macOSWorkflow, required this._toolContext}) : super('macOS devices');

  final MacOSWorkflow _macOSWorkflow;
  final ToolContext _toolContext;

  @override
  bool get supportsPlatform {
    final Platform platform = _toolContext.platform;
    return platform.isMacOS;
  }

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
    return <Device>[MacOSDevice(toolContext: _toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
