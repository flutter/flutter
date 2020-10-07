// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_windows.dart';
import 'windows_workflow.dart';

/// A device that represents a desktop Windows target.
class WindowsDevice extends DesktopDevice {
  WindowsDevice({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
  }) : super(
      'windows',
      platformType: PlatformType.windows,
      ephemeral: false,
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      operatingSystemUtils: operatingSystemUtils,
  );

  @override
  bool isSupported() => true;

  @override
  String get name => 'Windows';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.windows.existsSync();
  }

  @override
  Future<void> buildForDevice(
    covariant WindowsApp package, {
    String mainPath,
    BuildInfo buildInfo,
  }) async {
    await buildWindows(
      FlutterProject.current().windows,
      buildInfo,
      target: mainPath,
    );
  }

  @override
  String executablePathForDevice(covariant WindowsApp package, BuildMode buildMode) {
    return package.executable(buildMode);
  }
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
    @required WindowsWorkflow windowsWorkflow,
  }) : _fileSystem = fileSystem,
      _logger = logger,
      _processManager = processManager,
      _operatingSystemUtils = operatingSystemUtils,
      _windowsWorkflow = windowsWorkflow,
      super('windows devices');

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final WindowsWorkflow _windowsWorkflow;

  @override
  bool get supportsPlatform => _windowsWorkflow.appliesToHostPlatform;

  @override
  bool get canListAnything => _windowsWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      WindowsDevice(
        fileSystem: _fileSystem,
        logger: _logger,
        processManager: _processManager,
        operatingSystemUtils: _operatingSystemUtils,
      ),
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
  for (final String rawProcess in result.stdout.split('\n')) {
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
