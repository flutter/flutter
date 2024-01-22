// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/matchers.dart';
import 'common.dart';
import 'test_data.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit Images', () {
    setUpCanvasKitTest(withImplicitView: true);

    tearDown(() {
      mockHttpFetchResponseFactory = null;
    });

    _testCkAnimatedImage();
    _testForImageCodecs(useBrowserImageDecoder: false);

    if (browserSupportsImageDecoder) {
      _testForImageCodecs(useBrowserImageDecoder: true);
      _testCkBrowserImageDecoder();
    }

    test('isAvif', () {
      expect(isAvif(Uint8List.fromList(<int>[])), isFalse);
      expect(isAvif(Uint8List.fromList(<int>[1, 2, 3])), isFalse);
      expect(
        isAvif(Uint8List.fromList(<int>[
          0x00, 0x00, 0x00, 0x1c, 0x66, 0x74, 0x79, 0x70,
          0x61, 0x76, 0x69, 0x66, 0x00, 0x00, 0x00, 0x00,
        ])),
        isTrue,
      );
      expect(
        isAvif(Uint8List.fromList(<int>[
          0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
          0x61, 0x76, 0x69, 0x66, 0x00, 0x00, 0x00, 0x00,
        ])),
        isTrue,
      );
    });
  }, skip: isSafari);
}

