// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding();

  tearDown(() {
    PaintingBinding.instance!.imageCache!.clear();
    PaintingBinding.instance!.imageCache!.clearLiveImages();
  });

  test('ResizeImage resizes to the correct dimensions (up)', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    const Size resizeDims = Size(14, 7);
    final ResizeImage resizedImage = ResizeImage(MemoryImage(bytes), width: resizeDims.width.round(), height: resizeDims.height.round(), allowUpscaling: true);
    const ImageConfiguration resizeConfig = ImageConfiguration(size: resizeDims);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage, configuration: resizeConfig);
    expect(resizedImageSize, resizeDims);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56312


  test('ResizeImage resizes to the correct dimensions (down)', () async {
    final Uint8List bytes = Uint8List.fromList(kBlueSquarePng);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(50, 50));

    const Size resizeDims = Size(25, 25);
    final ResizeImage resizedImage = ResizeImage(MemoryImage(bytes), width: resizeDims.width.round(), height: resizeDims.height.round(), allowUpscaling: true);
    const ImageConfiguration resizeConfig = ImageConfiguration(size: resizeDims);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage, configuration: resizeConfig);
    expect(resizedImageSize, resizeDims);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56312

  test('ResizeImage resizes to the correct dimensions - no upscaling', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    const Size resizeDims = Size(1, 1);
    final ResizeImage resizedImage = ResizeImage(MemoryImage(bytes), width: resizeDims.width.round(), height: resizeDims.height.round());
    const ImageConfiguration resizeConfig = ImageConfiguration(size: resizeDims);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage, configuration: resizeConfig);
    expect(resizedImageSize, resizeDims);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56312

  test('ResizeImage does not resize when no size is passed', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    // Cannot pass in two null arguments for cache dimensions, so will use the regular
    // MemoryImage
    final MemoryImage resizedImage = MemoryImage(bytes);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage);
    expect(resizedImageSize, const Size(1, 1));
  });

  test('ResizeImage stores values', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    memoryImage.resolve(ImageConfiguration.empty);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 10, height: 20);
    expect(resizeImage.width, 10);
    expect(resizeImage.height, 20);
    expect(resizeImage.imageProvider, memoryImage);
    expect(memoryImage.resolve(ImageConfiguration.empty) != resizeImage.resolve(ImageConfiguration.empty), true);
  });

  test('ResizeImage takes one dim', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 10, height: null);
    expect(resizeImage.width, 10);
    expect(resizeImage.height, null);
    expect(resizeImage.imageProvider, memoryImage);
    expect(memoryImage.resolve(ImageConfiguration.empty) != resizeImage.resolve(ImageConfiguration.empty), true);
  });

  test('ResizeImage forms closure', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    Future<ui.Codec> decode(Uint8List bytes, {int? cacheWidth, int? cacheHeight, bool allowUpscaling = false}) {
      expect(cacheWidth, 123);
      expect(cacheHeight, 321);
      expect(allowUpscaling, false);
      return PaintingBinding.instance!.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight, allowUpscaling: allowUpscaling);
    }

    resizeImage.load(await resizeImage.obtainKey(ImageConfiguration.empty), decode);
  });

  test('ResizeImage handles sync obtainKey', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    bool isAsync = false;
    resizeImage.obtainKey(ImageConfiguration.empty).then((Object key) {
      expect(isAsync, false);
    });
    isAsync = true;
    expect(isAsync, true);
  });

  test('ResizeImage handles async obtainKey', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final _AsyncKeyMemoryImage memoryImage = _AsyncKeyMemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    bool isAsync = false;
    resizeImage.obtainKey(ImageConfiguration.empty).then((Object key) {
      expect(isAsync, true);
    });
    isAsync = true;
    expect(isAsync, true);
  });
}

Future<Size> _resolveAndGetSize(ImageProvider imageProvider,
    {ImageConfiguration configuration = ImageConfiguration.empty}) async {
  final ImageStream stream = imageProvider.resolve(configuration);
  final Completer<Size> completer = Completer<Size>();
  final ImageStreamListener listener =
    ImageStreamListener((ImageInfo image, bool synchronousCall) {
      final int height = image.image.height;
      final int width = image.image.width;
      completer.complete(Size(width.toDouble(), height.toDouble()));
    }
  );
  stream.addListener(listener);
  return completer.future;
}

// This version of MemoryImage guarantees obtainKey returns a future that has not been
// completed synchronously.
class _AsyncKeyMemoryImage extends MemoryImage {
  const _AsyncKeyMemoryImage(Uint8List bytes) : super(bytes);

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return Future<MemoryImage>(() => this);
  }
}
