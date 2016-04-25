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

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  if (target == null)
    target = '';
  String targetPath = path.absolute(target);
  if (FileSystemEntity.isDirectorySync(targetPath)) {
    return path.join(targetPath, 'lib', 'main.dart');
  } else {
    return targetPath;
  }
}

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
    argParser.addFlag('clear-logs',
        defaultsTo: true,
        help: 'Clear log history before running the app.');
    argParser.addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.');
    argParser.addOption('debug-port',
        defaultsTo: observatoryDefaultPort.toString(),
        help: 'Listen to the given port for a debug connection.');
    usesPubOption();
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
    bool clearLogs = argResults['clear-logs'];

    int debugPort;

    try {
      debugPort = int.parse(argResults['debug-port']);
    } catch (error) {
      printError('Invalid port for `--debug-port`: $error');
      return 1;
    }

    int result = await startApp(
      deviceForCommand,
      toolchain,
      target: target,
      enginePath: runner.enginePath,
      install: true,
      stop: argResults['full-restart'],
      checked: checked,
      traceStartup: traceStartup,
      route: route,
      clearLogs: clearLogs,
      startPaused: argResults['start-paused'],
      debugPort: debugPort,
      buildMode: getBuildMode()
    );

    return result;
  }
}

String _getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
      return 'Is your project missing an android/AndroidManifest.xml?';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Info.plist?';
    default:
      return null;
  }
}

Future<int> startApp(
  Device device,
  Toolchain toolchain, {
  String target,
  String enginePath,
  bool stop: true,
  bool install: true,
  bool checked: true,
  bool traceStartup: false,
  String route,
  bool clearLogs: false,
  bool startPaused: false,
  int debugPort: observatoryDefaultPort,
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
    printTrace('Running install command.');

    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    await installApp(device, package);
  }

  Map<String, dynamic> platformArgs = <String, dynamic>{};

  if (traceStartup != null)
    platformArgs['trace-startup'] = traceStartup;

  printStatus('Running ${_getDisplayPath(mainPath)} on ${device.name}...');

  bool result = await device.startApp(
    package,
    toolchain,
    mainPath: mainPath,
    route: route,
    checked: checked,
    clearLogs: clearLogs,
    startPaused: startPaused,
    observatoryPort: debugPort,
    platformArgs: platformArgs
  );

  if (!result)
    printError('Error running application on ${device.name}.');

  return result ? 0 : 2;
}

/// Delay until the Observatory / service protocol is available.
///
/// This does not fail if we're unable to connect, and times out after the given
/// [timeout].
Future<Null> delayUntilObservatoryAvailable(String host, int port, {
  Duration timeout: const Duration(seconds: 10)
}) async {
  printTrace('Waiting until Observatory is available (port $port).');

  Stopwatch stopwatch = new Stopwatch()..start();

  final String url = 'ws://$host:$port/ws';
  printTrace('Looking for the observatory at $url.');

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

/// Return a relative path if [fullPath] is contained by the cwd, else return an
/// absolute path.
String _getDisplayPath(String fullPath) {
  String cwd = Directory.current.path + Platform.pathSeparator;
  if (fullPath.startsWith(cwd))
    return fullPath.substring(cwd.length);
  return fullPath;
}
