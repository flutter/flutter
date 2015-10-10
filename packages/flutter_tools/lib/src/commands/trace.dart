// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.trace;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../application_package.dart';
import '../device.dart';

final Logger _logging = new Logger('sky_tools.trace');

class TraceCommand extends Command {
  final name = 'trace';
  final description = 'Start and stop tracing a running Flutter app '
      '(Android only, requires root).\n'
      'To start a trace, wait, and then stop the trace, don\'t set any flags '
      'except (optionally) duration.\n'
      'Otherwise, specify either start or stop to manually control the trace.';
  AndroidDevice android = null;

  TraceCommand([this.android]) {
    argParser.addFlag('start', negatable: false, help: 'Start tracing.');
    argParser.addFlag('stop', negatable: false, help: 'Stop tracing.');
    argParser.addOption('duration',
        defaultsTo: '10', abbr: 'd', help: 'Duration in seconds to trace.');
  }

  @override
  Future<int> run() async {
    if (android == null) {
      android = new AndroidDevice();
    }

    if (!android.isConnected()) {
      _logging.warning('No device connected, so no trace was completed.');
      return 1;
    }
    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];

    if ((!argResults['start'] && !argResults['stop']) ||
        (argResults['start'] && argResults['stop'])) {
      // Setting neither flags or both flags means do both commands and wait
      // duration seconds in between.
      android.startTracing(androidApp);
      await new Future.delayed(
          new Duration(seconds: int.parse(argResults['duration'])),
          () => _stopTracing(androidApp));
    } else if (argResults['stop']) {
      _stopTracing(androidApp);
    } else {
      android.startTracing(androidApp);
    }
    return 0;
  }

  void _stopTracing(AndroidApk androidApp) {
    String tracePath = android.stopTracing(androidApp);
    if (tracePath == null) {
      _logging.warning('No trace file saved.');
    } else {
      print('Trace file saved to $tracePath');
    }
  }
}
