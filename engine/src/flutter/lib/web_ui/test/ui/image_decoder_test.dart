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

  test('instantiateImageCodecFromUrl works with generic application/octet-stream MIME type via data URL', () async {
    const dataUrl =
        'data:application/octet-stream;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

    final ui.Codec codec = await renderer.instantiateImageCodecFromUrl(Uri.parse(dataUrl));
    expect(codec.frameCount, 1);

    final ui.FrameInfo frame = await codec.getNextFrame();
    expect(frame.image.width, 1);
    expect(frame.image.height, 1);

    codec.dispose();
  });

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

    final mockResponse = _TestHttpFetchResponse(stream: mockBody as DomReadableStream);

    final DomReadableStream result = await handleProgressAndGetStream(mockResponse, null);
    expect(result, mockBody);
  });

  test(
    'handleProgressAndGetStream bypasses stream teeing when Content-Length is missing',
    () async {
      final mockBody = JSObject();

      final mockResponse = _TestHttpFetchResponse(stream: mockBody as DomReadableStream);

      final DomReadableStream result = await handleProgressAndGetStream(
        mockResponse,
        (int loaded, int total) {},
      );
      expect(result, mockBody);
    },
  );

  test(
    'handleProgressAndGetStream tees the stream when chunkCallback and Content-Length are present',
    () async {
      final HttpFetchResponse response = await httpFetch('/test_images/1x1.png');
      final DomReadableStream originalBody = response.payload.stream;

      var callbackCalled = false;
      final DomReadableStream result = await handleProgressAndGetStream(response, (
        int loaded,
        int total,
      ) {
        callbackCalled = true;
      });

      expect(result, isNot(originalBody));

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

  test('BrowserImageDecoder calls dispose callbacks on initialization failure', () async {
    if (!browserSupportsImageDecoder) {
      return;
    }

    final decoder = BrowserImageDecoder(
      contentType: 'image/png',
      // Providing invalid/empty data will cause initialization/decoding to fail
      dataSource: Uint8List(0).toJS,
      debugSource: 'test',
    );

    var disposeCalled = false;
    decoder.addDisposeCallback(() {
      disposeCalled = true;
    });

    try {
      await decoder.initialize();
      fail('initialize should have thrown an exception');
    } catch (e) {
      decoder.dispose();
      expect(e, isA<ImageCodecException>());
    }

    expect(disposeCalled, isTrue);
  });

  // Exercises the decode routing used when the browser has no `ImageDecoder`.
  // This is the path Safari and Firefox take, and the only place
  // `Renderer.supportsAnimatedImages` is consulted.
  //
  // `supportsAnimatedImages` is a property of the build under test rather than
  // something a test can set: it is true for CanvasKit and false for the skwasm
  // variants whose animated codecs are stubbed out. Each test below therefore
  // asserts the behavior appropriate to the build it is running in, and CI
  // covers both sides (`chrome-dart2js-canvaskit-ui` for true,
  // `chrome-coi-dart2wasm-skwasm-ui` and `chrome-dart2wasm-wimp-ui` for false).
  //
  // These tests assert on `frameCount` rather than on the decoded pixels or
  // dimensions. `frameCount` is what distinguishes the two routes (1 for the
  // still-image path, >1 for a backend animated codec) and, unlike the decoded
  // image, it is reliable today.
  // TODO(gaaclarke): Assert the decoded dimensions as well once images decoded
  // through `createImageBitmap` stop reporting a size of 0x0 under skwasm.
  group('decode routing when ImageDecoder is unavailable', () {
    setUp(() {
      browserSupportsImageDecoder = false;
    });

    tearDown(() {
      debugResetBrowserSupportsImageDecoder();
      debugDisableCreateImageBitmapSupport = false;
    });

    Future<Uint8List> fetchBytes(String path) async {
      final HttpFetchResponse response = await httpFetch(path);
      return (await response.payload.asByteBuffer()).asUint8List();
    }

    test('static image decodes via createImageBitmap', () async {
      if (!browserSupportsCreateImageBitmap) {
        return;
      }
      final Uint8List pngBytes = await fetchBytes('/test_images/1x1.png');

      final ui.Codec codec = await renderer.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();

      expect(codec.frameCount, 1);

      frame.image.dispose();
      codec.dispose();
    });

    test('animated image uses the backend codec only when it has one', () async {
      if (!browserSupportsCreateImageBitmap) {
        return;
      }
      final Uint8List gifBytes = await fetchBytes('/test_images/flightAnim.gif');

      final ui.Codec codec = await renderer.instantiateImageCodec(gifBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();

      if (renderer.supportsAnimatedImages) {
        expect(codec.frameCount, greaterThan(1));
      } else {
        // Degrades to a still of the first frame via createImageBitmap rather
        // than failing.
        expect(codec.frameCount, 1);
      }

      frame.image.dispose();
      codec.dispose();
    });

    test('animated image throws when nothing can decode it', () async {
      // Regression test for the routing this change touches: with no
      // `ImageDecoder` and no `createImageBitmap`, the backend codec is the
      // only thing left. A backend that has one must still be reached, and a
      // backend that does not must fail explicitly rather than silently.
      debugDisableCreateImageBitmapSupport = true;
      final Uint8List gifBytes = await fetchBytes('/test_images/flightAnim.gif');

      if (renderer.supportsAnimatedImages) {
        final ui.Codec codec = await renderer.instantiateImageCodec(gifBytes);
        expect(codec.frameCount, greaterThan(1));
        codec.dispose();
        return;
      }

      await expectLater(
        renderer.instantiateImageCodec(gifBytes),
        throwsA(isA<ImageCodecException>()),
      );
    });

    // A companion test that decodes a *static* image through the backend codec
    // (`createImageBitmap` disabled) is missing on purpose. CanvasKit Chromium
    // reports `supportsAnimatedImages == true` but is built without the PNG,
    // JPEG and WebP decoders, so it fails that case while still handling GIF.
    // Covering it needs a real capability probe on the CanvasKit renderer.
  });
}

class _TestHttpFetchResponse implements HttpFetchResponse {
  _TestHttpFetchResponse({required this.stream});

  final DomReadableStream stream;

  @override
  final int? contentLength = null;

  @override
  bool get hasPayload => true;

  @override
  HttpFetchPayload get payload => _TestHttpFetchPayload(stream);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpFetchPayload implements HttpFetchPayload {
  _TestHttpFetchPayload(this.stream);

  @override
  final DomReadableStream stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
