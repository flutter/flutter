// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../desktop.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import 'application_package.dart';
import 'build_linux.dart';
import 'linux_workflow.dart';

/// A device that represents a desktop Linux target.
class LinuxDevice extends DesktopDevice {
  LinuxDevice() : super(
      'Linux',
      platformType: PlatformType.linux,
      ephemeral: false,
  );

  @override
  void clearLogs() { }

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    return _logReader;
  }
  final DesktopLogReader _logReader = DesktopLogReader();

  @override
  bool isSupported() => true;

  @override
  String get name => 'Linux';

  @override
  Future<LaunchResult> startApp(
    covariant LinuxApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    _lastBuiltMode = debuggingOptions.buildInfo.mode;
    if (!prebuiltApplication) {
      await buildLinux(
        FlutterProject.current().linux,
        debuggingOptions.buildInfo,
        target: mainPath,
      );
    }
    final Process process = await processManager.start(<String>[
      package.executable(debuggingOptions?.buildInfo?.mode)
    ]);
    if (debuggingOptions?.buildInfo?.isRelease == true) {
      return LaunchResult.succeeded();
    }
    _logReader.initializeProcess(process);
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(_logReader);
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  @override
  Future<bool> stopApp(covariant LinuxApp app) async {
    return killProcess(app.executable(_lastBuiltMode));
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.linux_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.linux.existsSync();
  }

  // Track the last built mode from startApp.
  BuildMode _lastBuiltMode;
}

class LinuxDevices extends PollingDeviceDiscovery {
  LinuxDevices() : super('linux devices');

  @override
  bool get supportsPlatform => platform.isLinux;

  @override
  bool get canListAnything => linuxWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      LinuxDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
