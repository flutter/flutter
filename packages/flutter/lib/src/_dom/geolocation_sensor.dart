// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'generic_sensor.dart';
import 'hr_time.dart';

@JS('GeolocationSensor')
@staticInterop
class GeolocationSensor implements Sensor {
  external factory GeolocationSensor([GeolocationSensorOptions options]);

  external static JSPromise read([ReadOptions readOptions]);
}

extension GeolocationSensorExtension on GeolocationSensor {
  external num? get latitude;
  external num? get longitude;
  external num? get altitude;
  external num? get accuracy;
  external num? get altitudeAccuracy;
  external num? get heading;
  external num? get speed;
}

@JS()
@staticInterop
@anonymous
class GeolocationSensorOptions implements SensorOptions {
  external factory GeolocationSensorOptions();
}

@JS()
@staticInterop
@anonymous
class ReadOptions implements GeolocationSensorOptions {
  external factory ReadOptions({AbortSignal? signal});
}

extension ReadOptionsExtension on ReadOptions {
  external set signal(AbortSignal? value);
  external AbortSignal? get signal;
}

@JS()
@staticInterop
@anonymous
class GeolocationSensorReading {
  external factory GeolocationSensorReading({
    DOMHighResTimeStamp? timestamp,
    num? latitude,
    num? longitude,
    num? altitude,
    num? accuracy,
    num? altitudeAccuracy,
    num? heading,
    num? speed,
  });
}

extension GeolocationSensorReadingExtension on GeolocationSensorReading {
  external set timestamp(DOMHighResTimeStamp? value);
  external DOMHighResTimeStamp? get timestamp;
  external set latitude(num? value);
  external num? get latitude;
  external set longitude(num? value);
  external num? get longitude;
  external set altitude(num? value);
  external num? get altitude;
  external set accuracy(num? value);
  external num? get accuracy;
  external set altitudeAccuracy(num? value);
  external num? get altitudeAccuracy;
  external set heading(num? value);
  external num? get heading;
  external set speed(num? value);
  external num? get speed;
}

@JS()
@staticInterop
@anonymous
class GeolocationReadingValues {
  external factory GeolocationReadingValues({
    required num? latitude,
    required num? longitude,
    required num? altitude,
    required num? accuracy,
    required num? altitudeAccuracy,
    required num? heading,
    required num? speed,
  });
}

extension GeolocationReadingValuesExtension on GeolocationReadingValues {
  external set latitude(num? value);
  external num? get latitude;
  external set longitude(num? value);
  external num? get longitude;
  external set altitude(num? value);
  external num? get altitude;
  external set accuracy(num? value);
  external num? get accuracy;
  external set altitudeAccuracy(num? value);
  external num? get altitudeAccuracy;
  external set heading(num? value);
  external num? get heading;
  external set speed(num? value);
  external num? get speed;
}
