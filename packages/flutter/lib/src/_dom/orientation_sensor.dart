// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'generic_sensor.dart';

typedef RotationMatrixType = JSObject;
typedef OrientationSensorLocalCoordinateSystem = String;

@JS('OrientationSensor')
@staticInterop
class OrientationSensor implements Sensor {}

extension OrientationSensorExtension on OrientationSensor {
  external void populateMatrix(RotationMatrixType targetMatrix);
  external JSArray? get quaternion;
}

@JS()
@staticInterop
@anonymous
class OrientationSensorOptions implements SensorOptions {
  external factory OrientationSensorOptions(
      {OrientationSensorLocalCoordinateSystem referenceFrame});
}

extension OrientationSensorOptionsExtension on OrientationSensorOptions {
  external set referenceFrame(OrientationSensorLocalCoordinateSystem value);
  external OrientationSensorLocalCoordinateSystem get referenceFrame;
}

@JS('AbsoluteOrientationSensor')
@staticInterop
class AbsoluteOrientationSensor implements OrientationSensor {
  external factory AbsoluteOrientationSensor(
      [OrientationSensorOptions sensorOptions]);
}

@JS('RelativeOrientationSensor')
@staticInterop
class RelativeOrientationSensor implements OrientationSensor {
  external factory RelativeOrientationSensor(
      [OrientationSensorOptions sensorOptions]);
}

@JS()
@staticInterop
@anonymous
class AbsoluteOrientationReadingValues {
  external factory AbsoluteOrientationReadingValues(
      {required JSArray? quaternion});
}

extension AbsoluteOrientationReadingValuesExtension
    on AbsoluteOrientationReadingValues {
  external set quaternion(JSArray? value);
  external JSArray? get quaternion;
}

@JS()
@staticInterop
@anonymous
class RelativeOrientationReadingValues
    implements AbsoluteOrientationReadingValues {
  external factory RelativeOrientationReadingValues();
}
