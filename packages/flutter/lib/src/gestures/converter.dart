// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' as ui show PointerChange, PointerData, PointerSignalKind;

import 'events.dart';

export 'dart:ui' show PointerData;

export 'events.dart' show PointerEvent;

// Add `kPrimaryButton` to [buttons] when a pointer of certain devices is down.
//
// TODO(tongmu): This patch is supposed to be done by embedders. Patching it
// in framework is a workaround before [PointerEventConverter] is moved to embedders.
// https://github.com/flutter/flutter/issues/30454
int _synthesiseDownButtons(int buttons, PointerDeviceKind kind) {
  switch (kind) {
    case PointerDeviceKind.mouse:
    case PointerDeviceKind.trackpad:
      return buttons;
    case PointerDeviceKind.touch:
    case PointerDeviceKind.stylus:
    case PointerDeviceKind.invertedStylus:
      return buttons == 0 ? kPrimaryButton : buttons;
    case PointerDeviceKind.unknown:
      // We have no information about the device but we know we never want
      // buttons to be 0 when the pointer is down.
      return buttons == 0 ? kPrimaryButton : buttons;
  }
}

/// Converts from engine pointer data to framework pointer events.
///
/// This takes [PointerDataPacket] objects, as received from the engine via
/// [dart:ui.PlatformDispatcher.onPointerDataPacket], and converts them to
/// [PointerEvent] objects.
class PointerEventConverter {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  PointerEventConverter._();

  /// Expand the given packet of pointer data into a sequence of framework
  /// pointer events.
  ///
  /// The `devicePixelRatio` argument (usually given the value from
  /// [dart:ui.FlutterView.devicePixelRatio]) is used to convert the incoming data
  /// from physical coordinates to logical pixels. See the discussion at
  /// [PointerEvent] for more details on the [PointerEvent] coordinate space.
  static Iterable<PointerEvent> expand(Iterable<ui.PointerData> data, double devicePixelRatio) {
    return data
        .where((ui.PointerData datum) => datum.signalKind != ui.PointerSignalKind.unknown)
        .map((ui.PointerData datum) {
          final Offset position = Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
          assert(position != null);
          final Offset delta = Offset(datum.physicalDeltaX, datum.physicalDeltaY) / devicePixelRatio;
          final double radiusMinor = _toLogicalPixels(datum.radiusMinor, devicePixelRatio);
          final double radiusMajor = _toLogicalPixels(datum.radiusMajor, devicePixelRatio);
          final double radiusMin = _toLogicalPixels(datum.radiusMin, devicePixelRatio);
          final double radiusMax = _toLogicalPixels(datum.radiusMax, devicePixelRatio);
          final Duration timeStamp = datum.timeStamp;
          final PointerDeviceKind kind = datum.kind;
          assert(datum.change != null);
          switch (datum.signalKind ?? ui.PointerSignalKind.none) {
            case ui.PointerSignalKind.none:
              switch (datum.change) {
                case ui.PointerChange.add:
                  return PointerAddedEvent(
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
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.hover:
                  return PointerHoverEvent(
                    timeStamp: timeStamp,
                    kind: kind,
                    device: datum.device,
                    position: position,
                    delta: delta,
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
                    synthesized: datum.synthesized,
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.down:
                  return PointerDownEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
                    kind: kind,
                    device: datum.device,
                    position: position,
                    buttons: _synthesiseDownButtons(datum.buttons, kind),
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
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.move:
                  return PointerMoveEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
                    kind: kind,
                    device: datum.device,
                    position: position,
                    delta: delta,
                    buttons: _synthesiseDownButtons(datum.buttons, kind),
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
                    synthesized: datum.synthesized,
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.up:
                  return PointerUpEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
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
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.cancel:
                  return PointerCancelEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
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
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.remove:
                  return PointerRemovedEvent(
                    timeStamp: timeStamp,
                    kind: kind,
                    device: datum.device,
                    position: position,
                    obscured: datum.obscured,
                    pressureMin: datum.pressureMin,
                    pressureMax: datum.pressureMax,
                    distanceMax: datum.distanceMax,
                    radiusMin: radiusMin,
                    radiusMax: radiusMax,
                    embedderId: datum.embedderId,
                  );
                case ui.PointerChange.panZoomStart:
                  return PointerPanZoomStartEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
                    device: datum.device,
                    position: position,
                    embedderId: datum.embedderId,
                    synthesized: datum.synthesized,
                  );
                case ui.PointerChange.panZoomUpdate:
                  final Offset pan =
                      Offset(datum.panX, datum.panY) / devicePixelRatio;
                  final Offset panDelta =
                      Offset(datum.panDeltaX, datum.panDeltaY) / devicePixelRatio;
                  return PointerPanZoomUpdateEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
                    device: datum.device,
                    position: position,
                    pan: pan,
                    panDelta: panDelta,
                    scale: datum.scale,
                    rotation: datum.rotation,
                    embedderId: datum.embedderId,
                    synthesized: datum.synthesized,
                  );
                case ui.PointerChange.panZoomEnd:
                  return PointerPanZoomEndEvent(
                    timeStamp: timeStamp,
                    pointer: datum.pointerIdentifier,
                    device: datum.device,
                    position: position,
                    embedderId: datum.embedderId,
                    synthesized: datum.synthesized,
                  );
              }
            case ui.PointerSignalKind.scroll:
              final Offset scrollDelta =
                  Offset(datum.scrollDeltaX, datum.scrollDeltaY) / devicePixelRatio;
              return PointerScrollEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                scrollDelta: scrollDelta,
                embedderId: datum.embedderId,
              );
            case ui.PointerSignalKind.scrollInertiaCancel:
              return PointerScrollInertiaCancelEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                embedderId: datum.embedderId,
              );
            case ui.PointerSignalKind.scale:
              return PointerScaleEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                embedderId: datum.embedderId,
                scale: datum.scale,
              );
            case ui.PointerSignalKind.unknown:
              // This branch should already have 'unknown' filtered out, but
              // we don't want to return anything or miss if someone adds a new
              // enumeration to PointerSignalKind.
              throw StateError('Unreachable');
          }
        });
  }

  static double _toLogicalPixels(double physicalPixels, double devicePixelRatio) => physicalPixels / devicePixelRatio;
}
