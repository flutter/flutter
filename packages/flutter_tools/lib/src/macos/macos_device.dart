// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({required super.toolContext})
    : super('macos', platformType: PlatformType.macos, ephemeral: false);

  @override
  Future<bool> isSupported() async => true;

  @override
  String get name => 'macOS';

  @override
  bool get supportsFlavors => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.fromHostPlatform(toolContext.os.hostPlatform);

  @override
  Future<String> get targetPlatformDisplayName async {
    if (toolContext.os.hostPlatform == HostPlatform.darwin_arm64) {
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
      verboseLogging: toolContext.logger.isVerbose,
      usingCISystem: usingCISystem,
    );
  }

  @override
  String? executablePathForDevice(covariant MacOSApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo);
  }

  @override
  bool get supportsScreenshot => true;

  @override
  bool get supportsScreenRecording => true;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    final ProcessResult result = await toolContext.processManager.run(<String>[
      'screencapture',
      '-x',
      outputFile.path,
    ]);
    if (result.exitCode != 0) {
      throwToolExit('screencapture failed: ${result.stderr}');
    }
  }

  @override
  Future<ScreenRecording> startScreenRecording(File outputFile, {Duration? duration}) async {
    final args = <String>[
      'screencapture',
      '-v',
      if (duration != null) ...['-V', '${duration.inSeconds}'],
      outputFile.path,
    ];
    final Process process = await toolContext.processManager.start(args);
    unawaited(process.stdout.drain<void>());
    final stderrBuf = StringBuffer();

    Future<void> runRecording() async {
      final (int exitCode, _) = await (
        process.exitCode,
        process.stderr.transform(utf8AllowMalformed.decoder).forEach(stderrBuf.write),
      ).wait;

      if (!ScreenRecording.stoppedExitCodes.contains(exitCode)) {
        throwToolExit('screencapture failed (exit $exitCode): $stderrBuf');
      }
    }

    return ScreenRecording(process, runRecording());
  }

  @override
  void onAttached(covariant MacOSApp package, BuildInfo buildInfo, Process process) {
    final ToolContext(:Logger logger, :ProcessManager processManager) = toolContext;
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
  MacOSDevices({required this._macOSWorkflow, required ToolContext super.toolContext})
    : super('macOS devices');

  final MacOSWorkflow _macOSWorkflow;

  @override
  bool get supportsPlatform => toolContext.platform.isMacOS;

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
    return <Device>[MacOSDevice(toolContext: toolContext)];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
