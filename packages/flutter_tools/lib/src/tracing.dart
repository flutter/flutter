// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'globals.dart';
import 'vmservice.dart';

// Names of some of the Timeline events we care about.
const String _kFlutterEngineMainEnterEventName = 'FlutterEngineMainEnter';
const String _kFrameworkInitEventName = 'Framework initialization';
const String _kFirstUsefulFrameEventName = 'Widgets completed first useful frame';

class Tracing {
  Tracing(this.vmService);

  static const String firstUsefulFrameEventName = _kFirstUsefulFrameEventName;

  static Future<Tracing> connect(Uri uri) async {
    final VMService observatory = await VMService.connect(uri);
    return Tracing(observatory);
  }

  final VMService vmService;

  Future<void> startTracing() async {
    await vmService.vm.setVMTimelineFlags(<String>['Compiler', 'Dart', 'Embedder', 'GC']);
    await vmService.vm.clearVMTimeline();
  }

  /// Stops tracing; optionally wait for first frame.
  Future<Map<String, dynamic>> stopTracingAndDownloadTimeline({
    bool awaitFirstFrame = false,
  }) async {
    if (awaitFirstFrame) {
      final Status status = logger.startProgress(
        'Waiting for application to render first frame...',
        timeout: timeoutConfiguration.fastOperation,
      );
      try {
        final Completer<void> whenFirstFrameRendered = Completer<void>();
        (await vmService.onTimelineEvent).listen((ServiceEvent timelineEvent) {
          final List<Map<String, dynamic>> events = timelineEvent.timelineEvents;
          for (Map<String, dynamic> event in events) {
            if (event['name'] == _kFirstUsefulFrameEventName)
              whenFirstFrameRendered.complete();
          }
        });
        bool done = false;
        for (FlutterView view in vmService.vm.views) {
          if (await view.uiIsolate.flutterAlreadyPaintedFirstUsefulFrame()) {
            done = true;
            break;
          }
        }
        if (!done)
          await whenFirstFrameRendered.future;
      } catch (exception) {
        status.cancel();
        rethrow;
      }
      status.stop();
    }
    final Map<String, dynamic> timeline = await vmService.vm.getVMTimeline();
    await vmService.vm.setVMTimelineFlags(<String>[]);
    return timeline;
  }
}

/// Download the startup trace information from the given observatory client and
/// store it to build/start_up_info.json.
Future<void> downloadStartupTrace(VMService observatory, { bool awaitFirstFrame = true }) async {
  final String traceInfoFilePath = fs.path.join(getBuildDirectory(), 'start_up_info.json');
  final File traceInfoFile = fs.file(traceInfoFilePath);

  // Delete old startup data, if any.
  if (await traceInfoFile.exists())
    await traceInfoFile.delete();

  // Create "build" directory, if missing.
  if (!(await traceInfoFile.parent.exists()))
    await traceInfoFile.parent.create();

  final Tracing tracing = Tracing(observatory);

  final Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline(
    awaitFirstFrame: awaitFirstFrame,
  );

  int extractInstantEventTimestamp(String eventName) {
    final List<Map<String, dynamic>> events =
        List<Map<String, dynamic>>.from(timeline['traceEvents']);
    final Map<String, dynamic> event = events.firstWhere(
      (Map<String, dynamic> event) => event['name'] == eventName, orElse: () => null,
    );
    return event == null ? null : event['ts'];
  }

  String message = 'No useful metrics were gathered.';

  final int engineEnterTimestampMicros = extractInstantEventTimestamp(_kFlutterEngineMainEnterEventName);
  final int frameworkInitTimestampMicros = extractInstantEventTimestamp(_kFrameworkInitEventName);

  if (engineEnterTimestampMicros == null) {
    printTrace('Engine start event is missing in the timeline: $timeline');
    throw 'Engine start event is missing in the timeline. Cannot compute startup time.';
  }

  final Map<String, dynamic> traceInfo = <String, dynamic>{
    'engineEnterTimestampMicros': engineEnterTimestampMicros,
  };

  if (frameworkInitTimestampMicros != null) {
    final int timeToFrameworkInitMicros = frameworkInitTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeToFrameworkInitMicros'] = timeToFrameworkInitMicros;
    message = 'Time to framework init: ${timeToFrameworkInitMicros ~/ 1000}ms.';
  }

  if (awaitFirstFrame) {
    final int firstFrameTimestampMicros = extractInstantEventTimestamp(_kFirstUsefulFrameEventName);
    if (firstFrameTimestampMicros == null) {
      printTrace('First frame event is missing in the timeline: $timeline');
      throw 'First frame event is missing in the timeline. Cannot compute startup time.';
    }
    final int timeToFirstFrameMicros = firstFrameTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeToFirstFrameMicros'] = timeToFirstFrameMicros;
    message = 'Time to first frame: ${timeToFirstFrameMicros ~/ 1000}ms.';
    if (frameworkInitTimestampMicros != null)
      traceInfo['timeAfterFrameworkInitMicros'] = firstFrameTimestampMicros - frameworkInitTimestampMicros;
  }

  traceInfoFile.writeAsStringSync(toPrettyJson(traceInfo));

  printStatus(message);
  printStatus('Saved startup trace info in ${traceInfoFile.path}.');
}
