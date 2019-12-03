// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helpers for tests which trigger GC in delicate places.

import 'dart:ffi';

import 'dylib_utils.dart';

typedef NativeNullaryOp = Void Function();
typedef NullaryOpVoid = void Function();

typedef NativeUnaryOp = Void Function(IntPtr);
typedef UnaryOpVoid = void Function(int);

final DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<NativeNullaryOp, NullaryOpVoid>("TriggerGC");

final collectOnNthAllocation = ffiTestFunctions
    .lookupFunction<NativeUnaryOp, UnaryOpVoid>("CollectOnNthAllocation");

extension PointerOffsetBy<T extends NativeType> on Pointer<T> {
  Pointer<T> offsetBy(int bytes) => Pointer.fromAddress(address + bytes);
}
