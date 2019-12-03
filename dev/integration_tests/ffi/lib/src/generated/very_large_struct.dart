// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Large sample struct for dart:ffi library.
class VeryLargeStruct extends Struct {
  @Int8()
  int a;

  @Int16()
  int b;

  @Int32()
  int c;

  @Int64()
  int d;

  @Uint8()
  int e;

  @Uint16()
  int f;

  @Uint32()
  int g;

  @Uint64()
  int h;

  @IntPtr()
  int i;

  @Double()
  double j;

  @Float()
  double k;

  Pointer<VeryLargeStruct> parent;

  @IntPtr()
  int numChildren;

  Pointer<VeryLargeStruct> children;

  @Int8()
  int smallLastField;
}
