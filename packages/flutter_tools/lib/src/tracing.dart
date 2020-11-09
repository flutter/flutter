// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';

import 'vmservice.dart';

// Names of some of the Timeline events we care about.
const String kFlutterEngineMainEnterEventName = 'FlutterEngineMainEnter';
const String kFrameworkInitEventName = 'Framework initialization';
const String kFirstFrameBuiltEventName = 'Widgets built first useful frame';
const String kFirstFrameRasterizedEventName = 'Rasterized first useful frame';

class Tracing {
  Tracing({
    @required this.vmService,
    @required Logger logger,
  }) : _logger = logger;

  static const String firstUsefulFrameEventName = kFirstFrameRasterizedEventName;

  final vm_service.VmService vmService;
  final Logger _logger;

  Future<void> startTracing() async {
    await vmService.setVMTimelineFlags(<String>['Compiler', 'Dart', 'Embedder', 'GC']);
    await vmService.clearVMTimeline();
  }

  /// Stops tracing; optionally wait for first frame.
  Future<Map<String, dynamic>> stopTracingAndDownloadTimeline({
    bool awaitFirstFrame = false,
  }) async {
    if (awaitFirstFrame) {
      final Status status = _logger.startProgress(
        'Waiting for application to render first frame...',
        timeout: null,
      );
      try {
        final Completer<void> whenFirstFrameRendered = Completer<void>();
        try {
          await vmService.streamListen(vm_service.EventStreams.kExtension);
        } on vm_service.RPCError {
          // It is safe to ignore this error because we expect an error to be
          // thrown if we're already subscribed.
        }
        vmService.onExtensionEvent.listen((vm_service.Event event) {
          if (event.extensionKind == 'Flutter.FirstFrame') {
            whenFirstFrameRendered.complete();
          }
        });
        bool done = false;
        final List<FlutterView> views = await vmService.getFlutterViews();
        for (final FlutterView view in views) {
          if (await vmService
              .flutterAlreadyPaintedFirstUsefulFrame(
                isolateId: view.uiIsolate.id,
              )) {
            done = true;
            break;
          }
        }
        if (!done) {
          await whenFirstFrameRendered.future;
        }
      // The exception is rethrown, so don't catch only Exceptions.
      } catch (exception) { // ignore: avoid_catches_without_on_clauses
        status.cancel();
        rethrow;
      }
      status.stop();
    }
    final vm_service.Timeline timeline = await vmService.getVMTimeline();
    await vmService.setVMTimelineFlags(<String>[]);
    return timeline.json;
  }
}

/// Download the startup trace information from the given observatory client and
/// store it to build/start_up_info.json.
Future<void> downloadStartupTrace(vm_service.VmService vmService, {
  bool awaitFirstFrame = true,
  @required Logger logger,
  @required Directory output,
}) async {
  final File traceInfoFile = output.childFile('start_up_info.json');

  // Delete old startup data, if any.
  if (traceInfoFile.existsSync()) {
    traceInfoFile.deleteSync();
  }

  // Create "build" directory, if missing.
  if (!traceInfoFile.parent.existsSync()) {
    traceInfoFile.parent.createSync();
  }

  final Tracing tracing = Tracing(vmService: vmService, logger: logger);

  final Map<String, dynamic> timeline = await tracing.stopTracingAndDownloadTimeline(
    awaitFirstFrame: awaitFirstFrame,
  );

  int extractInstantEventTimestamp(String eventName) {
    final List<Map<String, dynamic>> events =
        List<Map<String, dynamic>>.from(timeline['traceEvents'] as List<dynamic>);
    final Map<String, dynamic> event = events.firstWhere(
      (Map<String, dynamic> event) => event['name'] == eventName, orElse: () => null,
    );
    return event == null ? null : (event['ts'] as int);
  }

  String message = 'No useful metrics were gathered.';

  final int engineEnterTimestampMicros = extractInstantEventTimestamp(kFlutterEngineMainEnterEventName);
  final int frameworkInitTimestampMicros = extractInstantEventTimestamp(kFrameworkInitEventName);

  if (engineEnterTimestampMicros == null) {
    logger.printTrace('Engine start event is missing in the timeline: $timeline');
    throwToolExit('Engine start event is missing in the timeline. Cannot compute startup time.');
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
      logger.printTrace('First frame events are missing in the timeline: $timeline');
      throwToolExit('First frame events are missing in the timeline. Cannot compute startup time.');
    }

    // To keep our old benchmarks valid, we'll preserve the
    // timeToFirstFrameMicros as the firstFrameBuiltTimestampMicros.
    // Additionally, we add timeToFirstFrameRasterizedMicros for a more accurate
    // benchmark.
    traceInfo['timeToFirstFrameRasterizedMicros'] = firstFrameRasterizedTimestampMicros - engineEnterTimestampMicros;
    final int timeToFirstFrameMicros = firstFrameBuiltTimestampMicros - engineEnterTimestampMicros;
    traceInfo['timeToFirstFrameMicros'] = timeToFirstFrameMicros;
    message = 'Time to first frame: ${timeToFirstFrameMicros ~/ 1000}ms.';
    if (frameworkInitTimestampMicros != null) {
      traceInfo['timeAfterFrameworkInitMicros'] = firstFrameBuiltTimestampMicros - frameworkInitTimestampMicros;
    }
  }

  traceInfoFile.writeAsStringSync(toPrettyJson(traceInfo));

  logger.printStatus(message);
  logger.printStatus('Saved startup trace info in ${traceInfoFile.path}.');
}
