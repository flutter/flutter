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

  final wbemservices = IWbemServices(ptr);
  test('Can instantiate IWbemServices.openNamespace', () {
    expect(wbemservices.openNamespace, isA<Function>());
  });
  test('Can instantiate IWbemServices.cancelAsyncCall', () {
    expect(wbemservices.cancelAsyncCall, isA<Function>());
  });
  test('Can instantiate IWbemServices.queryObjectSink', () {
    expect(wbemservices.queryObjectSink, isA<Function>());
  });
  test('Can instantiate IWbemServices.getObject', () {
    expect(wbemservices.getObject, isA<Function>());
  });
  test('Can instantiate IWbemServices.getObjectAsync', () {
    expect(wbemservices.getObjectAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.putClass', () {
    expect(wbemservices.putClass, isA<Function>());
  });
  test('Can instantiate IWbemServices.putClassAsync', () {
    expect(wbemservices.putClassAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.deleteClass', () {
    expect(wbemservices.deleteClass, isA<Function>());
  });
  test('Can instantiate IWbemServices.deleteClassAsync', () {
    expect(wbemservices.deleteClassAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.createClassEnum', () {
    expect(wbemservices.createClassEnum, isA<Function>());
  });
  test('Can instantiate IWbemServices.createClassEnumAsync', () {
    expect(wbemservices.createClassEnumAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.putInstance', () {
    expect(wbemservices.putInstance, isA<Function>());
  });
  test('Can instantiate IWbemServices.putInstanceAsync', () {
    expect(wbemservices.putInstanceAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.deleteInstance', () {
    expect(wbemservices.deleteInstance, isA<Function>());
  });
  test('Can instantiate IWbemServices.deleteInstanceAsync', () {
    expect(wbemservices.deleteInstanceAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.createInstanceEnum', () {
    expect(wbemservices.createInstanceEnum, isA<Function>());
  });
  test('Can instantiate IWbemServices.createInstanceEnumAsync', () {
    expect(wbemservices.createInstanceEnumAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.execQuery', () {
    expect(wbemservices.execQuery, isA<Function>());
  });
  test('Can instantiate IWbemServices.execQueryAsync', () {
    expect(wbemservices.execQueryAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.execNotificationQuery', () {
    expect(wbemservices.execNotificationQuery, isA<Function>());
  });
  test('Can instantiate IWbemServices.execNotificationQueryAsync', () {
    expect(wbemservices.execNotificationQueryAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.execMethod', () {
    expect(wbemservices.execMethod, isA<Function>());
  });
  test('Can instantiate IWbemServices.execMethodAsync', () {
    expect(wbemservices.execMethodAsync, isA<Function>());
  });
  free(ptr);
}
