// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'image_data.dart';

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.testImage);

  final ui.Image testImage;

  final Completer<ImageInfo> _completer = Completer<ImageInfo>.sync();
  ImageConfiguration configuration;
  int loadCallCount = 0;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  void resolveStreamForKey(ImageConfiguration config, ImageStream stream, TestImageProvider key, ImageErrorListener handleError) {
    configuration = config;
    super.resolveStreamForKey(config, stream, key, handleError);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key, DecoderCallback decode) {
    loadCallCount += 1;
    return OneFrameImageStreamCompleter(_completer.future);
  }

  ImageInfo complete() {
    final ImageInfo imageInfo = ImageInfo(image: testImage);
    _completer.complete(imageInfo);
    return imageInfo;
  }

  @override
  String toString() => '${describeIdentity(this)}()';
}

Future<ui.Image> createTestImage() {
  final Completer<ui.Image> uiImage = Completer<ui.Image>();
  ui.decodeImageFromList(Uint8List.fromList(kTransparentImage), uiImage.complete);
  return uiImage.future;
}

class FakeImageConfiguration implements ImageConfiguration {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
