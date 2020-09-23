// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/io.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  LogsCommand() {
    argParser.addFlag('clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.',
    );
    usesDeviceTimeoutOption();
  }

  @override
  final String name = 'logs';

  @override
  final String description = 'Show log output for running Flutter apps.';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  Device device;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String commandPath) async {
    device = await findTargetDevice();
    if (device == null) {
      throwToolExit(null);
    }
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (boolArg('clear')) {
      device.clearLogs();
    }

    final DeviceLogReader logReader = await device.getLogReader();

    globals.printStatus('Showing $logReader logs:');

    final Completer<int> exitCompleter = Completer<int>();

    // Start reading.
    final StreamSubscription<String> subscription = logReader.logLines.listen(
      (String message) => globals.printStatus(message, wrap: false),
      onDone: () {
        exitCompleter.complete(0);
      },
      onError: (dynamic error) {
        exitCompleter.complete(error is int ? error : 1);
      },
    );

    // When terminating, close down the log reader.
    ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      globals.printStatus('');
      exitCompleter.complete(0);
    });
    ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      exitCompleter.complete(0);
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
