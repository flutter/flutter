// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

@JS('gc')
external JSFunction? get _jsGc;

@JS('gc')
external JSPromise<JSAny?> _callJsGc(_JsGcOptions options);

extension type _JsGcOptions._(JSObject _) implements JSObject {
  external factory _JsGcOptions({String type, String execution});
}

Future<void> _forceMajorGc() async {
  // Run multiple async major GC + macrotask turns so chained objects (e.g.
  // collected ImageShader -> CountedRef box) and separate FinalizationRegistry
  // instances drain all queued cleanup callbacks.
  for (var i = 0; i < 3; i++) {
    await _callJsGc(_JsGcOptions(type: 'major', execution: 'async')).toDart;
    await Future<void>.delayed(Duration.zero);
  }
}

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

  group('ImageSource and Picture finalization', () {
    late _MockFinalizer mockFinalizer;
    late Finalizer originalFinalizer;

    setUp(() {
      originalFinalizer = UniqueRef.finalizer;
      UniqueRef.finalizer = mockFinalizer = _MockFinalizer();
    });

    tearDown(() {
      UniqueRef.finalizer = originalFinalizer;
    });

    test('undisposed EngineImage and clone release ImageSource when collected', () async {
      final EngineImage image = await _createBitmapBackedImage();
      final ImageSource source = image.imageSource!;
      final EngineImage clone = image.clone();

      // Disposing one handle leaves the shared box and ImageSource alive.
      image.dispose();
      expect(source.debugIsClosed, isFalse);

      // Simulate GC collection of the shared CountedRef box after the remaining
      // clone becomes unreachable without dispose().
      expect(
        mockFinalizer.registeredPairs.where((pair) => identical(pair.target, clone.box)),
        hasLength(1),
      );
      mockFinalizer.trigger(clone.box);
      expect(source.debugIsClosed, isTrue);
    });

    test('undisposed ImageShader releases cloned EngineImage ImageSource when collected', () async {
      final EngineImage image = await _createBitmapBackedImage();
      final ImageSource source = image.imageSource!;
      final shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp, Float64List(16));
      expect(shader.debugDisposed, isFalse);

      // Disposing the original image leaves the shader's internal clone alive.
      image.dispose();
      expect(source.debugIsClosed, isFalse);

      // Simulate GC collection of the shared CountedRef box once shader is unreachable.
      mockFinalizer.trigger(image.box);
      expect(source.debugIsClosed, isTrue);
    });

    test('undisposed Picture and cloned Picture release ImageSource when collected', () async {
      final EngineImage image = await _createBitmapBackedImage();
      final ImageSource source = image.imageSource!;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      final ui.Picture picture = recorder.endRecording();
      final LayerPicture pictureClone = (picture as LayerPicture).clone();
      expect(pictureClone.isDisposed, isFalse);

      // Disposing the image detaches image.box, leaving only the picture's CountedRef
      // registered in UniqueRef.finalizer.
      image.dispose();
      expect(source.debugIsClosed, isFalse);

      // Disposing one picture handle leaves the shared CountedRef alive for pictureClone.
      picture.dispose();
      expect(source.debugIsClosed, isFalse);

      expect(mockFinalizer.registeredPairs, hasLength(1));
      mockFinalizer.trigger(mockFinalizer.registeredPairs.single.target);
      expect(source.debugIsClosed, isTrue);
    });

    test(
      'EngineCodec.staticImage releases ImageSource on GC and ignores duplicate dispose',
      () async {
        final ImageSource collectedSource = ImageBitmapImageSource(
          await createImageBitmap(createBlankDomImageData(4, 4)),
        );
        final ui.Codec collectedCodec = EngineCodec.staticImage(collectedSource);
        expect(collectedCodec.frameCount, 1);
        expect(collectedSource.debugIsClosed, isFalse);

        mockFinalizer.trigger(collectedCodec);
        expect(collectedSource.debugIsClosed, isTrue);

        final ImageSource activeSource = ImageBitmapImageSource(
          await createImageBitmap(createBlankDomImageData(4, 4)),
        );
        final ui.Codec codec = EngineCodec.staticImage(activeSource);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();

        // Disposing the codec twice must not decrement activeSource a second time
        // while frameInfo.image still retains it.
        codec.dispose();
        codec.dispose();
        expect(activeSource.debugIsClosed, isFalse);

        frameInfo.image.dispose();
        expect(activeSource.debugIsClosed, isTrue);
      },
    );

    test('EngineImage releases ImageSource even when BackendImage.dispose throws', () async {
      final ImageSource source = ImageBitmapImageSource(
        await createImageBitmap(createBlankDomImageData(4, 4)),
      );
      final trackedSource = ImageBitmapImageSource(
        await createImageBitmap(createBlankDomImageData(4, 4)),
      );
      final tracker = PictureImageTracker()..recordSource(trackedSource);
      final image = EngineImage(
        _ThrowingBackendImage(),
        4,
        4,
        imageSource: source,
        imageTracker: tracker,
      );
      tracker.releaseAll();
      expect(trackedSource.debugIsClosed, isFalse);

      expect(image.dispose, throwsStateError);
      expect(source.debugIsClosed, isTrue);
      expect(trackedSource.debugIsClosed, isTrue);
    });
  });

  group('Real GC finalization', () {
    test('undisposed Picture releases ImageSource via DomFinalizationRegistry on GC', () async {
      final DomImageBitmap bitmap = await createImageBitmap(createBlankDomImageData(4, 4));
      final ImageSource source = _recordAndDropPictureWithBitmap(bitmap);
      expect(source.debugIsClosed, isFalse);

      await _forceMajorGc();
      expect(source.debugIsClosed, isTrue);
    }, skip: _jsGc == null);

    test(
      'Paragraph with foreground or background ImageShader retains ImageSource across GC',
      () async {
        for (final useBackground in <bool>[false, true]) {
          final DomImageBitmap bitmap = await createImageBitmap(_createSolidGreenImageData(16, 16));
          final (:ui.Paragraph paragraph, :ImageSource source) =
              _buildParagraphDroppingShaderAndImage(bitmap, useBackground: useBackground);

          await _forceMajorGc();
          expect(
            source.debugIsClosed,
            isFalse,
            reason: 'useBackground=$useBackground: Paragraph must retain ImageSource across GC',
          );

          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawParagraph(paragraph, ui.Offset.zero);
          final ui.Picture picture = recorder.endRecording();

          paragraph.dispose();
          expect(
            source.debugIsClosed,
            isFalse,
            reason: 'useBackground=$useBackground: Picture must retain paragraph ImageSource',
          );

          // Wimp (Impeller) does not yet shade glyph foregrounds with ImageShader.
          if (!isWimp || useBackground) {
            final ui.Image rendered = await picture.toImage(16, 16);
            final ByteData? pixels = await rendered.toByteData();
            rendered.dispose();
            expect(pixels, isNotNull);
            const int centerOffset = (8 * 16 + 8) * 4;
            expect(
              <int>[
                pixels!.getUint8(centerOffset),
                pixels.getUint8(centerOffset + 1),
                pixels.getUint8(centerOffset + 2),
                pixels.getUint8(centerOffset + 3),
              ],
              <int>[0, 255, 0, 255],
              reason: 'useBackground=$useBackground: Text must render green from ImageShader',
            );
          }

          picture.dispose();
          expect(source.debugIsClosed, isTrue);
        }
      },
      skip: _jsGc == null,
    );

    test('undisposed Paragraph and abandoned ParagraphBuilder release ImageSource on GC', () async {
      final DomImageBitmap paragraphBitmap = await createImageBitmap(createBlankDomImageData(4, 4));
      final ImageSource paragraphSource = _buildAndDropParagraphWithBitmap(paragraphBitmap);
      expect(paragraphSource.debugIsClosed, isFalse);

      await _forceMajorGc();
      expect(paragraphSource.debugIsClosed, isTrue);

      final DomImageBitmap builderBitmap = await createImageBitmap(createBlankDomImageData(4, 4));
      final ImageSource builderSource = _pushStyleAndAbandonParagraphBuilder(builderBitmap);
      expect(builderSource.debugIsClosed, isFalse);

      await _forceMajorGc();
      expect(builderSource.debugIsClosed, isTrue);
    }, skip: _jsGc == null);
  });
}

