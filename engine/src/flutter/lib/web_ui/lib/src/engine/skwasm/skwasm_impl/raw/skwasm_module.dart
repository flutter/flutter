// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:_wasm';
import 'dart:js_interop';

@JS()
@staticInterop
class WebAssemblyMemory {}

extension WebAssemblyMemoryExtension on WebAssemblyMemory {
  external JSArrayBuffer get buffer;
}

@JS()
@staticInterop
class SkwasmInstance {}

extension SkwasmInstanceExtension on SkwasmInstance {
  external WebAssemblyMemory get wasmMemory;
}

@JS('window._flutter_skwasmInstance')
external SkwasmInstance get skwasmInstance;

@pragma('wasm:import', 'skwasmWrapper.addFunction')
external WasmI32 addFunction(WasmFuncRef function);
