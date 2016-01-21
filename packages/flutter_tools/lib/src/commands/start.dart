// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/logging.dart';
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

// We don't yet support iOS here. https://github.com/flutter/flutter/issues/1036

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
                             '(defaults to checked/debug mode) (Android only).';

  StartCommand() {
    argParser.addFlag('poke',
        negatable: false,
        help: 'Restart the connection to the server.');
    argParser.addFlag('clear-logs',
        defaultsTo: true,
        help: 'Clear log history before starting the app.');
  }

  @override
  Future<int> runInProject() async {
    logging.fine('Downloading toolchain.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ], eagerError: true);

    bool poke = argResults['poke'];
    bool clearLogs = argResults['clear-logs'];

    // Only stop and reinstall if the user did not specify a poke.
    int result = await startApp(
      devices,
      applicationPackages,
      toolchain,
      target: argResults['target'],
      install: !poke,
      stop: !poke,
      checked: argResults['checked'],
      traceStartup: argResults['trace-startup'],
      route: argResults['route'],
      poke: poke,
      clearLogs: clearLogs
    );

    logging.fine('Finished start command.');
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
  bool poke: false,
  bool clearLogs: false
}) async {

  String mainPath = findMainDartFile(target);
  if (!FileSystemEntity.isFileSync(mainPath)) {
    String message = 'Tried to run $mainPath, but that file does not exist.';
    if (target == null)
      message += '\nConsider using the -t option to specify the Dart file to start.';
    logging.severe(message);
    return 1;
  }

  if (stop) {
    logging.fine('Running stop command.');
    stopAll(devices, applicationPackages);
  }

  if (install) {
    logging.fine('Running install command.');
    installApp(devices, applicationPackages);
  }

  bool startedSomething = false;

  for (Device device in devices.all) {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
    if (package == null || !device.isConnected())
      continue;

    logging.fine('Running build command for $device.');

    Map<String, dynamic> platformArgs = <String, dynamic>{};

    if (poke != null)
      platformArgs['poke'] = poke;
    if (traceStartup != null)
      platformArgs['trace-startup'] = traceStartup;
    if (clearLogs != null)
      platformArgs['clear-logs'] = clearLogs;

    bool result = await device.startApp(
      package,
      toolchain,
      mainPath: mainPath,
      route: route,
      checked: checked,
      platformArgs: platformArgs
    );

    if (!result) {
      logging.severe('Could not start \'${package.name}\' on \'${device.id}\'');
    } else {
      startedSomething = true;
    }
  }

  if (!startedSomething) {
    if (!devices.all.any((device) => device.isConnected())) {
      logging.severe('Unable to run application - no connected devices.');
    } else {
      logging.severe('Unable to run application.');
    }
  }

  return startedSomething ? 0 : 2;
}
