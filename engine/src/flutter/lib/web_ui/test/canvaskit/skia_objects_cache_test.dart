// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:js/js.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('skia_objects_cache', () {
    _tests();
  });
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
      final FakeRasterizer fakeRasterizer = FakeRasterizer();
      CanvasKitRenderer.instance.rasterizer = fakeRasterizer;

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
      expect(fakeRasterizer.addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 0);
      expect(testObject.deleteCount, 1);

      // Trigger resurrect
      final SkPaint skiaObject2 = testObject.skiaObject;
      expect(skiaObject2, isNotNull);
      expect(skiaObject2, isNot(same(skiaObject1)));
      expect(SkiaObjects.resurrectableObjects.single, testObject);
      expect(fakeRasterizer.addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 1);

      // Trigger final delete
      SkiaObjects.postFrameCleanUp();
      expect(SkiaObjects.resurrectableObjects, isEmpty);
      expect(fakeRasterizer.addPostFrameCallbackCount, 1);
      expect(testObject.createDefaultCount, 1);
      expect(testObject.resurrectCount, 1);
      expect(testObject.deleteCount, 2);
    });

    test('is added to SkiaObjects cache if expensive', () {
      final TestSkiaObject object1 = TestSkiaObject(isExpensive: true);
      expect(SkiaObjects.expensiveCache.length, 1);
      expect(SkiaObjects.expensiveCache.debugContains(object1), isTrue);

      final TestSkiaObject object2 = TestSkiaObject(isExpensive: true);
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
}

class TestSkDeletableMock {
  static int deleteCount = 0;

  bool isDeleted() => _isDeleted;
  bool _isDeleted = false;

  void delete() {
    expect(_isDeleted, isFalse,
        reason:
            'CanvasKit does not allow deleting the same object more than once.');
    _isDeleted = true;
    deleteCount++;
  }

  JsConstructor get constructor => TestJsConstructor(name:
      'TestSkDeletable'.toJS);
}

@JS()
@anonymous
@staticInterop
class TestSkDeletable implements SkDeletable {
  factory TestSkDeletable() {
    final TestSkDeletableMock mock = TestSkDeletableMock();
    return TestSkDeletable._(
        isDeleted: () { return mock.isDeleted(); }.toJS,
        delete: () { return mock.delete(); }.toJS,
        constructor: mock.constructor);
  }

  external factory TestSkDeletable._({
    JSFunction isDeleted,
    JSFunction delete,
    JsConstructor constructor});
}

@JS()
@anonymous
@staticInterop
class TestJsConstructor implements JsConstructor {
  external factory TestJsConstructor({JSString name});
}

class TestSkiaObject extends ManagedSkiaObject<SkPaint> {
  TestSkiaObject({this.isExpensive = false});

  int createDefaultCount = 0;
  int resurrectCount = 0;
  int deleteCount = 0;

  final bool isExpensive;

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

class FakeRasterizer implements Rasterizer {
  int addPostFrameCallbackCount = 0;

  @override
  void addPostFrameCallback(VoidCallback callback) {
    addPostFrameCallbackCount++;
  }

  @override
  CompositorContext get context => throw UnimplementedError();

  @override
  void draw(LayerTree layerTree) {
    throw UnimplementedError();
  }

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    throw UnimplementedError();
  }

  @override
  void debugRunPostFrameCallbacks() {
    throw UnimplementedError();
  }
}

class TestSelfManagedObject extends SkiaObject<TestSkDeletable> {
  TestSkDeletable? _skiaObject = TestSkDeletable();

  @override
  void delete() {
    _skiaObject!.delete();
  }

  @override
  void didDelete() {
    _skiaObject = null;
  }

  @override
  TestSkDeletable get skiaObject => throw UnimplementedError();
}
