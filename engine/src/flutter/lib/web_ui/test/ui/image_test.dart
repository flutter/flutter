// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true);
  test('Image constructor invokes onCreate once', () async {
    var onCreateInvokedCount = 0;
    ui.Image? createdImage;
    addTearDown(() => ui.Image.onCreate = null);
    ui.Image.onCreate = (ui.Image image) {
      onCreateInvokedCount++;
      createdImage = image;
    };

    final ui.Image image1 = await _createImage();

    expect(onCreateInvokedCount, 1);
    expect(createdImage, image1);

    final ui.Image image2 = await _createImage();

    expect(onCreateInvokedCount, 2);
    expect(createdImage, image2);
  });

  test('dispose() invokes onDispose once', () async {
    var onDisposeInvokedCount = 0;
    ui.Image? disposedImage;
    addTearDown(() => ui.Image.onDispose = null);
    ui.Image.onDispose = (ui.Image image) {
      onDisposeInvokedCount++;
      disposedImage = image;
    };

    final ui.Image image1 = await _createImage()
      ..dispose();

    expect(onDisposeInvokedCount, 1);
    expect(disposedImage, image1);

    final ui.Image image2 = await _createImage()
      ..dispose();

    expect(onDisposeInvokedCount, 2);
    expect(disposedImage, image2);
  });

  test('scaledImageSize scales to a target width with no target height', () {
    final BitmapSize? size = scaledImageSize(200, 100, 600, null);
    expect(size?.width, 600);
    expect(size?.height, 300);
  });

  test('scaledImageSize does not derive a side of 0 for a very thin image', () {
    final BitmapSize? wide = scaledImageSize(4000, 1, 100, null);
    expect(wide?.width, 100);
    expect(wide?.height, 1);
    final BitmapSize? tall = scaledImageSize(1, 4000, null, 100);
    expect(tall?.width, 1);
    expect(tall?.height, 100);
  });

  test('instantiateImageCodecFromBuffer dispose buffer', () async {
    final ui.Image image = await _createImage();
    final ByteData? imageData = await image.toByteData(format: ui.ImageByteFormat.png);
    final ui.ImmutableBuffer imageBuffer = await ui.ImmutableBuffer.fromUint8List(
      imageData!.buffer.asUint8List(),
    );

    final ui.Codec codec = await ui.instantiateImageCodecFromBuffer(imageBuffer);
    codec.dispose();
    image.dispose();

    expect(imageBuffer.debugDisposed, isTrue);
  });

  test('instantiateImageCodecWithSize dispose buffer', () async {
    // getTargetSize is null, so the image is not scaled.
    final ui.Image image = await _createImage();
    final ByteData? imageData = await image.toByteData(format: ui.ImageByteFormat.png);
    final ui.ImmutableBuffer nullTargetSizeImageBuffer = await ui.ImmutableBuffer.fromUint8List(
      imageData!.buffer.asUint8List(),
    );

    final ui.Codec codec = await ui.instantiateImageCodecWithSize(nullTargetSizeImageBuffer);
    codec.dispose();
    image.dispose();

    expect(nullTargetSizeImageBuffer.debugDisposed, isTrue);

    // getTargetSize is not null, so the image is scaled.
    final ui.Image scaledImage = await _createImage();
    final ByteData? scaledImageData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
    final ui.ImmutableBuffer scaledImageBuffer = await ui.ImmutableBuffer.fromUint8List(
      scaledImageData!.buffer.asUint8List(),
    );

    final ui.Codec scaledCodec = await ui.instantiateImageCodecWithSize(
      scaledImageBuffer,
      getTargetSize: (w, h) => ui.TargetImageSize(width: w ~/ 2, height: h ~/ 2),
    );
    scaledCodec.dispose();
    scaledImage.dispose();

    expect(scaledImageBuffer.debugDisposed, isTrue);
  });

  test('instantiateImageCodecWithSize disposes temporary image', () async {
    final activeImages = <ui.Image>{};
    addTearDown(() {
      ui.Image.onCreate = null;
      ui.Image.onDispose = null;
    });
    ui.Image.onCreate = activeImages.add;
    ui.Image.onDispose = activeImages.remove;

    final ui.Image image = await _createImage();
    final ByteData? imageData = await image.toByteData(format: ui.ImageByteFormat.png);
    final ui.ImmutableBuffer imageBuffer = await ui.ImmutableBuffer.fromUint8List(
      imageData!.buffer.asUint8List(),
    );
    image.dispose();

    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      imageBuffer,
      getTargetSize: (w, h) => ui.TargetImageSize(width: w ~/ 2, height: h ~/ 2),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(activeImages.length, 1);

    frameInfo.image.dispose();
    codec.dispose();

    expect(activeImages.length, 0);
  });

  test('instantiateImageCodecWithSize honors upscaling when requested', () async {
    final ui.ImmutableBuffer imageBuffer = await _createImageBuffer();

    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      imageBuffer,
      getTargetSize: (int w, int h) => ui.TargetImageSize(width: w * 2, height: h * 2),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(frameInfo.image.width, 20);
    expect(frameInfo.image.height, 20);

    frameInfo.image.dispose();
    codec.dispose();
  });

  test('instantiateImageCodecWithSize upscales to a non-square size', () async {
    final ui.ImmutableBuffer imageBuffer = await _createImageBuffer();

    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      imageBuffer,
      getTargetSize: (int w, int h) => const ui.TargetImageSize(width: 25, height: 15),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(frameInfo.image.width, 25);
    expect(frameInfo.image.height, 15);

    frameInfo.image.dispose();
    codec.dispose();
  });

  test('instantiateImageCodecWithSize upscales one side and downscales the other', () async {
    final ui.ImmutableBuffer imageBuffer = await _createImageBuffer();

    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      imageBuffer,
      getTargetSize: (int w, int h) => const ui.TargetImageSize(width: 25, height: 5),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(frameInfo.image.width, 25);
    expect(frameInfo.image.height, 5);

    frameInfo.image.dispose();
    codec.dispose();
  });

  test('ImageDescriptor.instantiateCodec honors upscaling when requested', () async {
    final ui.ImmutableBuffer imageBuffer = await _createImageBuffer();
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(imageBuffer);

    final ui.Codec codec = await descriptor.instantiateCodec(targetWidth: 20, targetHeight: 20);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(frameInfo.image.width, 20);
    expect(frameInfo.image.height, 20);

    frameInfo.image.dispose();
    codec.dispose();
    descriptor.dispose();
    imageBuffer.dispose();
  });

  test('ImageDescriptor.instantiateCodec upscales from targetWidth alone', () async {
    final ui.ImmutableBuffer imageBuffer = await _createImageBuffer();
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(imageBuffer);

    final ui.Codec codec = await descriptor.instantiateCodec(targetWidth: 30);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    expect(frameInfo.image.width, 30);
    expect(frameInfo.image.height, 30);

    frameInfo.image.dispose();
    codec.dispose();
    descriptor.dispose();
    imageBuffer.dispose();
  });
}

Future<ui.ImmutableBuffer> _createImageBuffer() async {
  final ui.Image image = await _createImage();
  final ByteData? imageData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return ui.ImmutableBuffer.fromUint8List(imageData!.buffer.asUint8List());
}

Future<ui.Image> _createImage() => _createPicture().toImage(10, 10);

ui.Picture _createPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
