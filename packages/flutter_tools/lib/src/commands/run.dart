// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../observatory.dart';
import '../runner/flutter_command.dart';
import 'build_apk.dart';
import 'install.dart';
import 'trace.dart';

abstract class RunCommandBase extends FlutterCommand {
  RunCommandBase() {
    addBuildModeFlags(defaultToRelease: false);

    argParser.addFlag('trace-startup',
        negatable: true,
        defaultsTo: false,
        help: 'Start tracing during startup.');
    argParser.addOption('route',
        help: 'Which route to load when running the app.');
    usesTargetOption();
  }

  bool get traceStartup => argResults['trace-startup'];
  String get target => argResults['target'];
  String get route => argResults['route'];
}

class RunCommand extends RunCommandBase {
  @override
  final String name = 'run';

  @override
  final String description = 'Run your Flutter app on an attached device.';

  RunCommand() {
    argParser.addFlag('full-restart',
        defaultsTo: true,
        help: 'Stop any currently running application process before running the app.');
    argParser.addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.');
    argParser.addOption('debug-port',
        help: 'Listen to the given port for a debug connection (defaults to $kDefaultObservatoryPort).');
    usesPubOption();

    // A temporary, hidden flag to experiment with a different run style.
    // TODO(devoncarew): Remove this.
    argParser.addFlag('resident',
        defaultsTo: false,
        negatable: false,
        hide: true,
        help: 'Stay resident after running the app.');

    // Hidden option to enable a benchmarking mode. This will run the given
    // application, measure the startup time and the app restart time, write the
    // results out to 'refresh_benchmark.json', and exit. This flag is intended
    // for use in generating automated flutter benchmarks.
    argParser.addFlag('benchmark', negatable: false, hide: true);
  }

  @override
  bool get requiresDevice => true;

  @override
  String get usagePath {
    Device device = deviceForCommand;

    if (device == null)
      return name;

    // Return 'run/ios'.
    return '$name/${getNameForTargetPlatform(device.platform)}';
  }

  @override
  Future<int> runInProject() async {
    int debugPort;

    if (argResults['debug-port'] != null) {
      try {
        debugPort = int.parse(argResults['debug-port']);
      } catch (error) {
        printError('Invalid port for `--debug-port`: $error');
        return 1;
      }
    }

    if (deviceForCommand.isLocalEmulator && !isEmulatorBuildMode(getBuildMode())) {
      printError('${toTitleCase(getModeName(getBuildMode()))} mode is not supported for emulators.');
      return 1;
    }

    DebuggingOptions options;

    if (getBuildMode() == BuildMode.release) {
      options = new DebuggingOptions.disabled(getBuildMode());
    } else {
      options = new DebuggingOptions.enabled(
        getBuildMode(),
        startPaused: argResults['start-paused'],
        observatoryPort: debugPort
      );
    }

    if (argResults['resident']) {
      _RunAndStayResident runner = new _RunAndStayResident(
        deviceForCommand,
        target: target,
        debuggingOptions: options,
        buildMode: getBuildMode()
      );

      return runner.run(traceStartup: traceStartup, benchmark: argResults['benchmark']);
    } else {
      return startApp(
        deviceForCommand,
        target: target,
        stop: argResults['full-restart'],
        install: true,
        debuggingOptions: options,
        traceStartup: traceStartup,
        benchmark: argResults['benchmark'],
        route: route,
        buildMode: getBuildMode()
      );
    }
  }
}

Future<int> startApp(
  Device device, {
  String target,
  bool stop: true,
  bool install: true,
  DebuggingOptions debuggingOptions,
  bool traceStartup: false,
  bool benchmark: false,
  String route,
  BuildMode buildMode: BuildMode.debug
}) async {
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
    String hint = _getMissingPackageHintForPlatform(device.platform);
    if (hint != null)
      message += '\n$hint';
    printError(message);
    return 1;
  }

  Stopwatch stopwatch = new Stopwatch()..start();

  // TODO(devoncarew): We shouldn't have to do type checks here.
  if (install && device is AndroidDevice) {
    printTrace('Running build command.');

    int result = await buildApk(
      device.platform,
      target: target,
      buildMode: buildMode
    );

    if (result != 0)
      return result;
  }

  // TODO(devoncarew): Move this into the device.startApp() impls. They should
  // wait on the stop command to complete before (re-)starting the app. We could
  // plumb a Future through the start command from here, but that seems a little
  // messy.
  if (stop) {
    if (package != null) {
      printTrace("Stopping app '${package.name}' on ${device.name}.");
      // We don't wait for the stop command to complete.
      device.stopApp(package);
    }
  }

  // Allow any stop commands from above to start work.
  await new Future<Duration>.delayed(Duration.ZERO);

  // TODO(devoncarew): This fails for ios devices - we haven't built yet.
  if (install && device is AndroidDevice) {
    printStatus('Installing $package to $device...');

    if (!(installApp(device, package)))
      return 1;
  }

  Map<String, dynamic> platformArgs = <String, dynamic>{};

  if (traceStartup != null)
    platformArgs['trace-startup'] = traceStartup;

  printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

  LaunchResult result = await device.startApp(
    package,
    buildMode,
    mainPath: mainPath,
    route: route,
    debuggingOptions: debuggingOptions,
    platformArgs: platformArgs
  );

  stopwatch.stop();

  if (!result.started) {
    printError('Error running application on ${device.name}.');
  } else if (traceStartup) {
    try {
      Observatory observatory = await Observatory.connect(result.observatoryPort);
      await _downloadStartupTrace(observatory);
    } catch (error) {
      printError('Error connecting to observatory: $error');
      return 1;
    }
  }

  if (benchmark)
    _writeBenchmark(stopwatch);

  return result.started ? 0 : 2;
}

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

