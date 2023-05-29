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

  final spnotifysource = ISpNotifySource(ptr);
  test('Can instantiate ISpNotifySource.setNotifySink', () {
    expect(spnotifysource.setNotifySink, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.setNotifyWindowMessage', () {
    expect(spnotifysource.setNotifyWindowMessage, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.setNotifyCallbackFunction', () {
    expect(spnotifysource.setNotifyCallbackFunction, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.setNotifyCallbackInterface', () {
    expect(spnotifysource.setNotifyCallbackInterface, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.setNotifyWin32Event', () {
    expect(spnotifysource.setNotifyWin32Event, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.waitForNotifyEvent', () {
    expect(spnotifysource.waitForNotifyEvent, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.getNotifyEventHandle', () {
    expect(spnotifysource.getNotifyEventHandle, isA<Function>());
  });
  free(ptr);
}
