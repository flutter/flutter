// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON, JsonEncoder;

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

const String _kDefaultDirectory = 'build';
final JsonEncoder _prettyEncoder = new JsonEncoder.withIndent('  ');

/// The maximum amount of time considered safe to spend for a frame's build
/// phase. Anything past that is in the danger of missing the frame as 60FPS.
const Duration kBuildBudget = const Duration(milliseconds: 8);

/// Extracts statistics from the event loop timeline.
TimelineSummary summarizeTimeline(Map<String, dynamic> timeline) {
  return new TimelineSummary(timeline);
}

class TimelineSummary {
  TimelineSummary(this._timeline);

  final Map<String, dynamic> _timeline;

  /// Average amount of time spent per frame in the framework building widgets,
  /// updating layout, painting and compositing.
  double computeAverageFrameBuildTimeMillis() {
    int totalBuildTimeMicros = 0;
    int frameCount = 0;

    for (TimedEvent event in _extractBeginFrameEvents()) {
      frameCount++;
      totalBuildTimeMicros += event.duration.inMicroseconds;
    }

    return frameCount > 0
      ? (totalBuildTimeMicros / frameCount) / 1000
      : null;
  }

  /// The total number of frames recorded in the timeline.
  int countFrames() => _extractBeginFrameEvents().length;

  /// The number of frames that missed the [frameBuildBudget] and therefore are
  /// in the danger of missing frames.
  ///
  /// See [kBuildBudget].
  int computeMissedFrameBuildBudgetCount([Duration frameBuildBudget = kBuildBudget]) => _extractBeginFrameEvents()
    .where((TimedEvent event) => event.duration > kBuildBudget)
    .length;

  /// Encodes this summary as JSON.
  Map<String, dynamic> get summaryJson {
    return <String, dynamic> {
      'average_frame_build_time_millis': computeAverageFrameBuildTimeMillis(),
      'missed_frame_build_budget_count': computeMissedFrameBuildBudgetCount(),
      'frame_count': countFrames(),
    };
  }

  /// Writes all of the recorded timeline data to a file.
  Future<Null> writeTimelineToFile(String traceName,
      {String destinationDirectory: _kDefaultDirectory, bool pretty: false}) async {
    await fs.directory(destinationDirectory).create(recursive: true);
    File file = fs.file(path.join(destinationDirectory, '$traceName.timeline.json'));
    await file.writeAsString(_encodeJson(_timeline, pretty));
  }

  /// Writes [summaryJson] to a file.
  Future<Null> writeSummaryToFile(String traceName,
      {String destinationDirectory: _kDefaultDirectory, bool pretty: false}) async {
    await fs.directory(destinationDirectory).create(recursive: true);
    File file = fs.file(path.join(destinationDirectory, '$traceName.timeline_summary.json'));
    await file.writeAsString(_encodeJson(summaryJson, pretty));
  }

  String _encodeJson(dynamic json, bool pretty) {
    return pretty
      ? _prettyEncoder.convert(json)
      : JSON.encode(json);
  }

  List<Map<String, dynamic>> get _traceEvents => _timeline['traceEvents'];

  List<Map<String, dynamic>> _extractNamedEvents(String name) {
    return _traceEvents
      .where((Map<String, dynamic> event) => event['name'] == name)
      .toList();
  }

  /// Extracts timed events that are reported as a pair of begin/end events.
  List<TimedEvent> _extractTimedBeginEndEvents(String name) {
    List<TimedEvent> result = <TimedEvent>[];

    // Timeline does not guarantee that the first event is the "begin" event.
    Iterator<Map<String, dynamic>> events = _extractNamedEvents(name)
        .skipWhile((Map<String, dynamic> evt) => evt['ph'] != 'B').iterator;
    while(events.moveNext()) {
      Map<String, dynamic> beginEvent = events.current;
      if (events.moveNext()) {
        Map<String, dynamic> endEvent = events.current;
        result.add(new TimedEvent(beginEvent['ts'], endEvent['ts']));
      }
    }

    return result;
  }

  List<TimedEvent> _extractBeginFrameEvents() => _extractTimedBeginEndEvents('Engine::BeginFrame');
}

/// Timing information about an event that happened in the event loop.
class TimedEvent {
  /// The timestamp when the event began.
  final int beginTimeMicros;

  /// The timestamp when the event ended.
  final int endTimeMicros;

  /// The duration of the event.
  final Duration duration;

  TimedEvent(int beginTimeMicros, int endTimeMicros)
    : this.beginTimeMicros = beginTimeMicros,
      this.endTimeMicros = endTimeMicros,
      this.duration = new Duration(microseconds: endTimeMicros - beginTimeMicros);
}
