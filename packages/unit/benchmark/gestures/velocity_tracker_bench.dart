import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:test/test.dart';
import 'velocity_tracker_data.dart';

const int kNumIters = 10000;
const int kBatchSize = 1000;
const int kBatchOffset = 50;
const int kNumMarks = 130;

List<PointerInputEvent> _eventFromMap(List<Map> intermediate) {
  List<PointerInputEvent> events = new List<PointerInputEvent>();
  for (Map entry in intermediate)
    events.add(_eventFor(entry));
  return events;
}

PointerInputEvent _eventFor(Map entry) {
  PointerInputEvent result = new PointerInputEvent(
    type: entry['type'],
    timeStamp: entry['timeStamp'],
    pointer: entry['pointer'],
    x: entry['x'],
    y: entry['y']
  );
  return result;
}

void main() {
  List<PointerInputEvent> events = _eventFromMap(velocityEventData);

  test('Dart velocity tracker performance', () {
    VelocityTracker tracker = new VelocityTracker();
    Stopwatch watch = new Stopwatch();
    watch.start();
    for (int i = 0; i < kNumIters; i++) {
      for (PointerInputEvent event in events) {
        if (event.type == 'pointerdown' || event.type == 'pointermove')
          tracker.addPosition(event.timeStamp, event.x, event.y);
        if (event.type == 'pointerup')
          tracker.getVelocity();
      }
    }
    watch.stop();
    print("Dart tracker: " + watch.elapsed.toString());
  });

  test('Native velocity tracker performance', () {
    ui.VelocityTracker tracker = new ui.VelocityTracker();
    Stopwatch watch = new Stopwatch();
    watch.start();
    for (int i = 0; i < kNumIters; i++) {
      for (PointerInputEvent event in events) {
        if (event.type == 'pointerdown' || event.type == 'pointermove')
          tracker.addPosition((event.timeStamp*1000.0).toInt(), event.x, event.y);
        if (event.type == 'pointerup')
          tracker.getVelocity();
      }
    }
    watch.stop();
    print("Native tracker: " + watch.elapsed.toString());
  });
}
