// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_string' show JSStringImpl;
import 'dart:_wasm';
import 'dart:typed_data';

@patch
@pragma('wasm:prefer-inline')
JSStringImpl jsStringFromDartString(String s) => unsafeCast<JSStringImpl>(s);

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint8ArrayFromDartUint8List(Uint8List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt8ArrayFromDartInt8List(Int8List l) => throw UnsupportedError(
  'In JS compatibility mode we only support JS typed data implementations.',
);

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint8ClampedArrayFromDartUint8ClampedList(Uint8ClampedList l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt16ArrayFromDartInt16List(Int16List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint16ArrayFromDartUint16List(Uint16List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt32ArrayFromDartInt32List(Int32List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint32ArrayFromDartUint32List(Uint32List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat32ArrayFromDartFloat32List(Float32List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat64ArrayFromDartFloat64List(Float64List l) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsDataViewFromDartByteData(ByteData data, int length) =>
    throw UnsupportedError(
      'In JS compatibility mode we only support JS typed data implementations.',
    );
