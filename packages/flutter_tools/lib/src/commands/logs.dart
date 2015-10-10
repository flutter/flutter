// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.logs;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../device.dart';

final Logger _logging = new Logger('sky_tools.logs');

class LogsCommand extends Command {
  final name = 'logs';
  final description = 'Show logs for running Sky apps.';
  AndroidDevice android;
  IOSDevice ios;

  LogsCommand({this.android, this.ios}) {
    argParser.addFlag('clear',
        negatable: false,
        help: 'Clear log history before reading from logs (Android only).');
  }

  @override
  Future<int> run() async {
    if (android == null) {
      android = new AndroidDevice();
    }
    if (ios == null) {
      ios = new IOSDevice();
    }

    Future<int> androidLogProcess = null;
    if (android.isConnected()) {
      androidLogProcess = android.logs(clear: argResults['clear']);
    }

    Future<int> iosLogProcess = null;
    if (ios.isConnected()) {
      iosLogProcess = ios.logs(clear: argResults['clear']);
    }

    if (androidLogProcess != null) {
      await androidLogProcess;
    }

    if (iosLogProcess != null) {
      await iosLogProcess;
    }

    return 0;
  }
}
