// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_data.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  tearDown(() {
    ui.Image.onCreate = null;
    ui.Image.onDispose = null;
  });

  test('toImage succeeds', () async {
    final ui.Image image = await _createImage();
    expect(image, isA<EngineImage>());
    image.dispose();
  });

  test('EngineImage does not close image source too early', () async {
    // Create a shared ImageSource wrapping a blank 4x4 image bitmap.
    final ImageSource imageSource = ImageBitmapImageSource(
      await createImageBitmap(createBlankDomImageData(4, 4)),
    );

    // Instantiate the first CanvasKit-backed image using the shared imageSource.
    final SkImage skImage1 =
        ((await createImageFromBytes(k4x4PngImage)).backendImage as CkImageDelegate).skImage;
    final image1 = EngineImage(
      CkImageDelegate(skImage1),
      skImage1.width().toInt(),
      skImage1.height().toInt(),
      imageSource: imageSource,
    );

    // Instantiate a second separate CanvasKit image sharing the same imageSource.
    final SkImage skImage2 =
        ((await createImageFromBytes(k4x4PngImage)).backendImage as CkImageDelegate).skImage;
    final image2 = EngineImage(
      CkImageDelegate(skImage2),
      skImage2.width().toInt(),
      skImage2.height().toInt(),
      imageSource: imageSource,
    );

    // Clone the first image, which also increments the shared imageSource's reference count.
    final EngineImage image3 = image1.clone();

    // Verify that the image source starts in an active, non-closed state.
    expect(imageSource.debugIsClosed, isFalse);

    // Disposing the first image should leave the imageSource alive (two references remaining).
    image1.dispose();
    expect(imageSource.debugIsClosed, isFalse);

    // Disposing the second image should leave the imageSource alive (one reference remaining).
    image2.dispose();
    expect(imageSource.debugIsClosed, isFalse);

    // Disposing the final cloned image should release the last reference and close the imageSource.
    image3.dispose();
    expect(imageSource.debugIsClosed, isTrue);
  });

  test('ImageElementImageSource preserves src on closure', () {
    final DomHTMLImageElement imageElement = createDomHTMLImageElement();
    imageElement.src = 'sample_image1.png';
    final ImageSource imageSource = ImageElementImageSource(imageElement);

    expect(imageElement.src, contains('sample_image1.png'));
    imageSource.close();
    expect(imageElement.src, contains('sample_image1.png'));
    expect(imageSource.debugIsClosed, isTrue);
  });

  test('A picture retains image element pixels after the image is disposed', () async {
    final DomHTMLImageElement imageElement = createDomHTMLImageElement();
    imageElement.src = 'data:image/png;base64,${base64.encode(k4x4PngImage)}';
    await imageElement.decode();
    final ui.Image image = await renderer.createImageFromTextureSource(
      imageElement,
      width: 4,
      height: 4,
      transferOwnership: true,
    );
    // Read directly from the DOM source without triggering a GPU texture upload.
    final ByteData expected = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
    final ui.Picture picture = recorder.endRecording();
    addTearDown(picture.dispose);

    image.dispose();

    // The first texture upload happens only after the last Dart image handle
    // has been disposed, as can happen when ImageCache evicts an image.
    final ui.Image rasterized = await picture.toImage(4, 4);
    addTearDown(rasterized.dispose);
    final ByteData actual = (await rasterized.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!;
    expect(actual.buffer.asUint8List(), expected.buffer.asUint8List());
  });
}

Future<ui.Image> _createImage() => _createPicture().toImage(10, 10);

ui.Picture _createPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
