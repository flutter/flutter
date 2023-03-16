// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(goderbauer): Remove next line when compiler bug is fixed: https://github.com/flutter/flutter/issues/122724
// @dart = 2.19

import 'package:ui/ui.dart' as ui;

const bool _debugLogPointerConverter = false;

class _PointerState {
  _PointerState(this.x, this.y);

  /// The identifier used in framework hit test.
  int? get pointer => _pointer;
  int? _pointer;
  static int _pointerCount = 0;
  void startNewPointer() {
    _pointerCount += 1;
    _pointer = _pointerCount;
  }

  double x;
  double y;
}

/// Converter to convert web pointer data into a form that framework can
/// understand.
///
/// This converter calculates pointer location delta and pointer identifier for
/// each pointer. Both are required by framework to correctly trigger gesture
/// activity. It also attempts to sanitize pointer data input sequence by always
/// synthesizing an add pointer data prior to hover or down if it the pointer is
/// not previously added.
///
/// For example:
///   before:
///     hover -> down -> move -> up
///   after:
///     add(synthesize) -> hover -> down -> move -> up
///
///   before:
///     down -> move -> up
///   after:
///     add(synthesize) -> down -> move -> up
class PointerDataConverter {
  PointerDataConverter();

  // Map from browser pointer identifiers to PointerEvent pointer identifiers.
  final Map<int, _PointerState> _pointers = <int, _PointerState>{};

  /// This field is used to keep track of button state.
  ///
  /// To normalize pointer events, when we receive pointer down followed by
  /// pointer up, we synthesize a move event. To make sure that button state
  /// is correct for move regardless of button state at the time of up event
  /// we store it on down,hover and move events.
  int _activeButtons = 0;

  /// Clears the existing pointer states.
  ///
  /// This method is invoked during hot reload to make sure we have a clean
  /// converter after hot reload.
  void clearPointerState() {
    _pointers.clear();
    _PointerState._pointerCount = 0;
    _activeButtons = 0;
  }

  _PointerState _ensureStateForPointer(int device, double x, double y) {
    return _pointers.putIfAbsent(
      device,
      () => _PointerState(x, y),
    );
  }

  ui.PointerData _generateCompletePointerData({
    required Duration timeStamp,
    required ui.PointerChange change,
    required ui.PointerDeviceKind kind,
    ui.PointerSignalKind? signalKind,
    required int device,
    required double physicalX,
    required double physicalY,
    required int buttons,
    required bool obscured,
    required double pressure,
    required double pressureMin,
    required double pressureMax,
    required double distance,
    required double distanceMax,
    required double size,
    required double radiusMajor,
    required double radiusMinor,
    required double radiusMin,
    required double radiusMax,
    required double orientation,
    required double tilt,
    required int platformData,
    required double scrollDeltaX,
    required double scrollDeltaY,
  }) {
    assert(_pointers.containsKey(device));
    final _PointerState state = _pointers[device]!;
    final double deltaX = physicalX - state.x;
    final double deltaY = physicalY - state.y;
    state.x = physicalX;
    state.y = physicalY;
    return ui.PointerData(
      timeStamp: timeStamp,
      change: change,
      kind: kind,
      signalKind: signalKind,
      device: device,
      pointerIdentifier: state.pointer ?? 0,
      physicalX: physicalX,
      physicalY: physicalY,
      physicalDeltaX: deltaX,
      physicalDeltaY: deltaY,
      buttons: buttons,
      obscured: obscured,
      pressure: pressure,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      platformData: platformData,
      scrollDeltaX: scrollDeltaX,
      scrollDeltaY: scrollDeltaY,
    );
  }

  bool _locationHasChanged(int device, double physicalX, double physicalY) {
    assert(_pointers.containsKey(device));
    final _PointerState state = _pointers[device]!;
    return state.x != physicalX || state.y != physicalY;
  }

