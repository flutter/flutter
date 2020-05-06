// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/file_system.dart';
import 'device.dart';
import 'globals.dart' as globals;
import 'resident_runner.dart';
import 'tracing.dart';
import 'vmservice.dart';

// TODO(mklim): Test this, flutter/flutter#23031.
class ColdRunner extends ResidentRunner {
  ColdRunner(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    this.traceStartup = false,
    this.awaitFirstFrameWhenTracing = true,
    this.applicationBinary,
    bool ipv6 = false,
    bool stayResident = true,
  }) : super(devices,
             target: target,
             debuggingOptions: debuggingOptions,
             hotMode: false,
             stayResident: stayResident,
             ipv6: ipv6);

  final bool traceStartup;
  final bool awaitFirstFrameWhenTracing;
  final File applicationBinary;
  bool _didAttach = false;

  @override
  bool get canHotReload => false;

  @override
  bool get canHotRestart => false;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    final bool prebuiltMode = applicationBinary != null;
    if (!prebuiltMode) {
      if (!globals.fs.isFileSync(mainPath)) {
        String message = 'Tried to run $mainPath, but that file does not exist.';
        if (target == null) {
          message += '\nConsider using the -t option to specify the Dart file to start.';
        }
        globals.printError(message);
        return 1;
      }
    }

    for (final FlutterDevice device in flutterDevices) {
      final int result = await device.runCold(
        coldRunner: this,
        route: route,
      );
      if (result != 0) {
        return result;
      }
    }

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      try {
        await connectToServiceProtocol();
      } on String catch (message) {
        globals.printError(message);
        return 2;
      }
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
        await downloadStartupTrace(
          device.vmService,
          awaitFirstFrame: awaitFirstFrameWhenTracing,
        );
      }
      appFinished();
    }

    appStartedCompleter?.complete();

    writeVmserviceFile();

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
  }) async {
    _didAttach = true;
    try {
      await connectToServiceProtocol();
    } on Exception catch (error) {
      globals.printError('Error connecting to the service protocol: $error');
      // https://github.com/flutter/flutter/issues/33050
      // TODO(blasten): Remove this check once https://issuetracker.google.com/issues/132325318 has been fixed.
      if (await hasDeviceRunningAndroidQ(flutterDevices) &&
          error.toString().contains(kAndroidQHttpConnectionClosedExp)) {
        globals.printStatus('🔨 If you are using an emulator running Android Q Beta, consider using an emulator running API level 29 or lower.');
        globals.printStatus('Learn more about the status of this issue on https://issuetracker.google.com/issues/132325318');
      }
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

    await stopEchoingDeviceLog();
  }

  @override
  void printHelp({ @required bool details }) {
    globals.printStatus('Flutter run key commands.');
    if (supportsServiceProtocol) {
      if (details) {
        printHelpDetails();
      }
    }
    commandHelp.h.print();
    if (_didAttach) {
      commandHelp.d.print();
    }
    commandHelp.c.print();
    commandHelp.q.print();
    for (final FlutterDevice device in flutterDevices) {
      final String dname = device.device.name;
      if (device.vmService != null) {
        // Caution: This log line is parsed by device lab tests.
        globals.printStatus(
          'An Observatory debugger and profiler on $dname is available at: '
          '${device.vmService.httpAddress}',
        );
      }
    }
  }

  @override
  Future<void> preExit() async {
    for (final FlutterDevice device in flutterDevices) {
      // If we're running in release mode, stop the app using the device logic.
      if (device.vmService == null) {
        await device.device.stopApp(device.package);
      }
    }
    await super.preExit();
  }
}
