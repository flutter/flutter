// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../tracing.dart';

class TraceCommand extends FlutterCommand {
  TraceCommand() {
    requiresPubspecYaml();
    argParser.addFlag('start', negatable: false, help: 'Start tracing.');
    argParser.addFlag('stop', negatable: false, help: 'Stop tracing.');
    argParser.addOption('out', help: 'Specify the path of the saved trace file.');
    argParser.addOption('duration',
        defaultsTo: '10', abbr: 'd', help: 'Duration in seconds to trace.');
    argParser.addOption('debug-port',
        defaultsTo: kDefaultObservatoryPort.toString(),
        help: 'Local port where the observatory is listening.');
  }

  @override
  final String name = 'trace';

  @override
  final String description = 'Start and stop tracing for a running Flutter app.';

  @override
  final String usageFooter =
    '\`trace\` called with no arguments will automatically start tracing, delay a set amount of\n'
    'time (controlled by --duration), and stop tracing. To explicitly control tracing, call trace\n'
    'with --start and later with --stop.';

  @override
  Future<Null> runCommand() async {
    final int observatoryPort = int.parse(argResults['debug-port']);

    // TODO(danrubel): this will break if we move to the new observatory URL
    // See https://github.com/flutter/flutter/issues/7038
    final Uri observatoryUri = Uri.parse('http://127.0.0.1:$observatoryPort');

    Tracing tracing;

    try {
      tracing = await Tracing.connect(observatoryUri);
    } catch (error) {
      throwToolExit('Error connecting to observatory: $error');
    }

    Cache.releaseLockEarly();

    if ((!argResults['start'] && !argResults['stop']) ||
        (argResults['start'] && argResults['stop'])) {
      // Setting neither flags or both flags means do both commands and wait
      // duration seconds in between.
      await tracing.startTracing();
      await new Future<Null>.delayed(
        new Duration(seconds: int.parse(argResults['duration'])),
        () => _stopTracing(tracing)
      );
    } else if (argResults['stop']) {
      await _stopTracing(tracing);
    } else {
      await tracing.startTracing();
    }
  }

  Future<Null> _stopTracing(Tracing tracing) async {
    final Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline();
    File localFile;

    if (argResults['out'] != null) {
      localFile = fs.file(argResults['out']);
    } else {
      localFile = getUniqueFile(fs.currentDirectory, 'trace', 'json');
    }

    await localFile.writeAsString(json.encode(timeline));

    printStatus('Trace file saved to ${localFile.path}');
  }
}
