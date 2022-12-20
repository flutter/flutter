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
    await tester.pumpAndSettle();

    final Image image = Image.network(
      'assets/packages/flutter_gallery_assets/assets/icons/material/material.png',
      cacheHeight: 10,
      cacheWidth: 10,
    );

    bool called = false;

    Future<ui.Codec> decode(ui.ImmutableBuffer buffer, {int? cacheWidth, int? cacheHeight, bool allowUpscaling = false}) {
      expect(cacheWidth, 10);
      expect(cacheHeight, 10);
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
    streamCompleter.addListener(ImageStreamListener((ImageInfo imageInfo, bool syncCall) {
      completer.complete();
    }));
    await completer.future;

    expect(called, true);
  });
}
