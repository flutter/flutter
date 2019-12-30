// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import '../flutter_test_alternative.dart';

import '../rendering/rendering_tester.dart';
import 'mocks_for_image_cache.dart';

void main() {
  group(ImageCache, () {
    setUpAll(() {
      TestRenderingFlutterBinding(); // initializes the imageCache
    });

    tearDown(() {
      imageCache.clear();
      imageCache.maximumSize = 1000;
      imageCache.maximumSizeBytes = 10485760;
    });

    test('maintains cache size', () async {
      imageCache.maximumSize = 3;

      final TestImageInfo a = await extractOneFrame(const TestImageProvider(1, 1).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(a.value, equals(1));
      final TestImageInfo b = await extractOneFrame(const TestImageProvider(1, 2).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(b.value, equals(1));
      final TestImageInfo c = await extractOneFrame(const TestImageProvider(1, 3).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(c.value, equals(1));
      final TestImageInfo d = await extractOneFrame(const TestImageProvider(1, 4).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(d.value, equals(1));
      final TestImageInfo e = await extractOneFrame(const TestImageProvider(1, 5).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(e.value, equals(1));
      final TestImageInfo f = await extractOneFrame(const TestImageProvider(1, 6).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(f.value, equals(1));

      expect(f, equals(a));

      // cache still only has one entry in it: 1(1)

      final TestImageInfo g = await extractOneFrame(const TestImageProvider(2, 7).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(g.value, equals(7));

      // cache has two entries in it: 1(1), 2(7)

      final TestImageInfo h = await extractOneFrame(const TestImageProvider(1, 8).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(h.value, equals(1));

      // cache still has two entries in it: 2(7), 1(1)

      final TestImageInfo i = await extractOneFrame(const TestImageProvider(3, 9).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(i.value, equals(9));

      // cache has three entries in it: 2(7), 1(1), 3(9)

      final TestImageInfo j = await extractOneFrame(const TestImageProvider(1, 10).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(j.value, equals(1));

      // cache still has three entries in it: 2(7), 3(9), 1(1)

      final TestImageInfo k = await extractOneFrame(const TestImageProvider(4, 11).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(k.value, equals(11));

      // cache has three entries: 3(9), 1(1), 4(11)

      final TestImageInfo l = await extractOneFrame(const TestImageProvider(1, 12).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(l.value, equals(1));

      // cache has three entries: 3(9), 4(11), 1(1)

      final TestImageInfo m = await extractOneFrame(const TestImageProvider(2, 13).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(m.value, equals(13));

      // cache has three entries: 4(11), 1(1), 2(13)

      final TestImageInfo n = await extractOneFrame(const TestImageProvider(3, 14).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(n.value, equals(14));

      // cache has three entries: 1(1), 2(13), 3(14)

      final TestImageInfo o = await extractOneFrame(const TestImageProvider(4, 15).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(o.value, equals(15));

      // cache has three entries: 2(13), 3(14), 4(15)

      final TestImageInfo p = await extractOneFrame(const TestImageProvider(1, 16).resolve(ImageConfiguration.empty)) as TestImageInfo;
      expect(p.value, equals(16));

      // cache has three entries: 3(14), 4(15), 1(16)
    });

    test('clear removes all images and resets cache size', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      expect(imageCache.currentSize, 0);
      expect(imageCache.currentSizeBytes, 0);

      await extractOneFrame(const TestImageProvider(1, 1, image: testImage).resolve(ImageConfiguration.empty));
      await extractOneFrame(const TestImageProvider(2, 2, image: testImage).resolve(ImageConfiguration.empty));

      expect(imageCache.currentSize, 2);
      expect(imageCache.currentSizeBytes, 256 * 2);

      imageCache.clear();

      expect(imageCache.currentSize, 0);
      expect(imageCache.currentSizeBytes, 0);
    });

    test('evicts individual images', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);
      await extractOneFrame(const TestImageProvider(1, 1, image: testImage).resolve(ImageConfiguration.empty));
      await extractOneFrame(const TestImageProvider(2, 2, image: testImage).resolve(ImageConfiguration.empty));

      expect(imageCache.currentSize, 2);
      expect(imageCache.currentSizeBytes, 256 * 2);
      expect(imageCache.evict(1), true);
      expect(imageCache.currentSize, 1);
      expect(imageCache.currentSizeBytes, 256);
    });

    test('Increases cache size if an image is loaded that is larger then the maximum size', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      imageCache.maximumSizeBytes = 1;
      await extractOneFrame(const TestImageProvider(1, 1, image: testImage).resolve(ImageConfiguration.empty));
      expect(imageCache.currentSize, 1);
      expect(imageCache.currentSizeBytes, 256);
      expect(imageCache.maximumSizeBytes, 256 + 1000);
    });

    test('Returns null if an error is caught resolving an image', () {
      final ErrorImageProvider errorImage = ErrorImageProvider();
      expect(() => imageCache.putIfAbsent(errorImage, () => errorImage.load(errorImage, null)), throwsA(isInstanceOf<Error>()));
      bool caughtError = false;
      final ImageStreamCompleter result = imageCache.putIfAbsent(errorImage, () => errorImage.load(errorImage, null), onError: (dynamic error, StackTrace stackTrace) {
        caughtError = true;
      });
      expect(result, null);
      expect(caughtError, true);
    });

    test('already pending image is returned when it is put into the cache again', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
      final TestImageStreamCompleter completer2 = TestImageStreamCompleter();

      final TestImageStreamCompleter resultingCompleter1 = imageCache.putIfAbsent(testImage, () {
        return completer1;
      }) as TestImageStreamCompleter;
      final TestImageStreamCompleter resultingCompleter2 = imageCache.putIfAbsent(testImage, () {
        return completer2;
      }) as TestImageStreamCompleter;

      expect(resultingCompleter1, completer1);
      expect(resultingCompleter2, completer1);
    });

    test('pending image is removed when cache is cleared', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
      final TestImageStreamCompleter completer2 = TestImageStreamCompleter();

      final TestImageStreamCompleter resultingCompleter1 = imageCache.putIfAbsent(testImage, () {
        return completer1;
      }) as TestImageStreamCompleter;

      imageCache.clear();

      final TestImageStreamCompleter resultingCompleter2 = imageCache.putIfAbsent(testImage, () {
        return completer2;
      }) as TestImageStreamCompleter;

      expect(resultingCompleter1, completer1);
      expect(resultingCompleter2, completer2);
    });

    test('pending image is removed when image is evicted', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      final TestImageStreamCompleter completer1 = TestImageStreamCompleter();
      final TestImageStreamCompleter completer2 = TestImageStreamCompleter();

      final TestImageStreamCompleter resultingCompleter1 = imageCache.putIfAbsent(testImage, () {
        return completer1;
      }) as TestImageStreamCompleter;

      imageCache.evict(testImage);

      final TestImageStreamCompleter resultingCompleter2 = imageCache.putIfAbsent(testImage, () {
        return completer2;
      }) as TestImageStreamCompleter;

      expect(resultingCompleter1, completer1);
      expect(resultingCompleter2, completer2);
    });

    test('failed image can successfully be removed from the cache\'s pending images', () async {
      const TestImage testImage = TestImage(width: 8, height: 8);

      const FailingTestImageProvider(1, 1, image: testImage)
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener(
            (ImageInfo image, bool synchronousCall) { },
            onError: (dynamic exception, StackTrace stackTrace) {
              final bool evicationResult = imageCache.evict(1);
              expect(evicationResult, isTrue);
            },
          ));
    });
  });
}