DomImageData _createSolidGreenImageData(int width, int height) {
  final DomImageData data = createBlankDomImageData(width, height);
  for (var i = 0; i < data.data.length; i += 4) {
    data.data[i] = 0;
    data.data[i + 1] = 255;
    data.data[i + 2] = 0;
    data.data[i + 3] = 255;
  }
  return data;
}

Float64List _identityMatrix() => Float64List(16)
  ..[0] = 1
  ..[5] = 1
  ..[10] = 1
  ..[15] = 1;

@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
ImageSource _recordAndDropPictureWithBitmap(DomImageBitmap bitmap) {
  final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
  final ImageSource source = image.imageSource!;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
  final ui.Picture picture = recorder.endRecording();
  image.dispose();
  expect(picture.debugDisposed, isFalse);
  return source;
}

@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
({ui.Paragraph paragraph, ImageSource source}) _buildParagraphDroppingShaderAndImage(
  DomImageBitmap bitmap, {
  required bool useBackground,
}) {
  final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
  final ImageSource source = image.imageSource!;
  final shader = ui.ImageShader(
    image,
    ui.TileMode.repeated,
    ui.TileMode.repeated,
    _identityMatrix(),
  );
  final paint = ui.Paint()..shader = shader;
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 16));
  builder.pushStyle(
    useBackground
        ? ui.TextStyle(background: paint, color: const ui.Color(0x00000000))
        : ui.TextStyle(foreground: paint),
  );
  builder.addText('X');
  final ui.Paragraph paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 16));
  return (paragraph: paragraph, source: source);
}

