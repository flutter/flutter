// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_device.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class TraceCommand extends FlutterCommand {
  TraceCommand() {
    argParser.addFlag('start', negatable: false, help: 'Start tracing.');
    argParser.addFlag('stop', negatable: false, help: 'Stop tracing.');
    argParser.addOption('out', help: 'Specify the path of the saved trace file.');
    argParser.addOption('duration',
        defaultsTo: '10', abbr: 'd', help: 'Duration in seconds to trace.');
    argParser.addOption('debug-port',
        defaultsTo: defaultObservatoryPort.toString(),
        help: 'Local port where the observatory is listening.');
  }

  @override
  final String name = 'trace';

  @override
  final String description = 'Start and stop tracing for a running Flutter app (Android only).';

  @override
  final String usageFooter =
    '\`trace\` called with no arguments will automatically start tracing, delay a set amount of\n'
    'time (controlled by --duration), and stop tracing. To explicitly control tracing, call trace\n'
    'with --start and later with --stop.';

  @override
  bool get androidOnly => true;

  @override
  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    ApplicationPackage androidApp = applicationPackages.android;
    AndroidDevice device = deviceForCommand;
    int observatoryPort = int.parse(argResults['debug-port']);

    if ((!argResults['start'] && !argResults['stop']) ||
        (argResults['start'] && argResults['stop'])) {
      // Setting neither flags or both flags means do both commands and wait
      // duration seconds in between.
      await device.startTracing(androidApp, observatoryPort);
      await new Future<Null>.delayed(
        new Duration(seconds: int.parse(argResults['duration'])),
        () => _stopTracing(device, androidApp, observatoryPort)
      );
    } else if (argResults['stop']) {
      await _stopTracing(device, androidApp, observatoryPort);
    } else {
      await device.startTracing(androidApp, observatoryPort);
    }
    return 0;
  }

  Future<Null> _stopTracing(AndroidDevice android, AndroidApk androidApp, int observatoryPort) async {
    String tracePath = await android.stopTracing(androidApp, observatoryPort, argResults['out']);
    if (tracePath == null) {
      printError('No trace file saved.');
    } else {
      printStatus('Trace file saved to $tracePath');
    }
  }
}
