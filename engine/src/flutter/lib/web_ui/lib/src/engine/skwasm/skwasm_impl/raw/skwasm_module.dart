// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:ui/src/engine.dart';

@JS()
@staticInterop
class WebAssemblyMemory {}

extension WebAssemblyMemoryExtension on WebAssemblyMemory {
  external ArrayBuffer get buffer;
}

@JS()
@staticInterop
class SkwasmInstance {}

extension SkwasmInstanceExtension on SkwasmInstance {
  external JSNumber addFunction(JSFunction function, JSString signature);
  external void removeFunction(JSNumber functionPointer);
  external WebAssemblyMemory get wasmMemory;
}

@JS('window._flutter_skwasmInstance')
external SkwasmInstance get skwasmInstance;
