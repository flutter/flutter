// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  LogsCommand({
    required ToolContext toolContext,
    ApplicationPackageFactory? applicationPackageFactory,
    ProcessSignal? sigint,
    ProcessSignal? sigterm,
  }) : _toolContext = toolContext,
       _sigint = sigint ?? ProcessSignal.sigint,
       _sigterm = sigterm ?? ProcessSignal.sigterm,
       super(toolContext: toolContext) {
    applicationPackages = applicationPackageFactory;
    argParser.addFlag(
      'clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.',
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  final ToolContext _toolContext;
  final ProcessSignal _sigint;
  final ProcessSignal _sigterm;

  @override
  final name = 'logs';

  @override
  final description = 'Show log output for running Flutter apps.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  Device? device;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    device = await findTargetDevice(includeDevicesUnsupportedByProject: true);
    if (device == null) {
      throwToolExit(null);
    }
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Logger logger = _toolContext.logger;
    final Device cachedDevice = device!;
    if (boolArg('clear')) {
      cachedDevice.clearLogs();
    }

    final ApplicationPackage? app = await applicationPackages?.getPackageForPlatform(
      await cachedDevice.targetPlatform,
    );

    final DeviceLogReader logReader = await cachedDevice.getLogReader(app: app);

    logger.printStatus('Showing $logReader logs:');

    final exitCompleter = Completer<int>();

    // First check if we already completed by another branch before completing
    // with [exitCode].
    void maybeComplete([int exitCode = 0]) {
      if (exitCompleter.isCompleted) {
        return;
      }
      exitCompleter.complete(exitCode);
    }

    // Start reading.
    final StreamSubscription<String> subscription = logReader.logLines.listen(
      (String message) => logger.printStatus(message, wrap: false),
      onDone: () => maybeComplete(),
      onError: (Object error) => maybeComplete(error is int ? error : 1),
    );

    // When terminating, close down the log reader.
    _sigint.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      maybeComplete();
      logger.printStatus('');
    });
    _sigterm.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      maybeComplete();
    });

    // Wait for the log reader to be finished.
    final int result = await exitCompleter.future;
    await subscription.cancel();
    if (result != 0) {
      throwToolExit('Error listening to $logReader logs.');
    }

    return FlutterCommandResult.success();
  }
}
