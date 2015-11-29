// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../device.dart';
import '../runner/flutter_command.dart';

class LogsCommand extends FlutterCommand {
  final String name = 'logs';
  final String description = 'Show logs for running Sky apps.';

  LogsCommand() {
    argParser.addFlag('clear',
        negatable: false,
        abbr: 'c',
        help: 'Clear log history before reading from logs (Android only).');
  }

  bool get requiresProjectRoot => false;

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
