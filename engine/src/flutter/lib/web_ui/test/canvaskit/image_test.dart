// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../matchers.dart';
import 'common.dart';
import 'test_data.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit image', () {
    setUpCanvasKitTest();

    tearDown(() {
      debugRestoreHttpRequestFactory();
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
      testCollector.collectNow();
    });

    test('CkAnimatedImage remembers last animation position after resurrection', () async {
      browserSupportsFinalizationRegistry = false;

      Future<void> expectFrameData(ui.FrameInfo frame, List<int> data) async {
        final ByteData frameData = (await frame.image.toByteData())!;
        expect(frameData.buffer.asUint8List(), Uint8List.fromList(data));
      }

      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
      expect(image.frameCount, 3);
      expect(image.repetitionCount, -1);

      final ui.FrameInfo frame1 = await image.getNextFrame();
      expectFrameData(frame1, <int>[0, 255, 0, 255]);
      final ui.FrameInfo frame2 = await image.getNextFrame();
      expectFrameData(frame2, <int>[0, 0, 255, 255]);

      // Pretend that the image is temporarily deleted.
      image.delete();
      image.didDelete();

      // Check that we got the 3rd frame after resurrection.
      final ui.FrameInfo frame3 = await image.getNextFrame();
      expectFrameData(frame3, <int>[255, 0, 0, 255]);

      testCollector.collectNow();
    });

    test('CkImage toString', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.debugDisposed, isFalse);
      expect(image.box.isDeletedPermanently, isFalse);
      image.dispose();
      expect(image.debugDisposed, isTrue);
      expect(image.box.isDeletedPermanently, isTrue);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      final SkiaObjectBox<CkImage, SkImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      final CkImage clone = image.clone();
      expect(box.refCount, 2);
      expect(box.debugGetStackTraces().length, 2);

      expect(image.isCloneOf(clone), isTrue);
      expect(box.isDeletedPermanently, isFalse);

      testCollector.collectNow();
      expect(skImage.isDeleted(), isFalse);
      image.dispose();
      expect(box.refCount, 1);
      expect(box.isDeletedPermanently, isFalse);

      testCollector.collectNow();
      expect(skImage.isDeleted(), isFalse);
      clone.dispose();
      expect(box.refCount, 0);
      expect(box.isDeletedPermanently, isTrue);

      testCollector.collectNow();
      expect(skImage.isDeleted(), isTrue);
      expect(box.debugGetStackTraces().length, 0);
      testCollector.collectNow();
    });

    test('CkImage toByteData', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect((await image.toByteData()).lengthInBytes, greaterThan(0));
      expect((await image.toByteData(format: ui.ImageByteFormat.png)).lengthInBytes, greaterThan(0));
      testCollector.collectNow();
    });

    // Regression test for https://github.com/flutter/flutter/issues/72469
    test('CkImage can be resurrected', () {
      browserSupportsFinalizationRegistry = false;
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)!
              .makeImageAtCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.box.rawSkiaObject, isNotNull);

      // Pretend that the image is temporarily deleted.
      image.box.delete();
      image.box.didDelete();
      expect(image.box.rawSkiaObject, isNull);

      // Attempting to access the skia object here would previously throw
      // "Stack Overflow" in Safari.
      expect(image.box.skiaObject, isNotNull);
      testCollector.collectNow();
    });

    test('skiaInstantiateWebImageCodec loads an image from the network',
        () async {
      httpRequestFactory = () {
        return TestHttpRequest()
          ..status = 200
          ..onLoad = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
            html.ProgressEvent('test error'),
          ])
          ..response = kTransparentImage.buffer;
      };
      final ui.Codec codec = await skiaInstantiateWebImageCodec('http://image-server.com/picture.jpg', null);
      expect(codec.frameCount, 1);
      final ui.Image image = (await codec.getNextFrame()).image;
      expect(image.height, 1);
      expect(image.width, 1);
      testCollector.collectNow();
    });

    test('skiaInstantiateWebImageCodec throws exception on request error',
        () async {
      httpRequestFactory = () {
        return TestHttpRequest()
          ..onError = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
            html.ProgressEvent('test error'),
          ]);
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
      testCollector.collectNow();
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
      testCollector.collectNow();
    });

    test('skiaInstantiateWebImageCodec includes URL in the error for malformed image',
        () async {
      httpRequestFactory = () {
        return TestHttpRequest()
          ..status = 200
          ..onLoad = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[
            html.ProgressEvent('test error'),
          ])
          ..response = Uint8List(0).buffer;
      };
      try {
        await skiaInstantiateWebImageCodec('http://image-server.com/picture.jpg', null);
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        expect(
          exception.toString(),
          'ImageCodecException: Failed to decode image data.\n'
          'Image source: http://image-server.com/picture.jpg',
        );
      }
      testCollector.collectNow();
    });

    test('Reports error when failing to decode image data', () async {
      try {
        await ui.instantiateImageCodec(Uint8List(0));
        fail('Expected to throw');
      } on ImageCodecException catch (exception) {
        expect(
          exception.toString(),
          'ImageCodecException: Failed to decode image data.\n'
          'Image source: encoded image bytes'
        );
      }
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

class TestHttpRequest implements html.HttpRequest {
  @override
  String responseType = 'invalid';

  @override
  int? timeout = 10;

  @override
  bool? withCredentials = false;

  @override
  void abort() {
    throw UnimplementedError();
  }

  @override
  void addEventListener(String type, listener, [bool? useCapture]) {
    throw UnimplementedError();
  }

  @override
  bool dispatchEvent(html.Event event) {
    throw UnimplementedError();
  }

  @override
  String getAllResponseHeaders() {
    throw UnimplementedError();
  }

  @override
  String getResponseHeader(String name) {
    throw UnimplementedError();
  }

  @override
  html.Events get on => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onAbort => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> onError = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[]);

  @override
  Stream<html.ProgressEvent> onLoad = Stream<html.ProgressEvent>.fromIterable(<html.ProgressEvent>[]);

  @override
  Stream<html.ProgressEvent> get onLoadEnd => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onLoadStart => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onProgress => throw UnimplementedError();

  @override
  Stream<html.Event> get onReadyStateChange => throw UnimplementedError();

  @override
  Stream<html.ProgressEvent> get onTimeout => throw UnimplementedError();

  @override
  void open(String method, String url, {bool? async, String? user, String? password}) {}

  @override
  void overrideMimeType(String mime) {
    throw UnimplementedError();
  }

  @override
  int get readyState => throw UnimplementedError();

  @override
  void removeEventListener(String type, listener, [bool? useCapture]) {
    throw UnimplementedError();
  }

  @override
  dynamic response;

  @override
  Map<String, String> get responseHeaders => throw UnimplementedError();

  @override
  String get responseText => throw UnimplementedError();

  @override
  String get responseUrl => throw UnimplementedError();

  @override
  html.Document get responseXml => throw UnimplementedError();

  @override
  void send([dynamic bodyOrData]) {
  }

  @override
  void setRequestHeader(String name, String value) {
    throw UnimplementedError();
  }

  @override
  int status = -1;

  @override
  String get statusText => throw UnimplementedError();

  @override
  html.HttpRequestUpload get upload => throw UnimplementedError();
}
