// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late _MockFinalizer mockFinalizer;
  final Finalizer originalFinalizer = UniqueRef.finalizer;

  setUp(() {
    UniqueRef.finalizer = mockFinalizer = _MockFinalizer();
  });

  tearDown(() {
    UniqueRef.finalizer = originalFinalizer;
  });

  group(UniqueRef, () {
    test('create-dispose cycle', () {
      final owner = Object();
      final nativeObject = _MockNativeObject();
      var disposed = false;
      final ref = UniqueRef<_MockNativeObject>(
        owner,
        nativeObject,
        'TestObject',
        onDispose: (obj) => disposed = true,
      );

      expect(ref.isDisposed, isFalse);
      expect(ref.nativeObject, nativeObject);
      expect(disposed, isFalse);
      expect(mockFinalizer.attachedTargets, contains(owner));

      ref.dispose();
      expect(ref.isDisposed, isTrue);
      expect(disposed, isTrue);
      expect(mockFinalizer.attachedTargets, isEmpty);
    });

    test('collect calls onDispose', () {
      final owner = Object();
      final nativeObject = _MockNativeObject();
      var disposed = false;
      final ref = UniqueRef<_MockNativeObject>(
        owner,
        nativeObject,
        'TestObject',
        onDispose: (obj) => disposed = true,
      );

      ref.collect();
      expect(ref.isDisposed, isTrue);
      expect(disposed, isTrue);
    });
  });

  group(CountedRef, () {
    test('reference counting', () {
      final nativeObject = _MockNativeObject();
      var disposed = false;
      final referrer1 = _MockStackTraceDebugger();
      final referrer2 = _MockStackTraceDebugger();

      final ref = CountedRef<_MockStackTraceDebugger, _MockNativeObject>(
        nativeObject,
        referrer1,
        'TestObject',
        onDispose: (obj) => disposed = true,
      );

      expect(ref.refCount, 1);
      expect(disposed, isFalse);

      ref.ref(referrer2);
      expect(ref.refCount, 2);

      ref.unref(referrer1);
      expect(ref.refCount, 1);
      expect(disposed, isFalse);

      ref.unref(referrer2);
      expect(ref.refCount, 0);
      expect(disposed, isTrue);
    });
  });
}

class _MockNativeObject {}

class _MockStackTraceDebugger implements StackTraceDebugger {
  @override
  StackTrace get debugStackTrace => StackTrace.current;
}

class _MockFinalizer implements Finalizer {
  final Set<Object> attachedTargets = <Object>{};

  @override
  void attach(Object target, Object value, {Object? detach}) {
    attachedTargets.add(target);
  }

  @override
  void detach(Object detach) {
    // In our implementation, detach is called with the UniqueRef itself
    // We need to find which target it was attached to.
    // For simplicity in this mock, we'll just clear everything or
    // track by detach token if we want to be precise.
    attachedTargets.clear();
  }
}
