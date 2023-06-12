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

  final shellitemarray = IShellItemArray(ptr);
  test('Can instantiate IShellItemArray.BindToHandler', () {
    expect(shellitemarray.BindToHandler, isA<Function>());
  });
  test('Can instantiate IShellItemArray.GetPropertyStore', () {
    expect(shellitemarray.GetPropertyStore, isA<Function>());
  });
  test('Can instantiate IShellItemArray.GetPropertyDescriptionList', () {
    expect(shellitemarray.GetPropertyDescriptionList, isA<Function>());
  });
  test('Can instantiate IShellItemArray.GetAttributes', () {
    expect(shellitemarray.GetAttributes, isA<Function>());
  });
  test('Can instantiate IShellItemArray.GetCount', () {
    expect(shellitemarray.GetCount, isA<Function>());
  });
  test('Can instantiate IShellItemArray.GetItemAt', () {
    expect(shellitemarray.GetItemAt, isA<Function>());
  });
  test('Can instantiate IShellItemArray.EnumItems', () {
    expect(shellitemarray.EnumItems, isA<Function>());
  });
  free(ptr);
}
