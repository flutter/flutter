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

  final shellitem2 = IShellItem2(ptr);
  test('Can instantiate IShellItem2.getPropertyStore', () {
    expect(shellitem2.getPropertyStore, isA<Function>());
  });
  test('Can instantiate IShellItem2.getPropertyStoreWithCreateObject', () {
    expect(shellitem2.getPropertyStoreWithCreateObject, isA<Function>());
  });
  test('Can instantiate IShellItem2.getPropertyStoreForKeys', () {
    expect(shellitem2.getPropertyStoreForKeys, isA<Function>());
  });
  test('Can instantiate IShellItem2.getPropertyDescriptionList', () {
    expect(shellitem2.getPropertyDescriptionList, isA<Function>());
  });
  test('Can instantiate IShellItem2.update', () {
    expect(shellitem2.update, isA<Function>());
  });
  test('Can instantiate IShellItem2.getProperty', () {
    expect(shellitem2.getProperty, isA<Function>());
  });
  test('Can instantiate IShellItem2.getCLSID', () {
    expect(shellitem2.getCLSID, isA<Function>());
  });
  test('Can instantiate IShellItem2.getFileTime', () {
    expect(shellitem2.getFileTime, isA<Function>());
  });
  test('Can instantiate IShellItem2.getInt32', () {
    expect(shellitem2.getInt32, isA<Function>());
  });
  test('Can instantiate IShellItem2.getString', () {
    expect(shellitem2.getString, isA<Function>());
  });
  test('Can instantiate IShellItem2.getUInt32', () {
    expect(shellitem2.getUInt32, isA<Function>());
  });
  test('Can instantiate IShellItem2.getUInt64', () {
    expect(shellitem2.getUInt64, isA<Function>());
  });
  test('Can instantiate IShellItem2.getBool', () {
    expect(shellitem2.getBool, isA<Function>());
  });
  free(ptr);
}
