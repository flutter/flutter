// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'device.dart';
import 'globals.dart' as globals;
import 'resident_devtools_handler.dart';
import 'resident_runner.dart';
import 'tracing.dart';
import 'vmservice.dart';

const String kFlutterTestOutputsDirEnvName = 'FLUTTER_TEST_OUTPUTS_DIR';
class ColdRunner extends ResidentRunner {
  ColdRunner(
    List<FlutterDevice> devices, {
    @required String target,
    @required DebuggingOptions debuggingOptions,
    this.traceStartup = false,
    this.awaitFirstFrameWhenTracing = true,
    this.applicationBinary,
    this.multidexEnabled = false,
    bool ipv6 = false,
    bool stayResident = true,
    bool machine = false,
    ResidentDevtoolsHandlerFactory devtoolsHandler = createDefaultHandler,
  }) : super(
          devices,
          target: target,
          debuggingOptions: debuggingOptions,
          hotMode: false,
          stayResident: stayResident,
          ipv6: ipv6,
          machine: machine,
          devtoolsHandler: devtoolsHandler,
        );

  final bool traceStartup;
  final bool awaitFirstFrameWhenTracing;
  final File applicationBinary;
  final bool multidexEnabled;
  bool _didAttach = false;

  @override
  bool get canHotReload => false;

  @override
  Logger get logger => globals.logger;

  @override
  FileSystem get fileSystem => globals.fs;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool enableDevTools = false,
    String route,
  }) async {
    try {
      for (final FlutterDevice device in flutterDevices) {
        final int result = await device.runCold(
          coldRunner: this,
          route: route,
        );
        if (result != 0) {
          appFailedToStart();
          return result;
        }
      }
    } on Exception catch (err, stack) {
      globals.printError('$err\n$stack');
      appFailedToStart();
      return 1;
    }

    // Connect to observatory.
    if (debuggingEnabled) {
      try {
        await connectToServiceProtocol(allowExistingDdsInstance: false);
      } on Exception catch (exception) {
        globals.printError(exception.toString());
        appFailedToStart();
        return 2;
      }
    }

    if (enableDevTools && debuggingEnabled) {
      // The method below is guaranteed never to return a failing future.
      unawaited(residentDevtoolsHandler.serveAndAnnounceDevTools(
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
        flutterDevices: flutterDevices,
      ));
    }

    if (flutterDevices.first.observatoryUris != null) {
      // For now, only support one debugger connection.
      connectionInfoCompleter?.complete(DebugConnectionInfo(
        httpUri: flutterDevices.first.vmService.httpAddress,
        wsUri: flutterDevices.first.vmService.wsAddress,
      ));
    }

    globals.printTrace('Application running.');

    for (final FlutterDevice device in flutterDevices) {
      if (device.vmService == null) {
        continue;
      }
      await device.initLogReader();
      globals.printTrace('Connected to ${device.device.name}');
    }

    if (traceStartup) {
      // Only trace startup for the first device.
      final FlutterDevice device = flutterDevices.first;
      if (device.vmService != null) {
        globals.printStatus('Tracing startup on ${device.device.name}.');
        final String outputPath = globals.platform.environment[kFlutterTestOutputsDirEnvName] ?? getBuildDirectory();
        await downloadStartupTrace(
          device.vmService,
          awaitFirstFrame: awaitFirstFrameWhenTracing,
          logger: globals.logger,
          output: globals.fs.directory(outputPath),
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
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool allowExistingDdsInstance = false,
    bool enableDevTools = false,
  }) async {
    _didAttach = true;
    try {
      await connectToServiceProtocol(
        getSkSLMethod: writeSkSL,
        allowExistingDdsInstance: allowExistingDdsInstance,
      );
    } on Exception catch (error) {
      globals.printError('Error connecting to the service protocol: $error');
      return 2;
    }

    for (final FlutterDevice device in flutterDevices) {
      await device.initLogReader();
    }
    for (final FlutterDevice device in flutterDevices) {
      final List<FlutterView> views = await device.vmService.getFlutterViews();
      for (final FlutterView view in views) {
        globals.printTrace('Connected to $view.');
      }
    }

    if (enableDevTools && debuggingEnabled) {
      // The method below is guaranteed never to return a failing future.
      unawaited(residentDevtoolsHandler.serveAndAnnounceDevTools(
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
        flutterDevices: flutterDevices,
      ));
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
      await flutterDevice.device.dispose();
    }

    await residentDevtoolsHandler.shutdown();
    await stopEchoingDeviceLog();
  }

  @override
  void printHelp({ @required bool details }) {
    globals.printStatus('Flutter run key commands.');
    if (details) {
      printHelpDetails();
      commandHelp.hWithDetails.print();
    } else {
      commandHelp.hWithoutDetails.print();
    }
    if (_didAttach) {
      commandHelp.d.print();
    }
    commandHelp.c.print();
    commandHelp.q.print();
    printDebuggerList();
  }

  @override
  Future<void> preExit() async {
    for (final FlutterDevice device in flutterDevices) {
      // If we're running in release mode, stop the app using the device logic.
      if (device.vmService == null) {
        await device.device.stopApp(device.package, userIdentifier: device.userIdentifier);
      }
    }
    await super.preExit();
  }
}
