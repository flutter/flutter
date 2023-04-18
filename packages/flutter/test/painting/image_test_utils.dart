// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.testImage);

  final ui.Image testImage;

  final Completer<ImageInfo> _completer = Completer<ImageInfo>.sync();
  ImageConfiguration? configuration;
  int loadCallCount = 0;

  @override
  Future<TestImageProvider> obtainKey(final ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  void resolveStreamForKey(final ImageConfiguration config, final ImageStream stream, final TestImageProvider key, final ImageErrorListener handleError) {
    configuration = config;
    super.resolveStreamForKey(config, stream, key, handleError);
  }

  @override
  ImageStreamCompleter load(final TestImageProvider key, final DecoderCallback decode) {
    throw UnsupportedError('Use ImageProvider.loadImage instead.');
  }

  @override
  ImageStreamCompleter loadBuffer(final TestImageProvider key, final DecoderBufferCallback decode) {
    throw UnsupportedError('Use ImageProvider.loadImage instead.');
  }

  @override
  ImageStreamCompleter loadImage(final TestImageProvider key, final ImageDecoderCallback decode) {
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
