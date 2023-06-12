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
  test('Can instantiate IWbemClassObject.GetQualifierSet', () {
    expect(wbemclassobject.GetQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.Get', () {
    expect(wbemclassobject.Get, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.Put', () {
    expect(wbemclassobject.Put, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.Delete', () {
    expect(wbemclassobject.Delete, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetNames', () {
    expect(wbemclassobject.GetNames, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.BeginEnumeration', () {
    expect(wbemclassobject.BeginEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.Next', () {
    expect(wbemclassobject.Next, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.EndEnumeration', () {
    expect(wbemclassobject.EndEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetPropertyQualifierSet', () {
    expect(wbemclassobject.GetPropertyQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.Clone', () {
    expect(wbemclassobject.Clone, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetObjectText', () {
    expect(wbemclassobject.GetObjectText, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.SpawnDerivedClass', () {
    expect(wbemclassobject.SpawnDerivedClass, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.SpawnInstance', () {
    expect(wbemclassobject.SpawnInstance, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.CompareTo', () {
    expect(wbemclassobject.CompareTo, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetPropertyOrigin', () {
    expect(wbemclassobject.GetPropertyOrigin, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.InheritsFrom', () {
    expect(wbemclassobject.InheritsFrom, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetMethod', () {
    expect(wbemclassobject.GetMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.PutMethod', () {
    expect(wbemclassobject.PutMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.DeleteMethod', () {
    expect(wbemclassobject.DeleteMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.BeginMethodEnumeration', () {
    expect(wbemclassobject.BeginMethodEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.NextMethod', () {
    expect(wbemclassobject.NextMethod, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.EndMethodEnumeration', () {
    expect(wbemclassobject.EndMethodEnumeration, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetMethodQualifierSet', () {
    expect(wbemclassobject.GetMethodQualifierSet, isA<Function>());
  });
  test('Can instantiate IWbemClassObject.GetMethodOrigin', () {
    expect(wbemclassobject.GetMethodOrigin, isA<Function>());
  });
  free(ptr);
}
