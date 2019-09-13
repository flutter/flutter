// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../desktop.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import 'application_package.dart';
import 'build_windows.dart';
import 'windows_workflow.dart';

/// A device that represents a desktop Windows target.
class WindowsDevice extends Device {
  WindowsDevice() : super(
      'Windows',
      category: Category.desktop,
      platformType: PlatformType.windows,
      ephemeral: false,
  );

  @override
  void clearLogs() { }

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    return _logReader;
  }
  final DesktopLogReader _logReader = DesktopLogReader();

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  bool isSupported() => true;

  @override
  String get name => 'Windows';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;

  @override
  Future<LaunchResult> startApp(
    covariant WindowsApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    if (!prebuiltApplication) {
      await buildWindows(
        FlutterProject.current().windows,
        debuggingOptions.buildInfo,
        target: mainPath,
      );
    }
    await stopApp(package);
    final Process process = await processUtils.start(<String>[
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
  Future<bool> stopApp(covariant WindowsApp app) async {
    // Assume debug for now.
    final List<String> process = runningProcess(app.executable(BuildMode.debug));
    if (process == null) {
      return false;
    }
    final RunResult result = await processUtils.run(
      <String>['Taskkill', '/PID', process.first, '/F'],
    );
    return result.exitCode == 0;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_x64;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.windows.existsSync();
  }
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices() : super('windows devices');

  @override
  bool get supportsPlatform => platform.isWindows;

  @override
  bool get canListAnything => windowsWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      WindowsDevice(),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}

final RegExp _whitespace = RegExp(r'\s+');

/// Returns the running process matching `process` name.
///
/// This list contains the process name and id.
@visibleForTesting
List<String> runningProcess(String processName) {
  // TODO(jonahwilliams): find a way to do this without powershell.
  final RunResult result = processUtils.runSync(
    <String>['powershell', '-script="Get-CimInstance Win32_Process"'],
  );
  if (result.exitCode != 0) {
    return null;
  }
  for (String rawProcess in result.stdout.split('\n')) {
    final String process = rawProcess.trim();
    if (!process.contains(processName)) {
      continue;
    }
    final List<String> parts = process.split(_whitespace);

    final String processPid = parts[0];
    final String currentRunningProcessPid = pid.toString();
    // Don't kill the flutter tool process
    if (processPid == currentRunningProcessPid) {
      continue;
    }
    final List<String> data = <String>[
      processPid, // ID
      parts[1], // Name
    ];
    return data;
  }
  return null;
}
