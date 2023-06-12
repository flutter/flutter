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
  test('Can instantiate IMoniker.BindToObject', () {
    expect(moniker.BindToObject, isA<Function>());
  });
  test('Can instantiate IMoniker.BindToStorage', () {
    expect(moniker.BindToStorage, isA<Function>());
  });
  test('Can instantiate IMoniker.Reduce', () {
    expect(moniker.Reduce, isA<Function>());
  });
  test('Can instantiate IMoniker.ComposeWith', () {
    expect(moniker.ComposeWith, isA<Function>());
  });
  test('Can instantiate IMoniker.Enum', () {
    expect(moniker.Enum, isA<Function>());
  });
  test('Can instantiate IMoniker.IsEqual', () {
    expect(moniker.IsEqual, isA<Function>());
  });
  test('Can instantiate IMoniker.Hash', () {
    expect(moniker.Hash, isA<Function>());
  });
  test('Can instantiate IMoniker.IsRunning', () {
    expect(moniker.IsRunning, isA<Function>());
  });
  test('Can instantiate IMoniker.GetTimeOfLastChange', () {
    expect(moniker.GetTimeOfLastChange, isA<Function>());
  });
  test('Can instantiate IMoniker.Inverse', () {
    expect(moniker.Inverse, isA<Function>());
  });
  test('Can instantiate IMoniker.CommonPrefixWith', () {
    expect(moniker.CommonPrefixWith, isA<Function>());
  });
  test('Can instantiate IMoniker.RelativePathTo', () {
    expect(moniker.RelativePathTo, isA<Function>());
  });
  test('Can instantiate IMoniker.GetDisplayName', () {
    expect(moniker.GetDisplayName, isA<Function>());
  });
  test('Can instantiate IMoniker.ParseDisplayName', () {
    expect(moniker.ParseDisplayName, isA<Function>());
  });
  test('Can instantiate IMoniker.IsSystemMoniker', () {
    expect(moniker.IsSystemMoniker, isA<Function>());
  });
  free(ptr);
}
