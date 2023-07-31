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
  test('Can instantiate IWbemServices.OpenNamespace', () {
    expect(wbemservices.OpenNamespace, isA<Function>());
  });
  test('Can instantiate IWbemServices.CancelAsyncCall', () {
    expect(wbemservices.CancelAsyncCall, isA<Function>());
  });
  test('Can instantiate IWbemServices.QueryObjectSink', () {
    expect(wbemservices.QueryObjectSink, isA<Function>());
  });
  test('Can instantiate IWbemServices.GetObject', () {
    expect(wbemservices.GetObject, isA<Function>());
  });
  test('Can instantiate IWbemServices.GetObjectAsync', () {
    expect(wbemservices.GetObjectAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.PutClass', () {
    expect(wbemservices.PutClass, isA<Function>());
  });
  test('Can instantiate IWbemServices.PutClassAsync', () {
    expect(wbemservices.PutClassAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.DeleteClass', () {
    expect(wbemservices.DeleteClass, isA<Function>());
  });
  test('Can instantiate IWbemServices.DeleteClassAsync', () {
    expect(wbemservices.DeleteClassAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.CreateClassEnum', () {
    expect(wbemservices.CreateClassEnum, isA<Function>());
  });
  test('Can instantiate IWbemServices.CreateClassEnumAsync', () {
    expect(wbemservices.CreateClassEnumAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.PutInstance', () {
    expect(wbemservices.PutInstance, isA<Function>());
  });
  test('Can instantiate IWbemServices.PutInstanceAsync', () {
    expect(wbemservices.PutInstanceAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.DeleteInstance', () {
    expect(wbemservices.DeleteInstance, isA<Function>());
  });
  test('Can instantiate IWbemServices.DeleteInstanceAsync', () {
    expect(wbemservices.DeleteInstanceAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.CreateInstanceEnum', () {
    expect(wbemservices.CreateInstanceEnum, isA<Function>());
  });
  test('Can instantiate IWbemServices.CreateInstanceEnumAsync', () {
    expect(wbemservices.CreateInstanceEnumAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecQuery', () {
    expect(wbemservices.ExecQuery, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecQueryAsync', () {
    expect(wbemservices.ExecQueryAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecNotificationQuery', () {
    expect(wbemservices.ExecNotificationQuery, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecNotificationQueryAsync', () {
    expect(wbemservices.ExecNotificationQueryAsync, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecMethod', () {
    expect(wbemservices.ExecMethod, isA<Function>());
  });
  test('Can instantiate IWbemServices.ExecMethodAsync', () {
    expect(wbemservices.ExecMethodAsync, isA<Function>());
  });
  free(ptr);
}
