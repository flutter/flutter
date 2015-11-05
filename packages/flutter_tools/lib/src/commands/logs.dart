// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../device.dart';
import 'flutter_command.dart';

final Logger _logging = new Logger('sky_tools.logs');

class LogsCommand extends FlutterCommand {
  final String name = 'logs';
  final String description = 'Show logs for running Sky apps.';

  LogsCommand() {
    argParser.addFlag('clear',
        negatable: false,
        help: 'Clear log history before reading from logs (Android only).');
  }

  @override
  Future<int> runInProject() async {
    connectToDevices();

    bool clear = argResults['clear'];

    Iterable<Future<int>> results = devices.all.map(
        (Device device) => device.logs(clear: clear));

    for (Future<int> result in results)
      await result;

    return 0;
  }
}
