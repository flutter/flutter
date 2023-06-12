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

  final bindctx = IBindCtx(ptr);
  test('Can instantiate IBindCtx.registerObjectBound', () {
    expect(bindctx.registerObjectBound, isA<Function>());
  });
  test('Can instantiate IBindCtx.revokeObjectBound', () {
    expect(bindctx.revokeObjectBound, isA<Function>());
  });
  test('Can instantiate IBindCtx.releaseBoundObjects', () {
    expect(bindctx.releaseBoundObjects, isA<Function>());
  });
  test('Can instantiate IBindCtx.setBindOptions', () {
    expect(bindctx.setBindOptions, isA<Function>());
  });
  test('Can instantiate IBindCtx.getBindOptions', () {
    expect(bindctx.getBindOptions, isA<Function>());
  });
  test('Can instantiate IBindCtx.getRunningObjectTable', () {
    expect(bindctx.getRunningObjectTable, isA<Function>());
  });
  test('Can instantiate IBindCtx.registerObjectParam', () {
    expect(bindctx.registerObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.getObjectParam', () {
    expect(bindctx.getObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.enumObjectParam', () {
    expect(bindctx.enumObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.revokeObjectParam', () {
    expect(bindctx.revokeObjectParam, isA<Function>());
  });
  free(ptr);
}
