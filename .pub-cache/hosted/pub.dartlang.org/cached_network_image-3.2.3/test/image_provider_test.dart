// Copyright 2020 Rene Floor. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Codec, FrameInfo;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cache_manager.dart';
import 'image_data.dart';
import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding();

  late FakeCacheManager cacheManager;

  setUp(() {
    cacheManager = FakeCacheManager();
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('Expect thrown exception with statusCode - evicts from cache', () async {
    const requestUrl = 'foo-url';
    cacheManager.throwsNotFound(requestUrl);

    final caughtError = Completer<dynamic>();

    final ImageProvider imageProvider = CachedNetworkImageProvider(
        nonconst(requestUrl),
        cacheManager: cacheManager);
    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    final result = imageProvider.resolve(ImageConfiguration.empty);

    expect(imageCache.pendingImageCount, 1);
    expect(imageCache.statusForKey(imageProvider).pending, true);

    result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {},
        onError: (dynamic error, StackTrace? stackTrace) {
      caughtError.complete(error);
    }));

    final dynamic err = await caughtError.future;

    expect(imageCache.pendingImageCount, 0);
    expect(imageCache.statusForKey(imageProvider).untracked, true);

    expect(
      err,
      isA<HttpExceptionWithStatus>()
          .having(
            (HttpExceptionWithStatus e) => e.statusCode,
            'statusCode',
            404,
          )
          .having(
            (HttpExceptionWithStatus e) => e.uri,
            'uri',
            Uri.parse(requestUrl),
          ),
    );
  },
      skip:
          isBrowser); // Browser implementation does not use HTTP client but an <img> tag.

  test('Propagates http client errors during resolve()', () async {
    var uncaught = false;
    var url = 'asdasdasdas';
    cacheManager.throwsNotFound(url);

    await runZoned(() async {
      final ImageProvider imageProvider =
          CachedNetworkImageProvider(url, cacheManager: cacheManager);
      final caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        throw Error();
      };
      final result = imageProvider.resolve(ImageConfiguration.empty);
      result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {},
          onError: (dynamic error, StackTrace? stackTrace) {
        caughtError.complete(true);
      }));
      expect(await caughtError.future, true);
    }, zoneSpecification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent,
          Object error, StackTrace stackTrace) {
        uncaught = true;
      },
    ));
    expect(uncaught, false);
  });

  test('Notifies listeners of chunk events', () async {
    final imageAvailable = Completer<void>();
    var url = 'foo';
    var expectedResult = cacheManager.returns(url, kTransparentImage);

    final ImageProvider imageProvider =
        CachedNetworkImageProvider(nonconst('foo'), cacheManager: cacheManager);
    final result = imageProvider.resolve(ImageConfiguration.empty);
    final events = <ImageChunkEvent>[];
    result.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        imageAvailable.complete();
      },
      onChunk: (ImageChunkEvent event) {
        events.add(event);
      },
      onError: (dynamic error, StackTrace? stackTrace) {
        imageAvailable.completeError(error as Object, stackTrace);
      },
    ));
    await imageAvailable.future;
    expect(events.length, expectedResult.chunks);
    for (var i = 0; i < events.length; i++) {
      expect(
          events[i].cumulativeBytesLoaded,
          math.min(
              (i + 1) * expectedResult.chunkSize, kTransparentImage.length));
      expect(events[i].expectedTotalBytes, kTransparentImage.length);
    }
  }, skip: isBrowser); // Browser loads images through <img> not Http.
}

class FakeCodec implements Codec {
  @override
  void dispose() {}

  @override
  int get frameCount => throw UnimplementedError();

  @override
  Future<FrameInfo> getNextFrame() {
    throw UnimplementedError();
  }

  @override
  int get repetitionCount => throw UnimplementedError();
}
