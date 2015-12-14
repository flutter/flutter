// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky_services/pointer/pointer.mojom.dart';

import 'events.dart';

class _PointerState {
  _PointerState(this.lastPosition);

  int get pointer => _pointer; // The identifier used in PointerEvent objects.
  int _pointer;
  static int _pointerCount = 0;
  void startNewPointer() {
    _pointerCount += 1;
    _pointer = _pointerCount;
  }

  bool get down => _down;
  bool _down = false;
  void setDown() {
    assert(!_down);
    _down = true;
  }
  void setUp() {
    assert(_down);
    _down = false;
  }

  Point lastPosition;
}

class PointerEventConverter {
  // Map from platform pointer identifiers to PointerEvent pointer identifiers.
  static Map<int, _PointerState> _pointers = <int, _PointerState>{};

  static Iterable<PointerEvent> expand(Iterable<Pointer> packet) sync* {
    for (Pointer datum in packet) {
      Point position = new Point(datum.x, datum.y);
      Duration timeStamp = new Duration(microseconds: datum.timeStamp);
      assert(_pointerKindMap.containsKey(datum.kind));
      PointerDeviceKind kind = _pointerKindMap[datum.kind];
      switch (datum.type) {
        case PointerType.DOWN:
          assert(!_pointers.containsKey(datum.pointer));
          _PointerState state = _pointers.putIfAbsent(
            datum.pointer,
            () => new _PointerState(position)
          );
          assert(state.lastPosition == position);
          state.startNewPointer();
          state.setDown();
          yield new PointerAddedEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            obscured: datum.obscured,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distance: datum.distance,
            distanceMax: datum.distanceMax,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          yield new PointerDownEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            obscured: datum.obscured,
            pressure: datum.pressure,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distanceMax: datum.distanceMax,
            radiusMajor: datum.radiusMajor,
            radiusMinor: datum.radiusMajor,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          break;
        case PointerType.MOVE:
          // If the service starts supporting hover pointers, then it must also
          // start sending us ADDED and REMOVED data points.
          // See also: https://github.com/flutter/flutter/issues/720
          assert(_pointers.containsKey(datum.pointer));
          _PointerState state = _pointers[datum.pointer];
          assert(state.down);
          Offset offset = position - state.lastPosition;
          state.lastPosition = position;
          yield new PointerMoveEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            delta: offset,
            down: state.down,
            obscured: datum.obscured,
            pressure: datum.pressure,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distance: datum.distance,
            distanceMax: datum.distanceMax,
            radiusMajor: datum.radiusMajor,
            radiusMinor: datum.radiusMajor,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          break;
        case PointerType.UP:
        case PointerType.CANCEL:
          assert(_pointers.containsKey(datum.pointer));
          _PointerState state = _pointers[datum.pointer];
          assert(state.down);
          assert(position == state.lastPosition);
          state.setUp();
          if (datum.type == PointerType.UP) {
            yield new PointerUpEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              position: position,
              obscured: datum.obscured,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: datum.radiusMin,
              radiusMax: datum.radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt
            );
          } else {
            yield new PointerCancelEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              position: position,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: datum.radiusMin,
              radiusMax: datum.radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt
            );
          }
          yield new PointerRemovedEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            obscured: datum.obscured,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distanceMax: datum.distanceMax,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax
          );
          _pointers.remove(datum.pointer);
          break;
        default:
          // TODO(ianh): once https://github.com/flutter/flutter/issues/720 is
          // done, add real support for PointerAddedEvent and PointerRemovedEvent
          assert(false);
      }
    }
  }

  static const Map<PointerKind, PointerDeviceKind> _pointerKindMap = const <PointerKind, PointerDeviceKind>{
    PointerKind.TOUCH: PointerDeviceKind.touch,
    PointerKind.MOUSE: PointerDeviceKind.mouse,
    PointerKind.STYLUS: PointerDeviceKind.stylus,
    PointerKind.INVERTED_STYLUS: PointerDeviceKind.invertedStylus,
  };
}
