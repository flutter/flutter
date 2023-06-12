// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of retrieving a sensor using the Sensor API.

// C++ implementation can be found here:
// https://docs.microsoft.com/en-us/windows/win32/sensorsapi/retrieving-a-sensor

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

  final sensorManager = SensorManager.createInstance();

  // Replace this with the sensor category you're looking for.
  final sampleDateTimeSensorCategory =
      GUIDFromString('{062A5C3B-44C1-4ad1-8EFC-0F65B2E4AD48}');
  final pSensorsColl = calloc<Pointer<COMObject>>();
  final hr = sensorManager.getSensorsByCategory(
      sampleDateTimeSensorCategory, pSensorsColl);
  if (FAILED(hr)) throw WindowsException(hr);

  final coll = ISensorCollection(pSensorsColl.cast());
  final pCount = calloc<Uint32>();
  if (coll.getCount(pCount) > 1) {
    print('Found items');
  }

  free(pCount);
  free(pSensorsColl);
  free(sampleDateTimeSensorCategory);

  CoUninitialize();
}
