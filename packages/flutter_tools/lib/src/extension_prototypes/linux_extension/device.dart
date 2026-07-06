// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Linux prototype extension device and service.
///
/// This library implements the device and device service for the Linux platform
/// prototype extension, handling application launching and log streaming.
library linux_extension.device;

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';
import '../../flutter_tools_core/device.dart';

/// Represents a Linux desktop device managed by the extension.
///
/// This class implements the [Device] interface from `flutter_tools_core`
/// and defines how to install, launch, and stop applications on a Linux desktop target.
/// It uses [LocalDeviceLaunchHelper] to launch and monitor the application process.
class LinuxExtensionDevice extends Device {
  LinuxExtensionDevice({
    required this.id,
    required this.name,
    this.fileSystem = const LocalFileSystem(),
    this.processManager = const LocalProcessManager(),
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;

  @override
  final String id;

  @override
  final String name;

  @override
  final String category = DeviceCategory.desktop;

  @override
  bool get isEmulator => false;

  @override
  String get platform => 'linux';

  @override
  String get buildTarget => 'assemble_linux_app';

  @override
  bool isSupportedForProject(Uri projectRoot) {
    final String projectPath = fileSystem.path.fromUri(projectRoot);
    return fileSystem.directory(fileSystem.path.join(projectPath, 'linux')).existsSync();
  }

  final StreamController<String> _logController = StreamController<String>.broadcast();
  final Completer<Uri> _vmServiceUriCompleter = Completer<Uri>();
  Process? _process;

  /// Installs the app on the device.
  ///
  /// For this desktop prototype, it simply logs the installation path.
  @override
  Future<void> installApp(Uri appBundlePath) async {
    _logController.add('Installing app bundle ${appBundlePath.toFilePath()}...');
  }

  /// Launches the application binary.
  ///
  /// It uses [LocalDeviceLaunchHelper] to run the process and monitor its output
  /// for the VM Service URI.
  @override
  Future<void> launchApp(Uri appBundlePath, List<String> args) async {
    final String filePath = appBundlePath.toFilePath();

    _logController.add('Launching app bundle $filePath with args: $args...');

    try {
      _process = await LocalDeviceLaunchHelper.launchAndMonitorProcess(
        command: <String>[filePath, ...args],
        processManager: processManager,
        logController: _logController,
        vmServiceUriCompleter: _vmServiceUriCompleter,
      );
    } on Object catch (e) {
      _logController.add('Failed to launch application process: $e');
      if (!_vmServiceUriCompleter.isCompleted) {
        _vmServiceUriCompleter.completeError(e);
      }
    }
  }

  /// Returns a stream of log lines from the application.
  @override
  Stream<String> getLogReader() => _logController.stream;

  /// Returns the VM Service URI of the running application.
  ///
  /// This future completes once the launch helper parses the URI from the logs.
  @override
  Future<Uri> getVmServiceUri() async {
    return _vmServiceUriCompleter.future;
  }

  /// Stops the running application process.
  @override
  Future<void> stopApp() async {
    _logController.add('Stopping application...');
    _process?.kill();
    _process = null;
  }
}

/// Prototype implementation of a DeviceService for Linux support.
///
/// This service is registered by the Linux extension and provides a single
/// [LinuxExtensionDevice] instance ('linux-proto-1') for testing.
final class LinuxDeviceService extends DeviceService {
  LinuxDeviceService({
    required super.onNotification,
    this.fileSystem = const LocalFileSystem(),
    this.processManager = const LocalProcessManager(),
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;

  /// Returns the list of discovered devices.
  ///
  /// For this prototype, it always returns a single [LinuxExtensionDevice].
  @override
  Future<List<Device>> discoverDevices() async {
    return <Device>[
      LinuxExtensionDevice(
        id: 'linux-proto-1',
        name: 'Linux Desktop Target',
        fileSystem: fileSystem,
        processManager: processManager,
      ),
    ];
  }

  @override
  Future<void> launchEmulator(String emulatorId) async {}
}

typedef LinuxDevice = LinuxExtensionDevice;
