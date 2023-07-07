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

  final fileisinuse = IFileIsInUse(ptr);
  test('Can instantiate IFileIsInUse.getAppName', () {
    expect(fileisinuse.getAppName, isA<Function>());
  });
  test('Can instantiate IFileIsInUse.getUsage', () {
    expect(fileisinuse.getUsage, isA<Function>());
  });
  test('Can instantiate IFileIsInUse.getCapabilities', () {
    expect(fileisinuse.getCapabilities, isA<Function>());
  });
  test('Can instantiate IFileIsInUse.getSwitchToHWND', () {
    expect(fileisinuse.getSwitchToHWND, isA<Function>());
  });
  test('Can instantiate IFileIsInUse.closeFile', () {
    expect(fileisinuse.closeFile, isA<Function>());
  });
  free(ptr);
}
