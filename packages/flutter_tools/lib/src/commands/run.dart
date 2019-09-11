// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../device.dart';
import '../features.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../tracing.dart';
import '../version.dart';
import '../web/web_runner.dart';
import 'daemon.dart';

abstract class RunCommandBase extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  // Used by run and drive commands.
  RunCommandBase({ bool verboseHelp = false }) {
    addBuildModeFlags(defaultToRelease: false, verboseHelp: verboseHelp);
    usesFlavorOption();
    argParser
      ..addFlag('trace-startup',
        negatable: false,
        help: 'Trace application startup, then exit, saving the trace to a file.',
      )
      ..addFlag('verbose-system-logs',
        negatable: false,
        help: 'Include verbose logging from the flutter engine.',
      )
      ..addOption('route',
        help: 'Which route to load when running the app.',
      );
    usesWebOptions(hide: !verboseHelp);
    usesTargetOption();
    usesPortOptions();
    usesIpv6Flag();
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    usesIsolateFilterOption(hide: !verboseHelp);
  }

  bool get traceStartup => argResults['trace-startup'];

  String get route => argResults['route'];
}

class RunCommand extends RunCommandBase {
  RunCommand({ bool verboseHelp = false }) : super(verboseHelp: verboseHelp) {
    requiresPubspecYaml();
    usesFilesystemOptions(hide: !verboseHelp);
    argParser
      ..addFlag('start-paused',
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.',
      )
      ..addFlag('enable-software-rendering',
        negatable: false,
        help: 'Enable rendering using the Skia software backend. '
              'This is useful when testing Flutter on emulators. By default, '
              'Flutter will attempt to either use OpenGL or Vulkan and fall back '
              'to software when neither is available.',
      )
      ..addFlag('skia-deterministic-rendering',
        negatable: false,
        help: 'When combined with --enable-software-rendering, provides 100% '
              'deterministic Skia rendering.',
      )
      ..addFlag('trace-skia',
        negatable: false,
        help: 'Enable tracing of Skia code. This is useful when debugging '
              'the GPU thread. By default, Flutter will not log skia code.',
      )
      ..addFlag('trace-systrace',
        negatable: false,
        help: 'Enable tracing to the system tracer. This is only useful on '
              'platforms where such a tracer is available (Android and Fuchsia).',
      )
      ..addFlag('dump-skp-on-shader-compilation',
        negatable: false,
        help: 'Automatically dump the skp that triggers new shader compilations. '
              'This is useful for wrting custom ShaderWarmUp to reduce jank. '
              'By default, this is not enabled to reduce the overhead. '
              'This is only available in profile or debug build. ',
      )
      ..addFlag('await-first-frame-when-tracing',
        defaultsTo: true,
        help: 'Whether to wait for the first frame when tracing startup ("--trace-startup"), '
              'or just dump the trace as soon as the application is running. The first frame '
              'is detected by looking for a Timeline event with the name '
              '"${Tracing.firstUsefulFrameEventName}". '
              'By default, the widgets library\'s binding takes care of sending this event. ',
      )
      ..addFlag('use-test-fonts',
        negatable: true,
        help: 'Enable (and default to) the "Ahem" font. This is a special font '
              'used in tests to remove any dependencies on the font metrics. It '
              'is enabled when you use "flutter test". Set this flag when running '
              'a test using "flutter run" for debugging purposes. This flag is '
              'only available when running in debug mode.',
      )
      ..addFlag('build',
        defaultsTo: true,
        help: 'If necessary, build the app before running.',
      )
      ..addOption('dart-flags',
        hide: !verboseHelp,
        help: 'Pass a list of comma separated flags to the Dart instance at '
              'application startup. Flags passed through this option must be '
              'present on the whitelist defined within the Flutter engine. If '
              'a non-whitelisted flag is encountered, the process will be '
              'terminated immediately.\n\n'
              'This flag is not available on the stable channel and is only '
              'applied in debug and profile modes. This option should only '
              'be used for experiments and should not be used by typical users.')
      ..addOption('use-application-binary',
        hide: !verboseHelp,
        help: 'Specify a pre-built application binary to use when running.',
      )
      ..addOption('project-root',
        hide: !verboseHelp,
        help: 'Specify the project root directory.',
      )
      ..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
              'and progress in machine friendly format.',
      )
      ..addFlag('hot',
        negatable: true,
        defaultsTo: kHotReloadDefault,
        help: 'Run with support for hot reloading. Only available for debug mode. Not available with "--trace-startup".',
      )
      ..addFlag('resident',
        negatable: true,
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Stay resident after launching the application. Not available with "--trace-startup".',
      )
      ..addOption('pid-file',
        help: 'Specify a file to write the process id to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart.',
      )
      ..addFlag('benchmark',
        negatable: false,
        hide: !verboseHelp,
        help: 'Enable a benchmarking mode. This will run the given application, '
              'measure the startup time and the app restart time, write the '
              'results out to "refresh_benchmark.json", and exit. This flag is '
              'intended for use in generating automated flutter benchmarks.',
      )
      ..addFlag('disable-service-auth-codes',
        negatable: false,
        hide: !verboseHelp,
        help: 'No longer require an authentication code to connect to the VM '
              'service (not recommended).')
      ..addOption(FlutterOptions.kExtraFrontEndOptions, hide: true)
      ..addOption(FlutterOptions.kExtraGenSnapshotOptions, hide: true)
      ..addMultiOption(FlutterOptions.kEnableExperiment,
        splitCommas: true,
        hide: true,
      );
  }

  @override
  final String name = 'run';

  @override
  final String description = 'Run your Flutter app on an attached device.';

  List<Device> devices;

  @override
  Future<String> get usagePath async {
    final String command = await super.usagePath;

    if (devices == null)
      return command;
    else if (devices.length > 1)
      return '$command/all';
    else
      return '$command/${getNameForTargetPlatform(await devices[0].targetPlatform)}';
  }

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    String deviceType, deviceOsVersion;
    bool isEmulator;

    if (devices == null || devices.isEmpty) {
      deviceType = 'none';
      deviceOsVersion = 'none';
      isEmulator = false;
    } else if (devices.length == 1) {
      deviceType = getNameForTargetPlatform(await devices[0].targetPlatform);
      deviceOsVersion = await devices[0].sdkNameAndVersion;
      isEmulator = await devices[0].isLocalEmulator;
    } else {
      deviceType = 'multiple';
      deviceOsVersion = 'multiple';
      isEmulator = false;
    }
    final String modeName = getBuildInfo().modeName;
    final AndroidProject androidProject = FlutterProject.current().android;
    final IosProject iosProject = FlutterProject.current().ios;
    final List<String> hostLanguage = <String>[];

    if (androidProject != null && androidProject.existsSync()) {
      hostLanguage.add(androidProject.isKotlin ? 'kotlin' : 'java');
    }
    if (iosProject != null && iosProject.exists) {
      hostLanguage.add(iosProject.isSwift ? 'swift' : 'objc');
    }

    return <CustomDimensions, String>{
      CustomDimensions.commandRunIsEmulator: '$isEmulator',
      CustomDimensions.commandRunTargetName: deviceType,
      CustomDimensions.commandRunTargetOsVersion: deviceOsVersion,
      CustomDimensions.commandRunModeName: modeName,
      CustomDimensions.commandRunProjectModule: '${FlutterProject.current().isModule}',
      CustomDimensions.commandRunProjectHostLanguage: hostLanguage.join(','),
    };
  }

  @override
  bool get shouldRunPub {
    // If we are running with a prebuilt application, do not run pub.
    if (runningWithPrebuiltApplication)
      return false;

    return super.shouldRunPub;
  }

  bool shouldUseHotMode() {
    final bool hotArg = argResults['hot'] ?? false;
    final bool shouldUseHotMode = hotArg && !traceStartup;
    return getBuildInfo().isDebug && shouldUseHotMode;
  }

  bool get runningWithPrebuiltApplication =>
      argResults['use-application-binary'] != null;

  bool get stayResident => argResults['resident'];
  bool get awaitFirstFrameWhenTracing => argResults['await-first-frame-when-tracing'];

  @override
  Future<void> validateCommand() async {
    // When running with a prebuilt application, no command validation is
    // necessary.
    if (!runningWithPrebuiltApplication)
      await super.validateCommand();
    devices = await findAllTargetDevices();
    if (devices == null)
      throwToolExit(null);
    if (deviceManager.hasSpecifiedAllDevices && runningWithPrebuiltApplication)
      throwToolExit('Using -d all with --use-application-binary is not supported');
  }

  DebuggingOptions _createDebuggingOptions() {
    final BuildInfo buildInfo = getBuildInfo();
    if (buildInfo.isRelease) {
      return DebuggingOptions.disabled(buildInfo);
    } else {
      return DebuggingOptions.enabled(
        buildInfo,
        startPaused: argResults['start-paused'],
        disableServiceAuthCodes: argResults['disable-service-auth-codes'],
        dartFlags: argResults['dart-flags'] ?? '',
        useTestFonts: argResults['use-test-fonts'],
        enableSoftwareRendering: argResults['enable-software-rendering'],
        skiaDeterministicRendering: argResults['skia-deterministic-rendering'],
        traceSkia: argResults['trace-skia'],
        traceSystrace: argResults['trace-systrace'],
        dumpSkpOnShaderCompilation: argResults['dump-skp-on-shader-compilation'],
        observatoryPort: observatoryPort,
        verboseSystemLogs: argResults['verbose-system-logs'],
        hostname: featureFlags.isWebEnabled ? argResults['hostname'] : '',
        port: featureFlags.isWebEnabled ? argResults['port'] : '',
      );
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    // Enable hot mode by default if `--no-hot` was not passed and we are in
    // debug mode.
    final bool hotMode = shouldUseHotMode();

    writePidFile(argResults['pid-file']);

    if (argResults['machine']) {
      if (devices.length > 1)
        throwToolExit('--machine does not support -d all.');
      final Daemon daemon = Daemon(stdinCommandStream, stdoutCommandResponse,
          notifyingLogger: NotifyingLogger(), logToStdout: true);
      AppInstance app;
      try {
        final String applicationBinaryPath = argResults['use-application-binary'];
        app = await daemon.appDomain.startApp(
          devices.first, fs.currentDirectory.path, targetFile, route,
          _createDebuggingOptions(), hotMode,
          applicationBinary: applicationBinaryPath == null
              ? null
              : fs.file(applicationBinaryPath),
          trackWidgetCreation: argResults['track-widget-creation'],
          projectRootPath: argResults['project-root'],
          packagesFilePath: globalResults['packages'],
          dillOutputPath: argResults['output-dill'],
          ipv6: ipv6,
        );
      } catch (error) {
        throwToolExit(error.toString());
      }
      final DateTime appStartedTime = systemClock.now();
      final int result = await app.runner.waitForAppToFinish();
      if (result != 0)
        throwToolExit(null, exitCode: result);
      return FlutterCommandResult(
        ExitStatus.success,
        timingLabelParts: <String>['daemon'],
        endTimeOverride: appStartedTime,
      );
    }
    terminal.usesTerminalUi = true;

    if (argResults['dart-flags'] != null && !FlutterVersion.instance.isMaster) {
      throw UsageException('--dart-flags is not available on the stable '
                           'channel.', null);
    }

    for (Device device in devices) {
      if (await device.isLocalEmulator) {
        if (await device.supportsHardwareRendering) {
          final bool enableSoftwareRendering = argResults['enable-software-rendering'] == true;
          if (enableSoftwareRendering) {
            printStatus(
              'Using software rendering with device ${device.name}. You may get better performance '
              'with hardware mode by configuring hardware rendering for your device.'
            );
          } else {
            printStatus(
              'Using hardware rendering with device ${device.name}. If you get graphics artifacts, '
              'consider enabling software rendering with "--enable-software-rendering".'
            );
          }
        }

        if (!isEmulatorBuildMode(getBuildMode())) {
          throwToolExit('${toTitleCase(getFriendlyModeName(getBuildMode()))} mode is not supported for emulators.');
        }
      }
    }

    if (hotMode) {
      for (Device device in devices) {
        if (!device.supportsHotReload)
          throwToolExit('Hot reload is not supported by ${device.name}. Run with --no-hot.');
      }
    }

    List<String> expFlags;
    if (argParser.options.containsKey(FlutterOptions.kEnableExperiment) &&
        argResults[FlutterOptions.kEnableExperiment].isNotEmpty) {
      expFlags = argResults[FlutterOptions.kEnableExperiment];
    }
    final List<FlutterDevice> flutterDevices = <FlutterDevice>[];
    final FlutterProject flutterProject = FlutterProject.current();
    for (Device device in devices) {
      final FlutterDevice flutterDevice = await FlutterDevice.create(
        device,
        flutterProject: flutterProject,
        trackWidgetCreation: argResults['track-widget-creation'],
        fileSystemRoots: argResults['filesystem-root'],
        fileSystemScheme: argResults['filesystem-scheme'],
        viewFilter: argResults['isolate-filter'],
        experimentalFlags: expFlags,
        target: argResults['target'],
        buildMode: getBuildMode(),
      );
      flutterDevices.add(flutterDevice);
    }
    // Only support "web mode" with a single web device due to resident runner
    // refactoring required otherwise.
    final bool webMode = featureFlags.isWebEnabled &&
                         devices.length == 1  &&
                         await devices.single.targetPlatform == TargetPlatform.web_javascript;

    ResidentRunner runner;
    final String applicationBinaryPath = argResults['use-application-binary'];
    if (hotMode && !webMode) {
      runner = HotRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: _createDebuggingOptions(),
        benchmarkMode: argResults['benchmark'],
        applicationBinary: applicationBinaryPath == null
            ? null
            : fs.file(applicationBinaryPath),
        projectRootPath: argResults['project-root'],
        packagesFilePath: globalResults['packages'],
        dillOutputPath: argResults['output-dill'],
        stayResident: stayResident,
        ipv6: ipv6,
      );
    } else if (webMode) {
      runner = webRunnerFactory.createWebRunner(
        devices.single,
        target: targetFile,
        flutterProject: flutterProject,
        ipv6: ipv6,
        debuggingOptions: _createDebuggingOptions(),
      );
    } else {
      runner = ColdRunner(
        flutterDevices,
        target: targetFile,
        debuggingOptions: _createDebuggingOptions(),
        traceStartup: traceStartup,
        awaitFirstFrameWhenTracing: awaitFirstFrameWhenTracing,
        applicationBinary: applicationBinaryPath == null
            ? null
            : fs.file(applicationBinaryPath),
        ipv6: ipv6,
        stayResident: stayResident,
      );
    }

    DateTime appStartedTime;
    // Sync completer so the completing agent attaching to the resident doesn't
    // need to know about analytics.
    //
    // Do not add more operations to the future.
    final Completer<void> appStartedTimeRecorder = Completer<void>.sync();
    // This callback can't throw.
    unawaited(appStartedTimeRecorder.future.then<void>(
      (_) {
        appStartedTime = systemClock.now();
        if (stayResident) {
          TerminalHandler(runner)
            ..setupTerminal()
            ..registerSignalHandlers();
        }
      }
    ));

    final int result = await runner.run(
      appStartedCompleter: appStartedTimeRecorder,
      route: route,
    );
    if (result != 0) {
      throwToolExit(null, exitCode: result);
    }
    return FlutterCommandResult(
      ExitStatus.success,
      timingLabelParts: <String>[
        hotMode ? 'hot' : 'cold',
        getModeName(getBuildMode()),
        devices.length == 1
            ? getNameForTargetPlatform(await devices[0].targetPlatform)
            : 'multiple',
        devices.length == 1 && await devices[0].isLocalEmulator ? 'emulator' : null,
      ],
      endTimeOverride: appStartedTime,
    );
  }
}
