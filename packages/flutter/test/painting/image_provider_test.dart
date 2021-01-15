// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/rendering_tester.dart';
import 'mocks_for_image_cache.dart';

void main() {
  TestRenderingFlutterBinding();

  FlutterExceptionHandler? oldError;
  setUp(() {
    oldError = FlutterError.onError;
  });

  tearDown(() {
    FlutterError.onError = oldError;
    PaintingBinding.instance!.imageCache!.clear();
    PaintingBinding.instance!.imageCache!.clearLiveImages();
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
    }, onError: (dynamic error, StackTrace? stackTrace) {
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
      }, onError: (dynamic error, StackTrace? stackTrace) {
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
      }, onError: (dynamic error, StackTrace? stackTrace) {
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

    expect(imageCache!.statusForKey(provider).untracked, true);
    expect(imageCache!.pendingImageCount, 0);

    provider.resolve(ImageConfiguration.empty);

    expect(imageCache!.statusForKey(provider).pending, true);
    expect(imageCache!.pendingImageCount, 1);

    expect(await error.future, isStateError);
    expect(imageCache!.statusForKey(provider).untracked, true);
    expect(imageCache!.pendingImageCount, 0);
  });

  test('File image with empty file throws expected error (load)', () async {
    final Completer<StateError> error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final MemoryFileSystem fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final FileImage provider = FileImage(file);

    expect(provider.load(provider, (Uint8List bytes, {int? cacheWidth, int? cacheHeight, bool? allowUpscaling}) async {
      return Future<Codec>.value(FakeCodec());
    }), isA<MultiFrameImageStreamCompleter>());

    expect(await error.future, isStateError);
  });

  Future<Codec> _decoder(Uint8List bytes, {int? cacheWidth, int? cacheHeight, bool? allowUpscaling}) async {
    return FakeCodec();
  }

  test('File image sets tag', () async {
    final MemoryFileSystem fs = MemoryFileSystem();
    final File file = fs.file('/blue.png')..createSync(recursive: true)..writeAsBytesSync(kBlueSquarePng);
    final FileImage provider = FileImage(file);

    final MultiFrameImageStreamCompleter completer = provider.load(provider, _decoder) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, file.path);
  });

  test('Memory image sets tag', () async {
    final Uint8List bytes = Uint8List.fromList(kBlueSquarePng);
    final MemoryImage provider = MemoryImage(bytes);

    final MultiFrameImageStreamCompleter completer = provider.load(provider, _decoder) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, 'MemoryImage(${describeIdentity(bytes)})');
  });

  test('Asset image sets tag', () async {
    const String asset = 'images/blue.png';
    final ExactAssetImage provider = ExactAssetImage(asset, bundle: _TestAssetBundle());
    final AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration.empty);
    final MultiFrameImageStreamCompleter completer = provider.load(key, _decoder) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, asset);
  });

  test('Resize image sets tag', () async {
    final Uint8List bytes = Uint8List.fromList(kBlueSquarePng);
    final ResizeImage provider = ResizeImage(MemoryImage(bytes), width: 40, height: 40);
    final MultiFrameImageStreamCompleter completer = provider.load(
      await provider.obtainKey(ImageConfiguration.empty),
      _decoder,
    ) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, 'MemoryImage(${describeIdentity(bytes)}) - Resized(40×40)');
  });
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

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return Uint8List.fromList(kBlueSquarePng).buffer.asByteData();
  }
}
