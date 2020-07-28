// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'application_package.dart';
import 'base/common.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'convert.dart';
import 'device.dart';
import 'globals.dart' as globals;
import 'protocol_discovery.dart';

/// A partial implementation of Device for desktop-class devices to inherit
/// from, containing implementations that are common to all desktop devices.
abstract class DesktopDevice extends Device {
  DesktopDevice(String identifier, {
      @required PlatformType platformType,
      @required bool ephemeral,
      Logger logger,
      ProcessManager processManager,
    }) : _logger = logger ?? globals.logger, // TODO(jonahwilliams): remove after updating google3
         _processManager = processManager ?? globals.processManager,
         super(
          identifier,
          category: Category.desktop,
          platformType: platformType,
          ephemeral: ephemeral,
        );

  final Logger _logger;
  final ProcessManager _processManager;
  final Set<Process> _runningProcesses = <Process>{};
  final DesktopLogReader _deviceLogReader = DesktopLogReader();

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => globals.os.name;

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage app,
    bool includePastLogs = false,
  }) {
    assert(!includePastLogs, 'Past log reading not supported on desktop.');
    return _deviceLogReader;
  }

  @override
  void clearLogs() {}

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    if (!prebuiltApplication) {
      await buildForDevice(
        package,
        buildInfo: debuggingOptions?.buildInfo,
        mainPath: mainPath,
      );
    }

    // Ensure that the executable is locatable.
    final BuildMode buildMode = debuggingOptions?.buildInfo?.mode;
    final String executable = executablePathForDevice(package, buildMode);
    if (executable == null) {
      _logger.printError('Unable to find executable to run');
      return LaunchResult.failed();
    }

    final Process process = await _processManager.start(<String>[
      executable,
    ]);
    _runningProcesses.add(process);
    unawaited(process.exitCode.then((_) => _runningProcesses.remove(process)));

    _deviceLogReader.initializeProcess(process);
    if (debuggingOptions?.buildInfo?.isRelease == true) {
      return LaunchResult.succeeded();
    }
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(_deviceLogReader,
      devicePort: debuggingOptions?.deviceVmServicePort,
      hostPort: debuggingOptions?.hostVmServicePort,
      ipv6: ipv6,
    );
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      if (observatoryUri != null) {
        onAttached(package, buildMode, process);
        return LaunchResult.succeeded(observatoryUri: observatoryUri);
      }
      _logger.printError(
        'Error waiting for a debug connection: '
        'The log reader stopped unexpectedly.',
      );
    } on Exception catch (error) {
      _logger.printError('Error waiting for a debug connection: $error');
    } finally {
      await observatoryDiscovery.cancel();
    }
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async {
    bool succeeded = true;
    // Walk a copy of _runningProcesses, since the exit handler removes from the
    // set.
    for (final Process process in Set<Process>.of(_runningProcesses)) {
      succeeded &= process.kill();
    }
    return succeeded;
  }

  @override
  Future<void> dispose() async {
    await portForwarder?.dispose();
  }

  /// Builds the current project for this device, with the given options.
  Future<void> buildForDevice(
    ApplicationPackage package, {
    String mainPath,
    BuildInfo buildInfo,
  });

  /// Returns the path to the executable to run for [package] on this device for
  /// the given [buildMode].
  String executablePathForDevice(ApplicationPackage package, BuildMode buildMode);

  /// Called after a process is attached, allowing any device-specific extra
  /// steps to be run.
  void onAttached(ApplicationPackage package, BuildMode buildMode, Process process) {}
}

class DesktopLogReader extends DeviceLogReader {
  final StreamController<List<int>> _inputController = StreamController<List<int>>.broadcast();

  void initializeProcess(Process process) {
    process.stdout.listen(_inputController.add);
    process.stderr.listen(_inputController.add);
    process.exitCode.whenComplete(_inputController.close);
  }

  @override
  Stream<String> get logLines {
    return _inputController.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  }

  @override
  String get name => 'desktop';

  @override
  void dispose() {
    // Nothing to dispose.
  }
}
