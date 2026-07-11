// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

/// A WebAssembly-backed implementation of [BackendImage] using Skwasm.
///
/// This class wraps a native C/C++ image reference ([ImageHandle]) allocated
/// inside the Skwasm WebAssembly module.
class SkwasmImage implements BackendImage {
  SkwasmImage(this.handle);

  /// The native pointer/handle to the image inside the Skwasm instance.
  final ImageHandle handle;

  @override
  void dispose() {
    imageDispose(handle);
  }

  int get width => imageGetWidth(handle);

  int get height => imageGetHeight(handle);

  @override
  bool isCloneOf(BackendImage other) {
    // Check if the other backend image is a SkwasmImage referencing the identical native handle.
    return other is SkwasmImage && handle == other.handle;
  }
}

/// Creates a new [EngineImage] backed by a Skwasm image from a raw pixel buffer.
///
/// The [pixels] argument contains the raw image bytes.
/// The [width] and [height] are the dimensions of the image.
/// The [format] specifies the layout of color channels in the buffer.
/// The optional [rowBytes] defines the step length between two scan lines.
EngineImage createSkwasmImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  ui.PixelFormat format, {
  int? rowBytes,
}) {
  final SkDataHandle dataHandle = skDataCreate(pixels.length);
  try {
    final int dataAddress = skDataGetPointer(dataHandle).cast<Uint8>().address;

    // To avoid a slow element-by-element copy in Dart, we obtain the raw memory
    // address of the WASM buffer, create a JSUint8Array view pointing directly
    // to the Skwasm WASM linear memory heap, and perform a high-performance,
    // browser-native bulk copy (memcpy) of the pixel bytes.
    final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
    wasmMemory.set(pixels.toJS, dataAddress);

    final ImageHandle imageHandle = imageCreateFromPixels(
      dataHandle,
      width,
      height,
      format.index,
      rowBytes ?? 4 * width,
    );
    return EngineImage(SkwasmImage(imageHandle), width, height);
  } finally {
    skDataDispose(dataHandle);
  }
}
