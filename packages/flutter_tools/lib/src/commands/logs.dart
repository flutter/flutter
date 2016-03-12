// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  final String name = 'logs';
  final String description = 'Show log output for running Flutter apps.';

  LogsCommand() {
    argParser.addFlag('clear',
      negatable: false,
      abbr: 'c',
      help: 'Clear log history before reading from logs.'
    );
  }

  bool get requiresProjectRoot => false;

  bool get requiresDevice => true;

  Future<int> runInProject() async {
    Device device = deviceForCommand;

    if (argResults['clear'])
      device.clearLogs();

    DeviceLogReader logReader = device.logReader;

    printStatus('Showing $logReader logs:');

    // Start reading.
    if (!logReader.isReading)
      await logReader.start();

    StreamSubscription<String> subscription = logReader.lines.listen(printStatus);

    // Wait for the log reader to be finished.
    int result = await logReader.finished;

    subscription.cancel();

    if (result != 0)
      printError('Error listening to $logReader logs.');
    return result;
  }
}
