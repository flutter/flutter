// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:js';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

void main() {
  group(SkiaObject, () {
    test('implements create, cache, delete, resurrect, delete lifecycle', () {
      int addPostFrameCallbackCount = 0;

      MockRasterizer mockRasterizer = MockRasterizer();
      when(mockRasterizer.addPostFrameCallback(any)).thenAnswer((_) {
        addPostFrameCallbackCount++;
      });
      window.rasterizer = mockRasterizer;

      // Trigger first create
      final TestSkiaObject testObject = TestSkiaObject();
      expect(SkiaObjects.managedObjects.single, testObject);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 0);

      // Check that the getter does not have side-effects
      final JsObject skiaObject1 = testObject.skiaObject;
      expect(skiaObject1, isNotNull);
      expect(SkiaObjects.managedObjects.single, testObject);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 0);

      // Trigger first delete
      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.managedObjects, isEmpty);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 1);

      // Trigger resurrect
      final JsObject skiaObject2 = testObject.skiaObject;
      expect(skiaObject2, isNotNull);
      expect(skiaObject2, isNot(same(skiaObject1)));
      expect(SkiaObjects.managedObjects.single, testObject);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 1);

      // Trigger final delete
      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.managedObjects, isEmpty);
      expect(addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 2);
    });
  });
}

class TestSkiaObject extends SkiaObject {
  int createDefaultCount = 0;
  int resurrectCount = 0;
  int deleteCount = 0;

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
}

class MockRasterizer extends Mock implements Rasterizer {}
