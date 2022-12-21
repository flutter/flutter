// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';


class LoadTestImageProvider extends ImageProvider<Object> {
  LoadTestImageProvider(this.provider);

  final ImageProvider provider;

  ImageStreamCompleter testLoad(Object key, DecoderBufferCallback decode) {
    return provider.loadBuffer(key, decode);
  }

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    throw UnimplementedError();
  }

  @override
  ImageStreamCompleter loadBuffer(Object key, DecoderBufferCallback decode) {
    throw UnimplementedError();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Image.network uses cacheWidth and cacheHeight',
          (WidgetTester tester) async {

    const int expectedCacheHeight = 9;
    const int expectedCacheWidth = 11;
    await tester.pumpAndSettle();

    final Image image = Image.network(
      'assets/packages/flutter_gallery_assets/assets/icons/material/material.png',
      cacheHeight: 9,
      cacheWidth: 11,
    );

    bool called = false;

    Future<ui.Codec> decode(ui.ImmutableBuffer buffer, {int? cacheWidth, int? cacheHeight, bool allowUpscaling = false}) {
      expect(cacheHeight, expectedCacheHeight);
      expect(cacheWidth, expectedCacheWidth);
      expect(allowUpscaling, false);
      called = true;
      return PaintingBinding.instance.instantiateImageCodecFromBuffer(buffer, cacheWidth: cacheWidth, cacheHeight: cacheHeight, allowUpscaling: allowUpscaling);
    }

    final ImageProvider resizeImage = image.image;
    expect(image.image, isA<ResizeImage>());
    expect(called, false);

    final LoadTestImageProvider testProvider = LoadTestImageProvider(image.image);
    final ImageStreamCompleter streamCompleter = testProvider.testLoad(await resizeImage.obtainKey(ImageConfiguration.empty), decode);

    final Completer<void> completer = Completer<void>();
    int? imageInfoCachedWidth;
    int? imageInfoCachedHeight;
    streamCompleter.addListener(ImageStreamListener((ImageInfo imageInfo, bool syncCall) {
      imageInfoCachedWidth = imageInfo.image.width;
      imageInfoCachedHeight = imageInfo.image.height;
      completer.complete();
    }));
    await completer.future;

    expect(imageInfoCachedHeight, isNotNull);
    expect(imageInfoCachedHeight, expectedCacheHeight);
    expect(imageInfoCachedWidth, isNotNull);
    expect(imageInfoCachedWidth, expectedCacheWidth);
    expect(called, true);
  });
}
