// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal";
import "dart:_wasm";

@patch
final class Pointer<T extends NativeType> {
  @pragma("wasm:entry-point")
  WasmI32 _address;

  @pragma("wasm:prefer-inline")
  Pointer._(this._address);

  @patch
  int get address => _address.toIntUnsigned();

  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  factory Pointer._fromAddressI32(WasmI32 address) => Pointer._(address);
}

@patch
@pragma("wasm:prefer-inline")
Pointer<T> _fromAddress<T extends NativeType>(int address) =>
    Pointer._(WasmI32.fromInt(address));

@patch
@pragma("wasm:prefer-inline")
Pointer<S> _loadPointer<S extends NativeType>(
  Object typedDataBase,
  int offsetInBytes,
) => Pointer<S>.fromAddress(_loadUint32(typedDataBase, offsetInBytes));

@patch
@pragma("wasm:prefer-inline")
void _storePointer<S extends NativeType>(
  Object typedDataBase,
  int offsetInBytes,
  Pointer<S> value,
) => _storeUint32(typedDataBase, offsetInBytes, value._address.toIntUnsigned());

// The following functions are implemented in the method recognizer.
@patch
@pragma("wasm:intrinsic")
external int _loadInt8(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadInt16(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadInt32(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadInt64(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadUint8(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadUint16(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadUint32(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external int _loadUint64(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external double _loadFloat(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external double _loadDouble(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external double _loadFloatUnaligned(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external double _loadDoubleUnaligned(Object typedDataBase, int offsetInBytes);

@patch
@pragma("wasm:intrinsic")
external void _storeInt8(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeInt16(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeInt32(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeInt64(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeUint8(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeUint16(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeUint32(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeUint64(Object typedDataBase, int offsetInBytes, int value);

@patch
@pragma("wasm:intrinsic")
external void _storeFloat(
  Object typedDataBase,
  int offsetInBytes,
  double value,
);

@patch
@pragma("wasm:intrinsic")
external void _storeDouble(
  Object typedDataBase,
  int offsetInBytes,
  double value,
);

@patch
@pragma("wasm:intrinsic")
external void _storeFloatUnaligned(
  Object typedDataBase,
  int offsetInBytes,
  double value,
);

@patch
@pragma("wasm:intrinsic")
external void _storeDoubleUnaligned(
  Object typedDataBase,
  int offsetInBytes,
  double value,
);
