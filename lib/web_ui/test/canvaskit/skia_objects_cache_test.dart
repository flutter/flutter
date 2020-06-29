// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:js';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

void main() {
  SkiaObjects.maximumCacheSize = 4;
  group(ResurrectableSkiaObject, () {
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
      final JsObject skiaObject1 = testObject.skiaObject;
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
      final JsObject skiaObject2 = testObject.skiaObject;
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
      int deleteCount = 0;
      JsObject _makeJsObject() {
        return JsObject.jsify({
          'delete': allowInterop(() {
            deleteCount++;
          }),
        });
      }

      OneShotSkiaObject object1 = OneShotSkiaObject(_makeJsObject());
      expect(SkiaObjects.oneShotCache.length, 1);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isTrue);

      OneShotSkiaObject object2 = OneShotSkiaObject(_makeJsObject());
      expect(SkiaObjects.oneShotCache.length, 2);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isTrue);

      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.oneShotCache.length, 2);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isTrue);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isTrue);

      // Add 3 more objects to the cache to overflow it.
      OneShotSkiaObject(_makeJsObject());
      OneShotSkiaObject(_makeJsObject());
      OneShotSkiaObject(_makeJsObject());
      expect(SkiaObjects.oneShotCache.length, 5);
      expect(SkiaObjects.cachesToResize.length, 1);

      SkiaObjects.postFrameCleanUp();
      expect(deleteCount, 2);
      expect(SkiaObjects.oneShotCache.length, 3);
      expect(SkiaObjects.oneShotCache.debugContains(object1), isFalse);
      expect(SkiaObjects.oneShotCache.debugContains(object2), isFalse);
    });
  });
}

class TestSkiaObject extends ResurrectableSkiaObject {
  int createDefaultCount = 0;
  int resurrectCount = 0;
  int deleteCount = 0;

  final bool isExpensive;

  TestSkiaObject({this.isExpensive = false});

  JsObject _makeJsObject() {
    return JsObject.jsify({
      'delete': allowInterop(() {
        deleteCount++;
      }),
    });
  }

  @override
  JsObject createDefault() {
    createDefaultCount++;
    return _makeJsObject();
  }

  @override
  JsObject resurrect() {
    resurrectCount++;
    return _makeJsObject();
  }

  @override
  bool get isResurrectionExpensive => isExpensive;
}

class MockRasterizer extends Mock implements Rasterizer {}
