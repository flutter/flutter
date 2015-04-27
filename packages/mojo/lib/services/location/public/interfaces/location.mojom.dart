// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library location.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class Location extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(64, 0)
  ];
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

  Location() : super(kVersions.last.size);

  static Location deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Location decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Location result = new Location();

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
      
      result.time = decoder0.decodeUint64(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.hasElapsedRealTimeNanos = decoder0.decodeBool(16, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      result.hasAltitude = decoder0.decodeBool(16, 1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.hasSpeed = decoder0.decodeBool(16, 2);
    }
    if (mainDataHeader.version >= 0) {
      
      result.hasBearing = decoder0.decodeBool(16, 3);
    }
    if (mainDataHeader.version >= 0) {
      
      result.hasAccuracy = decoder0.decodeBool(16, 4);
    }
    if (mainDataHeader.version >= 0) {
      
      result.speed = decoder0.decodeFloat(20);
    }
    if (mainDataHeader.version >= 0) {
      
      result.elapsedRealTimeNanos = decoder0.decodeUint64(24);
    }
    if (mainDataHeader.version >= 0) {
      
      result.latitude = decoder0.decodeDouble(32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.longitude = decoder0.decodeDouble(40);
    }
    if (mainDataHeader.version >= 0) {
      
      result.altitude = decoder0.decodeDouble(48);
    }
    if (mainDataHeader.version >= 0) {
      
      result.bearing = decoder0.decodeFloat(56);
    }
    if (mainDataHeader.version >= 0) {
      
      result.accuracy = decoder0.decodeFloat(60);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
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

