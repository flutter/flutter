// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/file_system.dart';
import 'device.dart';
import 'globals.dart';
import 'resident_runner.dart';
import 'tracing.dart';

// TODO(mklim): Test this, flutter/flutter#23031.
class ColdRunner extends ResidentRunner {
  ColdRunner(
    List<FlutterDevice> devices, {
    String target,
    DebuggingOptions debuggingOptions,
    bool usesTerminalUI = true,
    this.traceStartup = false,
    this.applicationBinary,
    bool stayResident = true,
    bool ipv6 = false,
  }) : super(devices,
             target: target,
             debuggingOptions: debuggingOptions,
             usesTerminalUI: usesTerminalUI,
             stayResident: stayResident,
             ipv6: ipv6);

  final bool traceStartup;
  final File applicationBinary;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
    bool shouldBuild = true
  }) async {
    final bool prebuiltMode = applicationBinary != null;
    if (!prebuiltMode) {
      if (!fs.isFileSync(mainPath)) {
        String message = 'Tried to run $mainPath, but that file does not exist.';
        if (target == null)
          message += '\nConsider using the -t option to specify the Dart file to start.';
        printError(message);
        return 1;
      }
    }

    for (FlutterDevice device in flutterDevices) {
      final int result = await device.runCold(
        coldRunner: this,
        route: route,
        shouldBuild: shouldBuild,
      );
      if (result != 0)
        return result;
    }

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled)
      await connectToServiceProtocol();

    if (flutterDevices.first.observatoryUris != null) {
      // For now, only support one debugger connection.
      connectionInfoCompleter?.complete(DebugConnectionInfo(
        httpUri: flutterDevices.first.observatoryUris.first,
        wsUri: flutterDevices.first.vmServices.first.wsAddress,
      ));
    }

    printTrace('Application running.');

    for (FlutterDevice device in flutterDevices) {
      if (device.vmServices == null)
        continue;
      device.initLogReader();
      await device.refreshViews();
      printTrace('Connected to ${device.device.name}');
    }

    if (traceStartup) {
      // Only trace startup for the first device.
      final FlutterDevice device = flutterDevices.first;
      if (device.vmServices != null && device.vmServices.isNotEmpty) {
        printStatus('Downloading startup trace info for ${device.device.name}');
        try {
          await downloadStartupTrace(device.vmServices.first);
        } catch (error) {
          printError('Error downloading startup trace: $error');
          return 2;
        }
      }
      appFinished();
    } else if (stayResident) {
      setupTerminal();
      registerSignalHandlers();
    }

    appStartedCompleter?.complete();

    if (stayResident)
      return waitForAppToFinish();
    await cleanupAtFinish();
    return 0;
  }

  @override
  Future<void> handleTerminalCommand(String code) async { }

  @override
  Future<void> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    await stopApp();
  }

  @override
  Future<void> cleanupAtFinish() async {
    await stopEchoingDeviceLog();
  }

  @override
  void printHelp({ @required bool details }) {
    bool haveDetails = false;
    bool haveAnything = false;
    for (FlutterDevice device in flutterDevices) {
      final String dname = device.device.name;
      if (device.observatoryUris != null) {
        for (Uri uri in device.observatoryUris) {
          printStatus('An Observatory debugger and profiler on $dname is available at $uri');
          haveAnything = true;
        }
      }
    }
    if (supportsServiceProtocol) {
      haveDetails = true;
      if (details) {
        printHelpDetails();
        haveAnything = true;
      }
    }
    if (haveDetails && !details) {
      printStatus('For a more detailed help message, press "h". To quit, press "q".');
    } else if (haveAnything) {
      printStatus('To repeat this help message, press "h". To quit, press "q".');
    } else {
      printStatus('To quit, press "q".');
    }
  }

  @override
  Future<void> preStop() async {
    for (FlutterDevice device in flutterDevices) {
      // If we're running in release mode, stop the app using the device logic.
      if (device.vmServices == null || device.vmServices.isEmpty)
        await device.device.stopApp(device.package);
    }
  }
}
