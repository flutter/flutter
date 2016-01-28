// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/context.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';
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
        help: 'Target app path or filename to start.');
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
  }

  @override
  Future<int> runInProject() async {
    printTrace('Downloading toolchain.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ], eagerError: true);

    bool clearLogs = argResults['clear-logs'];

    int result = await startApp(
      devices,
      applicationPackages,
      toolchain,
      target: argResults['target'],
      install: true,
      stop: argResults['full-restart'],
      checked: argResults['checked'],
      traceStartup: argResults['trace-startup'],
      route: argResults['route'],
      clearLogs: clearLogs
    );

    printTrace('Finished start command.');
    return result;
  }
}

Future<int> startApp(
  DeviceStore devices,
  ApplicationPackageStore applicationPackages,
  Toolchain toolchain, {
  String target,
  bool stop: true,
  bool install: true,
  bool checked: true,
  bool traceStartup: false,
  String route,
  bool clearLogs: false
}) async {

  String mainPath = findMainDartFile(target);
  if (!FileSystemEntity.isFileSync(mainPath)) {
    String message = 'Tried to run $mainPath, but that file does not exist.';
    if (target == null)
      message += '\nConsider using the -t option to specify the Dart file to start.';
    printError(message);
    return 1;
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
    if (clearLogs != null)
      platformArgs['clear-logs'] = clearLogs;

    printStatus('Starting $mainPath on ${device.name}...');

    bool result = await device.startApp(
      package,
      toolchain,
      mainPath: mainPath,
      route: route,
      checked: checked,
      platformArgs: platformArgs
    );

    if (!result) {
      printError('Could not start \'${package.name}\' on \'${device.id}\'');
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
