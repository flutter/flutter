// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  external JSNumber getEmptyTableSlot();

  // The function here *must* be a directly exported wasm function, not a
  // JavaScript function. If you actually need to add a JavaScript function,
  // use `addFunction` instead.
  external void setWasmTableEntry(JSNumber index, JSAny function);

  external JSNumber addFunction(WebAssemblyFunction function);
  external void removeFunction(JSNumber functionPointer);

  external WebAssemblyMemory get wasmMemory;
}

@JS('window._flutter_skwasmInstance')
external SkwasmInstance get skwasmInstance;

@JS()
@staticInterop
@anonymous
class WebAssemblyFunctionType {
  external factory WebAssemblyFunctionType({
    required JSArray parameters,
    required JSArray results,
  });
}

@JS('WebAssembly.Function')
@staticInterop
class WebAssemblyFunction {
  external factory WebAssemblyFunction(
    WebAssemblyFunctionType functionType,
    JSFunction function
  );
}
