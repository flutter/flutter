// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../rendering/rendering_tester.dart';
import 'image_data.dart';
import 'mocks_for_image_cache.dart';

void main() {
  TestRenderingFlutterBinding(); // initializes the imageCache
  group(ImageProvider, () {
    tearDown(() {
      imageCache.clear();
    });

    test('NetworkImage non-null url test', () {
      expect(() {
        NetworkImage(nonconst(null));
      }, throwsAssertionError);
    });

    test('ImageProvider can evict images', () async {
      final Uint8List bytes = Uint8List.fromList(kTransparentImage);
      final MemoryImage imageProvider = MemoryImage(bytes);
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      final Completer<void> completer = Completer<void>();
      stream.addListener((ImageInfo info, bool syncCall) => completer.complete());
      await completer.future;

      expect(imageCache.currentSize, 1);
      expect(await MemoryImage(bytes).evict(), true);
      expect(imageCache.currentSize, 0);
    });

    test('ImageProvider.evict respects the provided ImageCache', () async {
      final ImageCache otherCache = ImageCache();
      final Uint8List bytes = Uint8List.fromList(kTransparentImage);
      final MemoryImage imageProvider = MemoryImage(bytes);
      otherCache.putIfAbsent(imageProvider, () => imageProvider.load(imageProvider));
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      final Completer<void> completer = Completer<void>();
      stream.addListener((ImageInfo info, bool syncCall) => completer.complete());
      await completer.future;

      expect(otherCache.currentSize, 1);
      expect(imageCache.currentSize, 1);
      expect(await imageProvider.evict(cache: otherCache), true);
      expect(otherCache.currentSize, 0);
      expect(imageCache.currentSize, 1);
    });

    test('ImageProvider errors can always be caught', () async {
      final ErrorImageProvider imageProvider = ErrorImageProvider();
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        caughtError.complete(false);
      };
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      stream.addListener((ImageInfo info, bool syncCall) {
        caughtError.complete(false);
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      });
      expect(await caughtError.future, true);
    });
  });

  test('ImageProvide.obtainKey errors will be caught', () async {
    final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
    final Completer<bool> caughtError = Completer<bool>();
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtError.complete(false);
    };
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener((ImageInfo info, bool syncCall) {
      caughtError.complete(false);
    }, onError: (dynamic error, StackTrace stackTrace) {
      caughtError.complete(true);
    });
    expect(await caughtError.future, true);
  });

  test('ImageProvider.resolve sync errors will be caught', () async {
    bool uncaught = false;
    final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      }
    ));
    await testZone.run(() async {
      final ImageProvider imageProvider = LoadErrorImageProvider();
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        throw Error();
      };
      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
      result.addListener((ImageInfo info, bool syncCall) {
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      });
      expect(await caughtError.future, true);
    });
    expect(uncaught, false);
  });

   test('ImageProvider.resolve errors in the completer will be caught', () async {
    bool uncaught = false;
    final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      }
    ));
    await testZone.run(() async {
      final ImageProvider imageProvider = LoadErrorCompleterImageProvider();
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        throw Error();
      };
      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
      result.addListener((ImageInfo info, bool syncCall) {
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      });
      expect(await caughtError.future, true);
    });
    expect(uncaught, false);
  });

  test('ImageProvider.resolve errors in the http client will be caught', () async {
    bool uncaught = false;
    final HttpClientMock httpClientMock = HttpClientMock();
    when(httpClientMock.getUrl(any)).thenThrow(Error());

    await HttpOverrides.runZoned(() async {
      const ImageProvider imageProvider = NetworkImage('asdasdasdas');
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        throw Error();
      };
      final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
      result.addListener((ImageInfo info, bool syncCall) {
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      });
      expect(await caughtError.future, true);
    }, createHttpClient: (SecurityContext context) => httpClientMock, zoneSpecification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      }
    ));
    expect(uncaught, false);
  });
}

class HttpClientMock extends Mock implements HttpClient {}
