// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

// Some APIs we need on typed arrays that are not exposed by the dart sdk yet
extension TypedArrayExtension on JSTypedArray {
  external JSTypedArray slice(int start, int end);
  external void set(JSTypedArray source, int start);
  external int get length;
}

// These are constructors on `Uint8Array` that we need that aren't exposed in
// the dart sdk yet
@JS('Uint8Array')
extension type JSUint8Array1._(JSObject _) implements JSObject {
  external factory JSUint8Array1._create1(JSAny bufferOrLength);
  external factory JSUint8Array1._create3(JSArrayBuffer buffer, int start, int length);
}

JSUint8Array createUint8ArrayFromBuffer(JSArrayBuffer buffer) =>
    JSUint8Array1._create1(buffer) as JSUint8Array;

JSUint8Array createUint8ArrayFromSubBuffer(JSArrayBuffer buffer, int start, int length) =>
    JSUint8Array1._create3(buffer, start, length) as JSUint8Array;

JSUint8Array createUint8ArrayFromLength(int length) =>
    JSUint8Array1._create1(length.toJS) as JSUint8Array;
