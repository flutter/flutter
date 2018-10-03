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
    argParser.addOption('debug-port',
      help: 'Local port where the observatory is listening. Required.',
    );
    argParser.addFlag('start', negatable: false, help: 'Start tracing. Implied if --stop is also omitted.');
    argParser.addFlag('stop', negatable: false, help: 'Stop tracing. Implied if --start is also omitted.');
    argParser.addOption('duration',
      abbr: 'd',
      help: 'Time to wait after starting (if --start is specified or implied) and before '
            'stopping (if --stop is specified or implied).\n'
            'Defaults to ten seconds if --stop is specified or implied, zero otherwise.',
    );
    argParser.addOption('out', help: 'Specify the path of the saved trace file.');
  }

  @override
  final String name = 'trace';

  @override
  final String description = 'Start and stop tracing for a running Flutter app.';

  @override
  final String usageFooter =
    '\`trace\` called without the --start or --stop flags will automatically start tracing, '
    'delay a set amount of time (controlled by --duration), and stop tracing. To explicitly '
    'control tracing, call trace with --start and later with --stop.\n'
    'The --debug-port argument is required.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    int observatoryPort;
    if (argResults.wasParsed('debug-port')) {
      observatoryPort = int.tryParse(argResults['debug-port']);
    }
    if (observatoryPort == null) {
      throwToolExit('The --debug-port argument must be specified.');
    }

    bool start = argResults['start'];
    bool stop = argResults['stop'];
    if (!start && !stop) {
      start = true;
      stop = true;
    }
    assert(start || stop);

    Duration duration;
    if (argResults.wasParsed('duration')) {
      try {
        duration = Duration(seconds: int.parse(argResults['duration']));
      } on FormatException {
        throwToolExit('Invalid duration passed to --duration; it should be a positive number of seconds.');
      }
    } else {
      duration = stop ? const Duration(seconds: 10) : Duration.zero;
    }

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

    if (start)
      await tracing.startTracing();
    await Future<void>.delayed(duration);
    if (stop)
      await _stopTracing(tracing);

    return null;
  }

  Future<void> _stopTracing(Tracing tracing) async {
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