  ui.PointerData _synthesizePointerData({
    required Duration timeStamp,
    required ui.PointerChange change,
    required ui.PointerDeviceKind kind,
    required int device,
    required double physicalX,
    required double physicalY,
    required int buttons,
    required bool obscured,
    required double pressure,
    required double pressureMin,
    required double pressureMax,
    required double distance,
    required double distanceMax,
    required double size,
    required double radiusMajor,
    required double radiusMinor,
    required double radiusMin,
    required double radiusMax,
    required double orientation,
    required double tilt,
    required int platformData,
    required double scrollDeltaX,
    required double scrollDeltaY,
  }) {
    assert(_pointers.containsKey(device));
    final _PointerState state = _pointers[device]!;
    final double deltaX = physicalX - state.x;
    final double deltaY = physicalY - state.y;
    state.x = physicalX;
    state.y = physicalY;
    return ui.PointerData(
      timeStamp: timeStamp,
      change: change,
      kind: kind,
      // All the pointer data except scroll should not have a signal kind, and
      // there is no use case for synthetic scroll event. We should be
      // safe to default it to ui.PointerSignalKind.none.
      signalKind: ui.PointerSignalKind.none,
      device: device,
      pointerIdentifier: state.pointer ?? 0,
      physicalX: physicalX,
      physicalY: physicalY,
      physicalDeltaX: deltaX,
      physicalDeltaY: deltaY,
      buttons: buttons,
      obscured: obscured,
      synthesized: true,
      pressure: pressure,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
      distance: distance,
      distanceMax: distanceMax,
      size: size,
      radiusMajor: radiusMajor,
      radiusMinor: radiusMinor,
      radiusMin: radiusMin,
      radiusMax: radiusMax,
      orientation: orientation,
      tilt: tilt,
      platformData: platformData,
      scrollDeltaX: scrollDeltaX,
      scrollDeltaY: scrollDeltaY,
    );
  }

