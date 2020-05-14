// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../rendering/rendering_tester.dart';
import 'image_data.dart';

void main() {
  TestRenderingFlutterBinding();

  final DecoderCallback _basicDecoder = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
    return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
  };

  _MockHttpClient httpClient;

  setUp(() {
    httpClient = _MockHttpClient();
    debugNetworkImageHttpClientProvider = () => httpClient;
  });

  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('Expect thrown exception with statusCode - evicts from cache', () async {
    final int errorStatusCode = HttpStatus.notFound;
    const String requestUrl = 'foo-url';

    final _MockHttpClientRequest request = _MockHttpClientRequest();
    final _MockHttpClientResponse response = _MockHttpClientResponse();
    when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
    when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
    when(response.statusCode).thenReturn(errorStatusCode);

    final Completer<dynamic> caughtError = Completer<dynamic>();

    final ImageProvider imageProvider = NetworkImage(nonconst(requestUrl));
    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

    expect(imageCache.pendingImageCount, 1);
    expect(imageCache.statusForKey(imageProvider).pending, true);

    result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
    }, onError: (dynamic error, StackTrace stackTrace) {
      caughtError.complete(error);
    }));

    final dynamic err = await caughtError.future;

    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    expect(
      err,
      isA<NetworkImageLoadException>()
        .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', errorStatusCode)
        .having((NetworkImageLoadException e) => e.uri, 'uri', Uri.base.resolve(requestUrl)),
    );
  }, skip: isBrowser); // Browser implementation does not use HTTP client but an <img> tag.

  test('Disallows null urls', () {
    expect(() {
      NetworkImage(nonconst(null));
    }, throwsAssertionError);
  });

  test('Uses the HttpClient provided by debugNetworkImageHttpClientProvider if set', () async {
    when(httpClient.getUrl(any)).thenThrow('client1');
    final List<dynamic> capturedErrors = <dynamic>[];

    Future<void> loadNetworkImage() async {
      final NetworkImage networkImage = NetworkImage(nonconst('foo'));
      final ImageStreamCompleter completer = networkImage.load(networkImage, _basicDecoder);
      completer.addListener(ImageStreamListener(
        (ImageInfo image, bool synchronousCall) { },
        onError: (dynamic error, StackTrace stackTrace) {
          capturedErrors.add(error);
        },
      ));
      await Future<void>.value();
    }

    await loadNetworkImage();
    expect(capturedErrors, <dynamic>['client1']);
    final _MockHttpClient client2 = _MockHttpClient();
    when(client2.getUrl(any)).thenThrow('client2');
    debugNetworkImageHttpClientProvider = () => client2;
    await loadNetworkImage();
    expect(capturedErrors, <dynamic>['client1', 'client2']);
  }, skip: isBrowser); // Browser implementation does not use HTTP client but an <img> tag.

  test('Propagates http client errors during resolve()', () async {
    when(httpClient.getUrl(any)).thenThrow(Error());
    bool uncaught = false;

    final FlutterExceptionHandler oldError = FlutterError.onError;
    await runZoned(() async {
      const ImageProvider imageProvider = NetworkImage('asdasdasdas');
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        throw Error();
      };
      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
      result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      }));
      expect(await caughtError.future, true);
    }, zoneSpecification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      },
    ));
    expect(uncaught, false);
    FlutterError.onError = oldError;
  });

  test('Notifies listeners of chunk events', () async {
    const int chunkSize = 8;
    final List<Uint8List> chunks = <Uint8List>[
      for (int offset = 0; offset < kTransparentImage.length; offset += chunkSize)
        Uint8List.fromList(kTransparentImage.skip(offset).take(chunkSize).toList()),
    ];
    final Completer<void> imageAvailable = Completer<void>();
    final _MockHttpClientRequest request = _MockHttpClientRequest();
    final _MockHttpClientResponse response = _MockHttpClientResponse();
    when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
    when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
    when(response.statusCode).thenReturn(HttpStatus.ok);
    when(response.contentLength).thenReturn(kTransparentImage.length);
    when(response.listen(
      any,
      onDone: anyNamed('onDone'),
      onError: anyNamed('onError'),
      cancelOnError: anyNamed('cancelOnError'),
    )).thenAnswer((Invocation invocation) {
      final void Function(List<int>) onData = invocation.positionalArguments[0] as void Function(List<int>);
      final void Function(Object) onError = invocation.namedArguments[#onError] as void Function(Object);
      final VoidCallback onDone = invocation.namedArguments[#onDone] as VoidCallback;
      final bool cancelOnError = invocation.namedArguments[#cancelOnError] as bool;

      return Stream<Uint8List>.fromIterable(chunks).listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
    });

    final ImageProvider imageProvider = NetworkImage(nonconst('foo'));
    final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
    final List<ImageChunkEvent> events = <ImageChunkEvent>[];
    result.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        imageAvailable.complete();
      },
      onChunk: (ImageChunkEvent event) {
        events.add(event);
      },
      onError: (dynamic error, StackTrace stackTrace) {
        imageAvailable.completeError(error, stackTrace);
      },
    ));
    await imageAvailable.future;
    expect(events.length, chunks.length);
    for (int i = 0; i < events.length; i++) {
      expect(events[i].cumulativeBytesLoaded, math.min((i + 1) * chunkSize, kTransparentImage.length));
      expect(events[i].expectedTotalBytes, kTransparentImage.length);
    }
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56317

  test('NetworkImage is evicted from cache on SocketException', () async {
    final _MockHttpClient mockHttpClient = _MockHttpClient();
    when(mockHttpClient.getUrl(any)).thenAnswer((_) => throw const SocketException('test exception'));
    debugNetworkImageHttpClientProvider = () => mockHttpClient;


    final ImageProvider imageProvider = NetworkImage(nonconst('testing.url'));
    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

    expect(imageCache.pendingImageCount, 1);
    expect(imageCache.statusForKey(imageProvider).pending, true);
    final Completer<dynamic> caughtError = Completer<dynamic>();
    result.addListener(ImageStreamListener(
      (ImageInfo info, bool syncCall) {},
      onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(error);
      },
    ));

    final dynamic err = await caughtError.future;

    expect(err, isA<SocketException>());

    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);
    expect(imageCache.containsKey(result), isFalse);

    debugNetworkImageHttpClientProvider = null;
  }, skip: isBrowser); // Browser does not resolve images this way.
}

class _MockHttpClient extends Mock implements HttpClient {}
class _MockHttpClientRequest extends Mock implements HttpClientRequest {}
class _MockHttpClientResponse extends Mock implements HttpClientResponse {}
