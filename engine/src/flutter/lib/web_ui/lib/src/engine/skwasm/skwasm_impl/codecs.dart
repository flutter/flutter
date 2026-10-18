// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

/// The Skwasm-specific implementation of the [BackendAnimatedImage] contract.
///
/// This class acts as a thin bridge to the C++ Skia animated image codecs compiled
/// into the WebAssembly module, interacting via Dart's FFI (`dart:ffi`).
class SkwasmAnimatedImageDecoder implements BackendAnimatedImage {
  /// Allocates native memory and instantiates a native C++ animated image decoder.
  factory SkwasmAnimatedImageDecoder(Uint8List imageData, [int? width, int? height]) {
    // Allocate a native SkData buffer on the WASM heap.
    final SkDataHandle data = skDataCreate(imageData.length);
    try {
      // Obtain the raw virtual memory address of the allocated buffer.
      final int dataAddress = skDataGetPointer(data).cast<Int8>().address;

      // Directly copy the Dart bytes into the WASM memory buffer.
      // We wrap the WASM module's memory buffer in a JSUint8Array view and use
      // the high-speed `.set()` method to copy the Dart Uint8List. This bypasses
      // standard serialization/deserialization overhead.
      final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
      wasmMemory.set(imageData.toJS, dataAddress);

      // Create the native animated image decoder.
      // If target width and height are provided, the native C++ decoder (SkAndroidCodec)
      // will scale the frames natively on decode, saving CPU/GPU memory.
      final AnimatedImageHandle handle = animatedImageCreate(data, width ?? 0, height ?? 0);
      if (handle == nullptr) {
        throw ImageCodecException('Failed to create Skwasm animated image from bytes.');
      }
      return SkwasmAnimatedImageDecoder._(handle);
    } finally {
      // Clean up the temporary SkData buffer.
      // The native animated image decoder has already retained a reference to the
      // data, so we must dispose of our local handle to prevent memory leaks.
      skDataDispose(data);
    }
  }

  SkwasmAnimatedImageDecoder._(this.handle);

  /// The raw FFI pointer to the underlying C++ SkAnimatedImage.
  AnimatedImageHandle handle;

  @override
  void dispose() {
    if (handle != nullptr) {
      animatedImageDispose(handle);
      handle = nullptr;
    }
  }

  @override
  int get frameCount {
    return animatedImageGetFrameCount(handle);
  }

  @override
  int get repetitionCount {
    return animatedImageGetRepetitionCount(handle);
  }

  @override
  Future<BackendFrameInfo> getNextFrame() {
    // Get the duration of the current frame prior to advancing.
    final duration = Duration(
      milliseconds: animatedImageGetCurrentFrameDurationMilliseconds(handle),
    );

    // Extract a native handle to the current frame's SkImage.
    final ImageHandle frameHandle = animatedImageGetCurrentFrame(handle);
    final backendImage = SkwasmImage(frameHandle);

    // Advance the native decoder to the next frame. The next call to
    // animatedImageGetCurrentFrame will yield the next frame.
    animatedImageDecodeNextFrame(handle);

    return Future<BackendFrameInfo>.value(
      BackendFrameInfo(duration: duration, image: backendImage),
    );
  }
}
