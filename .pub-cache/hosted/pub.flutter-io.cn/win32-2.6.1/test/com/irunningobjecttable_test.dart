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
  test('Can instantiate IRunningObjectTable.Register', () {
    expect(runningobjecttable.Register, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.Revoke', () {
    expect(runningobjecttable.Revoke, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.IsRunning', () {
    expect(runningobjecttable.IsRunning, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.GetObject', () {
    expect(runningobjecttable.GetObject, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.NoteChangeTime', () {
    expect(runningobjecttable.NoteChangeTime, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.GetTimeOfLastChange', () {
    expect(runningobjecttable.GetTimeOfLastChange, isA<Function>());
  });
  test('Can instantiate IRunningObjectTable.EnumRunning', () {
    expect(runningobjecttable.EnumRunning, isA<Function>());
  });
  free(ptr);
}