  /// Converts the given html pointer event metrics into a sequence of framework-compatible
  /// pointer data and stores it into [result]
  void convert(
    List<ui.PointerData> result, {
    Duration timeStamp = Duration.zero,
    ui.PointerChange change = ui.PointerChange.cancel,
    ui.PointerDeviceKind kind = ui.PointerDeviceKind.touch,
    ui.PointerSignalKind? signalKind,
    int device = 0,
    double physicalX = 0.0,
    double physicalY = 0.0,
    int buttons = 0,
    bool obscured = false,
    double pressure = 0.0,
    double pressureMin = 0.0,
    double pressureMax = 0.0,
    double distance = 0.0,
    double distanceMax = 0.0,
    double size = 0.0,
    double radiusMajor = 0.0,
    double radiusMinor = 0.0,
    double radiusMin = 0.0,
    double radiusMax = 0.0,
    double orientation = 0.0,
    double tilt = 0.0,
    int platformData = 0,
    double scrollDeltaX = 0.0,
    double scrollDeltaY = 0.0,
  }) {
    if (_debugLogPointerConverter) {
      print('>> device=$device change=$change buttons=$buttons');
    }
    final bool isDown = buttons != 0;
    if (signalKind == null ||
      signalKind == ui.PointerSignalKind.none) {
      switch (change) {
        case ui.PointerChange.add:
          assert(!_pointers.containsKey(device));
          _ensureStateForPointer(device, physicalX, physicalY);
          assert(!_locationHasChanged(device, physicalX, physicalY));
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          break;
        case ui.PointerChange.hover:
          final bool alreadyAdded = _pointers.containsKey(device);
          _ensureStateForPointer(device, physicalX, physicalY);
          assert(!isDown);
          if (!alreadyAdded) {
            // Synthesizes an add pointer data.
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.add,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: buttons,
                obscured: obscured,
                pressure: pressure,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
          }
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          _activeButtons = buttons;
          break;
        case ui.PointerChange.down:
          final bool alreadyAdded = _pointers.containsKey(device);
          final _PointerState state = _ensureStateForPointer(
            device, physicalX, physicalY);
          assert(isDown);
          state.startNewPointer();
          if (!alreadyAdded) {
            // Synthesizes an add pointer data.
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.add,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: buttons,
                obscured: obscured,
                pressure: pressure,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
          }
          if (_locationHasChanged(device, physicalX, physicalY)) {
            assert(alreadyAdded);
            // Synthesize a hover of the pointer to the down location before
            // sending the down event, if necessary.
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.hover,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: 0,
                obscured: obscured,
                pressure: 0.0,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
          }
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          _activeButtons = buttons;
          break;
        case ui.PointerChange.move:
          assert(_pointers.containsKey(device));
          assert(isDown);
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          _activeButtons = buttons;
          break;
        case ui.PointerChange.up:
        case ui.PointerChange.cancel:
          assert(_pointers.containsKey(device));
          final _PointerState state = _pointers[device]!;
          assert(!isDown);
          // Cancel events can have different coordinates due to various
          // reasons (window lost focus which is accompanied by window
          // movement, or PointerEvent simply always gives 0). Instead of
          // caring about the coordinates, we want to cancel the pointers as
          // soon as possible.
          if (change == ui.PointerChange.cancel) {
            physicalX = state.x;
            physicalY = state.y;
          }
          if (_locationHasChanged(device, physicalX, physicalY)) {
            // Synthesize a move of the pointer to the up location before
            // sending the up event, if necessary.
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.move,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: _activeButtons,
                obscured: obscured,
                pressure: pressure,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
          }
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          if (kind == ui.PointerDeviceKind.touch) {
            // The browser sends a new device ID for each touch gesture. To
            // avoid memory leaks, we send a "remove" event when the gesture is
            // over (i.e. when "up" or "cancel" is received).
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.remove,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: 0,
                obscured: obscured,
                pressure: 0.0,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
            _pointers.remove(device);
          }
          break;
        case ui.PointerChange.remove:
          assert(_pointers.containsKey(device));
          final _PointerState state = _pointers[device]!;
          assert(!isDown);
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: state.x,
              physicalY: state.y,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
          );
          _pointers.remove(device);
          break;
        case ui.PointerChange.panZoomStart:
        case ui.PointerChange.panZoomUpdate:
        case ui.PointerChange.panZoomEnd:
          // Pointer pan/zoom events are not generated on web.
          assert(false);
          break;
      }
    } else {
      switch (signalKind) {
        case ui.PointerSignalKind.scroll:
        case ui.PointerSignalKind.scrollInertiaCancel:
        case ui.PointerSignalKind.scale:
          final bool alreadyAdded = _pointers.containsKey(device);
          _ensureStateForPointer(device, physicalX, physicalY);
          if (!alreadyAdded) {
            // Synthesizes an add pointer data.
            result.add(
              _synthesizePointerData(
                timeStamp: timeStamp,
                change: ui.PointerChange.add,
                kind: kind,
                device: device,
                physicalX: physicalX,
                physicalY: physicalY,
                buttons: buttons,
                obscured: obscured,
                pressure: pressure,
                pressureMin: pressureMin,
                pressureMax: pressureMax,
                distance: distance,
                distanceMax: distanceMax,
                size: size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: orientation,
                tilt: tilt,
                platformData: platformData,
                scrollDeltaX: scrollDeltaX,
                scrollDeltaY: scrollDeltaY,
              )
            );
          }
          if (_locationHasChanged(device, physicalX, physicalY)) {
            // Synthesize a hover/move of the pointer to the scroll location
            // before sending the scroll event, if necessary, so that clients
            // don't have to worry about native ordering of hover and scroll
            // events.
            if (isDown) {
              result.add(
                _synthesizePointerData(
                  timeStamp: timeStamp,
                  change: ui.PointerChange.move,
                  kind: kind,
                  device: device,
                  physicalX: physicalX,
                  physicalY: physicalY,
                  buttons: buttons,
                  obscured: obscured,
                  pressure: pressure,
                  pressureMin: pressureMin,
                  pressureMax: pressureMax,
                  distance: distance,
                  distanceMax: distanceMax,
                  size: size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: orientation,
                  tilt: tilt,
                  platformData: platformData,
                  scrollDeltaX: scrollDeltaX,
                  scrollDeltaY: scrollDeltaY,
                )
              );
            } else {
              result.add(
                _synthesizePointerData(
                  timeStamp: timeStamp,
                  change: ui.PointerChange.hover,
                  kind: kind,
                  device: device,
                  physicalX: physicalX,
                  physicalY: physicalY,
                  buttons: buttons,
                  obscured: obscured,
                  pressure: pressure,
                  pressureMin: pressureMin,
                  pressureMax: pressureMax,
                  distance: distance,
                  distanceMax: distanceMax,
                  size: size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: orientation,
                  tilt: tilt,
                  platformData: platformData,
                  scrollDeltaX: scrollDeltaX,
                  scrollDeltaY: scrollDeltaY,
                )
              );
            }
          }
          result.add(
            _generateCompletePointerData(
              timeStamp: timeStamp,
              change: change,
              kind: kind,
              signalKind: signalKind,
              device: device,
              physicalX: physicalX,
              physicalY: physicalY,
              buttons: buttons,
              obscured: obscured,
              pressure: pressure,
              pressureMin: pressureMin,
              pressureMax: pressureMax,
              distance: distance,
              distanceMax: distanceMax,
              size: size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: orientation,
              tilt: tilt,
              platformData: platformData,
              scrollDeltaX: scrollDeltaX,
              scrollDeltaY: scrollDeltaY,
            )
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
