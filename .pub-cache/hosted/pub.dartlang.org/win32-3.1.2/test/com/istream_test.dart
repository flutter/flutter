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
  test('Can instantiate IStream.seek', () {
    expect(stream.seek, isA<Function>());
  });
  test('Can instantiate IStream.setSize', () {
    expect(stream.setSize, isA<Function>());
  });
  test('Can instantiate IStream.copyTo', () {
    expect(stream.copyTo, isA<Function>());
  });
  test('Can instantiate IStream.commit', () {
    expect(stream.commit, isA<Function>());
  });
  test('Can instantiate IStream.revert', () {
    expect(stream.revert, isA<Function>());
  });
  test('Can instantiate IStream.lockRegion', () {
    expect(stream.lockRegion, isA<Function>());
  });
  test('Can instantiate IStream.unlockRegion', () {
    expect(stream.unlockRegion, isA<Function>());
  });
  test('Can instantiate IStream.stat', () {
    expect(stream.stat, isA<Function>());
  });
  test('Can instantiate IStream.clone', () {
    expect(stream.clone, isA<Function>());
  });
  free(ptr);
}
