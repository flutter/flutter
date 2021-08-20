// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class TestImageInfo implements ImageInfo {
  const TestImageInfo(this.value, { required this.image, this.scale = 1.0, this.debugLabel });

  @override
  final ui.Image image;

  @override
  final double scale;

  @override
  final String? debugLabel;

  final int value;

  @override
  String toString() => '${objectRuntimeType(this, 'TestImageInfo')}($value)';

  @override
  TestImageInfo clone() {
    return TestImageInfo(value, image: image.clone(), scale: scale, debugLabel: debugLabel);
  }

  @override
  bool isCloneOf(ImageInfo other) {
    assert(other != null);
    return other.image.isCloneOf(image)
        && scale == scale
        && other.debugLabel == debugLabel;
  }

  @override
  void dispose() {
    image.dispose();
  }

  @override
  int get sizeBytes => image.height * image.width * 4;

  @override
  int get hashCode => hashValues(value, image, scale, debugLabel);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is TestImageInfo
        && other.value == value
        && other.image.isCloneOf(image)
        && other.scale == scale
        && other.debugLabel == debugLabel;

  }
}

class TestImageProvider extends ImageProvider<int> {
  const TestImageProvider(this.key, this.imageValue, { required this.image })
      : assert(image != null);

  final int key;
  final int imageValue;
  final ui.Image image;

  @override
  Future<int> obtainKey(ImageConfiguration configuration) {
    return Future<int>.value(key);
  }

  @override
  ImageStreamCompleter load(int key, DecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(TestImageInfo(imageValue, image: image.clone())),
    );
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TestImageProvider')}($key, $imageValue)';
}

class FailingTestImageProvider extends TestImageProvider {
  const FailingTestImageProvider(int key, int imageValue, { required ui.Image image }) : super(key, imageValue, image: image);

  @override
  ImageStreamCompleter load(int key, DecoderCallback decode) {
    return OneFrameImageStreamCompleter(Future<ImageInfo>.sync(() => Future<ImageInfo>.error('loading failed!')));
  }
}

Future<ImageInfo> extractOneFrame(ImageStream stream) {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  late ImageStreamListener listener;
  listener = ImageStreamListener((ImageInfo image, bool synchronousCall) {
    completer.complete(image);
    stream.removeListener(listener);
  });
  stream.addListener(listener);
  return completer.future;
}

class ErrorImageProvider extends ImageProvider<ErrorImageProvider> {
  @override
  ImageStreamCompleter load(ErrorImageProvider key, DecoderCallback decode) {
    throw Error();
  }

  @override
  Future<ErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ErrorImageProvider>(this);
  }
}

class ObtainKeyErrorImageProvider extends ImageProvider<ObtainKeyErrorImageProvider> {
  @override
  ImageStreamCompleter load(ObtainKeyErrorImageProvider key, DecoderCallback decode) {
    throw Error();
  }

  @override
  Future<ObtainKeyErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    throw Error();
  }
}

class LoadErrorImageProvider extends ImageProvider<LoadErrorImageProvider> {
  @override
  ImageStreamCompleter load(LoadErrorImageProvider key, DecoderCallback decode) {
    throw Error();
  }

  @override
  Future<LoadErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LoadErrorImageProvider>(this);
  }
}

class LoadErrorCompleterImageProvider extends ImageProvider<LoadErrorCompleterImageProvider> {
  @override
  ImageStreamCompleter load(LoadErrorCompleterImageProvider key, DecoderCallback decode) {
    final Completer<ImageInfo> completer = Completer<ImageInfo>.sync();
    completer.completeError(Error());
    return OneFrameImageStreamCompleter(completer.future);
  }

  @override
  Future<LoadErrorCompleterImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LoadErrorCompleterImageProvider>(this);
  }
}

class TestImageStreamCompleter extends ImageStreamCompleter {
  void testSetImage(ui.Image image) {
    setImage(ImageInfo(image: image, scale: 1.0));
  }
}
