// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_event.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;

final int EventType_UNKNOWN = 0;
final int EventType_POINTER_CANCEL = EventType_UNKNOWN + 1;
final int EventType_POINTER_DOWN = EventType_POINTER_CANCEL + 1;
final int EventType_POINTER_MOVE = EventType_POINTER_DOWN + 1;
final int EventType_POINTER_UP = EventType_POINTER_MOVE + 1;
final int EventType_GESTURE_FLING_CANCEL = EventType_POINTER_UP + 1;
final int EventType_GESTURE_FLING_START = EventType_GESTURE_FLING_CANCEL + 1;
final int EventType_GESTURE_LONG_PRESS = EventType_GESTURE_FLING_START + 1;
final int EventType_GESTURE_SCROLL_BEGIN = EventType_GESTURE_LONG_PRESS + 1;
final int EventType_GESTURE_SCROLL_END = EventType_GESTURE_SCROLL_BEGIN + 1;
final int EventType_GESTURE_SCROLL_UPDATE = EventType_GESTURE_SCROLL_END + 1;
final int EventType_GESTURE_SHOW_PRESS = EventType_GESTURE_SCROLL_UPDATE + 1;
final int EventType_GESTURE_TAP = EventType_GESTURE_SHOW_PRESS + 1;
final int EventType_GESTURE_TAP_DOWN = EventType_GESTURE_TAP + 1;

final int PointerKind_TOUCH = 0;


class PointerData extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(80, 0)
  ];
  int pointer = 0;
  int kind = 0;
  double x = 0.0;
  double y = 0.0;
  int buttons = 0;
  double pressure = 0.0;
  double pressureMin = 0.0;
  double pressureMax = 0.0;
  double distance = 0.0;
  double distanceMin = 0.0;
  double distanceMax = 0.0;
  double radiusMajor = 0.0;
  double radiusMinor = 0.0;
  double radiusMin = 0.0;
  double radiusMax = 0.0;
  double orientation = 0.0;
  double tilt = 0.0;

  PointerData() : super(kVersions.last.size);

  static PointerData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static PointerData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    PointerData result = new PointerData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.pointer = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.kind = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.x = decoder0.decodeFloat(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.y = decoder0.decodeFloat(20);
    }
    if (mainDataHeader.version >= 0) {
      
      result.buttons = decoder0.decodeInt32(24);
    }
    if (mainDataHeader.version >= 0) {
      
      result.pressure = decoder0.decodeFloat(28);
    }
    if (mainDataHeader.version >= 0) {
      
      result.pressureMin = decoder0.decodeFloat(32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.pressureMax = decoder0.decodeFloat(36);
    }
    if (mainDataHeader.version >= 0) {
      
      result.distance = decoder0.decodeFloat(40);
    }
    if (mainDataHeader.version >= 0) {
      
      result.distanceMin = decoder0.decodeFloat(44);
    }
    if (mainDataHeader.version >= 0) {
      
      result.distanceMax = decoder0.decodeFloat(48);
    }
    if (mainDataHeader.version >= 0) {
      
      result.radiusMajor = decoder0.decodeFloat(52);
    }
    if (mainDataHeader.version >= 0) {
      
      result.radiusMinor = decoder0.decodeFloat(56);
    }
    if (mainDataHeader.version >= 0) {
      
      result.radiusMin = decoder0.decodeFloat(60);
    }
    if (mainDataHeader.version >= 0) {
      
      result.radiusMax = decoder0.decodeFloat(64);
    }
    if (mainDataHeader.version >= 0) {
      
      result.orientation = decoder0.decodeFloat(68);
    }
    if (mainDataHeader.version >= 0) {
      
      result.tilt = decoder0.decodeFloat(72);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(pointer, 8);
    
    encoder0.encodeInt32(kind, 12);
    
    encoder0.encodeFloat(x, 16);
    
    encoder0.encodeFloat(y, 20);
    
    encoder0.encodeInt32(buttons, 24);
    
    encoder0.encodeFloat(pressure, 28);
    
    encoder0.encodeFloat(pressureMin, 32);
    
    encoder0.encodeFloat(pressureMax, 36);
    
    encoder0.encodeFloat(distance, 40);
    
    encoder0.encodeFloat(distanceMin, 44);
    
    encoder0.encodeFloat(distanceMax, 48);
    
    encoder0.encodeFloat(radiusMajor, 52);
    
    encoder0.encodeFloat(radiusMinor, 56);
    
    encoder0.encodeFloat(radiusMin, 60);
    
    encoder0.encodeFloat(radiusMax, 64);
    
    encoder0.encodeFloat(orientation, 68);
    
    encoder0.encodeFloat(tilt, 72);
  }

  String toString() {
    return "PointerData("
           "pointer: $pointer" ", "
           "kind: $kind" ", "
           "x: $x" ", "
           "y: $y" ", "
           "buttons: $buttons" ", "
           "pressure: $pressure" ", "
           "pressureMin: $pressureMin" ", "
           "pressureMax: $pressureMax" ", "
           "distance: $distance" ", "
           "distanceMin: $distanceMin" ", "
           "distanceMax: $distanceMax" ", "
           "radiusMajor: $radiusMajor" ", "
           "radiusMinor: $radiusMinor" ", "
           "radiusMin: $radiusMin" ", "
           "radiusMax: $radiusMax" ", "
           "orientation: $orientation" ", "
           "tilt: $tilt" ")";
  }
}

class GestureData extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int primaryPointer = 0;
  double x = 0.0;
  double y = 0.0;
  double dx = 0.0;
  double dy = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;

  GestureData() : super(kVersions.last.size);

  static GestureData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GestureData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GestureData result = new GestureData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.primaryPointer = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.x = decoder0.decodeFloat(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.y = decoder0.decodeFloat(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.dx = decoder0.decodeFloat(20);
    }
    if (mainDataHeader.version >= 0) {
      
      result.dy = decoder0.decodeFloat(24);
    }
    if (mainDataHeader.version >= 0) {
      
      result.velocityX = decoder0.decodeFloat(28);
    }
    if (mainDataHeader.version >= 0) {
      
      result.velocityY = decoder0.decodeFloat(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(primaryPointer, 8);
    
    encoder0.encodeFloat(x, 12);
    
    encoder0.encodeFloat(y, 16);
    
    encoder0.encodeFloat(dx, 20);
    
    encoder0.encodeFloat(dy, 24);
    
    encoder0.encodeFloat(velocityX, 28);
    
    encoder0.encodeFloat(velocityY, 32);
  }

  String toString() {
    return "GestureData("
           "primaryPointer: $primaryPointer" ", "
           "x: $x" ", "
           "y: $y" ", "
           "dx: $dx" ", "
           "dy: $dy" ", "
           "velocityX: $velocityX" ", "
           "velocityY: $velocityY" ")";
  }
}

class InputEvent extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int type = 0;
  int timeStamp = 0;
  PointerData pointerData = null;
  GestureData gestureData = null;

  InputEvent() : super(kVersions.last.size);

  static InputEvent deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static InputEvent decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    InputEvent result = new InputEvent();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.type = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.timeStamp = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.pointerData = PointerData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.gestureData = GestureData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(type, 8);
    
    encoder0.encodeInt64(timeStamp, 16);
    
    encoder0.encodeStruct(pointerData, 24, true);
    
    encoder0.encodeStruct(gestureData, 32, true);
  }

  String toString() {
    return "InputEvent("
           "type: $type" ", "
           "timeStamp: $timeStamp" ", "
           "pointerData: $pointerData" ", "
           "gestureData: $gestureData" ")";
  }
}

