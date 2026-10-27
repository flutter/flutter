// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:_wasm';
import 'dart:ffi';
import 'dart:js_interop';

extension type WebAssemblyMemory._(JSObject _) implements JSObject {
  external JSArrayBuffer get buffer;
}

extension type SkwasmInstance._(JSObject _) implements JSObject {
  external WebAssemblyMemory get wasmMemory;
}

@JS('window._flutter_skwasmInstance')
external SkwasmInstance get skwasmInstance;

@pragma('wasm:import', 'skwasmWrapper.addFunction')
external WasmI32 addFunction(WasmFuncRef function);

@Native<Bool Function()>(symbol: 'skwasm_isMultiThreaded', isLeaf: true)
external bool skwasmIsMultiThreaded();

@Native<Bool Function()>(symbol: 'skwasm_isWimp')
external bool skwasmIsWimp();

@Native<Bool Function()>(symbol: 'skwasm_isHeavy', isLeaf: true)
external bool skwasmIsHeavy();

/// Whether this skwasm binary was built with the builtin (Skia) animated image
/// codecs.
///
/// This is decoupled from [skwasmIsHeavy] because `wimp_heavy` has builtin ICU
/// but does not yet have an Impeller-compatible animated image implementation.
@Native<Bool Function()>(symbol: 'skwasm_supportsAnimatedImages', isLeaf: true)
external bool skwasmSupportsAnimatedImages();

@Native<Void Function(Pointer<Uint32>)>(symbol: 'skwasm_getLiveObjectCounts', isLeaf: true)
external void skwasmGetLiveObjectCounts(Pointer<Uint32> objectCounts);
