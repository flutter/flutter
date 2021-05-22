// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import '../base/common.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../preview_device.dart';
import '../resident_runner.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';

class PreviewCommand extends FlutterCommand {
  PreviewCommand({bool verboseHelp = false}) {
    requiresPubspecYaml();
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false);
    usesDartDefineOption();
    argParser
      ..addOption('vmservice-out-file',
        help: 'A file to write the attached vmservice URL to after an '
              'application is started.',
        valueHelp: 'project/example/out.txt',
        hide: !verboseHelp,
      )
      ..addFlag('start-paused',
        defaultsTo: startPausedDefault,
        help: 'Start in a paused mode and wait for a debugger to connect.',
      )
       ..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
              'and progress in machine friendly format.',
      )
       ..addOption('pid-file',
        help: 'Specify a file to write the process ID to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart. '
              'The file is created when the signal handlers '
              'are hooked and deleted when they are removed.',
      );
    usesTargetOption();
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addDdsOptions(verboseHelp: verboseHelp);
    addDevToolsOptions(verboseHelp: verboseHelp);
    usesIpv6Flag(verboseHelp: verboseHelp);
  }

  Future<DebuggingOptions> createDebuggingOptions() async {
    final BuildInfo buildInfo = await getBuildInfo();
    return DebuggingOptions.enabled(
      buildInfo,
      startPaused: boolArg('start-paused'),
      devToolsServerAddress: devToolsServerAddress,
      vmserviceOutFile: stringArg('vmservice-out-file'),
    );
  }

  @override
  String get description => 'Preview your application code.';

  @override
  String get name => 'preview';

  bool get startPausedDefault => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!Platform.isWindows) {
      throwToolExit('"flutter preview" is only supported on windows host');
    }
    final DebuggingOptions debuggingOptions = await createDebuggingOptions();
    final Device previewDevice = PreviewDevice(
      fileSystem: globals.fs,
      platform: globals.platform,
      logger: globals.logger,
      processManager: globals.processManager,
    );

    final HotRunner runner = HotRunner(
      <FlutterDevice>[
        await FlutterDevice.create(previewDevice, target: targetFile, buildInfo: debuggingOptions.buildInfo, platform: globals.platform),
      ],
      target: targetFile,
      debuggingOptions: debuggingOptions,
      benchmarkMode: false,
      stayResident: true,
      ipv6: ipv6,
    );

     DateTime appStartedTime;
    // Sync completer so the completing agent attaching to the resident doesn't
    // need to know about analytics.
    //
    // Do not add more operations to the future.
    final Completer<void> appStartedTimeRecorder = Completer<void>.sync();

    TerminalHandler handler;
    // This callback can't throw.
    unawaited(appStartedTimeRecorder.future.then<void>(
      (_) {
        appStartedTime = globals.systemClock.now();
          handler = TerminalHandler(
            runner,
            logger: globals.logger,
            terminal: globals.terminal,
            signals: globals.signals,
            processInfo: globals.processInfo,
            reportReady: false,
            pidFile: stringArg('pid-file'),
          )
            ..registerSignalHandlers()
            ..setupTerminal();
      }
    ));
    final int result = await runner.run(
      appStartedCompleter: appStartedTimeRecorder,
      enableDevTools: true,
    );
    handler?.stop();
    if (result != 0) {
      throwToolExit(null, exitCode: result);
    }
    return FlutterCommandResult(
      ExitStatus.success,
      endTimeOverride: appStartedTime,
    );
  }
}
