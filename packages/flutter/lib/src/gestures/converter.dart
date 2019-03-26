// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show PointerData, PointerChange, PointerSignalKind;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'events.dart';

/// The state of a device at any point of time between "right after an event"
/// and "right before the next event", which excludes "exactly at an event".
class _DeviceState {
  _DeviceState();

  /// "Pointer" is the identifier used in PointerEvent objects.
  /// [latestPointer] returns the pointer that was created recently.
  static int get latestPointer => _pointerCount;
  static int _pointerCount = 0;
  /// Increase global pointer counter and return the latest pointer.
  static int startNewPointer() {
    _pointerCount += 1;
    return _pointerCount;
  }

  PointerEvent _event;
  /// The latest event. Can be null.
  PointerEvent get event => _event;

  void _assertSanitized(PointerEvent next) {
    assert(next != null);
    // Make sure it's the same device
    if (_event != null) {
      assert(_event.kind == next.kind);
      assert(_event.device == next.device);
    }
    // Make sure it's the same pointer if applicable
    assert(
      (_event?.pointer ?? 0) == 0 ||
      next.pointer == 0 ||
      _event.pointer == next.pointer
    );
    // Make sure [next.delta] is correct.
    assert(() {
      final Offset correctDelta = deltaTo(next.position);
      const double epsilon = 1e-10;
      return correctDelta != null
          && next.delta != null
          && (correctDelta - next.delta).distance < epsilon;
    }());
  }

  /// Set [event] with the specified event [source].
  ///
  /// In terms of concept, it means the point of time that this state represents
  /// progresses from "before [next]" to "after [event]".
  PointerEvent record(PointerEvent next) {
    _assertSanitized(next);
    _event = next;
    return _event;
  }

  bool get down => _event?.down ?? false;
  int get pointer => _event?.pointer;
  Offset get position => _event?.position;

  Offset deltaTo(Offset to) {
    if (_event == null) { // [PointerAddedEvent]
      return to;
    }
    if (to == null) { // [PointerRemovedEvent]
      return Offset.zero;
    }
    return to - _event.position;
  }

  @override
  String toString() {
    return '_DeviceState(pointer: $pointer, event: ${event.toStringFull()})';
  }
}

/// Converts from engine pointer data to framework pointer events.
///
/// This takes [ui.PointerData] objects, as received from the engine via
/// [dart:ui.Window.onPointerDataPacket], and converts them to [PointerEvent]
/// objects.
class PointerEventConverter {
  PointerEventConverter._();

  /// Clears internal state mapping device identifiers to device states.
  ///
  /// Visible only so that tests can reset the global state contained in
  /// [PointerEventConverter].
  @visibleForTesting
  static void clearPointers() => _devices.clear();

  // Map from device identifiers to device states.
  // Static to guarantee that pointers are unique.
  static final Map<int, _DeviceState> _devices = <int, _DeviceState>{};

  static _DeviceState _createDevice(int device) {
    assert(!_devices.containsKey(device));
    final _DeviceState state = _DeviceState();
    _devices[device] = state;
    return state;
  }

  static _DeviceState _getDeviceState(int device) {
    assert(_devices.containsKey(device));
    return _devices[device];
  }

