// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show PointerData, PointerChange, PointerSignalKind;

import 'package:flutter/foundation.dart' show visibleForTesting;

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

  Offset lastPosition;

  @override
  String toString() {
    return '_PointerState(pointer: $pointer, down: $down, lastPosition: $lastPosition)';
  }
}

/// Converts from engine pointer data to framework pointer events.
///
/// This takes [PointerDataPacket] objects, as received from the engine via
/// [dart:ui.Window.onPointerDataPacket], and converts them to [PointerEvent]
/// objects.
class PointerEventConverter {
  PointerEventConverter._();

  /// Clears internal state mapping platform pointer identifiers to
  /// [PointerEvent] pointer identifiers.
  ///
  /// Visible only so that tests can reset the global state contained in
  /// [PointerEventConverter].
  @visibleForTesting
  static void clearPointers() => _pointers.clear();

  // Map from platform pointer identifiers to PointerEvent pointer identifiers.
  // Static to guarantee that pointers are unique.
  static final Map<int, _PointerState> _pointers = <int, _PointerState>{};

  static _PointerState _ensureStateForPointer(ui.PointerData datum, Offset position) {
    return _pointers.putIfAbsent(
      datum.device,
      () => _PointerState(position),
    );
  }

  static String _formatErrorMessage(ui.PointerChange change, String message) => 'Invalid event \'$change\': $message';

  /// Format the given packet of pointer data into a framework
  /// pointer events.
  ///
  /// The `devicePixelRatio` argument (usually given the value from
  /// [dart:ui.Window.devicePixelRatio]) is used to convert the incoming data
  /// from physical coordinates to logical pixels. See the discussion at
  /// [PointerEvent] for more details on the [PointerEvent] coordinate space.
  static Iterable<PointerEvent> expand(List<ui.PointerData> data, double devicePixelRatio) sync* {
    for (ui.PointerData datum in data) {
      final Offset position = Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
      final double radiusMinor = _toLogicalPixels(datum.radiusMinor, devicePixelRatio);
      final double radiusMajor = _toLogicalPixels(datum.radiusMajor, devicePixelRatio);
      final double radiusMin = _toLogicalPixels(datum.radiusMin, devicePixelRatio);
      final double radiusMax = _toLogicalPixels(datum.radiusMax, devicePixelRatio);
      final Duration timeStamp = datum.timeStamp;
      final PointerDeviceKind kind = datum.kind;
      assert(datum.change != null);
      if (datum.signalKind == null || datum.signalKind == ui.PointerSignalKind.none) {
        switch (datum.change) {
          case ui.PointerChange.add:
            assert(!_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} already exist.'));
            final _PointerState state = _ensureStateForPointer(datum, position);
            assert(state.lastPosition == position);
            yield PointerAddedEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.hover:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(!state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is down.'));
            final Offset offset = position - state.lastPosition;
            state.lastPosition = position;
            yield PointerHoverEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              delta: offset,
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.move:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is up.'));
            final Offset offset = position - state.lastPosition;
            state.lastPosition = position;
            yield PointerMoveEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              delta: offset,
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressure: datum.pressure,
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
            );
            break;
          case ui.PointerChange.down:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(!state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is already down.'));
            assert(position == state.lastPosition,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} new position does not match previous position'));
            state.startNewPointer();
            state.setDown();
            yield PointerDownEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressure: datum.pressure,
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
            );
            break;
          case ui.PointerChange.up:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is already up.'));
            assert(position == state.lastPosition,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} new position does not match previous position'));
            state.setUp();
            yield PointerUpEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressure: datum.pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.cancel:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is already up.'));
            assert(position == state.lastPosition,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} new position does not match previous position'));
            yield PointerCancelEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.remove:
            assert(_pointers.containsKey(datum.device),
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} does not exist.'));
            final _PointerState state = _pointers[datum.device];
            assert(!state.down,
              _formatErrorMessage(datum.change, 'Pointer ${datum.device} is down.'));
            _pointers.remove(datum.device);
            yield PointerRemovedEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
            );
            break;
        }
      } else {
        switch (datum.signalKind) {
          case ui.PointerSignalKind.scroll:
            // Devices must be added before they send scroll events.
            assert(_pointers.containsKey(datum.device));
            final _PointerState state = _ensureStateForPointer(datum, position);
            assert(state.lastPosition == position);
            final Offset scrollDelta =
                Offset(datum.scrollDeltaX, datum.scrollDeltaY) / devicePixelRatio;
            yield PointerScrollEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              scrollDelta: scrollDelta,
            );
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
