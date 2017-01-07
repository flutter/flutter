// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import '../vmservice.dart';
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
  Future<Null> verifyThenRunCommand() async {
    commandValidator();
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async {
    int observatoryPort = int.parse(argResults['debug-port']);

    // TODO(danrubel): this will break if we move to the new observatory URL
    // See https://github.com/flutter/flutter/issues/7038
    Uri observatoryUri = Uri.parse('http://127.0.0.1:$observatoryPort');

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
    Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline();
    File localFile;

    if (argResults['out'] != null) {
      localFile = fs.file(argResults['out']);
    } else {
      localFile = getUniqueFile(fs.currentDirectory, 'trace', 'json');
    }

    await localFile.writeAsString(JSON.encode(timeline));

    printStatus('Trace file saved to ${localFile.path}');
  }
}

class Tracing {
  Tracing(this.vmService);

  static Future<Tracing> connect(Uri uri) {
    return VMService.connect(uri).then((VMService observatory) => new Tracing(observatory));
  }

  final VMService vmService;

  Future<Null> startTracing() async {
    await vmService.vm.setVMTimelineFlags(<String>['Compiler', 'Dart', 'Embedder', 'GC']);
    await vmService.vm.clearVMTimeline();
  }

  /// Stops tracing; optionally wait for first frame.
  Future<Map<String, dynamic>> stopTracingAndDownloadTimeline({
    bool waitForFirstFrame: false
  }) async {
    Map<String, dynamic> timeline;

    if (!waitForFirstFrame) {
      // Stop tracing immediately and get the timeline
      await vmService.vm.setVMTimelineFlags(<String>[]);
      timeline = await vmService.vm.getVMTimeline();
    } else {
      Completer<Null> whenFirstFrameRendered = new Completer<Null>();

      vmService.onTimelineEvent.listen((ServiceEvent timelineEvent) {
        List<Map<String, dynamic>> events = timelineEvent.timelineEvents;
        for (Map<String, dynamic> event in events) {
          if (event['name'] == kFirstUsefulFrameEventName)
            whenFirstFrameRendered.complete();
        }
      });

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

      timeline = await vmService.vm.getVMTimeline();

      await vmService.vm.setVMTimelineFlags(<String>[]);
    }

    return timeline;
  }
}

/// Download the startup trace information from the given observatory client and
/// store it to build/start_up_info.json.
Future<Null> downloadStartupTrace(VMService observatory) async {
  String traceInfoFilePath = path.join(getBuildDirectory(), 'start_up_info.json');
  File traceInfoFile = fs.file(traceInfoFilePath);

  // Delete old startup data, if any.
  if (await traceInfoFile.exists())
    await traceInfoFile.delete();

  // Create "build" directory, if missing.
  if (!(await traceInfoFile.parent.exists()))
    await traceInfoFile.parent.create();

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
    throw 'Engine start event is missing in the timeline. Cannot compute startup time.';
  }

  if (firstFrameTimestampMicros == null) {
    throw 'First frame event is missing in the timeline. Cannot compute startup time.';
  }

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
