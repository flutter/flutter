// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/common.dart';
import 'base/dds.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/time.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'resident_runner.dart';
import 'tracing.dart';
import 'vmservice.dart';

const kFlutterTestOutputsDirEnvName = 'FLUTTER_TEST_OUTPUTS_DIR';

class ColdRunner extends ResidentRunner {
  ColdRunner(
    super.flutterDevices, {
    required super.analytics,
    required super.applicationPackageFactory,
    required super.assetBundleFactory,
    required super.buildSystem,
    required super.buildTargets,
    required super.debuggingOptions,
    required super.featureFlags,
    required super.target,
    required super.toolContext,
    required super.xcode,
    this.applicationBinary,
    this.awaitFirstFrameWhenTracing = true,
    super.dartBuilder,
    super.machine,
    super.projectRootPath,
    super.stayResident,
    this.traceStartup = false,
  }) : super(hotMode: false);

  static const _kHotRestartProgressId = 'hot.restart';

  final bool traceStartup;
  final bool awaitFirstFrameWhenTracing;
  final File? applicationBinary;
  var _didAttach = false;
  var _isRestarting = false;

  @override
  bool get canHotReload => false;

  @override
  bool get reloadIsRestart => supportsRestart;

  @override
  bool get supportsRestart =>
      flutterDevices.every((FlutterDevice device) => device.supportsColdRestart);

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
    } on ToolExit {
      appFailedToStart();
      rethrow;
    } on Exception catch (err, stack) {
      logger.printError('$err\n$stack');
      appFailedToStart();
      return 1;
    }

    // Connect to the VM Service.
    if (debuggingEnabled && supportsServiceProtocol) {
      try {
        await connectToServiceProtocol();
      } on Exception catch (exception) {
        logger.printError(exception.toString());
        appFailedToStart();
        return 2;
      }
    }

    final FlutterDevice flutterDevice = flutterDevices.first;
    if (flutterDevice.vmServiceUri != null) {
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
    } else if (!supportsServiceProtocol &&
        (flutterDevice.defersServiceProtocolConnection || flutterDevice.supportsColdRestart)) {
      connectionInfoCompleter?.complete(DebugConnectionInfo());
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
            platform.environment[kFlutterTestOutputsDirEnvName] ??
            getBuildDirectory(config, fileSystem);
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
  Future<OperationResult> restart({
    bool fullRestart = false,
    bool pause = false,
    String? reason,
  }) async {
    if (!supportsRestart) {
      return super.restart(fullRestart: fullRestart, pause: pause, reason: reason);
    }
    if (exited) {
      return OperationResult(1, 'Application has exited.');
    }
    if (_isRestarting) {
      return OperationResult(1, 'A restart is already in progress.');
    }
    _isRestarting = true;
    final SystemClock systemClock = toolContext.systemClock;
    final DateTime start = systemClock.now();
    final Status status = logger.startProgress(
      'Performing hot restart...',
      progressId: _kHotRestartProgressId,
    );
    try {
      for (final FlutterDevice device in flutterDevices) {
        await device.restartCold(coldRunner: this);
      }
    } on ToolExit {
      return OperationResult(1, 'Failed to recompile application.');
    } on Exception catch (err) {
      return OperationResult(1, err.toString(), fatal: true);
    } finally {
      _isRestarting = false;
      status.stop();
    }

    final Duration elapsed = systemClock.now().difference(start);
    logger.printStatus('Restarted application in ${getElapsedAsMilliseconds(elapsed)}.');
    return OperationResult.ok;
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
    for (final FlutterDevice flutterDevice in flutterDevices) {
      await flutterDevice.dispose();
      await flutterDevice.devFS?.destroy();
      await flutterDevice.device!.dispose();
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