void _testForImageCodecs({required bool useBrowserImageDecoder}) {
  final String mode = useBrowserImageDecoder ? 'webcodecs' : 'wasm';
  final List<String> warnings = <String>[];
  late void Function(String) oldPrintWarning;

  group('($mode)', () {
    setUp(() {
      browserSupportsImageDecoder = useBrowserImageDecoder;
      warnings.clear();
    });

    setUpAll(() {
      oldPrintWarning = printWarning;
      printWarning = (String warning) {
        warnings.add(warning);
      };
    });

    tearDown(() {
      debugResetBrowserSupportsImageDecoder();
    });

    tearDownAll(() {
      printWarning = oldPrintWarning;
    });

    test('CkAnimatedImage can be explicitly disposed of', () {
      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kTransparentImage, 'test');
      expect(image.debugDisposed, isFalse);
      image.dispose();
      expect(image.debugDisposed, isTrue);

      // Disallow usage after disposal
      expect(() => image.frameCount, throwsAssertionError);
      expect(() => image.repetitionCount, throwsAssertionError);
      expect(() => image.getNextFrame(), throwsAssertionError);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
    });

    test('CkAnimatedImage iterates frames correctly', () async {
      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
      expect(image.frameCount, 3);
      expect(image.repetitionCount, -1);

      final ui.FrameInfo frame1 = await image.getNextFrame();
      await expectFrameData(frame1, <int>[255, 0, 0, 255]);
      final ui.FrameInfo frame2 = await image.getNextFrame();
      await expectFrameData(frame2, <int>[0, 255, 0, 255]);
      final ui.FrameInfo frame3 = await image.getNextFrame();
      await expectFrameData(frame3, <int>[0, 0, 255, 255]);
    });

    test('CkImage toString', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.debugDisposed, isFalse);
      expect(image.box.isDisposed, isFalse);
      image.dispose();
      expect(image.debugDisposed, isTrue);
      expect(image.box.isDisposed, isTrue);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
    });

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      final CountedRef<CkImage, SkImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      final CkImage clone = image.clone();
      expect(box.refCount, 2);
      expect(box.debugGetStackTraces().length, 2);

      expect(image.isCloneOf(clone), isTrue);
      expect(box.isDisposed, isFalse);

      expect(skImage.isDeleted(), isFalse);
      image.dispose();
      expect(box.refCount, 1);
      expect(box.isDisposed, isFalse);

      expect(skImage.isDeleted(), isFalse);
      clone.dispose();
      expect(box.refCount, 0);
      expect(box.isDisposed, isTrue);

      expect(skImage.isDeleted(), isTrue);
      expect(box.debugGetStackTraces().length, 0);
    });

    test('CkImage toByteData', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect((await image.toByteData()).lengthInBytes, greaterThan(0));
      expect((await image.toByteData(format: ui.ImageByteFormat.png)).lengthInBytes, greaterThan(0));
    });

    test('toByteData with decodeImageFromPixels on videoFrame formats', () async {
      // This test ensures that toByteData() returns pixels that can be used by decodeImageFromPixels
      // for the following videoFrame formats:
      // [BGRX, I422, I420, I444, BGRA]
      final HttpFetchResponse listingResponse = await httpFetch('/test_images/');
      final List<String> testFiles = (await listingResponse.json() as List<dynamic>).cast<String>();

      Future<ui.Image> testDecodeFromPixels(Uint8List pixels, int width, int height) async {
        final Completer<ui.Image> completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pixels,
          width,
          height,
          ui.PixelFormat.rgba8888,
          (ui.Image image) {
            completer.complete(image);
          },
        );
        return completer.future;
      }

      // Sanity-check the test file list. If suddenly test files are moved or
      // deleted, and the test server returns an empty list, or is missing some
      // important test files, we want to know.
      expect(testFiles, isNotEmpty);
      expect(testFiles, contains(matches(RegExp(r'.*\.jpg'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.png'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.gif'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.webp'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.bmp'))));

      for (final String testFile in testFiles) {
        final HttpFetchResponse imageResponse = await httpFetch('/test_images/$testFile');
        final Uint8List imageData = await imageResponse.asUint8List();
        final ui.Codec codec = await skiaInstantiateImageCodec(imageData);
        expect(codec.frameCount, greaterThan(0));
        expect(codec.repetitionCount, isNotNull);

        final ui.FrameInfo frame = await codec.getNextFrame();
        final CkImage ckImage = frame.image as CkImage;
        final ByteData imageBytes = await ckImage.toByteData();
        expect(imageBytes.lengthInBytes, greaterThan(0));

        final Uint8List pixels = imageBytes.buffer.asUint8List();
        final ui.Image testImage = await testDecodeFromPixels(pixels, ckImage.width, ckImage.height);
        expect(testImage, isNotNull);
        codec.dispose();
      }
      // TODO(hterkelsen): Firefox and Safari do not currently support ImageDecoder.
      // TODO(jacksongardner): enable on wasm
      // see https://github.com/flutter/flutter/issues/118334
    }, skip: isFirefox || isSafari || isWasm);

    test('CkImage.clone also clones the VideoFrame', () async {
      final CkBrowserImageDecoder image = await CkBrowserImageDecoder.create(
        data: kAnimatedGif,
        debugSource: 'test',
      );
      final ui.FrameInfo frame = await image.getNextFrame();
      final CkImage ckImage = frame.image as CkImage;
      expect(ckImage.videoFrame, isNotNull);

      final CkImage imageClone = ckImage.clone();
      expect(imageClone.videoFrame, isNotNull);

      final ByteData png = await imageClone.toByteData(format: ui.ImageByteFormat.png);
      expect(png, isNotNull);

      // The precise PNG encoding is browser-specific, but we can check the file
      // signature.
      expect(detectContentType(png.buffer.asUint8List()), 'image/png');
    // TODO(hterkelsen): Firefox and Safari do not currently support ImageDecoder.
    }, skip: isFirefox || isSafari);

    test('skiaInstantiateWebImageCodec loads an image from the network',
        () async {
      mockHttpFetchResponseFactory = (String url) async {
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: kTransparentImage.buffer),
        );
      };

      final ui.Codec codec = await skiaInstantiateWebImageCodec(
          'http://image-server.com/picture.jpg', null);
      expect(codec.frameCount, 1);
      final ui.Image image = (await codec.getNextFrame()).image;
      expect(image.height, 1);
      expect(image.width, 1);
    });

    test('instantiateImageCodec respects target image size',
        () async {
      const List<List<int>> targetSizes = <List<int>>[
        <int>[1, 1],
        <int>[1, 2],
        <int>[2, 3],
        <int>[3, 4],
        <int>[4, 4],
        <int>[10, 20],
      ];

      for (final List<int> targetSize in targetSizes) {
        final int targetWidth = targetSize[0];
        final int targetHeight = targetSize[1];

        final ui.Codec codec = await ui.instantiateImageCodec(
          k4x4PngImage,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );

        final ui.Image image = (await codec.getNextFrame()).image;
        expect(image.width, targetWidth);
        expect(image.height, targetHeight);
        image.dispose();
        codec.dispose();
      }
    });

    test('instantiateImageCodec with multi-frame image does not support targetWidth/targetHeight',
        () async {
        final ui.Codec codec = await ui.instantiateImageCodec(
          kAnimatedGif,
          targetWidth: 2,
          targetHeight: 3,
        );
        final ui.Image image = (await codec.getNextFrame()).image;

        expect(
        warnings,
        containsAllInOrder(
          <String>[
            'targetWidth and targetHeight for multi-frame images not supported',
          ],
        ),
      );

        // expect the re-size did not happen, kAnimatedGif is [1x1]
        expect(image.width, 1);
        expect(image.height, 1);
        image.dispose();
        codec.dispose();
    });

    test('skiaInstantiateWebImageCodec throws exception on request error',
        () async {
      mockHttpFetchResponseFactory = (String url) async {
        throw HttpFetchError(url, requestError: 'This is a test request error.');
      };

      try {
        await skiaInstantiateWebImageCodec('url-does-not-matter', null);
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        expect(
          exception.toString(),
          'ImageCodecException: Failed to load network image.\n'
          'Image URL: url-does-not-matter\n'
          'Trying to load an image from another domain? Find answers at:\n'
          'https://flutter.dev/docs/development/platform-integration/web-images',
        );
      }
    });

    test('skiaInstantiateWebImageCodec throws exception on HTTP error',
        () async {
      try {
        await skiaInstantiateWebImageCodec('/does-not-exist.jpg', null);
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        expect(
          exception.toString(),
          'ImageCodecException: Failed to load network image.\n'
          'Image URL: /does-not-exist.jpg\n'
          'Server response code: 404',
        );
      }
    });

    test('skiaInstantiateWebImageCodec includes URL in the error for malformed image',
        () async {
      mockHttpFetchResponseFactory = (String url) async {
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      try {
        await skiaInstantiateWebImageCodec('http://image-server.com/picture.jpg', null);
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        if (!browserSupportsImageDecoder) {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to decode image data.\n'
            'Image source: http://image-server.com/picture.jpg',
          );
        } else {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to detect image file format using the file header.\n'
            'File header was empty.\n'
            'Image source: http://image-server.com/picture.jpg',
          );
        }
      }
    });

    test('Reports error when failing to decode empty image data', () async {
      try {
        await ui.instantiateImageCodec(Uint8List(0));
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        if (!browserSupportsImageDecoder) {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to decode image data.\n'
            'Image source: encoded image bytes',
          );
        } else {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to detect image file format using the file header.\n'
            'File header was empty.\n'
            'Image source: encoded image bytes',
          );
        }
      }
    });

    test('Reports error when failing to decode malformed image data', () async {
      try {
        await ui.instantiateImageCodec(Uint8List.fromList(<int>[
          0xFF, 0xD8, 0xFF, 0xDB, 0x00, 0x00, 0x00,
        ]));
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        if (!browserSupportsImageDecoder) {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to decode image data.\n'
            'Image source: encoded image bytes'
          );
        } else {
          expect(
            exception.toString(),
            // Browser error message is not checked as it can depend on the
            // browser engine and version.
            matches(RegExp(
              r"ImageCodecException: Failed to decode image using the browser's ImageDecoder API.\n"
              r'Image source: encoded image bytes\n'
              r'Original browser error: .+'
            ))
          );
        }
      }
    });

    test('Includes file header in the error message when fails to detect file type', () async {
      try {
        await ui.instantiateImageCodec(Uint8List.fromList(<int>[
          0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x00,
        ]));
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        if (!browserSupportsImageDecoder) {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to decode image data.\n'
            'Image source: encoded image bytes'
          );
        } else {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to detect image file format using the file header.\n'
            'File header was [0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x00].\n'
            'Image source: encoded image bytes'
          );
        }
      }
    });

    test('Provides readable error message when image type is unsupported', () async {
      addTearDown(() {
        debugContentTypeDetector = null;
      });
      debugContentTypeDetector = (_) {
        return 'unsupported/image-type';
      };
      try {
        await ui.instantiateImageCodec(Uint8List.fromList(<int>[
          0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x00,
        ]));
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        if (!browserSupportsImageDecoder) {
          expect(
            exception.toString(),
            'ImageCodecException: Failed to decode image data.\n'
            'Image source: encoded image bytes'
          );
        } else {
          expect(
            exception.toString(),
            "ImageCodecException: Image file format (unsupported/image-type) is not supported by this browser's ImageDecoder API.\n"
            'Image source: encoded image bytes'
          );
        }
      }
    });

    test('decodeImageFromPixels', () async {
      Future<ui.Image> testDecodeFromPixels(int width, int height) async {
        final Completer<ui.Image> completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          Uint8List.fromList(List<int>.filled(width * height * 4, 0)),
          width,
          height,
          ui.PixelFormat.rgba8888,
          (ui.Image image) {
            completer.complete(image);
          },
        );
        return completer.future;
      }

      final ui.Image image1 = await testDecodeFromPixels(10, 20);
      expect(image1, isNotNull);
      expect(image1.width, 10);
      expect(image1.height, 20);

      final ui.Image image2 = await testDecodeFromPixels(40, 100);
      expect(image2, isNotNull);
      expect(image2.width, 40);
      expect(image2.height, 100);
    });

    test('decodeImageFromPixels respects target image size', () async {
      Future<ui.Image> testDecodeFromPixels(int width, int height, int targetWidth, int targetHeight) async {
        final Completer<ui.Image> completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          Uint8List.fromList(List<int>.filled(width * height * 4, 0)),
          width,
          height,
          ui.PixelFormat.rgba8888,
          (ui.Image image) {
            completer.complete(image);
          },
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        return completer.future;
      }

      const List<List<int>> targetSizes = <List<int>>[
        <int>[1, 1],
        <int>[1, 2],
        <int>[2, 3],
        <int>[3, 4],
        <int>[4, 4],
        <int>[10, 20],
      ];

      for (final List<int> targetSize in targetSizes) {
        final int targetWidth = targetSize[0];
        final int targetHeight = targetSize[1];

        final ui.Image image = await testDecodeFromPixels(10, 20, targetWidth, targetHeight);

        expect(image.width, targetWidth);
        expect(image.height, targetHeight);
        image.dispose();
      }
    });

    test('decodeImageFromPixels upscale when allowUpscaling is false', () async {
      Future<ui.Image> testDecodeFromPixels(int width, int height) async {
        final Completer<ui.Image> completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          Uint8List.fromList(List<int>.filled(width * height * 4, 0)),
          width,
          height,
          ui.PixelFormat.rgba8888,
          (ui.Image image) {
            completer.complete(image);
          },
          targetWidth: 20,
          targetHeight: 30,
          allowUpscaling: false
        );
        return completer.future;
      }
      expect(() async => testDecodeFromPixels(10, 20), throwsAssertionError);
    });

    test('Decode test images', () async {
      final HttpFetchResponse listingResponse = await httpFetch('/test_images/');
      final List<String> testFiles = (await listingResponse.json() as List<dynamic>).cast<String>();

      // Sanity-check the test file list. If suddenly test files are moved or
      // deleted, and the test server returns an empty list, or is missing some
      // important test files, we want to know.
      expect(testFiles, isNotEmpty);
      expect(testFiles, contains(matches(RegExp(r'.*\.jpg'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.png'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.gif'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.webp'))));
      expect(testFiles, contains(matches(RegExp(r'.*\.bmp'))));

      for (final String testFile in testFiles) {
        final HttpFetchResponse imageResponse = await httpFetch('/test_images/$testFile');
        final Uint8List imageData = await imageResponse.asUint8List();
        final ui.Codec codec = await skiaInstantiateImageCodec(imageData);
        expect(codec.frameCount, greaterThan(0));
        expect(codec.repetitionCount, isNotNull);
        for (int i = 0; i < codec.frameCount; i++) {
          final ui.FrameInfo frame = await codec.getNextFrame();
          expect(frame.duration, isNotNull);
          expect(frame.image, isNotNull);
        }
        codec.dispose();
      }
    });

    // Reproduces https://skbug.com/12721
    test('decoded image can be read back from picture', () async {
      final HttpFetchResponse imageResponse = await httpFetch('/test_images/mandrill_128.png');
      final Uint8List imageData = await imageResponse.asUint8List();
      final ui.Codec codec = await skiaInstantiateImageCodec(imageData);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final CkImage image = frame.image as CkImage;

      final CkImage snapshot;
      {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(10, 10);
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawRect(
          const ui.Rect.fromLTRB(5, 5, 20, 20),
          CkPaint(),
        );
        canvas.drawImage(image, ui.Offset.zero, CkPaint());
        canvas.drawRect(
          const ui.Rect.fromLTRB(90, 90, 105, 105),
          CkPaint(),
        );
        sb.addPicture(ui.Offset.zero, recorder.endRecording());
        sb.pop();
        snapshot = await sb.build().toImage(150, 150) as CkImage;
      }

      {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawImage(snapshot, ui.Offset.zero, CkPaint());
        sb.addPicture(ui.Offset.zero, recorder.endRecording());

        await matchSceneGolden(
            'canvaskit_read_back_decoded_image_$mode.png', sb.build(),
            region: const ui.Rect.fromLTRB(0, 0, 150, 150));
      }

      image.dispose();
      codec.dispose();
    });

    // This is a regression test for the issues with transferring textures from
    // one GL context to another, such as:
    //
    //  * https://github.com/flutter/flutter/issues/86809
    //  * https://github.com/flutter/flutter/issues/91881
    test('the same image can be rendered on difference surfaces', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final ui.Codec codec = await ui.instantiateImageCodec(k4x4PngImage);
      final CkImage image = (await codec.getNextFrame()).image as CkImage;

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(4, 4);
      {
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.save();
        canvas.scale(16, 16);
        canvas.drawImage(image, ui.Offset.zero, CkPaint());
        canvas.restore();
        canvas.drawParagraph(makeSimpleText('1'), const ui.Offset(4, 4));
        sb.addPicture(ui.Offset.zero, recorder.endRecording());
      }
      sb.addPlatformView(0, width: 100, height: 100);
      sb.pushOffset(20, 20);
      {
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.save();
        canvas.scale(16, 16);
        canvas.drawImage(image, ui.Offset.zero, CkPaint());
        canvas.restore();
        canvas.drawParagraph(makeSimpleText('2'), const ui.Offset(2, 2));
        sb.addPicture(ui.Offset.zero, recorder.endRecording());
      }

      await matchSceneGolden(
          'canvaskit_cross_gl_context_image_$mode.png', sb.build(),
          region: const ui.Rect.fromLTRB(0, 0, 100, 100));

      await disposePlatformView(0);
    });

    test('toImageSync with texture-backed image', () async {
      final HttpFetchResponse imageResponse = await httpFetch('/test_images/mandrill_128.png');
      final Uint8List imageData = await imageResponse.asUint8List();
      final ui.Codec codec = await skiaInstantiateImageCodec(imageData);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final CkImage mandrill = frame.image as CkImage;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        mandrill,
        const ui.Rect.fromLTWH(0, 0, 128, 128),
        const ui.Rect.fromLTWH(0, 0, 128, 128),
        ui.Paint(),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = picture.toImageSync(50, 50);

      expect(image.width, 50);
      expect(image.height, 50);

      final ByteData? data = await image.toByteData();
      expect(data, isNotNull);
      expect(data!.lengthInBytes, 50 * 50 * 4);
      expect(data.buffer.asUint32List().any((int byte) => byte != 0), isTrue);

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      {
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.save();
        canvas.drawImage(image as CkImage, ui.Offset.zero, CkPaint());
        canvas.restore();
        sb.addPicture(ui.Offset.zero, recorder.endRecording());
      }

      await matchSceneGolden(
          'canvaskit_picture_texture_toimage.png', sb.build(),
          region: const ui.Rect.fromLTRB(0, 0, 128, 128));
      mandrill.dispose();
      codec.dispose();
    });

    test('decoded image can be read back from picture', () async {
      final HttpFetchResponse imageResponse = await httpFetch('/test_images/mandrill_128.png');
      final Uint8List imageData = await imageResponse.asUint8List();
      final ui.Codec codec = await skiaInstantiateImageCodec(imageData);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final CkImage image = frame.image as CkImage;

      final CkImage snapshot;
      {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(10, 10);
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawRect(
          const ui.Rect.fromLTRB(5, 5, 20, 20),
          CkPaint(),
        );
        canvas.drawImage(image, ui.Offset.zero, CkPaint());
        canvas.drawRect(
          const ui.Rect.fromLTRB(90, 90, 105, 105),
          CkPaint(),
        );
        sb.addPicture(ui.Offset.zero, recorder.endRecording());
        sb.pop();
        snapshot = await sb.build().toImage(150, 150) as CkImage;
      }

      {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        final CkPictureRecorder recorder = CkPictureRecorder();
        final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawImage(snapshot, ui.Offset.zero, CkPaint());
        sb.addPicture(ui.Offset.zero, recorder.endRecording());

        await matchSceneGolden(
            'canvaskit_read_back_decoded_image_$mode.png', sb.build(),
            region: const ui.Rect.fromLTRB(0, 0, 150, 150));
      }

      image.dispose();
      codec.dispose();
    });

    test('can detect JPEG from just magic number', () async {
      expect(
        detectContentType(
          Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xe2, 0x0c, 0x58, 0x49, 0x43, 0x43, 0x5f])),
        'image/jpeg');
    });
  }, timeout: const Timeout.factor(10)); // These tests can take a while. Allow for a longer timeout.
}

