// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';

enum EventRecorderMode {
  stop,
  record
}

typedef void EventsReadyCallback(Iterable<PointerEvent> events);

/// EventRecorder is a utility widget that allows input events occurring
/// on the child to be recorded. The widget is initially in the "stop" state
/// by default. When in the "record" state, all pointer input events
/// occurring on the child are recorded into a buffer. When the "stop" state
/// is entered again, the onEventsReady callback is invoked with a list of
/// the recorded events.
class EventRecorder extends StatefulComponent {
  EventRecorder({
    Key key,
    this.child,
    this.mode: EventRecorderMode.stop,
    this.onEventsReady
  });

  final Widget child;
  final EventRecorderMode mode;
  final EventsReadyCallback onEventsReady;

  _EventRecorderState createState() => new _EventRecorderState();
}

class _EventRecorderState extends State<EventRecorder> {

  final List<PointerEvent> _events = <PointerEvent>[];

  void didUpdateConfig(EventRecorder oldConfig) {
    if (oldConfig.mode == EventRecorderMode.record &&
        config.mode == EventRecorderMode.stop) {
      config.onEventsReady(_events);
      _events.clear();
    }
  }

  void _recordEvent(PointerEvent event) {
    if (config.mode == EventRecorderMode.record)
      _events.add(event);
  }

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _recordEvent,
      onPointerMove: _recordEvent,
      onPointerUp: _recordEvent,
      onPointerCancel: _recordEvent,
      child: config.child
    );
  }

}
