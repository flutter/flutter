// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPointerSignalListener {
  TestPointerSignalListener(this.event);

  final PointerSignalEvent event;
  bool callbackRan = false;

  void callback(PointerSignalEvent event) {
    expect(event, equals(this.event));
    expect(callbackRan, isFalse);
    callbackRan = true;
  }
}

class PointerSignalTester {
  final PointerSignalResolver resolver = PointerSignalResolver();
  PointerSignalEvent event = const PointerScrollEvent();

  TestPointerSignalListener addListener() {
    final listener = TestPointerSignalListener(event);
    resolver.register(event, listener.callback);
    return listener;
  }

  /// Simulates a new event dispatch cycle by resolving the current event and
  /// setting a new event to use for future calls.
  void resolve() {
    resolver.resolve(event);
    event = const PointerScrollEvent();
  }
}

void main() {
  test('Resolving with no entries should be a no-op', () {
    final tester = PointerSignalTester();
    tester.resolver.resolve(tester.event);
  });

  test('Resolving with no entries should notify engine of no-op', () {
    var allowedPlatformDefault = false;
    final tester = PointerSignalTester();
    tester.event = PointerScrollEvent(
      onRespond: ({required bool allowPlatformDefault}) {
        allowedPlatformDefault = allowPlatformDefault;
      },
    );
    tester.resolver.resolve(tester.event);
    expect(
      allowedPlatformDefault,
      isTrue,
      reason: 'Should have called respond with allowPlatformDefault: true',
    );
  });

  test('First entry should always win', () {
    final tester = PointerSignalTester();
    final TestPointerSignalListener first = tester.addListener();
    final TestPointerSignalListener second = tester.addListener();
    tester.resolve();
    expect(first.callbackRan, isTrue);
    expect(second.callbackRan, isFalse);
  });

  test('Re-use after resolve should work', () {
    final tester = PointerSignalTester();
    final TestPointerSignalListener first = tester.addListener();
    final TestPointerSignalListener second = tester.addListener();
    tester.resolve();
    expect(first.callbackRan, isTrue);
    expect(second.callbackRan, isFalse);

    final TestPointerSignalListener newEventListener = tester.addListener();
    tester.resolve();
    expect(newEventListener.callbackRan, isTrue);
    // Nothing should have changed for the previous event's listeners.
    expect(first.callbackRan, isTrue);
    expect(second.callbackRan, isFalse);
  });

  test('works with transformed events', () {
    final resolver = PointerSignalResolver();
    const originalEvent = PointerScrollEvent();
    final PointerSignalEvent transformedEvent = originalEvent.transformed(
      Matrix4.translationValues(10.0, 20.0, 0.0),
    );
    final PointerSignalEvent anotherTransformedEvent = originalEvent.transformed(
      Matrix4.translationValues(30.0, 50.0, 0.0),
    );

    expect(originalEvent, isNot(same(transformedEvent)));
    expect(transformedEvent.original, same(originalEvent));

    expect(originalEvent, isNot(same(anotherTransformedEvent)));
    expect(anotherTransformedEvent.original, same(originalEvent));

    final events = <PointerSignalEvent>[];
    resolver.register(transformedEvent, (PointerSignalEvent event) {
      events.add(event);
    });

    // Registering a second transformed event should not throw an assertion.
    expect(() {
      resolver.register(anotherTransformedEvent, (PointerSignalEvent event) {
        // This shouldn't be called because only the first registered callback is
        // invoked.
        events.add(event);
      });
    }, returnsNormally);

    resolver.resolve(originalEvent);

    expect(events.single, same(transformedEvent));
  });

  group('multiple registrations with keys', () {
    test('different keys: both callbacks are called', () {
      final resolver = PointerSignalResolver();
      final event = PointerScrollEvent();
      final calledKeys = <Object?>[];

      resolver.register(event, (_) { calledKeys.add('a'); }, key: 'a');
      resolver.register(event, (_) { calledKeys.add('b'); }, key: 'b');

      resolver.resolve(event);

      expect(calledKeys, unorderedEquals(<Object?>['a', 'b']));
    });

    test('same key: only first callback is called', () {
      final resolver = PointerSignalResolver();
      final event = PointerScrollEvent();
      final calledKeys = <Object?>[];

      resolver.register(event, (_) { calledKeys.add('a'); }, key: 'x');
      resolver.register(event, (_) { calledKeys.add('b'); }, key: 'x');

      resolver.resolve(event);

      expect(calledKeys, equals(<Object?>['a']));
    });

    test('key and keyless: both are called', () {
      final resolver = PointerSignalResolver();
      final event = PointerScrollEvent();
      final calledKeys = <Object?>[];

      resolver.register(event, (_) { calledKeys.add('keyed'); }, key: 'axis');
      resolver.register(event, (_) { calledKeys.add('keyless'); });

      resolver.resolve(event);

      expect(calledKeys, unorderedEquals(<Object?>['keyed', 'keyless']));
    });

    test('respond(false) called when registrations exist', () {
      final resolver = PointerSignalResolver();
      bool? respondValue;
      final event = PointerScrollEvent(
        onRespond: ({required bool allowPlatformDefault}) {
          respondValue = allowPlatformDefault;
        },
      );
      resolver.register(event, (_) {}, key: 'axis');
      resolver.resolve(event);

      expect(respondValue, isFalse);
    });

    test('multiple keyless: only first wins', () {
      final resolver = PointerSignalResolver();
      final event = PointerScrollEvent();
      final callOrder = <int>[];

      resolver.register(event, (_) { callOrder.add(1); });
      resolver.register(event, (_) { callOrder.add(2); });

      resolver.resolve(event);

      expect(callOrder, equals(<int>[1]));
    });
  });
}
