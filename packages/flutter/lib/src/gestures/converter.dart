// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show json;
import 'dart:ui' as ui show PointerData, PointerChange, PointerSignalKind, PointerDeviceKind;

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
      return buttons | kPrimaryButton;
    default:
      // We have no information about the device but we know we never want
      // buttons to be 0 when the pointer is down.
      return buttons == 0 ? kPrimaryButton : buttons;
  }
}

/// Converts from engine pointer data to framework pointer events.
///
/// This takes [PointerDataPacket] objects, as received from the engine via
/// [dart:ui.Window.onPointerDataPacket], and converts them to [PointerEvent]
/// objects.
class PointerEventConverter {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  PointerEventConverter._();

  /// Expand the given packet of pointer data into a sequence of framework
  /// pointer events.
  ///
  /// The `devicePixelRatio` argument (usually given the value from
  /// [dart:ui.Window.devicePixelRatio]) is used to convert the incoming data
  /// from physical coordinates to logical pixels. See the discussion at
  /// [PointerEvent] for more details on the [PointerEvent] coordinate space.
  static Iterable<PointerEvent> expand(Iterable<ui.PointerData> data, double devicePixelRatio) sync* {
    for (final ui.PointerData datum in data) {
      final Offset position = Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
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
        switch (datum.signalKind) {
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

  static double _toLogicalPixels(double physicalPixels, double devicePixelRatio) =>
      physicalPixels == null ? null : physicalPixels / devicePixelRatio;
}



/// Serializes [ui.PointerData] to a json object.
///
/// Default values are omitted in the json object.
///
/// See [deserializePointerData].
Map<String, dynamic> serializePointerData(ui.PointerData data) {
      // to perform null check on a variable rather than a getter
  return <String, dynamic>{
    if(data.timeStamp != Duration.zero) 'timeStamp': data.timeStamp.inMicroseconds,
    if(data.change != ui.PointerChange.cancel) 'change': data.change.index,
    if(data.kind != ui.PointerDeviceKind.touch) 'kind': data.kind.index,
    if(data.signalKind != null) 'signalKind': data.signalKind.index,
    if(data.device != 0) 'device': data.device,
    if(data.pointerIdentifier != 0) 'pointerIdentifier': data.pointerIdentifier,
    if(data.physicalX != 0.0) 'physicalX': data.physicalX,
    if(data.physicalY != 0.0) 'physicalY': data.physicalY,
    if(data.physicalDeltaX != 0.0) 'physicalDeltaX': data.physicalDeltaX,
    if(data.physicalDeltaY != 0.0) 'physicalDeltaY': data.physicalDeltaY,
    if(data.buttons != 0) 'buttons': data.buttons,
    if(data.obscured != false) 'obscured': data.obscured,
    if(data.synthesized != false) 'synthesized': data.synthesized,
    if(data.pressure != 0.0) 'pressure': data.pressure,
    if(data.pressureMin != 0.0) 'pressureMin': data.pressureMin,
    if(data.pressureMax != 0.0) 'pressureMax': data.pressureMax,
    if(data.distance != 0.0) 'distance': data.distance,
    if(data.distanceMax != 0.0) 'distanceMax': data.distanceMax,
    if(data.size != 0.0) 'size': data.size,
    if(data.radiusMajor != 0.0) 'radiusMajor': data.radiusMajor,
    if(data.radiusMinor != 0.0) 'radiusMinor': data.radiusMinor,
    if(data.radiusMin != 0.0) 'radiusMin': data.radiusMin,
    if(data.radiusMax != 0.0) 'radiusMax': data.radiusMax,
    if(data.orientation != 0.0) 'orientation': data.orientation,
    if(data.tilt != 0.0) 'tilt': data.tilt,
    if(data.platformData != 0) 'platformData': data.platformData,
    if(data.scrollDeltaX != 0.0) 'scrollDeltaX': data.scrollDeltaX,
    if(data.scrollDeltaY != 0.0) 'scrollDeltaY': data.scrollDeltaY,
  };
}

/// Deserializes [ui.PointerData] from a json object.
///
/// See [serializePointerData].
ui.PointerData deserializePointerData(dynamic value) {
  assert(value is Map<String, dynamic> || value is String);
  final Map<String, dynamic> jsonObject = value is String
    ? json.decode(value) as Map<String, dynamic>
    : value as Map<String, dynamic>;
  return ui.PointerData(
    timeStamp: Duration(microseconds: jsonObject['timeStamp'] as int ?? 0),
    change: ui.PointerChange.values[jsonObject['change'] as int ?? 0],
    kind: ui.PointerDeviceKind.values[jsonObject['kind'] as int ?? 0],
    signalKind: jsonObject.containsKey('signalKind')
      ? ui.PointerSignalKind.values[jsonObject['signalKind'] as int]
      : null,
    device: jsonObject['device'] as int ?? 0,
    pointerIdentifier: jsonObject['pointerIdentifier'] as int ?? 0,
    physicalX: jsonObject['physicalX'] as double ?? 0.0,
    physicalY: jsonObject['physicalY'] as double ?? 0.0,
    physicalDeltaX: jsonObject['physicalDeltaX'] as double ?? 0.0,
    physicalDeltaY: jsonObject['physicalDeltaY'] as double ?? 0.0,
    buttons: jsonObject['buttons'] as int ?? 0,
    obscured: jsonObject['obscured'] as bool ?? false,
    synthesized: jsonObject['synthesized'] as bool ?? false,
    pressure: jsonObject['pressure'] as double ?? 0.0,
    pressureMin: jsonObject['pressureMin'] as double ?? 0.0,
    pressureMax: jsonObject['pressureMax'] as double ?? 0.0,
    distance: jsonObject['distance'] as double ?? 0.0,
    distanceMax: jsonObject['distanceMax'] as double ?? 0.0,
    size: jsonObject['size'] as double ?? 0.0,
    radiusMajor: jsonObject['radiusMajor'] as double ?? 0.0,
    radiusMinor: jsonObject['radiusMinor'] as double ?? 0.0,
    radiusMin: jsonObject['radiusMin'] as double ?? 0.0,
    radiusMax: jsonObject['radiusMax'] as double ?? 0.0,
    orientation: jsonObject['orientation'] as double ?? 0.0,
    tilt: jsonObject['tilt'] as double ?? 0.0,
    platformData: jsonObject['platformData'] as int ?? 0,
    scrollDeltaX: jsonObject['scrollDeltaX'] as double ?? 0.0,
    scrollDeltaY: jsonObject['scrollDeltaY'] as double ?? 0.0,
  );
}


/// A pack of input PointerEvent queue.
///
/// [timeStamp] is used to indicate the time when the pack is received.
///
/// This is a simulation of how the framework is receiving input events from
/// the engine. See [GestureBinding] and [PointerDataPacket].
class PointerEventPack {
  /// Creates a pack of PointerEvents.
  PointerEventPack(this.timeStamp, this.events);

  /// Deserializing a pack of PointerEvents from a json String.
  ///
  /// The `timeOffset` value is subtraced from the timestamps in the json
  /// record.
  ///
  /// See [PointerEvent.fromJson].
  PointerEventPack.fromJson(Map<String, dynamic> jsonObject,
    final double devicePixelRatio, {Duration timeOffset = Duration.zero}) :
    timeStamp = Duration(microseconds: jsonObject['ts'] as int) - timeOffset,
    events = PointerEventConverter.expand(
      <ui.PointerData>[
        for (final dynamic item in jsonObject['events'] as List<dynamic>)
          deserializePointerData(item),
      ],
      devicePixelRatio,
    );

  /// The time stamp of when the event happens
  final Duration timeStamp;

  /// The event.
  final Iterable<PointerEvent> events;
}

/// Deserialize json String to a list of [PointerEventPack]. This
///
/// The json String can be generated from a flutter driver run with
/// [PointerEventRecord].
///
/// The `timeOffset` value is subtraced from the timestamps in the json record.
/// Default value is to make the first event with timestamp [Duration.zero].
List<PointerEventPack> pointerEventPackFromJson(String jsonString,
  final double devicePixelRatio, {Duration timeOffset,}) {
  final List<Map<String, dynamic>> jsonObjects = <Map<String, dynamic>>[
    for (final dynamic item in json.decode(jsonString) as List<dynamic>)
      item as Map<String, dynamic>
  ];
  assert(jsonObjects.isNotEmpty);

  timeOffset ??= Duration(microseconds: jsonObjects[0]['ts'] as int);
  return <PointerEventPack>[
    for (final Map<String, dynamic> jsonObject in jsonObjects)
      PointerEventPack.fromJson(jsonObject, devicePixelRatio,
          timeOffset: timeOffset),
  ];
}
