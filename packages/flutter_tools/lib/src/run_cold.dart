// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/dds.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'resident_runner.dart';
import 'tracing.dart';
import 'vmservice.dart';

const kFlutterTestOutputsDirEnvName = 'FLUTTER_TEST_OUTPUTS_DIR';

class ColdRunner extends ResidentRunner {
  ColdRunner(
    super.flutterDevices, {
    required super.debuggingOptions,
    required super.target,
    super.analytics,
    this.applicationBinary,
    super.artifacts,
    this.awaitFirstFrameWhenTracing = true,
    super.buildSystem,
    super.buildTargets,
    super.cache,
    super.commandHelp,
    super.config,
    super.dartBuilder,
    super.dillOutputPath,
    super.fileSystem,
    super.flutterVersion,
    super.logger,
    super.machine,
    super.osUtils,
    super.outputPreferences,
    super.platform,
    super.processManager,
    super.projectRootPath,
    super.stayResident,
    super.terminal,
    this.traceStartup = false,
    super.xcode,
  }) : super(hotMode: false);

  final bool traceStartup;
  final bool awaitFirstFrameWhenTracing;
  final File? applicationBinary;
  var _didAttach = false;

  @override
  bool get canHotReload => false;

  @override
  bool get reloadIsRestart => false;

  @override
  bool get supportsDetach => _didAttach;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    String? route,
  }) async {
    try {
      for (final FlutterDevice? device in flutterDevices) {
        final int result = await device!.runCold(coldRunner: this, route: route);
        if (result != 0) {
          appFailedToStart();
          return result;
        }
      }
    } on Exception catch (err, stack) {
      logger.printError('$err\n$stack');
      appFailedToStart();
      return 1;
    }

    // Connect to the VM Service.
    if (debuggingEnabled) {
      try {
        await connectToServiceProtocol();
      } on Exception catch (exception) {
        logger.printError(exception.toString());
        appFailedToStart();
        return 2;
      }
    }

    final FlutterDevice flutterDevice = flutterDevices.first;
    if (flutterDevice.vmServiceUris != null) {
      final FlutterVmService? vmService = flutterDevice.vmService;
      final DartDevelopmentService dds = flutterDevice.device!.dds;
      // For now, only support one debugger connection.
      connectionInfoCompleter?.complete(
        DebugConnectionInfo(
          httpUri: vmService!.httpAddress,
          wsUri: vmService.wsAddress,
          devToolsUri: dds.devToolsUri,
          dtdUri: dds.dtdUri,
        ),
      );
    }

    logger.printTrace('Application running.');

    for (final FlutterDevice? device in flutterDevices) {
      if (device!.vmService == null) {
        continue;
      }
      logger.printTrace('Connected to ${device.device!.displayName}');
    }

    if (traceStartup) {
      // Only trace startup for the first device.
      final FlutterDevice device = flutterDevices.first;
      if (device.vmService != null) {
        logger.printStatus('Tracing startup on ${device.device!.displayName}.');
        final String outputPath =
            platform.environment[kFlutterTestOutputsDirEnvName] ?? getBuildDirectory();
        await downloadStartupTrace(
          device.vmService!,
          awaitFirstFrame: awaitFirstFrameWhenTracing,
          logger: logger,
          output: fileSystem.directory(outputPath),
        );
      }
      appFinished();
    }

    appStartedCompleter?.complete();

    writeVmServiceFile();

    if (stayResident && !traceStartup) {
      return waitForAppToFinish();
    }
    await cleanupAtFinish();
    return 0;
  }

  @override
  Future<int> attach({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    bool needsFullRestart = true,
  }) async {
    _didAttach = true;
    try {
      await connectToServiceProtocol();
    } on Exception catch (error) {
      logger.printError('Error connecting to the service protocol: $error');
      return 2;
    }

    for (final FlutterDevice? device in flutterDevices) {
      final List<FlutterView> views = await device!.vmService!.getFlutterViews();
      for (final view in views) {
        logger.printTrace('Connected to $view.');
      }
    }

    appStartedCompleter?.complete();
    if (stayResident) {
      return waitForAppToFinish();
    }
    await cleanupAtFinish();
    return 0;
  }

  @override
  Future<void> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    if (_didAttach) {
      appFinished();
    }
    await exitApp();
  }

  @override
  Future<void> cleanupAtFinish() async {
    for (final FlutterDevice? flutterDevice in flutterDevices) {
      await flutterDevice!.device!.dispose();
    }
    await stopEchoingDeviceLog();
  }

  @override
  Future<void> preExit() async {
    for (final FlutterDevice? device in flutterDevices) {
      // If we're running in release mode, stop the app using the device logic.
      if (device!.vmService == null) {
        await device.device!.stopApp(device.package, userIdentifier: device.userIdentifier);
      }
    }
    await super.preExit();
  }
}
