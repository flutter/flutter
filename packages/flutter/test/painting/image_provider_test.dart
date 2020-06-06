// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';
import 'mocks_for_image_cache.dart';

void main() {
  TestRenderingFlutterBinding();

  FlutterExceptionHandler oldError;
  setUp(() {
    oldError = FlutterError.onError;
  });

  tearDown(() {
    FlutterError.onError = oldError;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('obtainKey errors will be caught', () async {
    final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
    final Completer<bool> caughtError = Completer<bool>();
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtError.complete(false);
    };
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
      caughtError.complete(false);
    }, onError: (dynamic error, StackTrace stackTrace) {
      caughtError.complete(true);
    }));
    expect(await caughtError.future, true);
  });

  test('obtainKey errors will be caught - check location', () async {
    final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
    final Completer<bool> caughtError = Completer<bool>();
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtError.complete(true);
    };
    await imageProvider.obtainCacheStatus(configuration: ImageConfiguration.empty);

    expect(await caughtError.future, true);
  });

  test('resolve sync errors will be caught', () async {
    bool uncaught = false;
    final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      },
    ));
    await testZone.run(() async {
      final ImageProvider imageProvider = LoadErrorImageProvider();
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
    });
    expect(uncaught, false);
  });

  test('resolve errors in the completer will be caught', () async {
    bool uncaught = false;
    final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
      handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
        uncaught = true;
      },
    ));
    await testZone.run(() async {
      final ImageProvider imageProvider = LoadErrorCompleterImageProvider();
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
    });
    expect(uncaught, false);
  });

  test('File image with empty file throws expected error and evicts from cache', () async {
    final Completer<StateError> error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final MemoryFileSystem fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final FileImage provider = FileImage(file);

    expect(imageCache.statusForKey(provider).untracked, true);
    expect(imageCache.pendingImageCount, 0);

    provider.resolve(ImageConfiguration.empty);

    expect(imageCache.statusForKey(provider).pending, true);
    expect(imageCache.pendingImageCount, 1);

    expect(await error.future, isStateError);
    expect(imageCache.statusForKey(provider).untracked, true);
    expect(imageCache.pendingImageCount, 0);
  });

  test('File image with empty file throws expected error (load)', () async {
    final Completer<StateError> error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final MemoryFileSystem fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final FileImage provider = FileImage(file);

    expect(provider.load(provider, null), isA<MultiFrameImageStreamCompleter>());

    expect(await error.future, isStateError);
  });
}
