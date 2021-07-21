// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' as ui show PointerData, PointerChange, PointerSignalKind;

import 'events.dart';

// Add `kPrimaryButton` to [buttons] when a pointer of certain devices is down.
//
// TODO(tongmu): This patch is supposed to be done by embedders. Patching it
// in framework is a workaround before [PointerEventConverter] is moved to embedders.
// https://github.com/flutter/flutter/issues/30454
int _synthesiseDownButtons(int buttons, PointerDeviceKind kind) {
  switch (kind) {
    case PointerDeviceKind.mouse:
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
  static Iterable<PointerEvent> expand(Iterable<ui.PointerData> data, double devicePixelRatio) sync* {
    for (final ui.PointerData datum in data) {
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
      if (datum.signalKind == null || datum.signalKind == ui.PointerSignalKind.none) {
        switch (datum.change) {
          case ui.PointerChange.add:
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
              embedderId: datum.embedderId,
            );
            break;
          case ui.PointerChange.hover:
            yield PointerHoverEvent(
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
            break;
          case ui.PointerChange.down:
            yield PointerDownEvent(
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
            break;
          case ui.PointerChange.move:
            yield PointerMoveEvent(
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
            break;
          case ui.PointerChange.up:
            yield PointerUpEvent(
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
            break;
          case ui.PointerChange.cancel:
            yield PointerCancelEvent(
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
            break;
          case ui.PointerChange.remove:
            yield PointerRemovedEvent(
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
            break;
        }
      } else {
        switch (datum.signalKind!) {
          case ui.PointerSignalKind.scroll:
            final Offset scrollDelta =
                Offset(datum.scrollDeltaX, datum.scrollDeltaY) / devicePixelRatio;
            yield PointerScrollEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              scrollDelta: scrollDelta,
              embedderId: datum.embedderId,
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

  static double _toLogicalPixels(double physicalPixels, double devicePixelRatio) => physicalPixels / devicePixelRatio;
}
