// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'application_package.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'commands/trace.dart';
import 'device.dart';
import 'globals.dart';
import 'resident_runner.dart';
import 'vmservice.dart';

class RunAndStayResident extends ResidentRunner {
  RunAndStayResident(
    Device device, {
    String target,
    DebuggingOptions debuggingOptions,
    bool usesTerminalUI: true,
    this.traceStartup: false,
    this.benchmark: false,
    this.applicationBinary
  }) : super(device,
             target: target,
             debuggingOptions: debuggingOptions,
             usesTerminalUI: usesTerminalUI);

  ApplicationPackage _package;
  String _mainPath;
  LaunchResult _result;
  final bool traceStartup;
  final bool benchmark;
  final String applicationBinary;

  bool get prebuiltMode => applicationBinary != null;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    String route,
    bool shouldBuild: true
  }) {
    // Don't let uncaught errors kill the process.
    return Chain.capture(() {
      assert(shouldBuild == !prebuiltMode);
      return _run(
        traceStartup: traceStartup,
        benchmark: benchmark,
        connectionInfoCompleter: connectionInfoCompleter,
        route: route,
        shouldBuild: shouldBuild
      );
    }, onError: (dynamic error, StackTrace stackTrace) {
      printError('Exception from flutter run: $error', stackTrace);
    });
  }

  @override
  Future<OperationResult> restart({ bool fullRestart: false, bool pauseAfterRestart: false }) async {
    if (vmService == null) {
      printError('Debugging is not enabled.');
      return new OperationResult(1, 'debugging not enabled');
    } else {
      Status status = logger.startProgress('Re-starting application...');

      Future<ServiceEvent> extensionAddedEvent;

      if (device.restartSendsFrameworkInitEvent) {
        extensionAddedEvent = vmService.onExtensionEvent
          .where((ServiceEvent event) => event.extensionKind == 'Flutter.FrameworkInitialization')
          .first;
      }

      bool result = await device.restartApp(
        _package,
        _result,
        mainPath: _mainPath,
        observatory: vmService,
        prebuiltApplication: prebuiltMode
      );

      status.stop(showElapsedTime: true);

      if (result && extensionAddedEvent != null) {
        await extensionAddedEvent;
      }

      return result ? OperationResult.ok : new OperationResult(1, 'restart error');
    }
  }

  Future<int> _run({
    bool traceStartup: false,
    bool benchmark: false,
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    String route,
    bool shouldBuild: true
  }) async {
    if (!prebuiltMode) {
      _mainPath = findMainDartFile(target);
      if (!FileSystemEntity.isFileSync(_mainPath)) {
        String message = 'Tried to run $_mainPath, but that file does not exist.';
        if (target == null)
          message += '\nConsider using the -t option to specify the Dart file to start.';
        printError(message);
        return 1;
      }
    }

    _package = getApplicationPackageForPlatform(device.platform, applicationBinary: applicationBinary);

    if (_package == null) {
      String message = 'No application found for ${device.platform}.';
      String hint = getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    Stopwatch startTime = new Stopwatch()..start();

    // TODO(devoncarew): We shouldn't have to do type checks here.
    if (shouldBuild && device is AndroidDevice) {
      printTrace('Running build command.');

      int result = await buildApk(
        device.platform,
        target: target,
        buildMode: debuggingOptions.buildMode
      );

      if (result != 0)
        return result;
    }

    // TODO(devoncarew): Move this into the device.startApp() impls.
    if (_package != null) {
      printTrace("Stopping app '${_package.name}' on ${device.name}.");
      await device.stopApp(_package);
    }

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    if (prebuiltMode || device is AndroidDevice) {
      printTrace('Running install command.');
      if (!(installApp(device, _package, uninstall: false)))
        return 1;
    }

    Map<String, dynamic> platformArgs;
    if (traceStartup != null)
      platformArgs = <String, dynamic>{ 'trace-startup': traceStartup };

    await startEchoingDeviceLog();
    if (_mainPath == null) {
      assert(prebuiltMode);
      printStatus('Running ${_package.displayName} on ${device.name}');
    } else {
      printStatus('Running ${getDisplayPath(_mainPath)} on ${device.name}...');
    }

    _result = await device.startApp(
      _package,
      debuggingOptions.buildMode,
      mainPath: _mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode
    );

    if (!_result.started) {
      printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }

    startTime.stop();

    if (connectionInfoCompleter != null && _result.hasObservatory)
      connectionInfoCompleter.complete(new DebugConnectionInfo(_result.observatoryPort));

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      await connectToServiceProtocol(_result.observatoryPort);

      if (benchmark) {
        await vmService.getVM();
      }
    }

    printTrace('Application running.');

    if (vmService != null) {
      await vmService.vm.refreshViews();
      printTrace('Connected to ${vmService.vm.mainView}\.');
    }

    if (vmService != null && traceStartup) {
      printStatus('Downloading startup trace info...');
      try {
        await downloadStartupTrace(vmService);
      } catch(error) {
        printError(error);
        return 2;
      }
      appFinished();
    } else {
      setupTerminal();
      registerSignalHandlers();
    }

    if (benchmark) {
      await new Future<Null>.delayed(new Duration(seconds: 4));

      // Touch the file.
      File mainFile = new File(_mainPath);
      mainFile.writeAsBytesSync(mainFile.readAsBytesSync());

      Stopwatch restartTime = new Stopwatch()..start();
      OperationResult result = await restart();
      restartTime.stop();
      writeRunBenchmarkFile(startTime, result.isOk ? restartTime : null);
      await new Future<Null>.delayed(new Duration(seconds: 2));
      stop();
    }

    return waitForAppToFinish();
  }

  @override
  Future<Null> handleTerminalCommand(String code) async {
    String lower = code.toLowerCase();
    if (lower == 'r' || code == AnsiTerminal.KEY_F5) {
      if (!supportsServiceProtocol)
        return;
      if (device.supportsRestart) {
        // F5, restart
        await restart();
      }
    }
  }

  @override
  Future<Null> cleanupAfterSignal() async {
    await stopEchoingDeviceLog();
    await stopApp();
  }

  @override
  Future<Null> cleanupAtFinish() async {
    await stopEchoingDeviceLog();
  }

  @override
  void printHelp({ @required bool details }) {
    bool haveDetails = false;
    if (!prebuiltMode && device.supportsRestart && supportsServiceProtocol)
      printStatus('To restart the app, press "r" or F5.');
    if (_result.hasObservatory)
      printStatus('The Observatory debugger and profiler is available at: http://127.0.0.1:${_result.observatoryPort}/');
    if (supportsServiceProtocol) {
      haveDetails = true;
      if (details) {
        printStatus('To dump the widget hierarchy of the app (debugDumpApp), press "w".');
        printStatus('To dump the rendering tree of the app (debugDumpRenderTree), press "r".');
      }
    }
    if (haveDetails && !details) {
      printStatus('For a more detailed help message, press "h" or F1. To quit, press "q", F10, or Ctrl-C.');
    } else {
      printStatus('To repeat this help message, press "h" or F1. To quit, press "q", F10, or Ctrl-C.');
    }
  }

  @override
  Future<Null> preStop() async {
    // If we're running in release mode, stop the app using the device logic.
    if (vmService == null)
      await device.stopApp(_package);
  }
}

void writeRunBenchmarkFile(Stopwatch startTime, [Stopwatch restartTime]) {
  final String benchmarkOut = 'refresh_benchmark.json';
  Map<String, dynamic> data = <String, dynamic>{
    'start': startTime.elapsedMilliseconds,
    'time': (restartTime ?? startTime).elapsedMilliseconds // time and restart are the same
  };
  if (restartTime != null)
    data['restart'] = restartTime.elapsedMilliseconds;

  new File(benchmarkOut).writeAsStringSync(toPrettyJson(data));
  printStatus('Run benchmark written to $benchmarkOut ($data).');
}
