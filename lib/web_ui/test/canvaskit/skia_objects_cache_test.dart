// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  group('skia_objects_cache', () {
    _tests();
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

void _tests() {
  SkiaObjects.maximumCacheSize = 4;
  bool originalBrowserSupportsFinalizationRegistry;

  setUpAll(() async {
    await ui.webOnlyInitializePlatform();

    // Pretend the browser does not support FinalizationRegistry so we can test the
    // resurrection logic.
    originalBrowserSupportsFinalizationRegistry = browserSupportsFinalizationRegistry;
    browserSupportsFinalizationRegistry = false;
  });

  tearDownAll(() {
    browserSupportsFinalizationRegistry = originalBrowserSupportsFinalizationRegistry;
  });

  group(ManagedSkiaObject, () {
    test('implements create, cache, delete, resurrect, delete lifecycle', () {
      int addPostFrameCallbackCount = 0;

      MockRasterizer mockRasterizer = MockRasterizer();
      when(mockRasterizer.addPostFrameCallback(any)).thenAnswer((_) {
        addPostFrameCallbackCount++;
      });
      window.rasterizer = mockRasterizer;

      // Trigger first create
      final TestSkiaObject testObject = TestSkiaObject();
      expect(SkiaObjects.resurrectableObjects.single, testObject);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 0);

      // Check that the getter does not have side-effects
      final SkPaint skiaObject1 = testObject.skiaObject;
      expect(skiaObject1, isNotNull);
      expect(SkiaObjects.resurrectableObjects.single, testObject);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 0);

      // Trigger first delete
      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.resurrectableObjects, isEmpty);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 1);

      // Trigger resurrect
      final SkPaint skiaObject2 = testObject.skiaObject;
      expect(skiaObject2, isNotNull);
      expect(skiaObject2, isNot(same(skiaObject1)));
      expect(SkiaObjects.resurrectableObjects.single, testObject);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 1);

      // Trigger final delete
      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.resurrectableObjects, isEmpty);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 2);
    });

    test('is added to SkiaObjects cache if expensive', () {
      TestSkiaObject object1 = TestSkiaObject(isExpensive: true);
      expect(SkiaObjects.expensiveCache.length, 1);
      expect(SkiaObjects.expensiveCache.debugContains(object1), isTrue);

      TestSkiaObject object2 = TestSkiaObject(isExpensive: true);
      expect(SkiaObjects.expensiveCache.length, 2);
      expect(SkiaObjects.expensiveCache.debugContains(object2), isTrue);

      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.expensiveCache.length, 2);
      expect(SkiaObjects.expensiveCache.debugContains(object1), isTrue);
      expect(SkiaObjects.expensiveCache.debugContains(object2), isTrue);

      /// Add 3 more objects to the cache to overflow it.
      TestSkiaObject(isExpensive: true);
      TestSkiaObject(isExpensive: true);
      TestSkiaObject(isExpensive: true);
      expect(SkiaObjects.expensiveCache.length, 5);
      expect(SkiaObjects.cachesToResize.length, 1);

      SkiaObjects.postFrameCleanUp();
      expect(object1.deleteCount, 1);
      expect(object2.deleteCount, 1);
      expect(SkiaObjects.expensiveCache.length, 3);
      expect(SkiaObjects.expensiveCache.debugContains(object1), isFalse);
      expect(SkiaObjects.expensiveCache.debugContains(object2), isFalse);
    });
  });

  group(OneShotSkiaObject, () {
    test('is added to SkiaObjects cache', () {
      TestOneShotSkiaObject.deleteCount = 0;
      OneShotSkiaObject object1 = TestOneShotSkiaObject();
      expect(SkiaObjects.oneShotCache.length, 1);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isTrue);

      OneShotSkiaObject object2 = TestOneShotSkiaObject();
      expect(SkiaObjects.oneShotCache.length, 2);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isTrue);

      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.oneShotCache.length, 2);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isTrue);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isTrue);

      // Add 3 more objects to the cache to overflow it.
      TestOneShotSkiaObject();
      TestOneShotSkiaObject();
      TestOneShotSkiaObject();
      expect(SkiaObjects.oneShotCache.length, 5);
      expect(SkiaObjects.cachesToResize.length, 1);

      SkiaObjects.postFrameCleanUp();
      expect(TestOneShotSkiaObject.deleteCount, 2);
      expect(SkiaObjects.oneShotCache.length, 3);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isFalse);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isFalse);
    });
  });
}

class TestOneShotSkiaObject extends OneShotSkiaObject<SkPaint> {
  static int deleteCount = 0;

  TestOneShotSkiaObject() : super(SkPaint());

  @override
  void delete() {
    rawSkiaObject?.delete();
    deleteCount++;
  }
}

class TestSkiaObject extends ManagedSkiaObject<SkPaint> {
  int createDefaultCount = 0;
  int resurrectCount = 0;
  int deleteCount = 0;

  final bool isExpensive;

  TestSkiaObject({this.isExpensive = false});

  @override
  SkPaint createDefault() {
    createDefaultCount++;
    return SkPaint();
  }

  @override
  SkPaint resurrect() {
    resurrectCount++;
    return SkPaint();
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
    deleteCount++;
  }

  @override
  bool get isResurrectionExpensive => isExpensive;
}

class MockRasterizer extends Mock implements Rasterizer {}
