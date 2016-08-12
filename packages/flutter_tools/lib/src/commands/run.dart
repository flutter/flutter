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
import '../hot.dart';
import '../vmservice.dart';
import '../resident_runner.dart';
import '../run.dart';
import '../runner/flutter_command.dart';
import 'build_apk.dart';
import 'install.dart';
import 'trace.dart';
import '../base/os.dart';

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
    argParser.addFlag('build',
        defaultsTo: true,
        help: 'If necessary, build the app before running.');
    argParser.addOption('use-application-binary',
        hide: true,
        help: 'Specify a pre-built application binary to use when running.');
    usesPubOption();

    // Option to enable hot reloading.
    argParser.addFlag('hot',
                      negatable: false,
                      defaultsTo: false,
                      help: 'Run with support for hot reloading.');

    // Option to enable control over a named pipe.
    argParser.addOption('control-pipe',
                        hide: true,
                        help: 'Specify a named pipe to receive commands on.');


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

    String command = argResults['hot'] ? 'hotrun' : name;

    if (device == null)
      return command;

    // Return 'run/ios'.
    return '$command/${getNameForTargetPlatform(device.platform)}';
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
    } else {
      if (argResults['control-pipe'] != null) {
        printError('--control-pipe requires --hot');
        return 1;
      }
    }

    String pipePath = argResults['control-pipe'];
    File pipe;
    if (pipePath != null) {
      try {
        // Attempt to create the pipe.
        os.makePipe(pipePath);
      } catch (_) { /* ignore */ }
      pipe = new File(pipePath);
    }

    ResidentRunner runner;

    if (argResults['hot']) {
      runner = new HotRunner(
        deviceForCommand,
        target: targetFile,
        debuggingOptions: options,
        pipe: pipe
      );
    } else {
      runner = new RunAndStayResident(
        deviceForCommand,
        target: targetFile,
        debuggingOptions: options,
        traceStartup: traceStartup,
        benchmark: argResults['benchmark'],
        applicationBinary: argResults['use-application-binary']
      );
    }

    return runner.run(route: route, shouldBuild: argResults['build']);
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
      await device.stopApp(package);
    }
  }

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
      VMService observatory = await VMService.connect(result.observatoryPort);
      await downloadStartupTrace(observatory);
    } catch (error) {
      printError('Error downloading trace from observatory: $error');
      return 1;
    }
  }

  if (benchmark)
    writeRunBenchmarkFile(stopwatch);

  return result.started ? 0 : 2;
}
