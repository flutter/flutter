// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/flx.dart' as flx;
import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';
import 'apk.dart';
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

abstract class StartCommandBase extends FlutterCommand {
  StartCommandBase() {
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
        defaultsTo: flx.defaultMainPath,
        help: 'Target app path / main entry-point file.');
    argParser.addOption('route',
        help: 'Which route to load when starting the app.');
  }
}

class StartCommand extends StartCommandBase {
  final String name = 'start';
  final String description = 'Start your Flutter app on an attached device '
                             '(defaults to checked/debug mode).';

  StartCommand() {
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
    argParser.addOption('debug-port',
        defaultsTo: observatoryDefaultPort.toString(),
        help: 'Listen to the given port for a debug connection.');
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

    printTrace('Finished start command.');
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
    applicationPackages = await buildAll(
      devices, applicationPackages, toolchain, configs,
      enginePath: enginePath,
      target: target);
  }

  if (stop) {
    printTrace('Running stop command.');
    stopAll(devices, applicationPackages);
  }

  if (install) {
    printTrace('Running install command.');
    installApp(devices, applicationPackages);
  }

  bool startedSomething = false;

  for (Device device in devices.all) {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
    if (package == null || !device.isConnected())
      continue;

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
    }
  }

  if (!startedSomething) {
    if (!devices.all.any((device) => device.isConnected())) {
      printError('Unable to run application - no connected devices.');
    } else {
      printError('Unable to run application.');
    }
  }

  return startedSomething ? 0 : 2;
}

/// Return a relative path if [fullPath] is contained by the cwd, else return an
/// absolute path.
String _getDisplayPath(String fullPath) {
  String cwd = Directory.current.path + Platform.pathSeparator;
  if (fullPath.startsWith(cwd))
    return fullPath.substring(cwd.length);
  return fullPath;
}
