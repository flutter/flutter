// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Win32 API prototypes can be successfully loaded (i.e. that
// lookupFunction works for all the APIs generated)

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_local_variable

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:win32/win32.dart';

void main() {
  final ptr = calloc<COMObject>();

  final sensor = ISensor(ptr);
  test('Can instantiate ISensor.getID', () {
    expect(sensor.getID, isA<Function>());
  });
  test('Can instantiate ISensor.getCategory', () {
    expect(sensor.getCategory, isA<Function>());
  });
  test('Can instantiate ISensor.getType', () {
    expect(sensor.getType, isA<Function>());
  });
  test('Can instantiate ISensor.getFriendlyName', () {
    expect(sensor.getFriendlyName, isA<Function>());
  });
  test('Can instantiate ISensor.getProperty', () {
    expect(sensor.getProperty, isA<Function>());
  });
  test('Can instantiate ISensor.getProperties', () {
    expect(sensor.getProperties, isA<Function>());
  });
  test('Can instantiate ISensor.getSupportedDataFields', () {
    expect(sensor.getSupportedDataFields, isA<Function>());
  });
  test('Can instantiate ISensor.setProperties', () {
    expect(sensor.setProperties, isA<Function>());
  });
  test('Can instantiate ISensor.supportsDataField', () {
    expect(sensor.supportsDataField, isA<Function>());
  });
  test('Can instantiate ISensor.getState', () {
    expect(sensor.getState, isA<Function>());
  });
  test('Can instantiate ISensor.getData', () {
    expect(sensor.getData, isA<Function>());
  });
  test('Can instantiate ISensor.supportsEvent', () {
    expect(sensor.supportsEvent, isA<Function>());
  });
  test('Can instantiate ISensor.getEventInterest', () {
    expect(sensor.getEventInterest, isA<Function>());
  });
  test('Can instantiate ISensor.setEventInterest', () {
    expect(sensor.setEventInterest, isA<Function>());
  });
  test('Can instantiate ISensor.setEventSink', () {
    expect(sensor.setEventSink, isA<Function>());
  });
  free(ptr);
}