  /// Expand the given packet of pointer data into a sequence of framework
  /// pointer events.
  ///
  /// The `devicePixelRatio` argument (usually given the value from
  /// [dart:ui.Window.devicePixelRatio]) is used to convert the incoming data
  /// from physical coordinates to logical pixels. See the discussion at
  /// [PointerEvent] for more details on the [PointerEvent] coordinate space.
  static Iterable<PointerEvent> expand(Iterable<ui.PointerData> data, double devicePixelRatio) sync* {
    for (ui.PointerData datum in data) {
      final Offset position = Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
      final double radiusMinor = _toLogicalPixels(datum.radiusMinor, devicePixelRatio);
      final double radiusMajor = _toLogicalPixels(datum.radiusMajor, devicePixelRatio);
      final double radiusMin = _toLogicalPixels(datum.radiusMin, devicePixelRatio);
      final double radiusMax = _toLogicalPixels(datum.radiusMax, devicePixelRatio);
      final int device = datum.device;
      final Duration timeStamp = datum.timeStamp;
      final PointerDeviceKind kind = datum.kind;
      final int buttons = datum.buttons;
      final double pressure = datum.pressure;
      final double distance = datum.distance;
      assert(datum.change != null);

      PointerAddedEvent createAndRecordAddedEvent() {
        final _DeviceState state = _createDevice(device);
        return state.record(PointerAddedEvent(
          timeStamp: timeStamp,
          kind: kind,
          device: device,
          position: position,
          obscured: datum.obscured,
          pressureMin: datum.pressureMin,
          pressureMax: datum.pressureMax,
          distance: distance,
          distanceMax: datum.distanceMax,
          radiusMin: radiusMin,
          radiusMax: radiusMax,
          orientation: datum.orientation,
          tilt: datum.tilt,
        ));
      }

      if (datum.signalKind == null || datum.signalKind == ui.PointerSignalKind.none) {
        switch (datum.change) {
          case ui.PointerChange.add:
            final PointerAddedEvent addedEvent = createAndRecordAddedEvent();
            yield addedEvent;
            break;
          case ui.PointerChange.hover:
            final bool alreadyAdded = _devices.containsKey(device);
            assert(!alreadyAdded || !_devices[device].down);
            if (!alreadyAdded) {
              final PointerAddedEvent addedEvent = createAndRecordAddedEvent();
              yield addedEvent;
            }
            final _DeviceState state = _getDeviceState(device);
            yield state.record(PointerHoverEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: device,
              position: position,
              delta: state.deltaTo(position),
              buttons: buttons,
              obscured: datum.obscured,
              pressure: pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: distance,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            ));
            break;
          case ui.PointerChange.down:
            final bool alreadyAdded = _devices.containsKey(device);
            assert(!alreadyAdded || !_devices[device].down);
            if (!alreadyAdded) {
              final PointerAddedEvent addedEvent = createAndRecordAddedEvent();
              yield addedEvent;
            }
            final _DeviceState state = _getDeviceState(device);
            if (state.position != position) {
              assert(state.event != null);
              // Not all sources of pointer packets respect the invariant that
              // they hover the pointer to the down location before sending the
              // down event. We restore the invariant here for our clients.
              yield state.record(PointerHoverEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: device,
                position: position,
                delta: state.deltaTo(position),
                buttons: buttons,
                obscured: datum.obscured,
                pressure: state.event.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              ));
            }
            final int pointer = _DeviceState.startNewPointer();
            yield state.record(PointerDownEvent(
              timeStamp: timeStamp,
              pointer: pointer,
              kind: kind,
              device: device,
              position: position,
              buttons: buttons,
              obscured: datum.obscured,
              pressure: pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            ));
            break;
          case ui.PointerChange.move:
            // If the service starts supporting hover pointers, then it must also
            // start sending us ADDED and REMOVED data points.
            // See also: https://github.com/flutter/flutter/issues/720
            final _DeviceState state = _getDeviceState(device);
            assert(state.down);
            yield state.record(PointerMoveEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: device,
              position: position,
              delta: state.deltaTo(position),
              buttons: buttons,
              obscured: datum.obscured,
              pressure: pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
              platformData: datum.platformData,
            ));
            break;
          case ui.PointerChange.up:
          case ui.PointerChange.cancel:
            final _DeviceState state = _getDeviceState(device);
            assert(state.down);
            if (position != state.position) {
              // Not all sources of pointer packets respect the invariant that
              // they move the pointer to the up location before sending the up or cancel
              // event. For example, in the iOS simulator, of you drag outside the
              // window, you'll get a stream of pointers that violates that
              // invariant. We restore the invariant here for our clients.
              assert(state.event != null);
              yield state.record(PointerMoveEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: device,
                position: position,
                delta: state.deltaTo(position),
                buttons: buttons,
                obscured: datum.obscured,
                pressure: pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              ));
            }
            if (datum.change == ui.PointerChange.up) {
              yield state.record(PointerUpEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: device,
                position: position,
                buttons: buttons,
                obscured: datum.obscured,
                pressure: pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              ));
            } else {
              yield state.record(PointerCancelEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: device,
                position: position,
                buttons: buttons,
                obscured: datum.obscured,
                pressure: pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              ));
            }
            break;
          case ui.PointerChange.remove:
            final _DeviceState state = _getDeviceState(device);
            if (state.down) {
              assert(state.event != null);
              yield state.record(PointerCancelEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: device,
                position: state.event.position, // Change position in Hover
                buttons: buttons,
                obscured: datum.obscured,
                pressure: pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              ));
            }
            if (position != state.position) {
              assert(state.event != null);
              yield state.record(PointerHoverEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: device,
                position: position,
                delta: state.deltaTo(position),
                buttons: buttons,
                obscured: datum.obscured,
                pressure: pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              ));
            }
            _devices.remove(datum.device);
            yield state.record(PointerRemovedEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: device,
              obscured: datum.obscured,
              pressure: pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
            ));
            break;
        }
      } else {
        switch (datum.signalKind) {
          case ui.PointerSignalKind.scroll:
            // Devices must be added before they send scroll events.
            final _DeviceState state =_getDeviceState(device);
            if (state.position != position) {
              // Synthesize a hover/move of the pointer to the scroll location
              // before sending the scroll event, if necessary, so that clients
              // don't have to worry about native ordering of hover and scroll
              // events.
              assert(state.event != null);
              if (state.down) {
                yield state.record(PointerMoveEvent(
                  timeStamp: timeStamp,
                  pointer: state.pointer,
                  kind: kind,
                  device: device,
                  position: position,
                  delta: state.deltaTo(position),
                  buttons: buttons,
                  obscured: datum.obscured,
                  pressureMin: datum.pressureMin,
                  pressureMax: datum.pressureMax,
                  distanceMax: datum.distanceMax,
                  size: datum.size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: datum.orientation,
                  tilt: datum.tilt,
                  synthesized: true,
                ));
              } else {
                yield state.record(PointerHoverEvent(
                  timeStamp: timeStamp,
                  kind: kind,
                  device: device,
                  position: position,
                  delta: state.deltaTo(position),
                  buttons: buttons,
                  obscured: datum.obscured,
                  pressure: pressure,
                  pressureMin: datum.pressureMin,
                  pressureMax: datum.pressureMax,
                  distance: distance,
                  distanceMax: datum.distanceMax,
                  size: datum.size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: datum.orientation,
                  tilt: datum.tilt,
                  synthesized: true,
                ));
              }
            }
            final Offset scrollDelta =
                Offset(datum.scrollDeltaX, datum.scrollDeltaY) / devicePixelRatio;
            yield state.record(PointerScrollEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: device,
              position: position,
              scrollDelta: scrollDelta,
            ));
            break;
          case ui.PointerSignalKind.none:
            assert(false); // This branch should already have 'none' filtered out.
            break;
          case ui.PointerSignalKind.unknown:
            // Ignore unknown signals.
            break;
        }
      }
    }
  }

  static double _toLogicalPixels(double physicalPixels, double devicePixelRatio) =>
      physicalPixels == null ? null : physicalPixels / devicePixelRatio;
}
