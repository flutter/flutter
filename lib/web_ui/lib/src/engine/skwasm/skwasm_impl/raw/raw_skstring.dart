// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

final class RawSkString extends Opaque {}
typedef SkStringHandle = Pointer<RawSkString>;

@Native<SkStringHandle Function(Size)>(symbol: 'skString_allocate', isLeaf: true)
external SkStringHandle skStringAllocate(int size);

@Native<Pointer<Int8> Function(SkStringHandle)>(symbol: 'skString_getData', isLeaf: true)
external Pointer<Int8> skStringGetData(SkStringHandle handle);

@Native<Void Function(SkStringHandle)>(symbol: 'skString_free', isLeaf: true)
external void skStringFree(SkStringHandle handle);