String _getMissingPackageHintForPlatform(TargetPlatform platform) {
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

/// Return a relative path if [fullPath] is contained by the cwd, else return an
/// absolute path.
String _getDisplayPath(String fullPath) {
  String cwd = Directory.current.path + Platform.pathSeparator;
  return fullPath.startsWith(cwd) ?  fullPath.substring(cwd.length) : fullPath;
}

class _RunAndStayResident {
  _RunAndStayResident(
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
  String _isolateId;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run({ bool traceStartup: false, bool benchmark: false }) async {
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
      String hint = _getMissingPackageHintForPlatform(device.platform);
      if (hint != null)
        message += '\n$hint';
      printError(message);
      return 1;
    }

    Stopwatch stopwatch = new Stopwatch()..start();

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

    printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

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

    stopwatch.stop();

    _exitCompleter = new Completer<int>();

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      observatory = await Observatory.connect(result.observatoryPort);
      printTrace('Connected to observatory port: ${result.observatoryPort}.');

      observatory.onIsolateEvent.listen((Event event) {
        if (event['isolate'] != null)
          _isolateId = event['isolate']['id'];
      });
      observatory.streamListen('Isolate');

      // Listen for observatory connection close.
      observatory.done.whenComplete(() {
        _handleExit();
      });

      observatory.getVM().then((VM vm) {
        if (vm.isolates.isNotEmpty)
          _isolateId = vm.isolates.first['id'];
      });
    }

    printStatus('Application running.');

    if (observatory != null && traceStartup) {
      printStatus('Downloading startup trace info...');

      await _downloadStartupTrace(observatory);

      _handleExit();
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
          _handleRefresh();
        } else if (lower == 'q' || code == AnsiTerminal.KEY_F10) {
          // F10, exit
          _handleExit();
        }
      });

      ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
        _handleExit();
      });
      ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
        _handleExit();
      });
    }

    if (benchmark) {
      _writeBenchmark(stopwatch);
      new Future<Null>.delayed(new Duration(seconds: 2)).then((_) {
        _handleExit();
      });
    }

    return _exitCompleter.future.then((int exitCode) async {
      if (observatory != null && !observatory.isClosed && _isolateId != null) {
        observatory.flutterExit(_isolateId);

        // WebSockets do not have a flush() method.
        await new Future<Null>.delayed(new Duration(milliseconds: 100));
      }

      return exitCode;
    });
  }

  void _printHelp() {
    printStatus('Type "h" or F1 for help, "r" or F5 to restart the app, and "q", F10, or ctrl-c to quit.');
  }

  void _handleRefresh() {
    if (observatory == null) {
      printError('Debugging is not enabled.');
    } else {
      printStatus('Re-starting application...');

      observatory.isolateReload(_isolateId).catchError((dynamic error) {
        printError('Error restarting app: $error');
      });
    }
  }

  void _handleExit() {
    terminal.singleCharMode = false;

    if (!_exitCompleter.isCompleted) {
      _loggingSubscription?.cancel();
      printStatus('Application finished.');
      _exitCompleter.complete(0);
    }
  }
}

Future<Null> _downloadStartupTrace(Observatory observatory) async {
  Tracing tracing = new Tracing(observatory);

  Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline(
    waitForFirstFrame: true
  );

  int extractInstantEventTimestamp(String eventName) {
    List<Map<String, dynamic>> events = timeline['traceEvents'];
    Map<String, dynamic> event = events.firstWhere(
      (Map<String, dynamic> event) => event['name'] == eventName, orElse: () => null
    );
    return event == null ? null : event['ts'];
  }

  int engineEnterTimestampMicros = extractInstantEventTimestamp(kFlutterEngineMainEnterEventName);
  int frameworkInitTimestampMicros = extractInstantEventTimestamp(kFrameworkInitEventName);
  int firstFrameTimestampMicros = extractInstantEventTimestamp(kFirstUsefulFrameEventName);

  if (engineEnterTimestampMicros == null) {
    printError('Engine start event is missing in the timeline. Cannot compute startup time.');
    return null;
  }

  if (firstFrameTimestampMicros == null) {
    printError('First frame event is missing in the timeline. Cannot compute startup time.');
    return null;
  }

  File traceInfoFile = new File('build/start_up_info.json');
  int timeToFirstFrameMicros = firstFrameTimestampMicros - engineEnterTimestampMicros;
  Map<String, dynamic> traceInfo = <String, dynamic>{
    'engineEnterTimestampMicros': engineEnterTimestampMicros,
    'timeToFirstFrameMicros': timeToFirstFrameMicros,
  };

  if (frameworkInitTimestampMicros != null) {
    traceInfo['timeToFrameworkInitMicros'] = frameworkInitTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeAfterFrameworkInitMicros'] = firstFrameTimestampMicros - frameworkInitTimestampMicros;
  }

  traceInfoFile.writeAsStringSync(toPrettyJson(traceInfo));

  printStatus('Time to first frame: ${timeToFirstFrameMicros ~/ 1000}ms.');
  printStatus('Saved startup trace info in ${traceInfoFile.path}.');
}

void _writeBenchmark(Stopwatch stopwatch) {
  final String benchmarkOut = 'refresh_benchmark.json';
  Map<String, dynamic> data = <String, dynamic>{
    'time': stopwatch.elapsedMilliseconds
  };
  new File(benchmarkOut).writeAsStringSync(toPrettyJson(data));
  printStatus('Run benchmark written to $benchmarkOut ($data).');
}
