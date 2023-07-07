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
  test('Can instantiate IShellItemResources.getAttributes', () {
    expect(shellitemresources.getAttributes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.getSize', () {
    expect(shellitemresources.getSize, isA<Function>());
  });
  test('Can instantiate IShellItemResources.getTimes', () {
    expect(shellitemresources.getTimes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.setTimes', () {
    expect(shellitemresources.setTimes, isA<Function>());
  });
  test('Can instantiate IShellItemResources.getResourceDescription', () {
    expect(shellitemresources.getResourceDescription, isA<Function>());
  });
  test('Can instantiate IShellItemResources.enumResources', () {
    expect(shellitemresources.enumResources, isA<Function>());
  });
  test('Can instantiate IShellItemResources.supportsResource', () {
    expect(shellitemresources.supportsResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.openResource', () {
    expect(shellitemresources.openResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.createResource', () {
    expect(shellitemresources.createResource, isA<Function>());
  });
  test('Can instantiate IShellItemResources.markForDelete', () {
    expect(shellitemresources.markForDelete, isA<Function>());
  });
  free(ptr);
}
