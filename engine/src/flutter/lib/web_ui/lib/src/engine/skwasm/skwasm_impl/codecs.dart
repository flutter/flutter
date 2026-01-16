// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
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
    final int width = frame.displayWidth.toInt();
    final int height = frame.displayHeight.toInt();
    final surface = renderer.pictureToImageSurface as SkwasmSurface;
    return SkwasmImage(imageCreateFromTextureSource(frame, width, height, surface.handle));
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
    final SkDataHandle data = skDataCreate(imageData.length);
    final Pointer<Int8> dataPointer = skDataGetPointer(data).cast<Int8>();
    for (var i = 0; i < imageData.length; i++) {
      dataPointer[i] = imageData[i];
    }
    final AnimatedImageHandle handle = animatedImageCreate(data, width ?? 0, height ?? 0);
    skDataDispose(data);
    return SkwasmAnimatedImageDecoder._(handle);
  }

  SkwasmAnimatedImageDecoder._(this.handle);

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
  Future<ui.FrameInfo> getNextFrame() async {
    final duration = Duration(
      milliseconds: animatedImageGetCurrentFrameDurationMilliseconds(handle),
    );
    final image = SkwasmImage(animatedImageGetCurrentFrame(handle));
    final ui.FrameInfo frameInfo = AnimatedImageFrameInfo(duration, image);
    return frameInfo;
  }
}
