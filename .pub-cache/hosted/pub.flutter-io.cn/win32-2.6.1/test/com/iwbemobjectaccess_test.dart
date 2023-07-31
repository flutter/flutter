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

  final wbemobjectaccess = IWbemObjectAccess(ptr);
  test('Can instantiate IWbemObjectAccess.GetPropertyHandle', () {
    expect(wbemobjectaccess.GetPropertyHandle, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.WritePropertyValue', () {
    expect(wbemobjectaccess.WritePropertyValue, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.ReadPropertyValue', () {
    expect(wbemobjectaccess.ReadPropertyValue, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.ReadDWORD', () {
    expect(wbemobjectaccess.ReadDWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.WriteDWORD', () {
    expect(wbemobjectaccess.WriteDWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.ReadQWORD', () {
    expect(wbemobjectaccess.ReadQWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.WriteQWORD', () {
    expect(wbemobjectaccess.WriteQWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.GetPropertyInfoByHandle', () {
    expect(wbemobjectaccess.GetPropertyInfoByHandle, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.Lock', () {
    expect(wbemobjectaccess.Lock, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.Unlock', () {
    expect(wbemobjectaccess.Unlock, isA<Function>());
  });
  free(ptr);
}
