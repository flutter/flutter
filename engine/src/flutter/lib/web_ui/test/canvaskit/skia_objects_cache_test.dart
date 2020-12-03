// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'package:mockito/mockito.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

import '../matchers.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('skia_objects_cache', () {
    _tests();
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

void _tests() {
  SkiaObjects.maximumCacheSize = 4;

  setUpCanvasKitTest();

  setUp(() async {
    // Pretend the browser does not support FinalizationRegistry so we can test the
    // resurrection logic.
    browserSupportsFinalizationRegistry = false;
  });

  group(ManagedSkiaObject, () {
    test('implements create, cache, delete, resurrect, delete lifecycle', () {
      int addPostFrameCallbackCount = 0;

      MockRasterizer mockRasterizer = MockRasterizer();
      when(mockRasterizer.addPostFrameCallback(any)).thenAnswer((_) {
        addPostFrameCallbackCount++;
      });
      EnginePlatformDispatcher.instance.rasterizer = mockRasterizer;

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

  group(SkiaObjectBox, () {
    test('Records stack traces and respects refcounts', () async {
      TestSkDeletable.deleteCount = 0;
      TestBoxWrapper.resurrectCount = 0;
      final TestBoxWrapper original = TestBoxWrapper();

      expect(original.box.debugGetStackTraces().length, 1);
      expect(original.box.refCount, 1);
      expect(original.box.isDeletedPermanently, false);

      final TestBoxWrapper clone = original.clone();
      expect(clone.box, same(original.box));
      expect(clone.box.debugGetStackTraces().length, 2);
      expect(clone.box.refCount, 2);
      expect(original.box.debugGetStackTraces().length, 2);
      expect(original.box.refCount, 2);
      expect(original.box.isDeletedPermanently, false);

      original.dispose();

      testCollector.collectNow();
      expect(TestSkDeletable.deleteCount, 0);

      expect(clone.box.debugGetStackTraces().length, 1);
      expect(clone.box.refCount, 1);
      expect(original.box.debugGetStackTraces().length, 1);
      expect(original.box.refCount, 1);

      clone.dispose();
      expect(clone.box.debugGetStackTraces().length, 0);
      expect(clone.box.refCount, 0);
      expect(original.box.debugGetStackTraces().length, 0);
      expect(original.box.refCount, 0);
      expect(original.box.isDeletedPermanently, true);

      testCollector.collectNow();
      expect(TestSkDeletable.deleteCount, 1);
      expect(TestBoxWrapper.resurrectCount, 0);

      expect(() => clone.box.unref(clone), throwsAssertionError);
    });

    test('Can resurrect Skia objects', () async {
      TestSkDeletable.deleteCount = 0;
      TestBoxWrapper.resurrectCount = 0;
      final TestBoxWrapper object = TestBoxWrapper();
      expect(TestSkDeletable.deleteCount, 0);
      expect(TestBoxWrapper.resurrectCount, 0);

      // Test 3 cycles of delete/resurrect.
      for (int i = 0; i < 3; i++) {
        object.box.delete();
        object.box.didDelete();
        expect(TestSkDeletable.deleteCount, i + 1);
        expect(TestBoxWrapper.resurrectCount, i);
        expect(object.box.isDeletedTemporarily, true);
        expect(object.box.isDeletedPermanently, false);

        expect(object.box.skiaObject, isNotNull);
        expect(TestSkDeletable.deleteCount, i + 1);
        expect(TestBoxWrapper.resurrectCount, i + 1);
        expect(object.box.isDeletedTemporarily, false);
        expect(object.box.isDeletedPermanently, false);
      }

      object.dispose();
      expect(object.box.isDeletedPermanently, true);
    });

    test('Can dispose temporarily deleted object', () async {
      TestSkDeletable.deleteCount = 0;
      TestBoxWrapper.resurrectCount = 0;
      final TestBoxWrapper object = TestBoxWrapper();
      expect(TestSkDeletable.deleteCount, 0);
      expect(TestBoxWrapper.resurrectCount, 0);

      object.box.delete();
      object.box.didDelete();
      expect(TestSkDeletable.deleteCount, 1);
      expect(TestBoxWrapper.resurrectCount, 0);
      expect(object.box.isDeletedTemporarily, true);
      expect(object.box.isDeletedPermanently, false);

      object.dispose();
      expect(object.box.isDeletedPermanently, true);
    });
  });
}

/// A simple class that wraps a [SkiaObjectBox].
///
/// Can be [clone]d such that the clones share the same ref counted box.
class TestBoxWrapper implements StackTraceDebugger {
  static int resurrectCount = 0;

  TestBoxWrapper() {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box = SkiaObjectBox<TestBoxWrapper, TestSkDeletable>.resurrectable(
      this,
      TestSkDeletable(),
      () {
        resurrectCount += 1;
        return TestSkDeletable();
      }
    );
  }

  TestBoxWrapper.cloneOf(this.box) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box.ref(this);
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  StackTrace _debugStackTrace;

  SkiaObjectBox<TestBoxWrapper, TestSkDeletable> box;

  void dispose() {
    box.unref(this);
  }

  TestBoxWrapper clone() => TestBoxWrapper.cloneOf(box);
}


class TestSkDeletable implements SkDeletable {
  static int deleteCount = 0;

  @override
  bool isDeleted() => _isDeleted;
  bool _isDeleted = false;

  @override
  void delete() {
    expect(_isDeleted, isFalse,
      reason: 'CanvasKit does not allow deleting the same object more than once.');
    _isDeleted = true;
    deleteCount++;
  }

  @override
  JsConstructor get constructor => TestJsConstructor('TestSkDeletable');
}

class TestJsConstructor implements JsConstructor{
  TestJsConstructor(this.name);

  @override
  final String name;
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
