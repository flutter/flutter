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
const String kFlutterEngineMainEnterEventName = 'FlutterEngineMainEnter';
const String kFrameworkInitEventName = 'Framework initialization';
const String kFirstFrameBuiltEventName = 'Widgets built first useful frame';
const String kFirstFrameRasterizedEventName = 'Rasterized first useful frame';

class Tracing {
  Tracing(this.vmService);

  static const String firstUsefulFrameEventName = kFirstFrameRasterizedEventName;

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
        (await vmService.onExtensionEvent).listen((ServiceEvent event) {
          if (event.extensionKind == 'Flutter.FirstFrame') {
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
  if (traceInfoFile.existsSync()) {
    traceInfoFile.deleteSync();
  }

  // Create "build" directory, if missing.
  if (!traceInfoFile.parent.existsSync()) {
    traceInfoFile.parent.createSync();
  }

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

  final int engineEnterTimestampMicros = extractInstantEventTimestamp(kFlutterEngineMainEnterEventName);
  final int frameworkInitTimestampMicros = extractInstantEventTimestamp(kFrameworkInitEventName);

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
    final int firstFrameBuiltTimestampMicros = extractInstantEventTimestamp(kFirstFrameBuiltEventName);
    final int firstFrameRasterizedTimestampMicros = extractInstantEventTimestamp(kFirstFrameRasterizedEventName);
    if (firstFrameBuiltTimestampMicros == null || firstFrameRasterizedTimestampMicros == null) {
      printTrace('First frame events are missing in the timeline: $timeline');
      throw 'First frame events are missing in the timeline. Cannot compute startup time.';
    }

    // To keep our old benchmarks valid, we'll preserve the
    // timeToFirstFrameMicros as the firstFrameBuiltTimestampMicros.
    // Additionally, we add timeToFirstFrameRasterizedMicros for a more accurate
    // benchmark.
    traceInfo['timeToFirstFrameRasterizedMicros'] = firstFrameRasterizedTimestampMicros - engineEnterTimestampMicros;
    final int timeToFirstFrameMicros = firstFrameBuiltTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeToFirstFrameMicros'] = timeToFirstFrameMicros;
    message = 'Time to first frame: ${timeToFirstFrameMicros ~/ 1000}ms.';
    if (frameworkInitTimestampMicros != null)
      traceInfo['timeAfterFrameworkInitMicros'] = firstFrameBuiltTimestampMicros - frameworkInitTimestampMicros;
  }

  traceInfoFile.writeAsStringSync(toPrettyJson(traceInfo));

  printStatus(message);
  printStatus('Saved startup trace info in ${traceInfoFile.path}.');
}
