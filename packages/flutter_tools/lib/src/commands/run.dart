// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../hot.dart';
import '../ios/mac.dart';
import '../resident_runner.dart';
import '../run.dart';
import '../runner/flutter_command.dart';
import 'daemon.dart';

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

  RunCommand({ bool verboseHelp: false }) {
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
        hide: !verboseHelp,
        help: 'Specify a pre-built application binary to use when running.');
    argParser.addOption('snapshotter',
        hide: !verboseHelp,
        help: 'Specify the path to the sky_snapshot binary.');
    argParser.addOption('packages',
        hide: !verboseHelp,
        help: 'Specify the path to the .packages file.');
    argParser.addOption('project_root',
        hide: !verboseHelp,
        help: 'Specify the project root directory.');
    argParser.addFlag('machine',
        hide: !verboseHelp,
        help: 'Handle machine structured JSON command input\n'
              'and provide output and progress in machine friendly format.');
    usesPubOption();

    // Option to enable hot reloading.
    argParser.addFlag(
      'hot',
      negatable: true,
      defaultsTo: kHotReloadDefault,
      help: 'Run with support for hot reloading.'
    );

    // Option to write the pid to a file.
    argParser.addOption(
      'pid-file',
      help: 'Specify a file to write the process id to.\n'
            'You can send SIGUSR1 to trigger a hot reload\n'
            'and SIGUSR2 to trigger a full restart.'
    );

    // Hidden option to enable a benchmarking mode. This will run the given
    // application, measure the startup time and the app restart time, write the
    // results out to 'refresh_benchmark.json', and exit. This flag is intended
    // for use in generating automated flutter benchmarks.
    argParser.addFlag('benchmark', negatable: false, hide: !verboseHelp);

    commandValidator = () {
      if (!runningWithPrebuiltApplication) {
        return commonCommandValidator();
      }
      // When running with a prebuilt application, no command validation is
      // necessary.
      return true;
    };
  }

  Device device;

  @override
  String get usagePath {
    String command = shouldUseHotMode() ? 'hotrun' : name;

    if (device == null)
      return command;

    // Return 'run/ios'.
    return '$command/${getNameForTargetPlatform(device.platform)}';
  }

  @override
  void printNoConnectedDevices() {
    super.printNoConnectedDevices();
    if (getCurrentHostPlatform() == HostPlatform.darwin_x64 &&
        XCode.instance.isInstalledAndMeetsVersionCheck) {
      printStatus('');
      printStatus('To run on a simulator, launch it first: open -a Simulator.app');
      printStatus('');
      printStatus('If you expected your device to be detected, please run "flutter doctor" to diagnose');
      printStatus('potential issues, or visit https://flutter.io/setup/ for troubleshooting tips.');
    }
  }

  @override
  bool get shouldRunPub {
    // If we are running with a prebuilt application, do not run pub.
    if (runningWithPrebuiltApplication)
      return false;

    return super.shouldRunPub;
  }

  bool shouldUseHotMode() {
    bool hotArg = argResults['hot'] ?? false;
    final bool shouldUseHotMode = hotArg;
    return (getBuildMode() == BuildMode.debug) && shouldUseHotMode;
  }

  bool get runningWithPrebuiltApplication =>
      argResults['use-application-binary'] != null;

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    device = await findTargetDevice();
    if (device == null)
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {

    Cache.releaseLockEarly();

    // Enable hot mode by default if `--no-hot` was not passed and we are in
    // debug mode.
    final bool hotMode = shouldUseHotMode();

    if (argResults['machine']) {
      Daemon daemon = new Daemon(stdinCommandStream, stdoutCommandResponse,
          notifyingLogger: new NotifyingLogger());
      AppInstance app = daemon.appDomain.startApp(
        device, Directory.current.path, targetFile, route,
        getBuildMode(), argResults['start-paused'], hotMode);
      return app.runner.waitForAppToFinish();
    }

    int debugPort;
    if (argResults['debug-port'] != null) {
      try {
        debugPort = int.parse(argResults['debug-port']);
      } catch (error) {
        printError('Invalid port for `--debug-port`: $error');
        return 1;
      }
    }

    if (device.isLocalEmulator && !isEmulatorBuildMode(getBuildMode())) {
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

    if (hotMode) {
      if (!device.supportsHotMode) {
        printError('Hot mode is not supported by this device. '
                   'Run with --no-hot.');
        return 1;
      }
    }

    String pidFile = argResults['pid-file'];
    if (pidFile != null) {
      // Write our pid to the file.
      new File(pidFile).writeAsStringSync(pid.toString());
    }
    ResidentRunner runner;

    if (hotMode) {
      runner = new HotRunner(
        device,
        target: targetFile,
        debuggingOptions: options,
        benchmarkMode: argResults['benchmark'],
        applicationBinary: argResults['use-application-binary'],
        projectRootPath: argResults['project_root'],
        packagesFilePath: argResults['packages'],
      );
    } else {
      runner = new RunAndStayResident(
        device,
        target: targetFile,
        debuggingOptions: options,
        traceStartup: traceStartup,
        applicationBinary: argResults['use-application-binary']
      );
    }

    return runner.run(route: route, shouldBuild: !runningWithPrebuiltApplication && argResults['build']);
  }
}
