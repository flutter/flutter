// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

enum EventRecorderMode {
  stop,
  record
}

typedef void EventsReady(List<PointerInputEvent> events);

class EventRecorder extends StatefulComponent {
  EventRecorder({
    Key key,
    this.child,
    this.mode: EventRecorderMode.stop,
    this.onEventsReady
  });

  final Widget child;
  final EventRecorderMode mode;
  final EventsReady onEventsReady;

  _EventRecorderState createState() => new _EventRecorderState();
}

class _EventRecorderState extends State<EventRecorder> {

  EventRecorderMode _mode;
  List<PointerInputEvent> _events = new List<PointerInputEvent>();

  void initState() {
    super.initState();
    _mode = config.mode;
  }

  void didUpdateConfig(EventRecorder oldConfig) {
    if (_mode == EventRecorderMode.record &&
        config.mode == EventRecorderMode.stop) {
      config.onEventsReady(_events);
      _events.clear();
    }
    _mode = config.mode;
  }

  void _recordEvent(PointerInputEvent event) {
    if (_mode == EventRecorderMode.record) {
      _events.add(event);
    }
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
