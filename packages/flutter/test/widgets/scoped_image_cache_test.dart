// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'image_data.dart';

void main() {
  testWidgets('ScopedImageCache.of finds the right cache', (WidgetTester tester) async {
    final GlobalKey<_TestStatefulWidgetState> key = GlobalKey<_TestStatefulWidgetState>();
    final TestImageCache imageCache = TestImageCache();
    await tester.pumpWidget(ScopedImageCache(
      child: TestStatefulWidget(key),
      imageCache: imageCache,
    ));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 1);
    expect(ScopedImageCache.of(key.currentContext), imageCache);
    expect(key.currentState.didChangeDependenciesCount, 1);

    await tester.pumpWidget(ScopedImageCache(
      child: TestStatefulWidget(key),
      imageCache: PaintingBinding.instance.imageCache,
    ));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 1);
    expect(ScopedImageCache.of(key.currentContext), PaintingBinding.instance.imageCache);
    expect(key.currentState.didChangeDependenciesCount, 1);

    await tester.pumpWidget(TestStatefulWidget(key));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 1);
    expect(ScopedImageCache.of(key.currentContext), PaintingBinding.instance.imageCache);
    expect(key.currentState.didChangeDependenciesCount, 1);
  });

  testWidgets('ScopedImageCache.dependOn finds the right cache', (WidgetTester tester) async {
    final GlobalKey<_TestStatefulWidgetState> key = GlobalKey<_TestStatefulWidgetState>();
    final TestImageCache imageCache = TestImageCache();
    await tester.pumpWidget(ScopedImageCache(
      child: TestStatefulWidget(key),
      imageCache: imageCache,
    ));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 1);
    expect(ScopedImageCache.dependOn(key.currentContext), imageCache);
    expect(key.currentState.didChangeDependenciesCount, 1);

    await tester.pumpWidget(ScopedImageCache(
      child: TestStatefulWidget(key),
      imageCache: PaintingBinding.instance.imageCache,
    ));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 2);
    expect(ScopedImageCache.dependOn(key.currentContext), PaintingBinding.instance.imageCache);
    expect(key.currentState.didChangeDependenciesCount, 2);

    await tester.pumpWidget(TestStatefulWidget(key));

    expect(find.byKey(key), findsOneWidget);
    expect(key.currentState.didChangeDependenciesCount, 3);
    expect(ScopedImageCache.dependOn(key.currentContext, paintingBindingOk: true), PaintingBinding.instance.imageCache);
    expect(key.currentState.didChangeDependenciesCount, 3);
  });

  testWidgets('ScopedImageCache works to catch the image stream', (WidgetTester tester) async {
    final TestImageCache imageCache = TestImageCache();
    final Completer<void> completer = Completer<void>();
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);

    final ExpensiveImageProvider provider = ExpensiveImageProvider('asdf', completer, bytes);
    final Image image = Image(image: provider);

    // Build a widget that acts like a custom wrapper around an Image widget
    // and uses the widget's image provider to resolve the image.
    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        // Trigger an early resolve call. A real client would rather do whatever
        // work with the stream they need via the custom image cache, but this
        // is enough to satisfy the test.
        image.image.resolve(
          createLocalImageConfiguration(context),
          imageCache: imageCache
        );
        return ScopedImageCache(
          imageCache: imageCache,
          child: image,
        );
      }
    ));

    expect(provider.loadAsyncCalls, 1);
    expect(provider.decodeCalls, 0);
    completer.complete();
    await tester.idle();

    // If the `image` failed to use our `imageCache`, these will be > 1.
    expect(provider.loadAsyncCalls, 1);
    expect(provider.decodeCalls, 1);
  });
}

class SpecialWrapperImage extends StatelessWidget {
  const SpecialWrapperImage(this.image, { Key key }) : super(key: key);

  final Image image;

  @override
  Widget build(BuildContext context) {
    return image;
  }
}

class ExpensiveImageProvider extends ImageProvider<String> {
  ExpensiveImageProvider(this.key, this.completer, this.bytes);

  final String key;

  final Completer<void> completer;
  final Uint8List bytes;

  int loadAsyncCalls = 0;
  int decodeCalls = 0;

  Future<ui.Codec> _loadAsync(String key, DecoderCallback decode) async {
    assert(key == this.key);

    loadAsyncCalls += 1;
    await completer.future;
    decodeCalls += 1;
    return decode(bytes);
  }

  @override
  ImageStreamCompleter load(String key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  @override
  Future<String> obtainKey(ImageConfiguration configuration) {
    return Future<String>.value(key);
  }


}

class TestImageCache implements ImageCache {
  final Map<Object, ImageStreamCompleter> cache = <Object, ImageStreamCompleter>{};

  @override
  int maximumSize;

  @override
  int maximumSizeBytes;

  @override
  void clear() {
    cache.clear();
  }

  @override
  int get currentSize => throw UnimplementedError();

  @override
  int get currentSizeBytes => throw UnimplementedError();

  @override
  bool evict(Object key) {
    return cache.remove(key) != null;
  }

  @override
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter Function() loader, { ImageErrorListener onError }) {
    if (!cache.containsKey(key)) {
      cache[key] = loader();
    }
    return cache[key];
  }
}

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget(Key key) : super (key: key);
  @override
  State<StatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends State<TestStatefulWidget>{
  int didChangeDependenciesCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount += 1;
  }

  @override
  Widget build(BuildContext context) => const  SizedBox(height: 10, width: 10);
}