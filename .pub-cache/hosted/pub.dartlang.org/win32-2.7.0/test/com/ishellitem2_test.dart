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
  test('Can instantiate IShellItem2.GetPropertyStore', () {
    expect(shellitem2.GetPropertyStore, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetPropertyStoreWithCreateObject', () {
    expect(shellitem2.GetPropertyStoreWithCreateObject, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetPropertyStoreForKeys', () {
    expect(shellitem2.GetPropertyStoreForKeys, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetPropertyDescriptionList', () {
    expect(shellitem2.GetPropertyDescriptionList, isA<Function>());
  });
  test('Can instantiate IShellItem2.Update', () {
    expect(shellitem2.Update, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetProperty', () {
    expect(shellitem2.GetProperty, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetCLSID', () {
    expect(shellitem2.GetCLSID, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetFileTime', () {
    expect(shellitem2.GetFileTime, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetInt32', () {
    expect(shellitem2.GetInt32, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetString', () {
    expect(shellitem2.GetString, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetUInt32', () {
    expect(shellitem2.GetUInt32, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetUInt64', () {
    expect(shellitem2.GetUInt64, isA<Function>());
  });
  test('Can instantiate IShellItem2.GetBool', () {
    expect(shellitem2.GetBool, isA<Function>());
  });
  free(ptr);
}
