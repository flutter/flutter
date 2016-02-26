// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_device.dart';
import '../application_package.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class TraceCommand extends FlutterCommand {
  final String name = 'trace';
  final String description = 'Start and stop tracing for a running Flutter app (Android only).';
  final String usageFooter =
    '\`trace\` called with no arguments will automatically start tracing, delay a set amount of\n'
    'time (controlled by --duration), and stop tracing. To explicitly control tracing, call trace\n'
    'with --start and later with --stop.';

  TraceCommand() {
    argParser.addFlag('start', negatable: false, help: 'Start tracing.');
    argParser.addFlag('stop', negatable: false, help: 'Stop tracing.');
    argParser.addOption('out', help: 'Specify the path of the saved trace file.');
    argParser.addOption('duration',
        defaultsTo: '10', abbr: 'd', help: 'Duration in seconds to trace.');
  }

  bool get androidOnly => true;

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackagesAndConnectToDevices();

    if (devices.android == null) {
      printError('No device connected, so no trace was completed.');
      return 1;
    }

    ApplicationPackage androidApp = applicationPackages.android;

    if ((!argResults['start'] && !argResults['stop']) ||
        (argResults['start'] && argResults['stop'])) {
      // Setting neither flags or both flags means do both commands and wait
      // duration seconds in between.
      devices.android.startTracing(androidApp);
      await new Future.delayed(
          new Duration(seconds: int.parse(argResults['duration'])),
          () => _stopTracing(devices.android, androidApp)
      );
    } else if (argResults['stop']) {
      await _stopTracing(devices.android, androidApp);
    } else {
      devices.android.startTracing(androidApp);
    }
    return 0;
  }

  Future _stopTracing(AndroidDevice android, AndroidApk androidApp) async {
    String tracePath = await android.stopTracing(androidApp, outPath: argResults['out']);
    if (tracePath == null) {
      printError('No trace file saved.');
    } else {
      printStatus('Trace file saved to $tracePath');
    }
  }
}
