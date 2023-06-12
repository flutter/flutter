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
  test('Can instantiate IWbemObjectAccess.getPropertyHandle', () {
    expect(wbemobjectaccess.getPropertyHandle, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.writePropertyValue', () {
    expect(wbemobjectaccess.writePropertyValue, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.readPropertyValue', () {
    expect(wbemobjectaccess.readPropertyValue, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.readDWORD', () {
    expect(wbemobjectaccess.readDWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.writeDWORD', () {
    expect(wbemobjectaccess.writeDWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.readQWORD', () {
    expect(wbemobjectaccess.readQWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.writeQWORD', () {
    expect(wbemobjectaccess.writeQWORD, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.getPropertyInfoByHandle', () {
    expect(wbemobjectaccess.getPropertyInfoByHandle, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.lock', () {
    expect(wbemobjectaccess.lock, isA<Function>());
  });
  test('Can instantiate IWbemObjectAccess.unlock', () {
    expect(wbemobjectaccess.unlock, isA<Function>());
  });
  free(ptr);
}
