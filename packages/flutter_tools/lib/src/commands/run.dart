// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';
import 'build_apk.dart';
import 'install.dart';

abstract class RunCommandBase extends FlutterCommand {
  RunCommandBase() {
    argParser.addFlag('checked',
        negatable: true,
        defaultsTo: true,
        help: 'Toggle Dart\'s checked mode.');
    argParser.addFlag('trace-startup',
        negatable: true,
        defaultsTo: false,
        help: 'Start tracing during startup.');
    argParser.addOption('route',
        help: 'Which route to load when running the app.');
    usesTargetOption();
  }

  bool get checked => argResults['checked'];
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
    addBuildModeFlags();
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

    int result;
    DebuggingOptions options;

    if (getBuildMode() != BuildMode.debug) {
      options = new DebuggingOptions.disabled();
    } else {
      options = new DebuggingOptions.enabled(
        checked: checked,
        startPaused: argResults['start-paused'],
        observatoryPort: debugPort
      );
    }

    if (argResults['resident']) {
      result = await startAppStayResident(
        deviceForCommand,
        toolchain,
        target: target,
        debuggingOptions: options,
        traceStartup: traceStartup,
        buildMode: getBuildMode()
      );
    } else {
      result = await startApp(
        deviceForCommand,
        toolchain,
        target: target,
        stop: argResults['full-restart'],
        install: true,
        debuggingOptions: options,
        traceStartup: traceStartup,
        route: route,
        buildMode: getBuildMode()
      );
    }

    return result;
  }
}

Future<int> startApp(
  Device device,
  Toolchain toolchain, {
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
      toolchain,
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

  if (install) {
    printStatus('Installing $package to $device...');

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    await installApp(device, package);
  }

  Map<String, dynamic> platformArgs = <String, dynamic>{};

  if (traceStartup != null)
    platformArgs['trace-startup'] = traceStartup;

  printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

  LaunchResult result = await device.startApp(
    package,
    toolchain,
    mainPath: mainPath,
    route: route,
    debuggingOptions: debuggingOptions,
    platformArgs: platformArgs
  );

  if (!result.started)
    printError('Error running application on ${device.name}.');

  return result.started ? 0 : 2;
}

// start logging
// start the app
// scrape obs. port
// connect via obs.
// stay alive as long as obs. is alive
// intercept SIG_QUIT; kill the launched app

Future<int> startAppStayResident(
  Device device,
  Toolchain toolchain, {
  String target,
  DebuggingOptions debuggingOptions,
  bool traceStartup: false,
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
  if (device is AndroidDevice) {
    printTrace('Running build command.');

    int result = await buildApk(
      device.platform,
      toolchain,
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

  printTrace('Running install command.');

  // TODO(devoncarew): This fails for ios devices - we haven't built yet.
  await installApp(device, package);

  Map<String, dynamic> platformArgs;
  if (traceStartup != null)
    platformArgs = <String, dynamic>{ 'trace-startup': traceStartup };

  printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

  StreamSubscription<String> loggingSubscription = device.logReader.logLines.listen((String line) {
    if (!line.contains('Observatory listening on http') && !line.contains('Diagnostic server listening on http'))
      printStatus(line);
  });

  LaunchResult result = await device.startApp(
    package,
    toolchain,
    mainPath: mainPath,
    debuggingOptions: debuggingOptions,
    platformArgs: platformArgs
  );

  if (!result.started) {
    printError('Error running application on ${device.name}.');
    await loggingSubscription.cancel();
    return 2;
  }

  Completer<int> exitCompleter = new Completer<int>();

  void complete(int exitCode) {
    if (!exitCompleter.isCompleted)
      exitCompleter.complete(0);
  };

  // Connect to observatory.
  WebSocket observatoryConnection;

  if (debuggingOptions.debuggingEnabled) {
    final String localhost = InternetAddress.LOOPBACK_IP_V4.address;
    final String url = 'ws://$localhost:${result.observatoryPort}/ws';

    observatoryConnection = await WebSocket.connect(url);
    printTrace('Connected to observatory port: ${result.observatoryPort}.');

    // Listen for observatory connection close.
    observatoryConnection.listen((dynamic data) {
      // Ignore observatory messages.
    }, onDone: () {
      loggingSubscription.cancel();
      printStatus('Application finished.');
      complete(0);
    });
  }

  printStatus('Application running.');

  // When terminating, close down the log reader.
  ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
    loggingSubscription.cancel();
    printStatus('');
    complete(0);
  });
  ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
    loggingSubscription.cancel();
    complete(0);
  });

  return exitCompleter.future;
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
