// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('Codec gives correct repetition count for GIFs', () async {
    final ui.Codec codec = await renderer.instantiateImageCodecFromUrl(
      Uri(path: '/test_images/required.gif'),
    );
    expect(codec.repetitionCount, 0);
    codec.dispose();
  });

  test('renderer.createAnimatedImage throws ImageCodecException on invalid bytes', () {
    expect(
      () => renderer.createAnimatedImage(Uint8List.fromList(<int>[1, 2, 3, 4, 5])),
      throwsA(isA<ImageCodecException>()),
    );
  });

  test('parseMimeType parses and cleans Content-Type headers', () {
    expect(parseMimeType('image/png'), 'image/png');
    expect(parseMimeType('image/jpeg'), 'image/jpeg');
    expect(parseMimeType('IMAGE/PNG'), 'image/png');
    expect(parseMimeType('image/jpeg; charset=utf-8'), 'image/jpeg');
    expect(parseMimeType('  image/gif  ; boundary=abc'), 'image/gif');
    expect(parseMimeType('image/webp;foo=bar;baz=qux'), 'image/webp');
    expect(parseMimeType(''), '');
    expect(parseMimeType(null), isNull);
  });

  test('ui.Image.toByteData(format: ui.ImageByteFormat.png) works without crashing', () async {
    final HttpFetchResponse response = await httpFetch('/test_images/1x1.png');
    final Uint8List pngBytes = (await response.payload.asByteBuffer()).asUint8List();
    final ui.Codec codec = await renderer.instantiateImageCodec(pngBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final ByteData? pngByteData = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(pngByteData, isNotNull);
    expect(pngByteData!.lengthInBytes, isNonZero);

    final Uint8List resultBytes = pngByteData.buffer.asUint8List();
    expect(resultBytes.length, greaterThan(8));
    expect(resultBytes[0], 0x89);
    expect(resultBytes[1], 0x50);
    expect(resultBytes[2], 0x4E);
    expect(resultBytes[3], 0x47);

    image.dispose();
    codec.dispose();
  });

  test(
    'instantiateImageCodecFromUrl works with generic application/octet-stream MIME type via data URL',
    () async {
      const dataUrl =
          'data:application/octet-stream;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final ui.Codec codec = await renderer.instantiateImageCodecFromUrl(Uri.parse(dataUrl));
      expect(codec.frameCount, 1);

      final ui.FrameInfo frame = await codec.getNextFrame();
      expect(frame.image.width, 1);
      expect(frame.image.height, 1);

      codec.dispose();
    },
  );

  test('BrowserImageDecoder closes native decoder if disposed during initialization', () async {
    if (!browserSupportsImageDecoder) {
      return;
    }

    final HttpFetchResponse response = await httpFetch('/test_images/1x1.png');
    final Uint8List pngBytes = (await response.payload.asByteBuffer()).asUint8List();

    final decoder = BrowserImageDecoder(
      contentType: 'image/png',
      dataSource: pngBytes.toJS,
      debugSource: 'test',
    );

    final Future<void> initFuture = decoder.initialize();
    decoder.dispose();
    await initFuture;

    expect(decoder.debugCachedWebDecoder, isNull);
  });

  test(
    '_BrowserEngineCodec.getNextFrame() throws StateError and cleans up if disposed during decode',
    () async {
      if (!browserSupportsImageDecoder) {
        return;
      }

      final HttpFetchResponse response = await httpFetch('/test_images/1x1.png');
      final Uint8List pngBytes = (await response.payload.asByteBuffer()).asUint8List();

      final ui.Codec codec = await renderer.instantiateImageCodec(pngBytes);
      final Future<ui.FrameInfo> frameFuture = codec.getNextFrame();
      codec.dispose();

      expect(frameFuture, throwsA(isA<StateError>()));
    },
  );

  test(
    '_SkiaEngineCodec.getNextFrame() throws StateError and cleans up if disposed during decode',
    () async {
      if (isSkwasm) {
        // Skwasm does not compile animated image decoders in the Wasm fallback path
        // (it relies entirely on the browser's native ImageDecoder).
        return;
      }

      final HttpFetchResponse response = await httpFetch('/test_images/flightAnim.gif');
      final Uint8List gifBytes = (await response.payload.asByteBuffer()).asUint8List();

      final bool originalDecoderSupport = browserSupportsImageDecoder;
      browserSupportsImageDecoder = false;
      try {
        final ui.Codec codec = await renderer.instantiateImageCodec(gifBytes);
        final Future<ui.FrameInfo> frameFuture = codec.getNextFrame();
        codec.dispose();

        expect(frameFuture, throwsA(isA<StateError>()));
      } finally {
        browserSupportsImageDecoder = originalDecoderSupport;
      }
    },
  );

  test('handleProgressAndGetStream bypasses stream teeing when chunkCallback is null', () async {
    final mockBody = JSObject();
    final mockResponse = JSObject();
    mockResponse['body'] = mockBody;

    final DomReadableStream result = await handleProgressAndGetStream(
      mockResponse as DomResponse,
      null,
    );
    expect(identical(result, mockBody), isTrue);
  });

  test(
    'handleProgressAndGetStream bypasses stream teeing when Content-Length is missing',
    () async {
      final mockBody = JSObject();
      final mockHeaders = JSObject();
      mockHeaders['get'] = ((JSString name) => null).toJS;

      final mockResponse = JSObject();
      mockResponse['body'] = mockBody;
      mockResponse['headers'] = mockHeaders;

      final DomReadableStream result = await handleProgressAndGetStream(
        mockResponse as DomResponse,
        (int loaded, int total) {},
      );
      expect(identical(result, mockBody), isTrue);
    },
  );

  test(
    'handleProgressAndGetStream tees the stream when chunkCallback and Content-Length are present',
    () async {
      final DomResponse response = await rawHttpGet('/test_images/1x1.png');
      final DomReadableStream originalBody = response.body;

      var callbackCalled = false;
      final DomReadableStream result = await handleProgressAndGetStream(response, (
        int loaded,
        int total,
      ) {
        callbackCalled = true;
      });

      expect(identical(result, originalBody), isFalse);

      // Read the result stream to trigger the progress callback on the teed stream
      final DomStreamReader reader = result.getReader();
      while (true) {
        final DomStreamChunk chunk = await reader.read();
        if (chunk.done) {
          break;
        }
      }

      expect(callbackCalled, isTrue);
    },
  );

  test('ImageDecoder.dispose is robust against throwing callbacks', () async {
    if (!browserSupportsImageDecoder) {
      return;
    }

    final HttpFetchResponse response = await httpFetch('/test_images/1x1.png');
    final Uint8List pngBytes = (await response.payload.asByteBuffer()).asUint8List();

    final decoder = BrowserImageDecoder(
      contentType: 'image/png',
      dataSource: pngBytes.toJS,
      debugSource: 'test',
    );

    await decoder.initialize();
    expect(decoder.debugCachedWebDecoder, isNotNull);

    var secondCallbackCalled = false;
    decoder.addDisposeCallback(() {
      throw Exception('Callback failure');
    });
    decoder.addDisposeCallback(() {
      secondCallbackCalled = true;
    });

    decoder.dispose();

    expect(secondCallbackCalled, isTrue);
    expect(decoder.debugCachedWebDecoder, isNull);
  });
}
