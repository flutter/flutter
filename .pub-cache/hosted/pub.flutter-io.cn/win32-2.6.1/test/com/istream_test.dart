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

  final stream = IStream(ptr);
  test('Can instantiate IStream.Seek', () {
    expect(stream.Seek, isA<Function>());
  });
  test('Can instantiate IStream.SetSize', () {
    expect(stream.SetSize, isA<Function>());
  });
  test('Can instantiate IStream.CopyTo', () {
    expect(stream.CopyTo, isA<Function>());
  });
  test('Can instantiate IStream.Commit', () {
    expect(stream.Commit, isA<Function>());
  });
  test('Can instantiate IStream.Revert', () {
    expect(stream.Revert, isA<Function>());
  });
  test('Can instantiate IStream.LockRegion', () {
    expect(stream.LockRegion, isA<Function>());
  });
  test('Can instantiate IStream.UnlockRegion', () {
    expect(stream.UnlockRegion, isA<Function>());
  });
  test('Can instantiate IStream.Stat', () {
    expect(stream.Stat, isA<Function>());
  });
  test('Can instantiate IStream.Clone', () {
    expect(stream.Clone, isA<Function>());
  });
  free(ptr);
}
