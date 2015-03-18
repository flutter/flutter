// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library location.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class Location extends bindings.Struct {
  static const int kStructSize = 64;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int time = 0;
  bool hasElapsedRealTimeNanos = false;
  bool hasAltitude = false;
  bool hasSpeed = false;
  bool hasBearing = false;
  bool hasAccuracy = false;
  double speed = 0.0;
  int elapsedRealTimeNanos = 0;
  double latitude = 0.0;
  double longitude = 0.0;
  double altitude = 0.0;
  double bearing = 0.0;
  double accuracy = 0.0;

  Location() : super(kStructSize);

  static Location deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Location decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Location result = new Location();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.time = decoder0.decodeUint64(8);
    }
    {
      
      result.hasElapsedRealTimeNanos = decoder0.decodeBool(16, 0);
    }
    {
      
      result.hasAltitude = decoder0.decodeBool(16, 1);
    }
    {
      
      result.hasSpeed = decoder0.decodeBool(16, 2);
    }
    {
      
      result.hasBearing = decoder0.decodeBool(16, 3);
    }
    {
      
      result.hasAccuracy = decoder0.decodeBool(16, 4);
    }
    {
      
      result.speed = decoder0.decodeFloat(20);
    }
    {
      
      result.elapsedRealTimeNanos = decoder0.decodeUint64(24);
    }
    {
      
      result.latitude = decoder0.decodeDouble(32);
    }
    {
      
      result.longitude = decoder0.decodeDouble(40);
    }
    {
      
      result.altitude = decoder0.decodeDouble(48);
    }
    {
      
      result.bearing = decoder0.decodeFloat(56);
    }
    {
      
      result.accuracy = decoder0.decodeFloat(60);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint64(time, 8);
    
    encoder0.encodeBool(hasElapsedRealTimeNanos, 16, 0);
    
    encoder0.encodeBool(hasAltitude, 16, 1);
    
    encoder0.encodeBool(hasSpeed, 16, 2);
    
    encoder0.encodeBool(hasBearing, 16, 3);
    
    encoder0.encodeBool(hasAccuracy, 16, 4);
    
    encoder0.encodeFloat(speed, 20);
    
    encoder0.encodeUint64(elapsedRealTimeNanos, 24);
    
    encoder0.encodeDouble(latitude, 32);
    
    encoder0.encodeDouble(longitude, 40);
    
    encoder0.encodeDouble(altitude, 48);
    
    encoder0.encodeFloat(bearing, 56);
    
    encoder0.encodeFloat(accuracy, 60);
  }

  String toString() {
    return "Location("
           "time: $time" ", "
           "hasElapsedRealTimeNanos: $hasElapsedRealTimeNanos" ", "
           "hasAltitude: $hasAltitude" ", "
           "hasSpeed: $hasSpeed" ", "
           "hasBearing: $hasBearing" ", "
           "hasAccuracy: $hasAccuracy" ", "
           "speed: $speed" ", "
           "elapsedRealTimeNanos: $elapsedRealTimeNanos" ", "
           "latitude: $latitude" ", "
           "longitude: $longitude" ", "
           "altitude: $altitude" ", "
           "bearing: $bearing" ", "
           "accuracy: $accuracy" ")";
  }
}