/// Tests specific to WASM codecs bundled with CanvasKit.
void _testCkAnimatedImage() {
  test('ImageDecoder toByteData(PNG)', () async {
    final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
    final ui.FrameInfo frame = await image.getNextFrame();
    final ByteData? png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull);

    // The precise PNG encoding is browser-specific, but we can check the file
    // signature.
    expect(detectContentType(png!.buffer.asUint8List()), 'image/png');
  });

  test('CkAnimatedImage toByteData(RGBA)', () async {
    final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
    const List<List<int>> expectedColors = <List<int>>[
      <int>[255, 0, 0, 255],
      <int>[0, 255, 0, 255],
      <int>[0, 0, 255, 255],
    ];
    for (int i = 0; i < image.frameCount; i++) {
      final ui.FrameInfo frame = await image.getNextFrame();
      final ByteData? rgba = await frame.image.toByteData();
      expect(rgba, isNotNull);
      expect(rgba!.buffer.asUint8List(), expectedColors[i]);
    }
  });
}

/// Tests specific to browser image codecs based functionality.
void _testCkBrowserImageDecoder() {
  assert(browserSupportsImageDecoder);

  test('ImageDecoder toByteData(PNG)', () async {
    final CkBrowserImageDecoder image = await CkBrowserImageDecoder.create(
      data: kAnimatedGif,
      debugSource: 'test',
    );
    final ui.FrameInfo frame = await image.getNextFrame();
    final ByteData? png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull);

    // The precise PNG encoding is browser-specific, but we can check the file
    // signature.
    expect(detectContentType(png!.buffer.asUint8List()), 'image/png');
  });

  test('ImageDecoder toByteData(RGBA)', () async {
    final CkBrowserImageDecoder image = await CkBrowserImageDecoder.create(
      data: kAnimatedGif,
      debugSource: 'test',
    );
    const List<List<int>> expectedColors = <List<int>>[
      <int>[255, 0, 0, 255],
      <int>[0, 255, 0, 255],
      <int>[0, 0, 255, 255],
    ];
    for (int i = 0; i < image.frameCount; i++) {
      final ui.FrameInfo frame = await image.getNextFrame();
      final ByteData? rgba = await frame.image.toByteData();
      expect(rgba, isNotNull);
      expect(rgba!.buffer.asUint8List(), expectedColors[i]);
    }
  });

  test('ImageDecoder expires after inactivity', () async {
    const Duration testExpireDuration = Duration(milliseconds: 100);
    debugOverrideWebDecoderExpireDuration(testExpireDuration);

    final CkBrowserImageDecoder image = await CkBrowserImageDecoder.create(
      data: kAnimatedGif,
      debugSource: 'test',
    );

    // ImageDecoder is initialized eagerly to populate `frameCount` and
    // `repetitionCount`.
    final ImageDecoder? decoder1 = image.debugCachedWebDecoder;
    expect(decoder1, isNotNull);
    expect(image.frameCount, 3);
    expect(image.repetitionCount, -1);

    // A frame can be decoded right away.
    final ui.FrameInfo frame1 = await image.getNextFrame();
    await expectFrameData(frame1, <int>[255, 0, 0, 255]);
    expect(frame1, isNotNull);

    // The cached decoder should not yet expire.
    await Future<void>.delayed(testExpireDuration ~/ 2);
    expect(image.debugCachedWebDecoder, same(decoder1));

    // Now it expires.
    await Future<void>.delayed(testExpireDuration);
    expect(image.debugCachedWebDecoder, isNull);

    // A new decoder should be created upon the next frame request.
    final ui.FrameInfo frame2 = await image.getNextFrame();

    // Check that the cached decoder is indeed new.
    final ImageDecoder? decoder2 = image.debugCachedWebDecoder;
    expect(decoder2, isNot(same(decoder1)));
    await expectFrameData(frame2, <int>[0, 255, 0, 255]);

    // Check that the new decoder remembers the last frame index.
    final ui.FrameInfo frame3 = await image.getNextFrame();
    await expectFrameData(frame3, <int>[0, 0, 255, 255]);

    debugRestoreWebDecoderExpireDuration();
  });
}

Future<void> expectFrameData(ui.FrameInfo frame, List<int> data) async {
  final ByteData frameData = (await frame.image.toByteData())!;
  expect(frameData.buffer.asUint8List(), Uint8List.fromList(data));
}
