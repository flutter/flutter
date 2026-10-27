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

  test('ImageElementImageSource clears src on closure', () async {
    final DomHTMLImageElement imageElement = createDomHTMLImageElement();
    imageElement.src = 'sample_image1.png';
    final ImageSource imageSource = ImageElementImageSource(imageElement);

    expect(imageElement.src, contains('sample_image1.png'));
    imageSource.close();
    expect(imageElement.src, isNot(contains('sample_image1.png')));
  });

  test(
    'ImageSource remains alive when Picture is alive after Image is disposed (ImageBitmap)',
    () async {
      final ui.Image image = await _createBitmapTestImage();
      final ImageSource source = (image as EngineImage).imageSource!;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      final ui.Picture picture = recorder.endRecording();

      image.dispose();
      expect(source.debugIsClosed, isFalse);

      picture.dispose();
      expect(source.debugIsClosed, isTrue);
    },
  );

  test(
    'ImageSource remains alive when Picture is alive after Image is disposed (ImageElement)',
    () async {
      final ui.Image image = await _createElementTestImage();
      final ImageSource source = (image as EngineImage).imageSource!;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      final ui.Picture picture = recorder.endRecording();

      image.dispose();
      expect(source.debugIsClosed, isFalse);

      picture.dispose();
      expect(source.debugIsClosed, isTrue);
    },
  );

  test('ImageSource remains alive when drawn via ImageShader', () async {
    final ui.Image image = await _createBitmapTestImage();
    final ImageSource source = (image as EngineImage).imageSource!;

    final shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp, Float64List(16));

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..shader = shader);
    final ui.Picture picture = recorder.endRecording();

    image.dispose();
    expect(source.debugIsClosed, isFalse);

    shader.dispose();
    expect(source.debugIsClosed, isFalse);

    picture.dispose();
    expect(source.debugIsClosed, isTrue);
  });

  test('ImageSource remains alive when recorded in nested drawPicture', () async {
    final ui.Image image = await _createBitmapTestImage();
    final ImageSource source = (image as EngineImage).imageSource!;

    final childRecorder = ui.PictureRecorder();
    final childCanvas = ui.Canvas(childRecorder);
    childCanvas.drawImage(image, ui.Offset.zero, ui.Paint());
    final ui.Picture childPicture = childRecorder.endRecording();

    final parentRecorder = ui.PictureRecorder();
    final parentCanvas = ui.Canvas(parentRecorder);
    parentCanvas.drawPicture(childPicture);
    final ui.Picture parentPicture = parentRecorder.endRecording();

    image.dispose();
    childPicture.dispose();

    expect(source.debugIsClosed, isFalse);

    parentPicture.dispose();
    expect(source.debugIsClosed, isTrue);
  });

  test('ImageSource remains alive across picture.clone()', () async {
    final ui.Image image = await _createBitmapTestImage();
    final ImageSource source = (image as EngineImage).imageSource!;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    final ui.Picture picture1 = recorder.endRecording();
    final ui.Picture picture2 = (picture1 as CkPicture).clone();

    image.dispose();
    expect(source.debugIsClosed, isFalse);

    picture1.dispose();
    expect(source.debugIsClosed, isFalse);

    picture2.dispose();
    expect(source.debugIsClosed, isTrue);
  });

  test(
    'Canvas.drawRect with FragmentShader retaining sampler ImageSource until Picture disposal',
    () async {
      const textureShaderJson = r'''
{
  "format_version": 1,
  "sksl": {
    "entrypoint": "texture_fragment_main",
    "shader": "// This SkSL shader is autogenerated by spirv-cross.\n\nfloat4 flutter_FragCoord;\n\nuniform vec2 u_size;\nuniform shader u_texture;\nuniform half2 u_texture_size;\n\nvec4 frag_color;\n\nvec2 FLT_flutter_local_FlutterFragCoord()\n{\n    return flutter_FragCoord.xy;\n}\n\nvoid FLT_main()\n{\n    frag_color = u_texture.eval(u_texture_size * ( FLT_flutter_local_FlutterFragCoord() / u_size));\n}\n\nhalf4 main(float2 iFragCoord)\n{\n      flutter_FragCoord = float4(iFragCoord, 0, 0);\n      FLT_main();\n      return frag_color;\n}\n",
    "stage": 1,
    "uniforms": [
      {
        "array_elements": 0,
        "bit_width": 32,
        "columns": 1,
        "location": 0,
        "name": "u_size",
        "rows": 2,
        "type": 10
      },
      {
        "array_elements": 0,
        "bit_width": 0,
        "columns": 1,
        "location": 1,
        "name": "u_texture",
        "rows": 1,
        "type": 12
      }
    ]
  }
}
''';
      final Uint8List data = utf8.encode(textureShaderJson);
      final program = CkFragmentProgram.fromBytes('texture_test', data);
      final fragmentShader = program.fragmentShader() as EngineFragmentShader;

      final ui.Image image = await _createBitmapTestImage();
      final ImageSource source = (image as EngineImage).imageSource!;

      fragmentShader.setImageSampler(0, image);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..shader = fragmentShader;
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 50, 50), paint);

      image.dispose();
      expect(source.debugIsClosed, isFalse);

      final ui.Picture picture = recorder.endRecording();
      expect(source.debugIsClosed, isFalse);

      // Disposing the shader first still leaves the picture retaining the image source.
      fragmentShader.dispose();
      expect(source.debugIsClosed, isFalse);

      // Disposing the picture drops the final reference to the image source.
      picture.dispose();
      expect(source.debugIsClosed, isTrue);
    },
  );

  test('Abandoned CkPictureRecorder releases retained ImageSource via finalizer', () async {
    final Finalizer originalFinalizer = CkPictureRecorder.finalizer;
    final mockFinalizer = _MockFinalizer();
    CkPictureRecorder.finalizer = mockFinalizer;
    try {
      final ui.Image image = await _createBitmapTestImage();
      final ImageSource source = (image as EngineImage).imageSource!;

      final recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());

      image.dispose();
      // Image is retained by the unended recorder's tracker.
      expect(source.debugIsClosed, isFalse);

      // Verify the recorder attached its tracker to the finalizer.
      expect(mockFinalizer.registeredPairs, hasLength(1));
      expect(mockFinalizer.registeredPairs.single.target, same(recorder));
      expect(mockFinalizer.registeredPairs.single.value, same(recorder.tracker));

      // Simulate GC collection of the abandoned recorder.
      mockFinalizer.trigger(recorder);
      expect(source.debugIsClosed, isTrue);
    } finally {
      CkPictureRecorder.finalizer = originalFinalizer;
    }
  });
}

