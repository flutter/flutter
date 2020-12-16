// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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
      expect(image.debugDisposed, false);
      image.dispose();
      expect(image.debugDisposed, true);

      // Disallow usage after disposal
      expect(() => image.frameCount, throwsAssertionError);
      expect(() => image.repetitionCount, throwsAssertionError);
      expect(() => image.getNextFrame(), throwsAssertionError);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
      testCollector.collectNow();
    });

    test('CkImage toString', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.debugDisposed, false);
      expect(image.box.isDeletedPermanently, false);
      image.dispose();
      expect(image.debugDisposed, true);
      expect(image.box.isDeletedPermanently, true);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      final SkiaObjectBox<CkImage, SkImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      final CkImage clone = image.clone();
      expect(box.refCount, 2);
      expect(box.debugGetStackTraces().length, 2);

      expect(image.isCloneOf(clone), true);
      expect(box.isDeletedPermanently, false);

      testCollector.collectNow();
      expect(skImage.isDeleted(), false);
      image.dispose();
      expect(box.refCount, 1);
      expect(box.isDeletedPermanently, false);

      testCollector.collectNow();
      expect(skImage.isDeleted(), false);
      clone.dispose();
      expect(box.refCount, 0);
      expect(box.isDeletedPermanently, true);

      testCollector.collectNow();
      expect(skImage.isDeleted(), true);
      expect(box.debugGetStackTraces().length, 0);
      testCollector.collectNow();
    });

    test('CkImage toByteData', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect((await image.toByteData()).lengthInBytes, greaterThan(0));
      expect((await image.toByteData(format: ui.ImageByteFormat.png)).lengthInBytes, greaterThan(0));
      testCollector.collectNow();
    });

    // Regression test for https://github.com/flutter/flutter/issues/72469
    test('CkImage can be resurrected', () {
      browserSupportsFinalizationRegistry = false;
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
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
  String responseType;

  @override
  int timeout = 10;

  @override
  bool withCredentials = false;

  @override
  void abort() {
    throw UnimplementedError();
  }

  @override
  void addEventListener(String type, listener, [bool useCapture]) {
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
  void open(String method, String url, {bool async, String user, String password}) {}

  @override
  void overrideMimeType(String mime) {
    throw UnimplementedError();
  }

  @override
  int get readyState => throw UnimplementedError();

  @override
  void removeEventListener(String type, listener, [bool useCapture]) {
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
