// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library input_events.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;
import 'package:mojo/services/input_events/public/interfaces/input_event_constants.mojom.dart' as input_event_constants_mojom;
import 'package:mojo/services/input_events/public/interfaces/input_key_codes.mojom.dart' as input_key_codes_mojom;


class LocationData extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  geometry_mojom.Point inViewLocation = null;
  geometry_mojom.Point screenLocation = null;

  LocationData() : super(kStructSize);

  static LocationData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static LocationData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    LocationData result = new LocationData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.inViewLocation = geometry_mojom.Point.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.screenLocation = geometry_mojom.Point.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(inViewLocation, 8, true);
    
    encoder0.encodeStruct(screenLocation, 16, true);
  }

  String toString() {
    return "LocationData("
           "inViewLocation: $inViewLocation" ", "
           "screenLocation: $screenLocation" ")";
  }
}

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

class TouchData extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int pointerId = 0;

  TouchData() : super(kStructSize);

  static TouchData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TouchData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TouchData result = new TouchData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.pointerId = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(pointerId, 8);
  }

  String toString() {
    return "TouchData("
           "pointerId: $pointerId" ")";
  }
}

class GestureData extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  geometry_mojom.RectF boundingBox = null;
  double scrollX = 0.0;
  double scrollY = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;
  double scale = 0.0;
  bool swipeLeft = false;
  bool swipeRight = false;
  bool swipeUp = false;
  bool swipeDown = false;
  int tapCount = 0;

  GestureData() : super(kStructSize);

  static GestureData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GestureData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GestureData result = new GestureData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.boundingBox = geometry_mojom.RectF.decode(decoder1);
    }
    {
      
      result.scrollX = decoder0.decodeFloat(16);
    }
    {
      
      result.scrollY = decoder0.decodeFloat(20);
    }
    {
      
      result.velocityX = decoder0.decodeFloat(24);
    }
    {
      
      result.velocityY = decoder0.decodeFloat(28);
    }
    {
      
      result.scale = decoder0.decodeFloat(32);
    }
    {
      
      result.swipeLeft = decoder0.decodeBool(36, 0);
    }
    {
      
      result.swipeRight = decoder0.decodeBool(36, 1);
    }
    {
      
      result.swipeUp = decoder0.decodeBool(36, 2);
    }
    {
      
      result.swipeDown = decoder0.decodeBool(36, 3);
    }
    {
      
      result.tapCount = decoder0.decodeInt32(40);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(boundingBox, 8, true);
    
    encoder0.encodeFloat(scrollX, 16);
    
    encoder0.encodeFloat(scrollY, 20);
    
    encoder0.encodeFloat(velocityX, 24);
    
    encoder0.encodeFloat(velocityY, 28);
    
    encoder0.encodeFloat(scale, 32);
    
    encoder0.encodeBool(swipeLeft, 36, 0);
    
    encoder0.encodeBool(swipeRight, 36, 1);
    
    encoder0.encodeBool(swipeUp, 36, 2);
    
    encoder0.encodeBool(swipeDown, 36, 3);
    
    encoder0.encodeInt32(tapCount, 40);
  }

  String toString() {
    return "GestureData("
           "boundingBox: $boundingBox" ", "
           "scrollX: $scrollX" ", "
           "scrollY: $scrollY" ", "
           "velocityX: $velocityX" ", "
           "velocityY: $velocityY" ", "
           "scale: $scale" ", "
           "swipeLeft: $swipeLeft" ", "
           "swipeRight: $swipeRight" ", "
           "swipeUp: $swipeUp" ", "
           "swipeDown: $swipeDown" ", "
           "tapCount: $tapCount" ")";
  }
}

class MouseWheelData extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int xOffset = 0;
  int yOffset = 0;

  MouseWheelData() : super(kStructSize);

  static MouseWheelData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MouseWheelData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MouseWheelData result = new MouseWheelData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.xOffset = decoder0.decodeInt32(8);
    }
    {
      
      result.yOffset = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(xOffset, 8);
    
    encoder0.encodeInt32(yOffset, 12);
  }

  String toString() {
    return "MouseWheelData("
           "xOffset: $xOffset" ", "
           "yOffset: $yOffset" ")";
  }
}

class Event extends bindings.Struct {
  static const int kStructSize = 64;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int action = 0;
  int flags = 0;
  int timeStamp = 0;
  LocationData locationData = null;
  KeyData keyData = null;
  TouchData touchData = null;
  GestureData gestureData = null;
  MouseWheelData wheelData = null;

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
      result.locationData = LocationData.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.keyData = KeyData.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, true);
      result.touchData = TouchData.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, true);
      result.gestureData = GestureData.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(56, true);
      result.wheelData = MouseWheelData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(action, 8);
    
    encoder0.encodeInt32(flags, 12);
    
    encoder0.encodeInt64(timeStamp, 16);
    
    encoder0.encodeStruct(locationData, 24, true);
    
    encoder0.encodeStruct(keyData, 32, true);
    
    encoder0.encodeStruct(touchData, 40, true);
    
    encoder0.encodeStruct(gestureData, 48, true);
    
    encoder0.encodeStruct(wheelData, 56, true);
  }

  String toString() {
    return "Event("
           "action: $action" ", "
           "flags: $flags" ", "
           "timeStamp: $timeStamp" ", "
           "locationData: $locationData" ", "
           "keyData: $keyData" ", "
           "touchData: $touchData" ", "
           "gestureData: $gestureData" ", "
           "wheelData: $wheelData" ")";
  }
}

