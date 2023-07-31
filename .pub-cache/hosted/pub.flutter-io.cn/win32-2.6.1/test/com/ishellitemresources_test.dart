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

  final shellitemresources = IShellItemResources(ptr);
  test('Can instantiate IShellItemResources.GetAttributes', () {
    expect(shellitemresources.GetAttributes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.GetSize', () {
    expect(shellitemresources.GetSize, isA<Function>());
  });
  test('Can instantiate IShellItemResources.GetTimes', () {
    expect(shellitemresources.GetTimes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.SetTimes', () {
    expect(shellitemresources.SetTimes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.GetResourceDescription', () {
    expect(shellitemresources.GetResourceDescription, isA<Function>());
  });
  test('Can instantiate IShellItemResources.EnumResources', () {
    expect(shellitemresources.EnumResources, isA<Function>());
  });
  test('Can instantiate IShellItemResources.SupportsResource', () {
    expect(shellitemresources.SupportsResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.OpenResource', () {
    expect(shellitemresources.OpenResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.CreateResource', () {
    expect(shellitemresources.CreateResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.MarkForDelete', () {
    expect(shellitemresources.MarkForDelete, isA<Function>());
  });
  free(ptr);
}
