// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../build_configuration.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../flx.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';
import 'apk.dart';
import 'devices.dart';
import 'install.dart';
import 'stop.dart';

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
    argParser.addOption('target',
        abbr: 't',
        defaultsTo: defaultMainPath,
        help: 'Target app path / main entry-point file.');
    argParser.addOption('route',
        help: 'Which route to load when starting the app.');
  }
}

class RunCommand extends RunCommandBase {
  final String name = 'run';
  final String description = 'Run your Flutter app on an attached device.';
  final List<String> aliases = <String>['start'];

  RunCommand() {
    argParser.addFlag('full-restart',
        defaultsTo: true,
        help: 'Stop any currently running application process before starting the app.');
    argParser.addFlag('clear-logs',
        defaultsTo: true,
        help: 'Clear log history before starting the app.');
    argParser.addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.');
    argParser.addFlag('pub',
        defaultsTo: true,
        help: 'Whether to run "pub get" before running the app.');
    argParser.addOption('debug-port',
        defaultsTo: observatoryDefaultPort.toString(),
        help: 'Listen to the given port for a debug connection.');
  }

  bool get requiresDevice => true;

  @override
  Future<int> run() async {
    if (argResults['pub'])
      await pubGet();
    return await super.run();
  }

  @override
  Future<int> runInProject() async {
    printTrace('Downloading toolchain.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ], eagerError: true);

    bool clearLogs = argResults['clear-logs'];

    int debugPort;

    try {
      debugPort = int.parse(argResults['debug-port']);
    } catch (error) {
      printError('Invalid port for `--debug-port`: $error');
      return 1;
    }

    int result = await startApp(
      devices,
      applicationPackages,
      toolchain,
      buildConfigurations,
      target: argResults['target'],
      enginePath: runner.enginePath,
      install: true,
      stop: argResults['full-restart'],
      checked: argResults['checked'],
      traceStartup: argResults['trace-startup'],
      route: argResults['route'],
      clearLogs: clearLogs,
      startPaused: argResults['start-paused'],
      debugPort: debugPort
    );

    printTrace('Finished $name command.');
    return result;
  }
}

Future<int> startApp(
  DeviceStore devices,
  ApplicationPackageStore applicationPackages,
  Toolchain toolchain,
  List<BuildConfiguration> configs, {
  String target,
  String enginePath,
  bool stop: true,
  bool install: true,
  bool checked: true,
  bool traceStartup: false,
  String route,
  bool clearLogs: false,
  bool startPaused: false,
  int debugPort: observatoryDefaultPort
}) async {
  String mainPath = findMainDartFile(target);
  if (!FileSystemEntity.isFileSync(mainPath)) {
    String message = 'Tried to run $mainPath, but that file does not exist.';
    if (target == null)
      message += '\nConsider using the -t option to specify the Dart file to start.';
    printError(message);
    return 1;
  }

  if (install) {
    printTrace('Running build command.');
    int result = await buildAll(
      devices, applicationPackages, toolchain, configs,
      enginePath: enginePath,
      target: target
    );
    if (result != 0)
      return result;
  }

  if (stop) {
    printTrace('Running stop command.');
    await stopAll(devices, applicationPackages);
  }

  if (install) {
    printTrace('Running install command.');
    // TODO(devoncarew): This fails for ios devices - we haven't built yet.
    await installApp(devices, applicationPackages);
  }

  bool startedSomething = false;
  int unsupportedCount = 0;

  for (Device device in devices.all) {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
    if (package == null || !device.isConnected())
      continue;

    if (!device.isSupported()) {
      printStatus("Skipping unsupported device '${device.name}'. ${device.supportMessage()}");
      unsupportedCount++;
      continue;
    }

    printTrace('Running build command for $device.');

    Map<String, dynamic> platformArgs = <String, dynamic>{};

    if (traceStartup != null)
      platformArgs['trace-startup'] = traceStartup;

    printStatus('Starting ${_getDisplayPath(mainPath)} on ${device.name}...');

    bool result = await device.startApp(
      package,
      toolchain,
      mainPath: mainPath,
      route: route,
      checked: checked,
      clearLogs: clearLogs,
      startPaused: startPaused,
      debugPort: debugPort,
      platformArgs: platformArgs
    );

    if (!result) {
      printError('Error starting application on ${device.name}.');
    } else {
      startedSomething = true;

      // If the user specified --start-paused (and the device supports it) then
      // wait for the observatory port to become available before returning from
      // `startApp()`.
      if (startPaused && device.supportsStartPaused) {
        await _delayUntilObservatoryAvailable('localhost', debugPort);
      }
    }
  }

  if (!startedSomething) {
    int connected = devices.all.where((device) => device.isConnected()).length;
    String message = 'Unable to run application';
    if (connected == 0) {
      message += ' - no connected devices.';
    } else if (unsupportedCount != 0) {
      message += ' - $unsupportedCount unsupported ${pluralize('device', unsupportedCount)} connected';
    }
    printError(message);
  }

  return startedSomething ? 0 : 2;
}

/// Delay until the Observatory / service protocol is available.
///
/// This does not fail if we're unable to connect, and times out after the given
/// [timeout].
Future _delayUntilObservatoryAvailable(String host, int port, {
  Duration timeout: const Duration(seconds: 10)
}) async {
  Stopwatch stopwatch = new Stopwatch()..start();

  final String url = 'ws://$host:$port/ws';
  printTrace('Looking for the observatory at $url.');

  while (stopwatch.elapsed <= timeout) {
    try {
      WebSocket ws = await WebSocket.connect(url);

      printTrace('Connected to the observatory port (${stopwatch.elapsedMilliseconds}ms).');
      ws.close().catchError((error) => null);

      return;
    } catch (error) {
      await new Future.delayed(new Duration(milliseconds: 250));
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
