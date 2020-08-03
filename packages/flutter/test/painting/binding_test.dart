// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';


void main() {
  testWidgets('didHaveMemoryPressure clears imageCache', (WidgetTester tester) async {
    imageCache.putIfAbsent(1, () => OneFrameImageStreamCompleter(
      Future<ImageInfo>.value(ImageInfo(
        image: FakeImage(),
        scale: 1.0,
      ),
    )));

    await tester.idle();
    expect(imageCache.currentSize, 1);
    final ByteData message = const JSONMessageCodec().encodeMessage(
      <String, dynamic>{'type': 'memoryPressure'});
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/system', message, (_) { });
    expect(imageCache.currentSize, 0);
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
  ui.Window get window => throw UnimplementedError();
}

class TestPaintingBinding extends TestBindingBase with SchedulerBinding, ServicesBinding, PaintingBinding {

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

class FakeImage implements ui.Image {
  @override
  void dispose() {}

  @override
  int get height => 10;

  @override
  Future<ByteData> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw UnimplementedError();
  }

  @override
  int get width => 10;
}
