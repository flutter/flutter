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

  final runningobjecttable = IRunningObjectTable(ptr);
  test('Can instantiate IRunningObjectTable.register', () {
    expect(runningobjecttable.register, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.revoke', () {
    expect(runningobjecttable.revoke, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.isRunning', () {
    expect(runningobjecttable.isRunning, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.getObject', () {
    expect(runningobjecttable.getObject, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.noteChangeTime', () {
    expect(runningobjecttable.noteChangeTime, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.getTimeOfLastChange', () {
    expect(runningobjecttable.getTimeOfLastChange, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.enumRunning', () {
    expect(runningobjecttable.enumRunning, isA<Function>());
  });
  free(ptr);
}
