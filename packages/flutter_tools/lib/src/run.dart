// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'application_package.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'cache.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'commands/trace.dart';
import 'device.dart';
import 'globals.dart';
import 'vmservice.dart';
import 'resident_runner.dart';

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
    return runZoned(() {
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
  Future<bool> restart({ bool fullRestart: false }) async {
    if (vmService == null) {
      printError('Debugging is not enabled.');
      return false;
    } else {
      Status status = logger.startProgress('Re-starting application...');

      Future<ServiceEvent> extensionAddedEvent;

      if (device.restartSendsFrameworkInitEvent) {
        extensionAddedEvent = vmService.onExtensionEvent
          .where((ServiceEvent event) => event.extensionKind == 'Flutter.FrameworkInitialization')
          .first;
      }

      bool restartResult = await device.restartApp(
        _package,
        _result,
        mainPath: _mainPath,
        observatory: vmService,
        prebuiltApplication: prebuiltMode
      );

      status.stop(showElapsedTime: true);

      if (restartResult && extensionAddedEvent != null) {
        // TODO(devoncarew): We should restore the route here.
        await extensionAddedEvent;
      }

      return restartResult;
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

    _result = null;
    Stopwatch startTime = new Stopwatch()..start();

    String toolsExtension = Cache.instance.getToolsExtension('run');
    if (toolsExtension != null) {
      int observatoryPort;
      const observatoryPrefix = 'Observatory listening on http://127.0.0.1:';
      int diagnosticPort;
      const diagnosticPrefix = 'Diagnostic server listening on http://127.0.0.1:';
      Completer<bool> launched = new Completer<bool>();

      await startEchoingDeviceLog();
      int exitCode;
      runCommandAndStreamOutput(
        <String>[toolsExtension, _mainPath],
        mapFunction: (String line) {
          if (line.startsWith(observatoryPrefix))
            observatoryPort = int.parse(line.substring(observatoryPrefix.length), onError: (_) => null);
          if (line.startsWith(diagnosticPrefix))
            diagnosticPort = int.parse(line.substring(diagnosticPrefix.length), onError: (_) => null);
          if (!launched.isCompleted) {
            if (line.contains('Application not launched by flutter-run script'))
              launched.complete(false);
            else if (line.contains('Application running'))
              launched.complete(true);
          }
          return line;
        }).then((int result) {
        exitCode = result;
        if (!launched.isCompleted)
          launched.complete(exitCode == 0);
      });

      if (await launched.future) {
        _result = new LaunchResult.succeeded(
            observatoryPort: observatoryPort, diagnosticPort: diagnosticPort);
        // fall through to connect observatory
      } else if (exitCode == null || exitCode == 0) {
        _result = null;
        // fall through to launch app and connect observatory
      } else {
        _result = new LaunchResult.failed();
        printStatus('flutter-run script failed: $exitCode');
        // fall through to report failure
      }
    }

    if (_result == null) {
      _package = getApplicationPackageForPlatform(device.platform, applicationBinary: applicationBinary);

      if (_package == null) {
        String message = 'No application found for ${device.platform}.';
        String hint = getMissingPackageHintForPlatform(device.platform);
        if (hint != null)
          message += '\n$hint';
        printError(message);
        return 1;
      }

      // TODO(devoncarew): We shouldn't have to do type checks here.
      if (shouldBuild && device is AndroidDevice) {
        printStatus('Building APK...');

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
        printStatus("Stopping app '${_package.name}' on ${device.name}.");
        await device.stopApp(_package);
      }

      // TODO(devoncarew): This fails for ios devices - we haven't built yet.
      if (device is AndroidDevice) {
        printStatus('Installing onto ${device.name}...');
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
    }

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

    printStatus('Application running.');
    if (debuggingOptions.buildMode == BuildMode.release)
      return 0;

    if (vmService != null) {
      await vmService.vm.refreshViews();
      printStatus('Connected to ${vmService.vm.mainView}\.');
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
      bool restarted = await restart();
      restartTime.stop();
      writeRunBenchmarkFile(startTime, restarted ? restartTime : null);
      await new Future<Null>.delayed(new Duration(seconds: 2));
      stop();
    }

    return waitForAppToFinish();
  }

  @override
  Future<Null> handleTerminalCommand(String code) async {
    String lower = code.toLowerCase();
    if (lower == 'r' || code == AnsiTerminal.KEY_F5) {
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
  void printHelp() {
    final bool showRestartText = !prebuiltMode && device.supportsRestart;
    String restartText = showRestartText ? ', "r" or F5 to restart the app,' : '';
    printStatus('Type "h" or F1 for help$restartText and "q", F10, or ctrl-c to quit.');
    printStatus('Type "w" to print the widget hierarchy of the app, and "t" for the render tree.');
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
