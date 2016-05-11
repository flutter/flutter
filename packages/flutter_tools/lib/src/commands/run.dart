// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import 'build_apk.dart';
import 'install.dart';

abstract class RunCommandBase extends FlutterCommand {
  RunCommandBase() {
    addBuildModeFlags();

    // TODO(devoncarew): Remove in favor of --debug/--profile/--release.
    argParser.addFlag('checked',
        negatable: true,
        defaultsTo: true,
        help: 'Run the application in checked ("slow") mode.\n'
          'Note: this flag will be removed in favor of the --debug/--profile/--release flags.');

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

  @override
  final List<String> aliases = <String>['start'];

  RunCommand() {
    argParser.addFlag('full-restart',
        defaultsTo: true,
        help: 'Stop any currently running application process before running the app.');
    argParser.addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.');
    argParser.addOption('debug-port',
        help: 'Listen to the given port for a debug connection (defaults to $defaultObservatoryPort).');
    usesPubOption();

    // A temporary, hidden flag to experiment with a different run style.
    // TODO(devoncarew): Remove this.
    argParser.addFlag('resident',
        defaultsTo: false,
        negatable: false,
        hide: true,
        help: 'Stay resident after running the app.');
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

    DebuggingOptions options;

    if (getBuildMode() != BuildMode.debug) {
      options = new DebuggingOptions.disabled();
    } else {
      options = new DebuggingOptions.enabled(
        // TODO(devoncarew): Check this to 'getBuildMode() == BuildMode.debug'.
        checked: argResults['checked'],
        startPaused: argResults['start-paused'],
        observatoryPort: debugPort
      );
    }

    if (argResults['resident']) {
      _RunAndStayResident runner = new _RunAndStayResident(
        deviceForCommand,
        target: target,
        debuggingOptions: options,
        traceStartup: traceStartup,
        buildMode: getBuildMode()
      );

      return runner.run();
    } else {
      return startApp(
        deviceForCommand,
        target: target,
        stop: argResults['full-restart'],
        install: true,
        debuggingOptions: options,
        traceStartup: traceStartup,
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

    if (!(await installApp(device, package)))
      return 1;
  }

  Map<String, dynamic> platformArgs = <String, dynamic>{};

  if (traceStartup != null)
    platformArgs['trace-startup'] = traceStartup;

  printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

  LaunchResult result = await device.startApp(
    package,
    mainPath: mainPath,
    route: route,
    debuggingOptions: debuggingOptions,
    platformArgs: platformArgs
  );

  if (!result.started)
    printError('Error running application on ${device.name}.');
  else if (traceStartup)
    await _downloadStartupTrace(result.observatoryPort, device);

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

Future<Null> _downloadStartupTrace(int observatoryPort, Device device) async {
  Map<String, dynamic> timeline = await device.stopTracingAndDownloadTimeline(
    observatoryPort,
    waitForFirstFrame: true
  );

  int extractInstantEventTimestamp(String eventName) {
    List<Map<String, dynamic>> events = timeline['traceEvents'];
    Map<String, dynamic> event = events
        .firstWhere((Map<String, dynamic> event) => event['name'] == eventName, orElse: () => null);
    if (event == null)
      return null;
    return event['ts'];
  }

  int engineEnterTimestampMicros = extractInstantEventTimestamp(flutterEngineMainEnterEventName);
  int frameworkInitTimestampMicros = extractInstantEventTimestamp(frameworkInitEventName);
  int firstFrameTimestampMicros = extractInstantEventTimestamp(firstUsefulFrameEventName);

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

  await traceInfoFile.writeAsString(JSON.encode(traceInfo));

  String timeToFirstFrameMessage;
  if (timeToFirstFrameMicros > 1000000) {
    timeToFirstFrameMessage = '${(timeToFirstFrameMicros / 1000000).toStringAsFixed(2)} seconds';
  } else {
    timeToFirstFrameMessage = '${timeToFirstFrameMicros ~/ 1000} milliseconds';
  }

  printStatus('Time to first frame $timeToFirstFrameMessage');
  printStatus('Saved startup trace info in ${traceInfoFile.path}');
}

/// Delay until the Observatory / service protocol is available.
///
/// This does not fail if we're unable to connect, and times out after the given
/// [timeout].
Future<Null> delayUntilObservatoryAvailable(String host, int port, {
  Duration timeout: const Duration(seconds: 10)
}) async {
  printTrace('Waiting until Observatory is available (port $port).');

  final String url = 'ws://$host:$port/ws';
  printTrace('Looking for the observatory at $url.');
  Stopwatch stopwatch = new Stopwatch()..start();

  while (stopwatch.elapsed <= timeout) {
    try {
      WebSocket ws = await WebSocket.connect(url);
      printTrace('Connected to the observatory port.');
      ws.close().catchError((dynamic error) => null);
      return;
    } catch (error) {
      await new Future<Null>.delayed(new Duration(milliseconds: 250));
    }
  }

  printTrace('Unable to connect to the observatory.');
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
    this.traceStartup : false,
    this.buildMode : BuildMode.debug
  });

  final Device device;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool traceStartup;
  final BuildMode buildMode;

  Completer<int> _exitCompleter;
  StreamSubscription<String> _loggingSubscription;

  WebSocket _observatoryConnection;
  String _isolateId;
  int _messageId = 0;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run() async {
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
      if (!(await installApp(device, package)))
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
      mainPath: mainPath,
      debuggingOptions: debuggingOptions,
      platformArgs: platformArgs
    );

    if (!result.started) {
      printError('Error running application on ${device.name}.');
      await _loggingSubscription.cancel();
      return 2;
    }

    _exitCompleter = new Completer<int>();

    // Connect to observatory.
    if (debuggingOptions.debuggingEnabled) {
      final String localhost = InternetAddress.LOOPBACK_IP_V4.address;
      final String url = 'ws://$localhost:${result.observatoryPort}/ws';

      _observatoryConnection = await WebSocket.connect(url);
      printTrace('Connected to observatory port: ${result.observatoryPort}.');

      // Listen for observatory connection close.
      _observatoryConnection.listen((dynamic data) {
        if (data is String) {
          Map<String, dynamic> json = JSON.decode(data);

          if (json['method'] == 'streamNotify') {
            Map<String, dynamic> event = json['params']['event'];
            if (event['isolate'] != null && _isolateId == null)
              _isolateId = event['isolate']['id'];
          } else if (json['result'] != null && json['result']['type'] == 'VM') {
            // isolates: [{
            //   type: @Isolate, fixedId: true, id: isolates/724543296, name: dev.flx$main, number: 724543296
            // }]
            List<dynamic> isolates = json['result']['isolates'];
            if (isolates.isNotEmpty)
              _isolateId = isolates.first['id'];
          } else if (json['error'] != null) {
            printError('Error: ${json['error']['message']}.');
            printTrace(data);
          }
        }
      }, onDone: () {
        _handleExit();
      });

      _observatoryConnection.add(JSON.encode(<String, dynamic>{
        'method': 'streamListen',
        'params': <String, dynamic>{ 'streamId': 'Isolate' },
        'id': _messageId++
      }));

      _observatoryConnection.add(JSON.encode(<String, dynamic>{
        'method': 'getVM',
        'id': _messageId++
      }));
    }

    printStatus('Application running.');
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

    return _exitCompleter.future.then((int exitCode) async {
      if (_observatoryConnection != null &&
          _observatoryConnection.readyState == WebSocket.OPEN &&
          _isolateId != null) {
        _observatoryConnection.add(JSON.encode(<String, dynamic>{
          'method': 'ext.flutter.exit',
          'params': <String, dynamic>{ 'isolateId': _isolateId },
          'id': _messageId++
        }));
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
    if (_observatoryConnection == null) {
      printError('Debugging is not enabled.');
    } else {
      printStatus('Re-starting application...');

      // TODO(devoncarew): Show an error if the isolate reload fails.
      _observatoryConnection.add(JSON.encode(<String, dynamic>{
        'method': 'isolateReload',
        'params': <String, dynamic>{ 'isolateId': _isolateId },
        'id': _messageId++
      }));
    }
  }

  void _handleExit() {
    if (!_exitCompleter.isCompleted) {
      _loggingSubscription?.cancel();
      printStatus('');
      printStatus('Application finished.');
      terminal.singleCharMode = false;
      _exitCompleter.complete(0);
    }
  }
}
