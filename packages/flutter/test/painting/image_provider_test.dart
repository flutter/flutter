// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/rendering_tester.dart';
import 'mocks_for_image_cache.dart';
import 'no_op_codec.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  FlutterExceptionHandler? oldError;
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
    final caughtError = Completer<bool>();
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtError.complete(false);
    };
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool syncCall) {
          caughtError.complete(false);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          caughtError.complete(true);
        },
      ),
    );
    expect(await caughtError.future, true);
  });

  test('obtainKey errors will be caught - check location', () async {
    final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
    final caughtError = Completer<bool>();
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtError.complete(true);
    };
    await imageProvider.obtainCacheStatus(configuration: ImageConfiguration.empty);

    expect(await caughtError.future, true);
  });

  test('File image with empty file throws expected error and evicts from cache', () async {
    final error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final provider = FileImage(file);

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
    final error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final provider = FileImage(file);

    expect(
      provider.loadBuffer(provider, (
        ImmutableBuffer buffer, {
        int? cacheWidth,
        int? cacheHeight,
        bool? allowUpscaling,
      }) async {
        return Future<Codec>.value(createNoOpCodec());
      }),
      isA<MultiFrameImageStreamCompleter>(),
    );

    expect(await error.future, isStateError);
  });

  test('File image sets tag', () async {
    final fs = MemoryFileSystem();
    final File file = fs.file('/blue.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(kBlueSquarePng);
    final provider = FileImage(file);

    final completer =
        provider.loadBuffer(provider, noOpDecoderBufferCallback) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, file.path);
  });

  test('Memory image sets tag', () async {
    final bytes = Uint8List.fromList(kBlueSquarePng);
    final provider = MemoryImage(bytes);

    final completer =
        provider.loadBuffer(provider, noOpDecoderBufferCallback) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, 'MemoryImage(${describeIdentity(bytes)})');
  });

  test('Asset image sets tag', () async {
    const asset = 'images/blue.png';
    final provider = ExactAssetImage(asset, bundle: _TestAssetBundle());
    final AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration.empty);
    final completer =
        provider.loadBuffer(key, noOpDecoderBufferCallback) as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, asset);
  });

  test('Resize image sets tag', () async {
    final bytes = Uint8List.fromList(kBlueSquarePng);
    final provider = ResizeImage(MemoryImage(bytes), width: 40, height: 40);
    final completer =
        provider.loadBuffer(
              await provider.obtainKey(ImageConfiguration.empty),
              noOpDecoderBufferCallback,
            )
            as MultiFrameImageStreamCompleter;

    expect(completer.debugLabel, 'MemoryImage(${describeIdentity(bytes)}) - Resized(40×40)');
  });

  test('File image throws error when given a real but non-image file', () async {
    final error = Completer<Exception>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as Exception);
    };
    final provider = FileImage(File('pubspec.yaml'));

    expect(imageCache.statusForKey(provider).untracked, true);
    expect(imageCache.pendingImageCount, 0);

    provider.resolve(ImageConfiguration.empty);

    expect(imageCache.statusForKey(provider).pending, true);
    expect(imageCache.pendingImageCount, 1);

    expect(
      await error.future,
      isException.having(
        (Exception exception) => exception.toString(),
        'toString',
        contains('Invalid image data'),
      ),
    );

    // Invalid images are marked as pending so that we do not attempt to reload them.
    expect(imageCache.statusForKey(provider).untracked, false);
    expect(imageCache.pendingImageCount, 1);
  }, skip: kIsWeb); // [intended] The web cannot load files.

  test('ImageProvider toStrings', () async {
    expect(
      const NetworkImage('test', scale: 1.21).toString(),
      'NetworkImage("test", scale: 1.2, webHtmlElementStrategy: never, headers: null)',
    );
    expect(
      const ExactAssetImage('test', scale: 1.21).toString(),
      'ExactAssetImage(name: "test", scale: 1.2, bundle: null)',
    );
    expect(
      MemoryImage(Uint8List(0), scale: 1.21).toString(),
      equalsIgnoringHashCodes('MemoryImage(Uint8List#00000, scale: 1.2)'),
    );
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return Uint8List.fromList(kBlueSquarePng).buffer.asByteData();
  }
}
