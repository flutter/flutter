// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  LogsCommand() {
    argParser.addFlag('clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.'
    );
  }

  @override
  final String name = 'logs';

  @override
  final String description = 'Show log output for running Flutter apps.';

  Device device;

  @override
  Future<int> verifyThenRunCommand() async {
    device = await findTargetDevice();
    if (device == null)
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    if (argResults['clear'])
      device.clearLogs();

    DeviceLogReader logReader = device.logReader;

    Cache.releaseLockEarly();

    printStatus('Showing $logReader logs:');

    Completer<int> exitCompleter = new Completer<int>();

    // Start reading.
    StreamSubscription<String> subscription = logReader.logLines.listen(
      printStatus,
      onDone: () {
        exitCompleter.complete(0);
      },
      onError: (dynamic error) {
        exitCompleter.complete(error is int ? error : 1);
      }
    );

    // When terminating, close down the log reader.
    ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      printStatus('');
      exitCompleter.complete(0);
    });
    ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) {
      subscription.cancel();
      exitCompleter.complete(0);
    });

    // Wait for the log reader to be finished.
    int result = await exitCompleter.future;
    subscription.cancel();
    if (result != 0)
      printError('Error listening to $logReader logs.');
    return result;
  }
}
