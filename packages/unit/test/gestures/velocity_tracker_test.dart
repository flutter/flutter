import 'package:flutter/gestures.dart';
import 'package:test/test.dart';
import 'velocity_tracker_data.dart';

bool _withinTolerance(double actual, double expected) {
  const double kTolerance = 0.001; // Within .1% of expected value
  double diff = (actual - expected)/expected;
  return diff.abs() < kTolerance;
}

bool _checkVelocity(GestureVelocity actual, GestureVelocity expected) {
  return (actual.isValid == expected.isValid) &&
    _withinTolerance(actual.x, expected.x) &&
    _withinTolerance(actual.y, expected.y);
}

List<PointerInputEvent> _eventFromMap(List<Map> intermediate) {
  List<PointerInputEvent> events = new List<PointerInputEvent>();
  for (Map entry in intermediate)
    events.add(_eventFor(entry));
  return events;
}

PointerInputEvent _eventFor(Map entry) {
  PointerInputEvent result = new PointerInputEvent(
    type: entry['type'],
    timeStamp: new Duration(milliseconds: entry['timeStamp'].round()),
    pointer: entry['pointer'],
    x: entry['x'],
    y: entry['y']
  );
  return result;
}

void main() {
  List<PointerInputEvent> events = _eventFromMap(velocityEventData);

  List<GestureVelocity> expected = new List<GestureVelocity>(13);
  expected[0] = new GestureVelocity(isValid: true, x: 219.5762939453125, y: 1304.6705322265625);
  expected[1] = new GestureVelocity(isValid: true, x: 355.6900939941406, y: 967.1700439453125);
  expected[2] = new GestureVelocity(isValid: true, x: 12.651158332824707, y: -36.9227180480957);
  expected[3] = new GestureVelocity(isValid: true, x: 714.1383056640625, y: -2561.540283203125);
  expected[4] = new GestureVelocity(isValid: true, x: -19.658065795898438, y: -2910.080322265625);
  expected[5] = new GestureVelocity(isValid: true, x: 646.8700561523438, y: 2976.982421875);
  expected[6] = new GestureVelocity(isValid: true, x: 396.6878967285156, y: 2106.204833984375);
  expected[7] = new GestureVelocity(isValid: true, x: 298.3150634765625, y: -3660.821044921875);
  expected[8] = new GestureVelocity(isValid: true, x: -1.7460877895355225, y: -3288.16162109375);
  expected[9] = new GestureVelocity(isValid: true, x: 384.6415710449219, y: -2645.6484375);
  expected[10] = new GestureVelocity(isValid: true, x: 176.3752899169922, y: 2711.24609375);
  expected[11] = new GestureVelocity(isValid: true, x: 396.9254455566406, y: 4280.640625);
  expected[12] = new GestureVelocity(isValid: true, x: -71.51288604736328, y: 3716.74560546875);

  test('Velocity tracker gives expected results', () {
    VelocityTracker tracker = new VelocityTracker();
    int i = 0;
    for (PointerInputEvent event in events) {
      if (event.type == 'pointerdown' || event.type == 'pointermove')
        tracker.addPosition(event.timeStamp, event.x, event.y);
      if (event.type == 'pointerup') {
        _checkVelocity(tracker.getVelocity(), expected[i++]);
      }
    }
  });
}
