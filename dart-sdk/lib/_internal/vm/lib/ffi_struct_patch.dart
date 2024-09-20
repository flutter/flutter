// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:typed_data';

@pragma("vm:entry-point")
@patch
final class _Compound implements NativeType {}

@pragma("vm:entry-point")
@patch
abstract base class Struct extends _Compound implements SizedNativeType {}

@pragma("vm:entry-point")
@patch
abstract base class Union extends _Compound implements SizedNativeType {}

@pragma("vm:entry-point")
final class _FfiStructLayout {
  @pragma("vm:entry-point")
  final List<Object> fieldTypes;

  @pragma("vm:entry-point")
  final int? packing;

  const _FfiStructLayout(this.fieldTypes, this.packing);
}

@pragma("vm:entry-point")
final class _FfiInlineArray {
  @pragma("vm:entry-point")
  final Type elementType;
  @pragma("vm:entry-point")
  final int length;

  const _FfiInlineArray(this.elementType, this.length);
}
