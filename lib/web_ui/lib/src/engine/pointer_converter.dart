// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class _PointerState {
  _PointerState(this.x, this.y);

  /// The identifier used in framework hit test.
  int get pointer => _pointer;
  int _pointer;
  static int _pointerCount = 0;
  void startNewPointer() {
    _pointerCount += 1;
    _pointer = _pointerCount;
  }

  bool down = false;

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

  /// Clears the existing pointer states.
  ///
  /// This method is invoked during hot reload to make sure we have a clean
  /// converter after hot reload.
  void clearPointerState() {
    _pointers.clear();
    _PointerState._pointerCount = 0;
  }

  _PointerState _ensureStateForPointer(int device, double x, double y) {
    return _pointers.putIfAbsent(
      device,
      () => _PointerState(x, y),
    );
  }

  ui.PointerData _generateCompletePointerData({
    Duration timeStamp,
    ui.PointerChange change,
    ui.PointerDeviceKind kind,
    ui.PointerSignalKind signalKind,
    int device,
    double physicalX,
    double physicalY,
    int buttons,
    bool obscured,
    double pressure,
    double pressureMin,
    double pressureMax,
    double distance,
    double distanceMax,
    double size,
    double radiusMajor,
    double radiusMinor,
    double radiusMin,
    double radiusMax,
    double orientation,
    double tilt,
    int platformData,
    double scrollDeltaX,
    double scrollDeltaY,
  }) {
    assert(_pointers.containsKey(device));
    final _PointerState state = _pointers[device];
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
    final _PointerState state = _pointers[device];
    return state.x != physicalX || state.y != physicalY;
  }

  ui.PointerData _synthesizePointerData({
    Duration timeStamp,
    ui.PointerChange change,
    ui.PointerDeviceKind kind,
    int device,
    double physicalX,
    double physicalY,
    int buttons,
    bool obscured,
    double pressure,
    double pressureMin,
    double pressureMax,
    double distance,
    double distanceMax,
    double size,
    double radiusMajor,
    double radiusMinor,
    double radiusMin,
    double radiusMax,
    double orientation,
    double tilt,
    int platformData,
    double scrollDeltaX,
    double scrollDeltaY,
  }) {
    assert(_pointers.containsKey(device));
    final _PointerState state = _pointers[device];
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
    ui.PointerSignalKind signalKind,
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
    assert(change != null);
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
          final _PointerState state = _ensureStateForPointer(
            device, physicalX, physicalY);
          assert(!state.down);
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
          break;
        case ui.PointerChange.down:
          final bool alreadyAdded = _pointers.containsKey(device);
          final _PointerState state = _ensureStateForPointer(
            device, physicalX, physicalY);
          assert(!state.down);
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
          state.down = true;
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
        case ui.PointerChange.move:
          assert(_pointers.containsKey(device));
          final _PointerState state = _pointers[device];
          assert(state.down);
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
        case ui.PointerChange.up:
        case ui.PointerChange.cancel:
          assert(_pointers.containsKey(device));
          final _PointerState state = _pointers[device];
          assert(state.down);
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
          state.down = false;
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
          final _PointerState state = _pointers[device];
          assert(!state.down);
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
      }
    } else {
      switch (signalKind) {
        case ui.PointerSignalKind.scroll:
          final bool alreadyAdded = _pointers.containsKey(device);
          final _PointerState state = _ensureStateForPointer(
            device, physicalX, physicalY);
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
            if (state.down) {
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
