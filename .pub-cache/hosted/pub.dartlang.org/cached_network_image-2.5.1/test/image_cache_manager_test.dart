import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Codec, FrameInfo;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cache_manager.dart';
import 'image_data.dart';
import 'rendering_tester.dart';
import 'package:mockito/mockito.dart';

void main() {
  TestRenderingFlutterBinding();

  setUp(() {});

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('Supplying an ImageCacheManager should call getImageFile', () async {
    var url = 'foo.nl';

    var cacheManager = FakeImageCacheManager();
    cacheManager.returns(url, kTransparentImage);
    final imageAvailable = Completer<void>();

    final ImageProvider imageProvider =
        CachedNetworkImageProvider(url, cacheManager: cacheManager);
    final result = imageProvider.resolve(ImageConfiguration.empty);

    result.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        imageAvailable.complete();
      },
    ));
    await imageAvailable.future;

    verify(cacheManager.getImageFile(
      url,
      withProgress: anyNamed('withProgress'),
      headers: anyNamed('headers'),
      key: anyNamed('key'),
    )).called(1);

    verifyNever(cacheManager.getFileStream(
      url,
      withProgress: anyNamed('withProgress'),
      headers: anyNamed('headers'),
      key: anyNamed('key'),
    ));
  }, skip: isBrowser);

  test('Supplying an CacheManager should call getFileStream', () async {
    var url = 'foo.nl';

    var cacheManager = FakeCacheManager();
    cacheManager.returns(url, kTransparentImage);
    final imageAvailable = Completer<void>();

    final ImageProvider imageProvider =
        CachedNetworkImageProvider(url, cacheManager: cacheManager);
    final result = imageProvider.resolve(ImageConfiguration.empty);

    result.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        imageAvailable.complete();
      },
    ));
    await imageAvailable.future;

    verify(cacheManager.getFileStream(
      url,
      withProgress: anyNamed('withProgress'),
      headers: anyNamed('headers'),
      key: anyNamed('key'),
    )).called(1);
  }, skip: isBrowser);

  test('Supplying an CacheManager with maxHeight throws assertion', () async {
    var url = 'foo.nl';
    final caughtError = Completer<dynamic>();

    var cacheManager = FakeCacheManager();
    cacheManager.returns(url, kTransparentImage);
    final imageAvailable = Completer<void>();

    final ImageProvider imageProvider = CachedNetworkImageProvider(url,
        cacheManager: cacheManager, maxHeight: 20);
    final result = imageProvider.resolve(ImageConfiguration.empty);

    result.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      imageAvailable.complete();
    }, onError: (dynamic error, StackTrace stackTrace) {
      caughtError.complete(error);
    }));
    final dynamic err = await caughtError.future;

    expect(err, isA<AssertionError>());
  }, skip: isBrowser);

  test('Supplying an CacheManager with maxWidth throws assertion', () async {
    var url = 'foo.nl';
    final caughtError = Completer<dynamic>();

    var cacheManager = FakeCacheManager();
    cacheManager.returns(url, kTransparentImage);
    final imageAvailable = Completer<void>();

    final ImageProvider imageProvider = CachedNetworkImageProvider(url,
        cacheManager: cacheManager, maxWidth: 20);
    final result = imageProvider.resolve(ImageConfiguration.empty);

    result.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      imageAvailable.complete();
    }, onError: (dynamic error, StackTrace stackTrace) {
      caughtError.complete(error);
    }));
    final dynamic err = await caughtError.future;

    expect(err, isA<AssertionError>());
  }, skip: isBrowser);
}