@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
ImageSource _buildAndDropParagraphWithBitmap(DomImageBitmap bitmap) {
  final (:ui.Paragraph paragraph, :ImageSource source) = _buildParagraphDroppingShaderAndImage(
    bitmap,
    useBackground: false,
  );
  expect(paragraph.debugDisposed, isFalse);
  return source;
}

@pragma('dart2js:noInline')
@pragma('wasm:never-inline')
ImageSource _pushStyleAndAbandonParagraphBuilder(DomImageBitmap bitmap) {
  final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
  final ImageSource source = image.imageSource!;
  final shader = ui.ImageShader(
    image,
    ui.TileMode.repeated,
    ui.TileMode.repeated,
    _identityMatrix(),
  );
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 16));
  builder.pushStyle(ui.TextStyle(foreground: ui.Paint()..shader = shader));
  builder.addText('X');
  return source;
}

class _ThrowingBackendImage implements BackendImage {
  @override
  int get width => 4;

  @override
  int get height => 4;

  @override
  void dispose() {
    throw StateError('Simulated backend disposal failure');
  }

  @override
  bool isCloneOf(BackendImage other) => identical(this, other);
}

Future<EngineImage> _createBitmapBackedImage() async {
  final DomImageBitmap bitmap = await createImageBitmap(createBlankDomImageData(4, 4));
  return renderer.createImageFromImageBitmap(bitmap) as EngineImage;
}

class _MockFinalizer implements Finalizer {
  final List<({Object target, Object value, Object? detach})> registeredPairs =
      <({Object target, Object value, Object? detach})>[];

  @override
  void attach(Object target, Object value, {Object? detach}) {
    registeredPairs.add((target: target, value: value, detach: detach));
  }

  @override
  void detach(Object detach) {
    registeredPairs.removeWhere((pair) => identical(pair.detach, detach));
  }

  void trigger(Object target) {
    final List<({Object target, Object value, Object? detach})> matches = registeredPairs
        .where((pair) => identical(pair.target, target))
        .toList();
    for (final match in matches) {
      if (match.value is UniqueRef<dynamic>) {
        (match.value as UniqueRef<dynamic>).collect();
      }
    }
  }
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
