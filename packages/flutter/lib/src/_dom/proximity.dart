// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'generic_sensor.dart';

@JS('ProximitySensor')
@staticInterop
class ProximitySensor implements Sensor {
  external factory ProximitySensor([SensorOptions sensorOptions]);
}

extension ProximitySensorExtension on ProximitySensor {
  external num? get distance;
  external num? get max;
  external bool? get near;
}

@JS()
@staticInterop
@anonymous
class ProximityReadingValues {
  external factory ProximityReadingValues({
    required num? distance,
    required num? max,
    required bool? near,
  });
}

extension ProximityReadingValuesExtension on ProximityReadingValues {
  external set distance(num? value);
  external num? get distance;
  external set max(num? value);
  external num? get max;
  external set near(bool? value);
  external bool? get near;
}
