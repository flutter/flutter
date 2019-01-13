// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Timeline data recorded by the Flutter runtime.
class Timeline {
  /// Creates a timeline given JSON-encoded timeline data.
  ///
  /// [json] is in the `chrome://tracing` format. It can be saved to a file
  /// and loaded in Chrome for visual inspection.
  ///
  /// See https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/preview
  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline._(json, _parseEvents(json));
  }

  Timeline._(this.json, this.events);

  /// The original timeline JSON.
  final Map<String, dynamic> json;

  /// List of all timeline events.
  final List<TimelineEvent> events;
}

/// A single timeline event.
class TimelineEvent {
  /// Creates a timeline event given JSON-encoded event data.
  factory TimelineEvent(Map<String, dynamic> json) {
    return TimelineEvent._(
      json,
      json['name'],
      json['cat'],
      json['ph'],
      json['pid'],
      json['tid'],
      json['dur'] != null
        ? Duration(microseconds: json['dur'])
        : null,
      json['tdur'] != null
        ? Duration(microseconds: json['tdur'])
        : null,
      json['ts'],
      json['tts'],
      json['args']
    );
  }

  TimelineEvent._(
    this.json,
    this.name,
    this.category,
    this.phase,
    this.processId,
    this.threadId,
    this.duration,
    this.threadDuration,
    this.timestampMicros,
    this.threadTimestampMicros,
    this.arguments
  );

  /// The original event JSON.
  final Map<String, dynamic> json;

  /// The name of the event.
  ///
  /// Corresponds to the "name" field in the JSON event.
  final String name;

  /// Event category. Events with different names may share the same category.
  ///
  /// Corresponds to the "cat" field in the JSON event.
  final String category;

  /// For a given long lasting event, denotes the phase of the event, such as
  /// "B" for "event began", and "E" for "event ended".
  ///
  /// Corresponds to the "ph" field in the JSON event.
  final String phase;

  /// ID of process that emitted the event.
  ///
  /// Corresponds to the "pid" field in the JSON event.
  final int processId;

  /// ID of thread that issues the event.
  ///
  /// Corresponds to the "tid" field in the JSON event.
  final int threadId;

  /// The duration of the event.
  ///
  /// Note, some events are reported with duration. Others are reported as a
  /// pair of begin/end events.
  ///
  /// Corresponds to the "dur" field in the JSON event.
  final Duration duration;

  /// The thread duration of the event.
  ///
  /// Note, some events are reported with duration. Others are reported as a
  /// pair of begin/end events.
  ///
  /// Corresponds to the "tdur" field in the JSON event.
  final Duration threadDuration;

  /// Time passed since tracing was enabled, in microseconds.
  ///
  /// Corresponds to the "ts" field in the JSON event.
  final int timestampMicros;

  /// Thread clock time, in microseconds.
  ///
  /// Corresponds to the "tts" field in the JSON event.
  final int threadTimestampMicros;

  /// Arbitrary data attached to the event.
  ///
  /// Corresponds to the "args" field in the JSON event.
  final Map<String, dynamic> arguments;
}

List<TimelineEvent> _parseEvents(Map<String, dynamic> json) {
  final List<dynamic> jsonEvents = json['traceEvents'];

  if (jsonEvents == null)
    return null;

  // TODO(vegorov): use instance method version of castFrom when it is available.
  return Iterable.castFrom<dynamic, Map<String, dynamic>>(jsonEvents)
    .map<TimelineEvent>((Map<String, dynamic> eventJson) => TimelineEvent(eventJson))
    .toList();
}
