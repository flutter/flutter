// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_events.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;
import 'package:mojo/services/input_events/public/interfaces/input_event_constants.mojom.dart' as input_event_constants_mojom;
import 'package:mojo/services/input_events/public/interfaces/input_key_codes.mojom.dart' as input_key_codes_mojom;


class KeyData extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int keyCode = 0;
  bool isChar = false;
  int character = 0;
  int windowsKeyCode = 0;
  int nativeKeyCode = 0;
  int text = 0;
  int unmodifiedText = 0;

  KeyData() : super(kStructSize);

  static KeyData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyData result = new KeyData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.keyCode = decoder0.decodeInt32(8);
    }
    {
      
      result.isChar = decoder0.decodeBool(12, 0);
    }
    {
      
      result.character = decoder0.decodeUint16(14);
    }
    {
      
      result.windowsKeyCode = decoder0.decodeInt32(16);
    }
    {
      
      result.nativeKeyCode = decoder0.decodeInt32(20);
    }
    {
      
      result.text = decoder0.decodeUint16(24);
    }
    {
      
      result.unmodifiedText = decoder0.decodeUint16(26);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(keyCode, 8);
    
    encoder0.encodeBool(isChar, 12, 0);
    
    encoder0.encodeUint16(character, 14);
    
    encoder0.encodeInt32(windowsKeyCode, 16);
    
    encoder0.encodeInt32(nativeKeyCode, 20);
    
    encoder0.encodeUint16(text, 24);
    
    encoder0.encodeUint16(unmodifiedText, 26);
  }

  String toString() {
    return "KeyData("
           "keyCode: $keyCode" ", "
           "isChar: $isChar" ", "
           "character: $character" ", "
           "windowsKeyCode: $windowsKeyCode" ", "
           "nativeKeyCode: $nativeKeyCode" ", "
           "text: $text" ", "
           "unmodifiedText: $unmodifiedText" ")";
  }
}

class PointerData extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int pointerId = 0;
  int kind = 0;
  double x = 0.0;
  double y = 0.0;
  double screenX = 0.0;
  double screenY = 0.0;
  double pressure = 0.0;
  double radiusMajor = 0.0;
  double radiusMinor = 0.0;
  double orientation = 0.0;
  double horizontalWheel = 0.0;
  double verticalWheel = 0.0;

  PointerData() : super(kStructSize);

  static PointerData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static PointerData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    PointerData result = new PointerData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.pointerId = decoder0.decodeInt32(8);
    }
    {
      
      result.kind = decoder0.decodeInt32(12);
    }
    {
      
      result.x = decoder0.decodeFloat(16);
    }
    {
      
      result.y = decoder0.decodeFloat(20);
    }
    {
      
      result.screenX = decoder0.decodeFloat(24);
    }
    {
      
      result.screenY = decoder0.decodeFloat(28);
    }
    {
      
      result.pressure = decoder0.decodeFloat(32);
    }
    {
      
      result.radiusMajor = decoder0.decodeFloat(36);
    }
    {
      
      result.radiusMinor = decoder0.decodeFloat(40);
    }
    {
      
      result.orientation = decoder0.decodeFloat(44);
    }
    {
      
      result.horizontalWheel = decoder0.decodeFloat(48);
    }
    {
      
      result.verticalWheel = decoder0.decodeFloat(52);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(pointerId, 8);
    
    encoder0.encodeInt32(kind, 12);
    
    encoder0.encodeFloat(x, 16);
    
    encoder0.encodeFloat(y, 20);
    
    encoder0.encodeFloat(screenX, 24);
    
    encoder0.encodeFloat(screenY, 28);
    
    encoder0.encodeFloat(pressure, 32);
    
    encoder0.encodeFloat(radiusMajor, 36);
    
    encoder0.encodeFloat(radiusMinor, 40);
    
    encoder0.encodeFloat(orientation, 44);
    
    encoder0.encodeFloat(horizontalWheel, 48);
    
    encoder0.encodeFloat(verticalWheel, 52);
  }

  String toString() {
    return "PointerData("
           "pointerId: $pointerId" ", "
           "kind: $kind" ", "
           "x: $x" ", "
           "y: $y" ", "
           "screenX: $screenX" ", "
           "screenY: $screenY" ", "
           "pressure: $pressure" ", "
           "radiusMajor: $radiusMajor" ", "
           "radiusMinor: $radiusMinor" ", "
           "orientation: $orientation" ", "
           "horizontalWheel: $horizontalWheel" ", "
           "verticalWheel: $verticalWheel" ")";
  }
}

class Event extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int action = 0;
  int flags = 0;
  int timeStamp = 0;
  KeyData keyData = null;
  PointerData pointerData = null;

  Event() : super(kStructSize);

  static Event deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Event decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Event result = new Event();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.action = decoder0.decodeInt32(8);
    }
    {
      
      result.flags = decoder0.decodeInt32(12);
    }
    {
      
      result.timeStamp = decoder0.decodeInt64(16);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.keyData = KeyData.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.pointerData = PointerData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(action, 8);
    
    encoder0.encodeInt32(flags, 12);
    
    encoder0.encodeInt64(timeStamp, 16);
    
    encoder0.encodeStruct(keyData, 24, true);
    
    encoder0.encodeStruct(pointerData, 32, true);
  }

  String toString() {
    return "Event("
           "action: $action" ", "
           "flags: $flags" ", "
           "timeStamp: $timeStamp" ", "
           "keyData: $keyData" ", "
           "pointerData: $pointerData" ")";
  }
}

