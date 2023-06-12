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

  final wbemclassobject = IWbemClassObject(ptr);
  test('Can instantiate IWbemClassObject.getQualifierSet', () {
    expect(wbemclassobject.getQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.get', () {
    expect(wbemclassobject.get, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.put', () {
    expect(wbemclassobject.put, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.delete', () {
    expect(wbemclassobject.delete, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getNames', () {
    expect(wbemclassobject.getNames, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.beginEnumeration', () {
    expect(wbemclassobject.beginEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.next', () {
    expect(wbemclassobject.next, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.endEnumeration', () {
    expect(wbemclassobject.endEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getPropertyQualifierSet', () {
    expect(wbemclassobject.getPropertyQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.clone', () {
    expect(wbemclassobject.clone, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getObjectText', () {
    expect(wbemclassobject.getObjectText, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.spawnDerivedClass', () {
    expect(wbemclassobject.spawnDerivedClass, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.spawnInstance', () {
    expect(wbemclassobject.spawnInstance, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.compareTo', () {
    expect(wbemclassobject.compareTo, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getPropertyOrigin', () {
    expect(wbemclassobject.getPropertyOrigin, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.inheritsFrom', () {
    expect(wbemclassobject.inheritsFrom, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getMethod', () {
    expect(wbemclassobject.getMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.putMethod', () {
    expect(wbemclassobject.putMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.deleteMethod', () {
    expect(wbemclassobject.deleteMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.beginMethodEnumeration', () {
    expect(wbemclassobject.beginMethodEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.nextMethod', () {
    expect(wbemclassobject.nextMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.endMethodEnumeration', () {
    expect(wbemclassobject.endMethodEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getMethodQualifierSet', () {
    expect(wbemclassobject.getMethodQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.getMethodOrigin', () {
    expect(wbemclassobject.getMethodOrigin, isA<Function>());
  });
  free(ptr);
}
