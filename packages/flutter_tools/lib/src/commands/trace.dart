// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../base/common.dart';
import '../base/utils.dart';
import '../globals.dart';
import '../observatory.dart';
import '../runner/flutter_command.dart';

// Names of some of the Timeline events we care about.
const String kFlutterEngineMainEnterEventName = 'FlutterEngineMainEnter';
const String kFrameworkInitEventName = 'Framework initialization';
const String kFirstUsefulFrameEventName = 'Widgets completed first useful frame';

class TraceCommand extends FlutterCommand {
  TraceCommand() {
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
  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    int observatoryPort = int.parse(argResults['debug-port']);

    Tracing tracing;

    try {
      tracing = await Tracing.connect(observatoryPort);
    } catch (error) {
      printError('Error connecting to observatory: $error');
      return 1;
    }

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

    return 0;
  }

  Future<Null> _stopTracing(Tracing tracing) async {
    Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline();
    File localFile;

    if (argResults['out'] != null) {
      localFile = new File(argResults['out']);
    } else {
      localFile = getUniqueFile(Directory.current, 'trace', 'json');
    }

    await localFile.writeAsString(JSON.encode(timeline));

    printStatus('Trace file saved to ${localFile.path}');
  }
}

class Tracing {
  Tracing(this.observatory);

  static Future<Tracing> connect(int port) {
    return Observatory.connect(port).then((Observatory observatory) => new Tracing(observatory));
  }

  final Observatory observatory;

  Future<Null> startTracing() async {
    await observatory.setVMTimelineFlags(<String>['Compiler', 'Dart', 'Embedder', 'GC']);
    await observatory.clearVMTimeline();
  }

  /// Stops tracing; optionally wait for first frame.
  Future<Map<String, dynamic>> stopTracingAndDownloadTimeline({
    bool waitForFirstFrame: false
  }) async {
    Response timeline;

    if (!waitForFirstFrame) {
      // Stop tracing immediately and get the timeline
      await observatory.setVMTimelineFlags(<String>[]);
      timeline = await observatory.getVMTimeline();
    } else {
      Completer<Null> whenFirstFrameRendered = new Completer<Null>();

      observatory.onTimelineEvent.listen((Event timelineEvent) {
        List<Map<String, dynamic>> events = timelineEvent['timelineEvents'];
        for (Map<String, dynamic> event in events) {
          if (event['name'] == kFirstUsefulFrameEventName)
            whenFirstFrameRendered.complete();
        }
      });
      await observatory.streamListen('Timeline');

      await whenFirstFrameRendered.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          printError(
            'Timed out waiting for the first frame event. Either the '
            'application failed to start, or the event was missed because '
            '"flutter run" took too long to subscribe to timeline events.'
          );
          return null;
        }
      );

      timeline = await observatory.getVMTimeline();

      await observatory.setVMTimelineFlags(<String>[]);
    }

    return timeline.response;
  }
}

/// Download the startup trace information from the given observatory client and
/// store it to build/start_up_info.json.
Future<Null> downloadStartupTrace(Observatory observatory) async {
  Tracing tracing = new Tracing(observatory);

  Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline(
    waitForFirstFrame: true
  );

  int extractInstantEventTimestamp(String eventName) {
    List<Map<String, dynamic>> events = timeline['traceEvents'];
    Map<String, dynamic> event = events.firstWhere(
      (Map<String, dynamic> event) => event['name'] == eventName, orElse: () => null
    );
    return event == null ? null : event['ts'];
  }

  int engineEnterTimestampMicros = extractInstantEventTimestamp(kFlutterEngineMainEnterEventName);
  int frameworkInitTimestampMicros = extractInstantEventTimestamp(kFrameworkInitEventName);
  int firstFrameTimestampMicros = extractInstantEventTimestamp(kFirstUsefulFrameEventName);

  if (engineEnterTimestampMicros == null) {
    printError('Engine start event is missing in the timeline. Cannot compute startup time.');
    return null;
  }

  if (firstFrameTimestampMicros == null) {
    printError('First frame event is missing in the timeline. Cannot compute startup time.');
    return null;
  }

  File traceInfoFile = new File('build/start_up_info.json');
  int timeToFirstFrameMicros = firstFrameTimestampMicros - engineEnterTimestampMicros;
  Map<String, dynamic> traceInfo = <String, dynamic>{
    'engineEnterTimestampMicros': engineEnterTimestampMicros,
    'timeToFirstFrameMicros': timeToFirstFrameMicros,
  };

  if (frameworkInitTimestampMicros != null) {
    traceInfo['timeToFrameworkInitMicros'] = frameworkInitTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeAfterFrameworkInitMicros'] = firstFrameTimestampMicros - frameworkInitTimestampMicros;
  }

  traceInfoFile.writeAsStringSync(toPrettyJson(traceInfo));

  printStatus('Time to first frame: ${timeToFirstFrameMicros ~/ 1000}ms.');
  printStatus('Saved startup trace info in ${traceInfoFile.path}.');
}
