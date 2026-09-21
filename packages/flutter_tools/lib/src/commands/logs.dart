// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_device.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

/// Show log output for running Flutter apps.
class LogsCommand extends FlutterCommand {
  /// Creates a new [LogsCommand].
  ///
  /// If [toolContext] is omitted, ambient fallbacks from [globals] will be used.
  LogsCommand({
    ApplicationPackageFactory? applicationPackageFactory,
    ProcessSignal? sigint,
    ProcessSignal? sigterm,
    super.toolContext,
  }) : _sigint = sigint ?? ProcessSignal.sigint,
       _sigterm = sigterm ?? ProcessSignal.sigterm {
    applicationPackages = applicationPackageFactory;
    argParser.addFlag(
      'clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.',
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
    usesAdbLogFilteringOption(hide: false);
  }

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
    final Logger logger = toolContext?.logger ?? globals.logger;
    final Device cachedDevice = device!;
    if (boolArg('clear')) {
      cachedDevice.clearLogs();
    }

    final ApplicationPackage? app = await applicationPackages?.getPackageForPlatform(
      await cachedDevice.targetPlatform,
    );

    final bool filtering =
        argParser.options.containsKey('adb-log-filtering') && boolArg('adb-log-filtering');
    final DeviceLogReader logReader;
    if (cachedDevice is AndroidDevice) {
      logReader = await cachedDevice.getLogReader(app: app, adbLogFiltering: filtering);
    } else {
      logReader = await cachedDevice.getLogReader(app: app);
    }

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
