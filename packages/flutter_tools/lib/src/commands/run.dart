// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../application_package.dart';
import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../observatory.dart';
import '../run.dart';
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

    argParser.addFlag('resident',
        defaultsTo: true,
        help: 'Don\'t terminate the \'flutter run\' process after starting the application.');

    // Option to enable hot reloading.
    argParser.addFlag('hot',
                      negatable: false,
                      defaultsTo: false,
                      help: 'Run with support for hot reloading.');

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

    Cache.releaseLockEarly();

    // Do some early error checks for hot mode.
    bool hotMode = argResults['hot'];
    if (hotMode) {
      if (getBuildMode() != BuildMode.debug) {
        printError('Hot mode only works with debug builds.');
        return 1;
      }
      if (!deviceForCommand.supportsHotMode) {
        printError('Hot mode is not supported by this device.');
        return 1;
      }
    }

    if (argResults['resident']) {
      RunAndStayResident runner = new RunAndStayResident(
        deviceForCommand,
        target: targetFile,
        debuggingOptions: options,
        hotMode: argResults['hot']
      );

      return runner.run(
        traceStartup: traceStartup,
        benchmark: argResults['benchmark'],
        route: route
      );
    } else {
      // TODO(devoncarew): Remove this path and support the `--no-resident` option
      // using the `RunAndStayResident` class.
      return startApp(
        deviceForCommand,
        target: targetFile,
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
    String hint = getMissingPackageHintForPlatform(device.platform);
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

    if (!(installApp(device, package, uninstall: false)))
      return 1;
  }

  Map<String, dynamic> platformArgs = <String, dynamic>{};

  if (traceStartup != null)
    platformArgs['trace-startup'] = traceStartup;

  printStatus('Running ${getDisplayPath(mainPath)} on ${device.name}...');

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
      await downloadStartupTrace(observatory);
    } catch (error) {
      printError('Error connecting to observatory: $error');
      return 1;
    }
  }

  if (benchmark)
    writeRunBenchmarkFile(stopwatch);

  return result.started ? 0 : 2;
}