/// Creates a synthetic [EngineImage] backed by a genuine [SkImage] and an
/// [ImageBitmapImageSource].
///
/// In browser tests, creating an actual WebGL texture from a DOM ImageBitmap
/// requires an asynchronous GPU upload pipeline. Pairing a valid 4x4 PNG
/// SkImage delegate with an [ImageBitmapImageSource] allows testing the
/// reference-counting and disposal lifecycle of DOM image sources during canvas
/// draw calls without relying on asynchronous WebGL texture creation.
Future<ui.Image> _createBitmapTestImage() async {
  final ImageSource imageSource = ImageBitmapImageSource(
    await createImageBitmap(createBlankDomImageData(4, 4)),
  );
  final SkImage skImage =
      ((await createImageFromBytes(k4x4PngImage)).backendImage as CkImageDelegate).skImage;
  return EngineImage(
    CkImageDelegate(skImage),
    skImage.width().toInt(),
    skImage.height().toInt(),
    imageSource: imageSource,
  );
}

/// Creates a synthetic [EngineImage] backed by a genuine [SkImage] and an
/// [ImageElementImageSource].
///
/// Similar to [_createBitmapTestImage], this pairs a valid 4x4 PNG SkImage
/// with an HTML <img> element source to test the DOM `src = ''` disposal lifecycle.
Future<ui.Image> _createElementTestImage() async {
  final DomHTMLImageElement imageElement = createDomHTMLImageElement();
  imageElement.src = 'sample_image1.png';
  final ImageSource imageSource = ImageElementImageSource(imageElement);
  final SkImage skImage =
      ((await createImageFromBytes(k4x4PngImage)).backendImage as CkImageDelegate).skImage;
  return EngineImage(
    CkImageDelegate(skImage),
    skImage.width().toInt(),
    skImage.height().toInt(),
    imageSource: imageSource,
  );
}

class _MockFinalizer implements Finalizer {
  final List<_MockPair> registeredPairs = <_MockPair>[];

  @override
  void attach(Object target, Object value, {Object? detach}) {
    registeredPairs.add(_MockPair(target, value, detach));
  }

  @override
  void detach(Object detach) {
    registeredPairs.removeWhere((pair) => pair.detach == detach);
  }

  void trigger(Object target) {
    final List<_MockPair> pairs = registeredPairs
        .where((_MockPair pair) => pair.target == target)
        .toList();
    for (final pair in pairs) {
      if (pair.value is PictureImageTracker) {
        (pair.value as PictureImageTracker).releaseAll();
      }
    }
  }
}

class _MockPair {
  _MockPair(this.target, this.value, this.detach);

  Object target;
  Object value;
  Object? detach;
}

Future<ui.Image> _createImage() => _createPicture().toImage(10, 10);

ui.Picture _createPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
