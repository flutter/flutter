// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:js/js.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../matchers.dart';
import '../spy.dart';
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

  group(SkiaObjectBox, () {
    test('Records stack traces and respects refcounts', () async {
      final ZoneSpy spy = ZoneSpy();
      spy.run(() {
        Instrumentation.enabled = true;
        TestSkDeletableMock.deleteCount = 0;
        TestBoxWrapper.resurrectCount = 0;
        final TestBoxWrapper original = TestBoxWrapper();

        expect(original.box.debugGetStackTraces().length, 1);
        expect(original.box.refCount, 1);
        expect(original.box.isDeletedPermanently, isFalse);

        final TestBoxWrapper clone = original.clone();
        expect(clone.box, same(original.box));
        expect(clone.box.debugGetStackTraces().length, 2);
        expect(clone.box.refCount, 2);
        expect(original.box.debugGetStackTraces().length, 2);
        expect(original.box.refCount, 2);
        expect(original.box.isDeletedPermanently, isFalse);

        original.dispose();

        testCollector.collectNow();
        expect(TestSkDeletableMock.deleteCount, 0);

        spy.fakeAsync.elapse(const Duration(seconds: 2));
        expect(
          spy.printLog,
          <String>[
            'Engine counters:\n  TestSkDeletable created: 1\n'
          ],
        );

        expect(clone.box.debugGetStackTraces().length, 1);
        expect(clone.box.refCount, 1);
        expect(original.box.debugGetStackTraces().length, 1);
        expect(original.box.refCount, 1);

        clone.dispose();
        expect(clone.box.debugGetStackTraces().length, 0);
        expect(clone.box.refCount, 0);
        expect(original.box.debugGetStackTraces().length, 0);
        expect(original.box.refCount, 0);
        expect(original.box.isDeletedPermanently, isTrue);

        testCollector.collectNow();
        expect(TestSkDeletableMock.deleteCount, 1);
        expect(TestBoxWrapper.resurrectCount, 0);

        expect(() => clone.box.unref(clone), throwsAssertionError);
        spy.printLog.clear();
        spy.fakeAsync.elapse(const Duration(seconds: 2));
        expect(
          spy.printLog,
          <String>[
            'Engine counters:\n  TestSkDeletable created: 1\n  TestSkDeletable deleted: 1\n'
          ],
        );
        Instrumentation.enabled = false;
      });
    });

    test('Can resurrect Skia objects', () async {
      TestSkDeletableMock.deleteCount = 0;
      TestBoxWrapper.resurrectCount = 0;
      final TestBoxWrapper object = TestBoxWrapper();
      expect(TestSkDeletableMock.deleteCount, 0);
      expect(TestBoxWrapper.resurrectCount, 0);

      // Test 3 cycles of delete/resurrect.
      for (int i = 0; i < 3; i++) {
        object.box.delete();
        object.box.didDelete();
        expect(TestSkDeletableMock.deleteCount, i + 1);
        expect(TestBoxWrapper.resurrectCount, i);
        expect(object.box.isDeletedTemporarily, isTrue);
        expect(object.box.isDeletedPermanently, isFalse);

        expect(object.box.skiaObject, isNotNull);
        expect(TestSkDeletableMock.deleteCount, i + 1);
        expect(TestBoxWrapper.resurrectCount, i + 1);
        expect(object.box.isDeletedTemporarily, isFalse);
        expect(object.box.isDeletedPermanently, isFalse);
      }

      object.dispose();
      expect(object.box.isDeletedPermanently, isTrue);
    });

    test('Can dispose temporarily deleted object', () async {
      TestSkDeletableMock.deleteCount = 0;
      TestBoxWrapper.resurrectCount = 0;
      final TestBoxWrapper object = TestBoxWrapper();
      expect(TestSkDeletableMock.deleteCount, 0);
      expect(TestBoxWrapper.resurrectCount, 0);

      object.box.delete();
      object.box.didDelete();
      expect(TestSkDeletableMock.deleteCount, 1);
      expect(TestBoxWrapper.resurrectCount, 0);
      expect(object.box.isDeletedTemporarily, isTrue);
      expect(object.box.isDeletedPermanently, isFalse);

      object.dispose();
      expect(object.box.isDeletedPermanently, isTrue);
    });
  });

  group('$SynchronousSkiaObjectCache', () {
    test('is initialized empty', () {
      expect(SynchronousSkiaObjectCache(10), hasLength(0));
    });

    test('adds objects', () {
      final SynchronousSkiaObjectCache cache = SynchronousSkiaObjectCache(2);
      cache.add(TestSelfManagedObject());
      expect(cache, hasLength(1));
      cache.add(TestSelfManagedObject());
      expect(cache, hasLength(2));
    });

    test('forbids adding the same object twice', () {
      final SynchronousSkiaObjectCache cache = SynchronousSkiaObjectCache(2);
      final TestSelfManagedObject object = TestSelfManagedObject();
      cache.add(object);
      expect(cache, hasLength(1));
      expect(() => cache.add(object), throwsAssertionError);
    });

    void expectObjectInCache(
      SynchronousSkiaObjectCache cache,
      TestSelfManagedObject object,
    ) {
      expect(cache.debugContains(object), isTrue);
      expect(object._skiaObject, isNotNull);
    }

    void expectObjectNotInCache(
      SynchronousSkiaObjectCache cache,
      TestSelfManagedObject object,
    ) {
      expect(cache.debugContains(object), isFalse);
      expect(object._skiaObject, isNull);
    }

    test('respects maximumSize', () {
      final SynchronousSkiaObjectCache cache = SynchronousSkiaObjectCache(2);
      final TestSelfManagedObject object1 = TestSelfManagedObject();
      final TestSelfManagedObject object2 = TestSelfManagedObject();
      final TestSelfManagedObject object3 = TestSelfManagedObject();
      final TestSelfManagedObject object4 = TestSelfManagedObject();

      cache.add(object1);
      expect(cache, hasLength(1));
      expectObjectInCache(cache, object1);

      cache.add(object2);
      expect(cache, hasLength(2));
      expectObjectInCache(cache, object1);
      expectObjectInCache(cache, object2);

      cache.add(object3);
      expect(cache, hasLength(2));
      expectObjectNotInCache(cache, object1);
      expectObjectInCache(cache, object2);
      expectObjectInCache(cache, object3);

      cache.add(object4);
      expect(cache, hasLength(2));
      expectObjectNotInCache(cache, object1);
      expectObjectNotInCache(cache, object2);
      expectObjectInCache(cache, object3);
      expectObjectInCache(cache, object4);
    });

    test('uses RLU strategy', () {
      final SynchronousSkiaObjectCache cache = SynchronousSkiaObjectCache(2);
      final TestSelfManagedObject object1 = TestSelfManagedObject();
      final TestSelfManagedObject object2 = TestSelfManagedObject();
      final TestSelfManagedObject object3 = TestSelfManagedObject();
      final TestSelfManagedObject object4 = TestSelfManagedObject();

      cache.add(object1);
      expectObjectInCache(cache, object1);
      cache.add(object2);
      expectObjectInCache(cache, object2);
      cache.add(object3);
      expectObjectInCache(cache, object3);
      expectObjectNotInCache(cache, object1);

      cache.markUsed(object2);
      cache.add(object4);
      expectObjectInCache(cache, object2);
      expectObjectNotInCache(cache, object3);
      expectObjectInCache(cache, object4);
    });
  });
}

/// A simple class that wraps a [SkiaObjectBox].
///
/// Can be [clone]d such that the clones share the same ref counted box.
class TestBoxWrapper implements StackTraceDebugger {
  TestBoxWrapper() {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box = SkiaObjectBox<TestBoxWrapper, TestSkDeletable>.resurrectable(
        this, TestSkDeletable(), () {
      resurrectCount += 1;
      return TestSkDeletable();
    });
  }

  TestBoxWrapper.cloneOf(this.box) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box.ref(this);
  }

  static int resurrectCount = 0;

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  late SkiaObjectBox<TestBoxWrapper, TestSkDeletable> box;

  void dispose() {
    box.unref(this);
  }

  TestBoxWrapper clone() => TestBoxWrapper.cloneOf(box);
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
