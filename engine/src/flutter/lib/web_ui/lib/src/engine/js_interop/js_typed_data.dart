// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

@JS()
@staticInterop
class ArrayBuffer {}

@JS()
@staticInterop
class TypedArray {}

extension TypedArrayExtension on TypedArray {
  external void set(JSUint8Array1 source, JSNumber start);
  external JSNumber get length;
}

// Due to some differences between wasm and JS backends, we can't use the
// JSUint8Array object provided by the dart sdk. So for now, we can define this
// as an opaque JS object.
@JS('Uint8Array')
@staticInterop
class JSUint8Array1 extends TypedArray {
  external factory JSUint8Array1._(JSAny bufferOrLength);
}

JSUint8Array1 createUint8ArrayFromBuffer(ArrayBuffer buffer) => JSUint8Array1._(buffer as JSObject);
JSUint8Array1 createUint8ArrayFromLength(int length) => JSUint8Array1._(length.toJS);
