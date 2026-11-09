// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

final class RawSkString extends Opaque {}

typedef SkStringHandle = Pointer<RawSkString>;

final class RawSkString16 extends Opaque {}

typedef SkString16Handle = Pointer<RawSkString16>;

@Native<SkStringHandle Function(Size)>(symbol: 'skString_allocate', isLeaf: true)
external SkStringHandle skStringAllocate(int size);

@Native<Pointer<Int8> Function(SkStringHandle)>(symbol: 'skString_getData', isLeaf: true)
external Pointer<Int8> skStringGetData(SkStringHandle handle);

@Native<Int Function(SkStringHandle)>(symbol: 'skString_getLength', isLeaf: true)
external int skStringGetLength(SkStringHandle handle);

@Native<Void Function(SkStringHandle)>(symbol: 'skString_free', isLeaf: true)
external void skStringFree(SkStringHandle handle);

@Native<SkString16Handle Function(Size)>(symbol: 'skString16_allocate', isLeaf: true)
external SkString16Handle skString16Allocate(int size);

@Native<Pointer<Int16> Function(SkString16Handle)>(symbol: 'skString16_getData', isLeaf: true)
external Pointer<Int16> skString16GetData(SkString16Handle handle);

@Native<Void Function(SkString16Handle)>(symbol: 'skString16_free', isLeaf: true)
external void skString16Free(SkString16Handle handle);

SkStringHandle skStringFromDartString(String string) {
  final List<int> rawUtf8Bytes = utf8.encode(string);
  final SkStringHandle stringHandle = skStringAllocate(rawUtf8Bytes.length);
  final Pointer<Int8> stringDataPointer = skStringGetData(stringHandle);
  for (var i = 0; i < rawUtf8Bytes.length; i++) {
    stringDataPointer[i] = rawUtf8Bytes[i];
  }
  return stringHandle;
}

/// Decodes the UTF-8 contents of [handle] into a Dart string.
///
/// Does not free [handle].
String skStringToDartString(SkStringHandle handle) {
  return utf8.decode(skStringGetData(handle).toUint8List(skStringGetLength(handle)));
}

/// Using a specialized local extension rather than a generic List<int>.generate
/// prevents dart2wasm from dynamically boxing the primitive integers into
/// heap-allocated objects ($BoxedInt / struct allocations) during copy blocks.
/// Explicitly masks the signed Int8 values to positive unsigned bytes (& 0xFF)
/// to guarantee correct decoding by the UTF-8 decoder.
extension on Pointer<Int8> {
  Uint8List toUint8List(int length) {
    final list = Uint8List(length);
    for (int i = length - 1; i >= 0; i--) {
      list[i] = this[i] & 0xFF;
    }
    return list;
  }
}

SkString16Handle skString16FromDartString(String string) {
  final SkString16Handle stringHandle = skString16Allocate(string.length);
  final Pointer<Int16> stringDataPointer = skString16GetData(stringHandle);
  for (var i = 0; i < string.length; i++) {
    stringDataPointer[i] = string.codeUnitAt(i);
  }
  return stringHandle;
}
