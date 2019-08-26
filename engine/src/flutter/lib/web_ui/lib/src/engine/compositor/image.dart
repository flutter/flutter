// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Instantiates a [ui.Codec] backed by an `SkImage` from Skia.
void skiaInstantiateImageCodec(Uint8List list, Callback<ui.Codec> callback,
    [int width, int height, int format, int rowBytes]) {
  final js.JsObject skImage =
      canvasKit.callMethod('MakeImageFromEncoded', <Uint8List>[list]);
  final SkImage image = SkImage(skImage);
  final SkImageCodec codec = SkImageCodec(image);
  callback(codec);
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class SkImage implements ui.Image {
  js.JsObject skImage;

  SkImage(this.skImage);

  @override
  void dispose() {
    skImage = null;
  }

  @override
  int get width => skImage.callMethod('width');

  @override
  int get height => skImage.callMethod('height');

  @override
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw 'unimplemented';
  }
}

/// A [ui.Codec] backed by an `SkImage` from Skia.
class SkImageCodec implements ui.Codec {
  final SkImage skImage;

  SkImageCodec(this.skImage);

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  int get frameCount => 1;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    return Future<ui.FrameInfo>.value(SingleFrameInfo(skImage));
  }

  @override
  int get repetitionCount => 0;
}
