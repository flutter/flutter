// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'application_package.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'commands/build_apk.dart';
import 'commands/install.dart';
import 'commands/trace.dart';
import 'device.dart';
import 'globals.dart';
import 'observatory.dart';

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  if (target == null)
    target = '';
  String targetPath = path.absolute(target);
  if (FileSystemEntity.isDirectorySync(targetPath))
    return path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

// TODO: split out the cli part of the UI from this class

class RunAndStayResident {
  RunAndStayResident(
    this.device, {
    this.target,
    this.debuggingOptions,
    this.buildMode : BuildMode.debug
  });

  final Device device;
  final String target;
  final DebuggingOptions debuggingOptions;
  final BuildMode buildMode;

  Completer<int> _exitCompleter;
  StreamSubscription<String> _loggingSubscription;

  Observatory observatory;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run({ bool traceStartup: false, bool benchmark: false }) {
    // Don't let uncaught errors kill the process.
    return runZoned(() {
      return _run(traceStartup: traceStartup, benchmark: benchmark);
    }, onError: (dynamic error) {
      printError('Exception from flutter run: $error');
    });
  }

  Future<Null> stop() {
    _stopLogger();
    return _stopApp();
  }

  Future<int> _run({ bool traceStartup: false, bool benchmark: false }) async {
    String mainPath = findMainDartFile(target);
    if (!FileSystemEntity.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (target == null)
        message += '\nConsider using the -t option to specify the Dart file to start.';
      printError(message);
      return 1;
    }

    ApplicationPackage package = getApplicationPackageForPlatform(device.platform);

    if (package == null) {
      String message = 'No application found for ${device.platform}.';
      String hint = getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    Stopwatch startTime = new Stopwatch()..start();

    // TODO(devoncarew): We shouldn't have to do type checks here.
    if (device is AndroidDevice) {
      printTrace('Running build command.');

      int result = await buildApk(
        device.platform,
        target: target,
        buildMode: buildMode
      );

      if (result != 0)
        return result;
    }

    // TODO(devoncarew): Move this into the device.startApp() impls.
    if (package != null) {
      printTrace("Stopping app '${package.name}' on ${device.name}.");
      // We don't wait for the stop command to complete.
      device.stopApp(package);
    }

    // Allow any stop commands from above to start work.
    await new Future<Duration>.delayed(Duration.ZERO);

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    if (device is AndroidDevice) {
      printTrace('Running install command.');
      if (!(installApp(device, package)))
        return 1;
    }

    Map<String, dynamic> platformArgs;
    if (traceStartup != null)
      platformArgs = <String, dynamic>{ 'trace-startup': traceStartup };

    printStatus('Running ${getDisplayPath(mainPath)} on ${device.name}...');

    _loggingSubscription = device.logReader.logLines.listen((String line) {
      if (!line.contains('Observatory listening on http') && !line.contains('Diagnostic server listening on http'))
        printStatus(line);
    });

    LaunchResult result = await device.startApp(
      package,
      buildMode,
      mainPath: mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs
    );

    if (!result.started) {
      printError('Error running application on ${device.name}.');
      await _loggingSubscription.cancel();
      return 2;
    }

    startTime.stop();

    _exitCompleter = new Completer<int>();

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      observatory = await Observatory.connect(result.observatoryPort);
      printTrace('Connected to observatory port: ${result.observatoryPort}.');

      observatory.populateIsolateInfo();
      observatory.onExtensionEvent.listen((Event event) {
        printTrace(event.toString());
      });
      observatory.onIsolateEvent.listen((Event event) {
        printTrace(event.toString());
      });

      if (benchmark)
        await observatory.waitFirstIsolate;

      // Listen for observatory connection close.
      observatory.done.whenComplete(() {
        if (!_exitCompleter.isCompleted) {
          printStatus('Application finished.');
          _exitCompleter.complete(0);
        }
      });
    }

    printStatus('Application running.');

    if (observatory != null && traceStartup) {
      printStatus('Downloading startup trace info...');

      await downloadStartupTrace(observatory);

      if (!_exitCompleter.isCompleted)
        _exitCompleter.complete(0);
    } else {
      if (!logger.quiet)
        _printHelp();

      terminal.singleCharMode = true;

      terminal.onCharInput.listen((String code) {
        String lower = code.toLowerCase();

        if (lower == 'h' || code == AnsiTerminal.KEY_F1) {
          // F1, help
          _printHelp();
        } else if (lower == 'r' || code == AnsiTerminal.KEY_F5) {
          // F5, refresh
          _handleRefresh(package, result, mainPath);
        } else if (lower == 'q' || code == AnsiTerminal.KEY_F10) {
          // F10, exit
          _stopApp();
        }
      });

      ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
        _resetTerminal();
        _stopLogger();
        _stopApp();
      });
      ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
        _resetTerminal();
        _stopLogger();
        _stopApp();
      });
    }

    if (benchmark) {
      await new Future<Null>.delayed(new Duration(seconds: 4));

      // Touch the file.
      File mainFile = new File(mainPath);
      mainFile.writeAsBytesSync(mainFile.readAsBytesSync());

      Stopwatch restartTime = new Stopwatch()..start();
      bool restarted = await _handleRefresh(package, result, mainPath);
      restartTime.stop();
      writeRunBenchmarkFile(startTime, restarted ? restartTime : null);
      await new Future<Null>.delayed(new Duration(seconds: 2));
      stop();
    }

    return _exitCompleter.future.then((int exitCode) async {
      _resetTerminal();
      _stopLogger();
      return exitCode;
    });
  }

  void _printHelp() {
    printStatus('Type "h" or F1 for help, "r" or F5 to restart the app, and "q", F10, or ctrl-c to quit.');
  }

  Future<bool> _handleRefresh(ApplicationPackage package, LaunchResult result, String mainPath) async {
    if (observatory == null) {
      printError('Debugging is not enabled.');
      return false;
    } else {
      Status status = logger.startProgress('Re-starting application...');

      Future<Event> extensionAddedEvent = observatory.onExtensionEvent
        .where((Event event) => event.extensionKind == 'Flutter.FrameworkInitialization')
        .first;

      bool restartResult = await device.restartApp(
        package,
        result,
        mainPath: mainPath,
        observatory: observatory
      );

      status.stop(showElapsedTime: true);

      if (restartResult) {
        // TODO(devoncarew): We should restore the route here.
        await extensionAddedEvent;
      }

      return restartResult;
    }
  }

  void _stopLogger() {
    _loggingSubscription?.cancel();
  }

  void _resetTerminal() {
    terminal.singleCharMode = false;
  }

  Future<Null> _stopApp() {
    if (observatory != null && !observatory.isClosed) {
      if (observatory.isolates.isNotEmpty) {
        observatory.flutterExit(observatory.firstIsolateId);
        return new Future<Null>.delayed(new Duration(milliseconds: 100));
      }
    }

    if (!_exitCompleter.isCompleted)
      _exitCompleter.complete(0);

    return new Future<Null>.value();
  }
}

String getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
      return 'Is your project missing an android/AndroidManifest.xml?';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Info.plist?';
    default:
      return null;
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
