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
      expect(mockFinalizer.registeredPairs.single.target, same(owner));
      expect(mockFinalizer.registeredPairs.single.value, same(ref));

      ref.dispose();
      expect(ref.isDisposed, isTrue);
      expect(disposed, isTrue);
      expect(mockFinalizer.registeredPairs, isEmpty);
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
      var nativeDisposed = false;
      var wrapperDisposed = false;
      final referrer1 = _MockStackTraceDebugger();
      final referrer2 = _MockStackTraceDebugger();

      final ref = CountedRef<_MockStackTraceDebugger, _MockNativeObject>(
        nativeObject,
        referrer1,
        'TestObject',
        onDispose: (obj) => nativeDisposed = true,
        onDisposed: (referrer) => wrapperDisposed = true,
      );

      expect(ref.refCount, 1);
      expect(nativeDisposed, isFalse);
      expect(wrapperDisposed, isFalse);

      ref.ref(referrer2);
      expect(ref.refCount, 2);

      ref.unref(referrer1);
      expect(ref.refCount, 1);
      expect(nativeDisposed, isFalse);
      expect(wrapperDisposed, isFalse);

      ref.unref(referrer2);
      expect(ref.refCount, 0);
      expect(nativeDisposed, isTrue);
      expect(wrapperDisposed, isTrue);
    });
  });
}

class _MockNativeObject {}

class _MockStackTraceDebugger implements StackTraceDebugger {
  @override
  StackTrace get debugStackTrace => StackTrace.current;
}

class _MockFinalizer implements Finalizer {
  final List<({Object target, Object value, Object? detach})> _registeredPairs = [];

  List<({Object target, Object value, Object? detach})> get registeredPairs => _registeredPairs;

  @override
  void attach(Object target, Object value, {Object? detach}) {
    _registeredPairs.add((target: target, value: value, detach: detach));
  }

  @override
  void detach(Object detach) {
    _registeredPairs.removeWhere((pair) => pair.detach == detach);
  }
}
