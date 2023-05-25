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
  external JSNumber addFunction(JSFunction function, JSString signature);
  external void removeFunction(JSNumber functionPointer);

  @JS('skwasm_registerObject')
  external void skwasmRegisterObject(JSNumber objectId, JSAny object);

  @JS('skwasm_unregisterObject')
  external void skwasmUnregisterObject(JSNumber objectId);

  @JS('skwasm_getObject')
  external JSAny skwasmGetObject(JSNumber objectId);

  @JS('skwasm_transferObjectToThread')
  external void skwasmTransferObjectToThread(JSNumber objectId, JSNumber threadId);

  external WebAssemblyMemory get wasmMemory;
}

@JS('window._flutter_skwasmInstance')
external SkwasmInstance get skwasmInstance;
