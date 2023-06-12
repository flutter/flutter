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
  test('Can instantiate ISpNotifySource.SetNotifySink', () {
    expect(spnotifysource.SetNotifySink, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.SetNotifyWindowMessage', () {
    expect(spnotifysource.SetNotifyWindowMessage, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.SetNotifyCallbackFunction', () {
    expect(spnotifysource.SetNotifyCallbackFunction, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.SetNotifyCallbackInterface', () {
    expect(spnotifysource.SetNotifyCallbackInterface, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.SetNotifyWin32Event', () {
    expect(spnotifysource.SetNotifyWin32Event, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.WaitForNotifyEvent', () {
    expect(spnotifysource.WaitForNotifyEvent, isA<Function>());
  });
  test('Can instantiate ISpNotifySource.GetNotifyEventHandle', () {
    expect(spnotifysource.GetNotifyEventHandle, isA<Function>());
  });
  free(ptr);
}
