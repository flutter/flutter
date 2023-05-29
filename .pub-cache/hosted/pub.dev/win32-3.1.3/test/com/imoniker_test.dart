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

  final moniker = IMoniker(ptr);
  test('Can instantiate IMoniker.bindToObject', () {
    expect(moniker.bindToObject, isA<Function>());
  });
  test('Can instantiate IMoniker.bindToStorage', () {
    expect(moniker.bindToStorage, isA<Function>());
  });
  test('Can instantiate IMoniker.reduce', () {
    expect(moniker.reduce, isA<Function>());
  });
  test('Can instantiate IMoniker.composeWith', () {
    expect(moniker.composeWith, isA<Function>());
  });
  test('Can instantiate IMoniker.enum_', () {
    expect(moniker.enum_, isA<Function>());
  });
  test('Can instantiate IMoniker.isEqual', () {
    expect(moniker.isEqual, isA<Function>());
  });
  test('Can instantiate IMoniker.hash', () {
    expect(moniker.hash, isA<Function>());
  });
  test('Can instantiate IMoniker.isRunning', () {
    expect(moniker.isRunning, isA<Function>());
  });
  test('Can instantiate IMoniker.getTimeOfLastChange', () {
    expect(moniker.getTimeOfLastChange, isA<Function>());
  });
  test('Can instantiate IMoniker.inverse', () {
    expect(moniker.inverse, isA<Function>());
  });
  test('Can instantiate IMoniker.commonPrefixWith', () {
    expect(moniker.commonPrefixWith, isA<Function>());
  });
  test('Can instantiate IMoniker.relativePathTo', () {
    expect(moniker.relativePathTo, isA<Function>());
  });
  test('Can instantiate IMoniker.getDisplayName', () {
    expect(moniker.getDisplayName, isA<Function>());
  });
  test('Can instantiate IMoniker.parseDisplayName', () {
    expect(moniker.parseDisplayName, isA<Function>());
  });
  test('Can instantiate IMoniker.isSystemMoniker', () {
    expect(moniker.isSystemMoniker, isA<Function>());
  });
  free(ptr);
}
