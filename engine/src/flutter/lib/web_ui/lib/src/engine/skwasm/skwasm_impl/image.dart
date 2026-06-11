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
    // Dispose of the native image reference to prevent memory leaks in WASM memory.
    imageDispose(handle);
  }

  /// Retrieve the image width from the native handle.
  int get width => imageGetWidth(handle);

  /// Retrieve the image height from the native handle.
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
  // Allocate a native buffer in WebAssembly memory to copy the pixel bytes into.
  final SkDataHandle dataHandle = skDataCreate(pixels.length);
  final int dataAddress = skDataGetPointer(dataHandle).cast<Uint8>().address;

  // Efficiently transfer the pixel data from the Dart TypedData array to the native buffer.
  final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
  wasmMemory.set(pixels.toJS, dataAddress);

  // Construct the native image using the loaded pixel buffer.
  final ImageHandle imageHandle = imageCreateFromPixels(
    dataHandle,
    width,
    height,
    format.index,
    rowBytes ?? 4 * width,
  );

  // Clean up the temporary native data handle because the image constructor has taken
  // a reference/copied the buffer.
  skDataDispose(dataHandle);

  // Wrap the native image in a SkwasmImage and return the final EngineImage.
  return EngineImage(SkwasmImage(imageHandle), width, height);
}
