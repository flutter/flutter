// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Uint8List;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';

import 'image_data.dart';
import 'painting_utils.dart';

void main() {
  final PaintingBindingSpy binding = PaintingBindingSpy();

  test('instantiateImageCodec used for loading images', () async {
    expect(binding.instantiateImageCodecCalledCount, 0);

    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    memoryImage.load(memoryImage, (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
      return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
    });
    expect(binding.instantiateImageCodecCalledCount, 1);
  });

  test('evict clears live references', () async {
    final TestPaintingBinding binding = TestPaintingBinding();
    expect(binding.imageCache.clearCount, 0);
    expect(binding.imageCache.liveClearCount, 0);

    binding.evict('/path/to/asset.png');
    expect(binding.imageCache.clearCount, 1);
    expect(binding.imageCache.liveClearCount, 1);
  });
}

class TestBindingBase implements BindingBase {
  @override
  void initInstances() {}

  @override
  void initServiceExtensions() {}

  @override
  Future<void> lockEvents(Future<void> Function() callback) async {}

  @override
  bool get locked => throw UnimplementedError();

  @override
  Future<void> performReassemble() {
    throw UnimplementedError();
  }

  @override
  void postEvent(String eventKind, Map<String, dynamic> eventData) {}

  @override
  Future<void> reassembleApplication() {
    throw UnimplementedError();
  }

  @override
  void registerBoolServiceExtension({String name, AsyncValueGetter<bool> getter, AsyncValueSetter<bool> setter}) {}

  @override
  void registerNumericServiceExtension({String name, AsyncValueGetter<double> getter, AsyncValueSetter<double> setter}) {}

  @override
  void registerServiceExtension({String name, ServiceExtensionCallback callback}) {}

  @override
  void registerSignalServiceExtension({String name, AsyncCallback callback}) {}

  @override
  void registerStringServiceExtension({String name, AsyncValueGetter<String> getter, AsyncValueSetter<String> setter}) {}

  @override
  void unlocked() {}

  @override
  Window get window => throw UnimplementedError();
}

class TestPaintingBinding extends TestBindingBase with ServicesBinding, PaintingBinding {

  @override
  final FakeImageCache imageCache = FakeImageCache();

  @override
  ImageCache createImageCache() => imageCache;
}

class FakeImageCache extends ImageCache {
  int clearCount = 0;
  int liveClearCount = 0;

  @override
  void clear() {
    clearCount += 1;
    super.clear();
  }

  @override
  void clearLiveImages() {
    liveClearCount += 1;
    super.clearLiveImages();
  }
}