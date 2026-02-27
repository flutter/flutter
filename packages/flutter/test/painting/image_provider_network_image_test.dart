// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/rendering_tester.dart';
import 'no_op_codec.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();
  HttpOverrides.global = _FakeHttpOverrides();

  Future<Codec> basicDecoder(
    ImmutableBuffer buffer, {
    int? cacheWidth,
    int? cacheHeight,
    bool? allowUpscaling,
  }) {
    return PaintingBinding.instance.instantiateImageCodecFromBuffer(
      buffer,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      allowUpscaling: allowUpscaling ?? false,
    );
  }

  late _FakeHttpClient httpClient;

  setUp(() {
    _FakeHttpOverrides.createHttpClientCalls = 0;
    httpClient = _FakeHttpClient();
    debugNetworkImageHttpClientProvider = () => httpClient;
  });

  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    expect(_FakeHttpOverrides.createHttpClientCalls, 0);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test(
    'Expect thrown exception with statusCode - evicts from cache and drains',
    () async {
      const int errorStatusCode = HttpStatus.notFound;
      const requestUrl = 'foo-url';

      httpClient.request.response.statusCode = errorStatusCode;

      final caughtError = Completer<dynamic>();

      final ImageProvider imageProvider = NetworkImage(nonconst(requestUrl));
      expect(imageCache.pendingImageCount, 0);
      expect(imageCache.statusForKey(imageProvider).untracked, true);

      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

      expect(imageCache.pendingImageCount, 1);
      expect(imageCache.statusForKey(imageProvider).pending, true);

      result.addListener(
        ImageStreamListener(
          (ImageInfo info, bool syncCall) {},
          onError: (dynamic error, StackTrace? stackTrace) {
            caughtError.complete(error);
          },
        ),
      );

      final dynamic err = await caughtError.future;

      expect(imageCache.pendingImageCount, 0);
      expect(imageCache.statusForKey(imageProvider).untracked, true);

      expect(
        err,
        isA<NetworkImageLoadException>()
            .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', errorStatusCode)
            .having((NetworkImageLoadException e) => e.uri, 'uri', Uri.base.resolve(requestUrl)),
      );
      expect(httpClient.request.response.drained, true);
    },
    // [intended] Browser implementation does not use HTTP client but an <img> tag.
    skip: isBrowser,
  );

  test(
    'Expect thrown exception with statusCode - evicts from cache and drains, when using ResizeImage',
    () async {
      const int errorStatusCode = HttpStatus.notFound;
      const requestUrl = 'foo-url';

      httpClient.request.response.statusCode = errorStatusCode;

      final caughtError = Completer<dynamic>();

      final ImageProvider imageProvider = ResizeImage(
        NetworkImage(nonconst(requestUrl)),
        width: 5,
        height: 5,
      );
      expect(imageCache.pendingImageCount, 0);
      expect(imageCache.statusForKey(imageProvider).untracked, true);

      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

      expect(imageCache.pendingImageCount, 1);

      result.addListener(
        ImageStreamListener(
          (ImageInfo info, bool syncCall) {},
          onError: (dynamic error, StackTrace? stackTrace) {
            caughtError.complete(error);
          },
        ),
      );

      final Object? err = await caughtError.future;
      await Future<void>.delayed(Duration.zero);

      expect(imageCache.pendingImageCount, 0);
      expect(imageCache.statusForKey(imageProvider).untracked, true);

      expect(
        err,
        isA<NetworkImageLoadException>()
            .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', errorStatusCode)
            .having((NetworkImageLoadException e) => e.uri, 'uri', Uri.base.resolve(requestUrl)),
      );
      expect(httpClient.request.response.drained, true);
    },
    // [intended] Browser implementation does not use HTTP client but an <img> tag.
    skip: isBrowser,
  );

  test(
    'Uses the HttpClient provided by debugNetworkImageHttpClientProvider if set',
    () async {
      httpClient.thrownError = 'client1';
      final capturedErrors = <dynamic>[];

      Future<void> loadNetworkImage() async {
        final networkImage = NetworkImage(nonconst('foo'));
        final ImageStreamCompleter completer = networkImage.loadBuffer(networkImage, basicDecoder);
        completer.addListener(
          ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {},
            onError: (dynamic error, StackTrace? stackTrace) {
              capturedErrors.add(error);
            },
          ),
        );
        await Future<void>.value();
      }

      await loadNetworkImage();
      expect(capturedErrors, <dynamic>['client1']);
      final client2 = _FakeHttpClient();
      client2.thrownError = 'client2';
      debugNetworkImageHttpClientProvider = () => client2;
      await loadNetworkImage();
      expect(capturedErrors, <dynamic>['client1', 'client2']);
    },
    // [intended] Browser implementation does not use HTTP client but an <img> tag.
    skip: isBrowser,
  );

  test('Propagates http client errors during resolve()', () async {
    httpClient.thrownError = Error();
    var uncaught = false;

    final FlutterExceptionHandler? oldError = FlutterError.onError;
    await runZoned(
      () async {
        const ImageProvider imageProvider = NetworkImage('asdasdasdas');
        final caughtError = Completer<bool>();
        FlutterError.onError = (FlutterErrorDetails details) {
          throw Error();
        };
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(
          ImageStreamListener(
            (ImageInfo info, bool syncCall) {},
            onError: (dynamic error, StackTrace? stackTrace) {
              caughtError.complete(true);
            },
          ),
        );
        expect(await caughtError.future, true);
      },
      zoneSpecification: ZoneSpecification(
        handleUncaughtError:
            (
              Zone zone,
              ZoneDelegate zoneDelegate,
              Zone parent,
              Object error,
              StackTrace stackTrace,
            ) {
              uncaught = true;
            },
      ),
    );
    expect(uncaught, false);
    FlutterError.onError = oldError;
  });

  test('Notifies listeners of chunk events', () async {
    const chunkSize = 8;
    final chunks = <Uint8List>[
      for (int offset = 0; offset < kTransparentImage.length; offset += chunkSize)
        Uint8List.fromList(kTransparentImage.skip(offset).take(chunkSize).toList()),
    ];
    final imageAvailable = Completer<void>();

    httpClient.request.response
      ..statusCode = HttpStatus.ok
      ..contentLength = kTransparentImage.length
      ..content = chunks;

    final ImageProvider imageProvider = NetworkImage(nonconst('foo'));
    final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
    final events = <ImageChunkEvent>[];
    result.addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          imageAvailable.complete();
        },
        onChunk: (ImageChunkEvent event) {
          events.add(event);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          imageAvailable.completeError(error as Object, stackTrace);
        },
      ),
    );
    await imageAvailable.future;
    expect(events.length, chunks.length);
    for (var i = 0; i < events.length; i++) {
      expect(
        events[i].cumulativeBytesLoaded,
        math.min((i + 1) * chunkSize, kTransparentImage.length),
      );
      expect(events[i].expectedTotalBytes, kTransparentImage.length);
    }
  }, skip: isBrowser); // [intended] Browser loads images through <img> not Http.

  test('NetworkImage is evicted from cache on SocketException', () async {
    final mockHttpClient = _FakeHttpClient();
    mockHttpClient.thrownError = const SocketException('test exception');
    debugNetworkImageHttpClientProvider = () => mockHttpClient;

    final ImageProvider imageProvider = NetworkImage(nonconst('testing.url'));
    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

    expect(imageCache.pendingImageCount, 1);
    expect(imageCache.statusForKey(imageProvider).pending, true);
    final caughtError = Completer<dynamic>();
    result.addListener(
      ImageStreamListener(
        (ImageInfo info, bool syncCall) {},
        onError: (dynamic error, StackTrace? stackTrace) {
          caughtError.complete(error);
        },
      ),
    );

    final Object? err = await caughtError.future;

    expect(err, isA<SocketException>());

    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);
    expect(imageCache.containsKey(result), isFalse);

    debugNetworkImageHttpClientProvider = null;
  }, skip: isBrowser); // [intended] Browser does not resolve images this way.

  test('Network image with same arguments uses cache', () async {
    final mockHttpClient = _FakeHttpClient();
    debugNetworkImageHttpClientProvider = () => mockHttpClient;
    mockHttpClient.request.response
      ..statusCode = HttpStatus.ok
      ..contentLength = kTransparentImage.length
      ..content = <Uint8List>[Uint8List.fromList(kTransparentImage)];

    final imageAvailable1 = Completer<void>();
    final ImageProvider imageProvider1 = NetworkImage(
      nonconst('testing.url'),
      headers: nonconst(<String, String>{'key': 'value'}),
    );
    expect(imageCache.liveImageCount, 0);

    final ImageStream result1 = imageProvider1.resolve(ImageConfiguration.empty);
    result1.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        imageAvailable1.complete();
      }),
    );
    await imageAvailable1.future;
    expect(imageCache.liveImageCount, 1);

    // NetworkImage should not make another request.
    mockHttpClient.request.response.statusCode = HttpStatus.badRequest;

    final imageAvailable2 = Completer<void>();
    final ImageProvider imageProvider2 = NetworkImage(
      nonconst('testing.url'),
      headers: nonconst(<String, String>{'key': 'value'}),
    );

    final ImageStream result2 = imageProvider2.resolve(ImageConfiguration.empty);
    result2.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        imageAvailable2.complete();
      }),
    );
    await imageAvailable2.future;
    expect(imageCache.liveImageCount, 1);

    debugNetworkImageHttpClientProvider = null;
  }, skip: isBrowser); // [intended] Browser does not resolve images this way.

  test('Network image sets tag', () async {
    const url = 'http://test.png';
    const chunkSize = 8;
    final chunks = <Uint8List>[
      for (int offset = 0; offset < kTransparentImage.length; offset += chunkSize)
        Uint8List.fromList(kTransparentImage.skip(offset).take(chunkSize).toList()),
    ];
    httpClient.request.response
      ..statusCode = HttpStatus.ok
      ..contentLength = kTransparentImage.length
      ..content = chunks;

    const provider = NetworkImage(url);

    final ImageStreamCompleter completer = provider.loadBuffer(provider, noOpDecoderBufferCallback);

    expect(completer.debugLabel, url);
  });
}

/// Override `HttpClient()` to throw an error.
///
/// This ensures that these tests never cause a call to the [HttpClient]
/// constructor.
///
/// Regression test for <https://github.com/flutter/flutter/issues/129532>.
class _FakeHttpOverrides extends HttpOverrides {
  static int createHttpClientCalls = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    createHttpClientCalls++;
    throw Exception('This test tried to create an HttpClient.');
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  final _FakeHttpClientRequest request = _FakeHttpClientRequest();
  Object? thrownError;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (thrownError != null) {
      throw thrownError!;
    }
    return request;
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final _FakeHttpClientResponse response = _FakeHttpClientResponse();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  bool drained = false;

  @override
  int statusCode = HttpStatus.ok;

  @override
  int contentLength = 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  late List<List<int>> content;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(
      content,
    ).listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  @override
  Future<E> drain<E>([E? futureValue]) async {
    drained = true;
    return futureValue ?? futureValue as E; // Mirrors the implementation in Stream.
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}
