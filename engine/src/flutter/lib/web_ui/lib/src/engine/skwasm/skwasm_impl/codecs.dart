// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmBrowserImageDecoder extends BrowserImageDecoder {
  SkwasmBrowserImageDecoder({
    required super.contentType,
    required super.dataSource,
    required super.debugSource,
  });

  @override
  ui.Image generateImageFromVideoFrame(VideoFrame frame) {
    // Determine the visual bounds of the image using the video frame's display dimensions.
    final int width = frame.displayWidth.toInt();
    final int height = frame.displayHeight.toInt();

    // Retrieve the Skwasm-specific rendering surface to bind the texture.
    final surface = renderer.pictureToImageSurface as SkwasmSurface;

    // Create the native WebAssembly-backed ImageHandle from the VideoFrame texture source.
    final ImageHandle handle = imageCreateFromTextureSource(frame, width, height, surface.handle);

    // Return the EngineImage instance initialized with the SkwasmImage and the original video frame source.
    return EngineImage(
      SkwasmImage(handle),
      width,
      height,
      imageSource: VideoFrameImageSource(frame),
    );
  }
}

class SkwasmDomImageDecoder extends HtmlBlobCodec {
  SkwasmDomImageDecoder(super.blob, [this.width, this.height]);

  final int? width;
  final int? height;

  @override
  FutureOr<ui.Image> createImageFromHTMLImageElement(
    DomHTMLImageElement image,
    int naturalWidth,
    int naturalHeight,
  ) {
    return renderer.createImageFromTextureSource(
      image,
      width: width ?? naturalWidth,
      height: height ?? naturalHeight,
      transferOwnership: false,
    );
  }
}

class SkwasmAnimatedImageDecoder implements ui.Codec {
  factory SkwasmAnimatedImageDecoder(Uint8List imageData, [int? width, int? height]) {
    // Allocate native WebAssembly memory to hold the image byte data.
    final SkDataHandle data = skDataCreate(imageData.length);
    final int dataAddress = skDataGetPointer(data).cast<Int8>().address;

    // Copy Dart bytes into the allocated native memory block.
    final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
    wasmMemory.set(imageData.toJS, dataAddress);

    // Initialize the native animated image structure with the native buffer.
    final AnimatedImageHandle handle = animatedImageCreate(data, width ?? 0, height ?? 0);

    // Dispose of the temporary native data container after copying.
    skDataDispose(data);

    return SkwasmAnimatedImageDecoder._(handle);
  }

  SkwasmAnimatedImageDecoder._(this.handle);

  AnimatedImageHandle handle;

  @override
  void dispose() {
    // Release the WebAssembly native resources bound to this animated image decoder.
    if (handle != nullptr) {
      animatedImageDispose(handle);
      handle = nullptr;
    }
  }

  @override
  int get frameCount {
    // Retrieve the total number of frames in the animated image source.
    return animatedImageGetFrameCount(handle);
  }

  @override
  int get repetitionCount {
    // Retrieve the target loop count for the animation.
    return animatedImageGetRepetitionCount(handle);
  }

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    // Determine how long the active frame should display.
    final duration = Duration(
      milliseconds: animatedImageGetCurrentFrameDurationMilliseconds(handle),
    );

    // Grab the native canvas image representation of the current frame.
    final ImageHandle frameHandle = animatedImageGetCurrentFrame(handle);

    // Create an EngineImage that manages the native frame handle.
    final image = EngineImage(
      SkwasmImage(frameHandle),
      imageGetWidth(frameHandle),
      imageGetHeight(frameHandle),
    );

    // Bundle the duration and the image frame together and return them.
    final ui.FrameInfo frameInfo = AnimatedImageFrameInfo(duration, image);
    return frameInfo;
  }
}
