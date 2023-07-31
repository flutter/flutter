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
  test('Can instantiate IBindCtx.RegisterObjectBound', () {
    expect(bindctx.RegisterObjectBound, isA<Function>());
  });
  test('Can instantiate IBindCtx.RevokeObjectBound', () {
    expect(bindctx.RevokeObjectBound, isA<Function>());
  });
  test('Can instantiate IBindCtx.ReleaseBoundObjects', () {
    expect(bindctx.ReleaseBoundObjects, isA<Function>());
  });
  test('Can instantiate IBindCtx.SetBindOptions', () {
    expect(bindctx.SetBindOptions, isA<Function>());
  });
  test('Can instantiate IBindCtx.GetBindOptions', () {
    expect(bindctx.GetBindOptions, isA<Function>());
  });
  test('Can instantiate IBindCtx.GetRunningObjectTable', () {
    expect(bindctx.GetRunningObjectTable, isA<Function>());
  });
  test('Can instantiate IBindCtx.RegisterObjectParam', () {
    expect(bindctx.RegisterObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.GetObjectParam', () {
    expect(bindctx.GetObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.EnumObjectParam', () {
    expect(bindctx.EnumObjectParam, isA<Function>());
  });
  test('Can instantiate IBindCtx.RevokeObjectParam', () {
    expect(bindctx.RevokeObjectParam, isA<Function>());
  });
  free(ptr);
}
