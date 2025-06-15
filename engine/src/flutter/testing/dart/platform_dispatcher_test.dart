// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('ViewConstraints.tight', () {
    final ViewConstraints tightConstraints = ViewConstraints.tight(const Size(200, 300));
    expect(tightConstraints.minWidth, 200);
    expect(tightConstraints.maxWidth, 200);
    expect(tightConstraints.minHeight, 300);
    expect(tightConstraints.maxHeight, 300);

    expect(tightConstraints.isTight, true);
    expect(tightConstraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(tightConstraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(tightConstraints / 2, ViewConstraints.tight(const Size(100, 150)));
  });

  test('ViewConstraints unconstrained', () {
    const ViewConstraints defaultValues = ViewConstraints();
    expect(defaultValues.minWidth, 0);
    expect(defaultValues.maxWidth, double.infinity);
    expect(defaultValues.minHeight, 0);
    expect(defaultValues.maxHeight, double.infinity);

    expect(defaultValues.isTight, false);
    expect(defaultValues.isSatisfiedBy(const Size(200, 300)), true);
    expect(defaultValues.isSatisfiedBy(const Size(400, 500)), true);
    expect(defaultValues / 2, const ViewConstraints());
  });

  test('ViewConstraints', () {
    const ViewConstraints constraints = ViewConstraints(
      minWidth: 100,
      maxWidth: 200,
      minHeight: 300,
      maxHeight: 400,
    );
    expect(constraints.minWidth, 100);
    expect(constraints.maxWidth, 200);
    expect(constraints.minHeight, 300);
    expect(constraints.maxHeight, 400);

    expect(constraints.isTight, false);
    expect(constraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(constraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(
      constraints / 2,
      const ViewConstraints(minWidth: 50, maxWidth: 100, minHeight: 150, maxHeight: 200),
    );
  });

  test('scheduleWarmupFrame should call both callbacks and flush microtasks', () async {
    bool microtaskFlushed = false;
    bool beginFrameCalled = false;
    final Completer<void> drawFrameCalled = Completer<void>();
    PlatformDispatcher.instance.scheduleWarmUpFrame(
      beginFrame: () {
        expect(microtaskFlushed, false);
        expect(drawFrameCalled.isCompleted, false);
        expect(beginFrameCalled, false);
        beginFrameCalled = true;
        scheduleMicrotask(() {
          expect(microtaskFlushed, false);
          expect(drawFrameCalled.isCompleted, false);
          microtaskFlushed = true;
        });
        expect(microtaskFlushed, false);
      },
      drawFrame: () {
        expect(beginFrameCalled, true);
        expect(microtaskFlushed, true);
        expect(drawFrameCalled.isCompleted, false);
        drawFrameCalled.complete();
      },
    );
    await drawFrameCalled.future;
    expect(beginFrameCalled, true);
    expect(drawFrameCalled.isCompleted, true);
    expect(microtaskFlushed, true);
  });

  group('SemanticsEvent', () {
    test('creates SemanticsEvent with required parameters', () {
      const event = SemanticsEvent(type: 'focus', data: <String, dynamic>{'key': 'value'});

      expect(event.type, equals('focus'));
      expect(event.data, equals(<String, dynamic>{'key': 'value'}));
      expect(event.nodeId, isNull);
    });

    test('creates SemanticsEvent with optional nodeId', () {
      const event = SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'key': 'value'},
        nodeId: 123,
      );

      expect(event.type, equals('focus'));
      expect(event.data, equals(<String, dynamic>{'key': 'value'}));
      expect(event.nodeId, equals(123));
    });

    test('toString returns correct format', () {
      const event = SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'key': 'value'},
        nodeId: 123,
      );

      expect(event.toString(), equals('SemanticsEvent(focus, nodeId: 123)'));
    });

    test('toString handles null nodeId', () {
      const event = SemanticsEvent(type: 'focus', data: <String, dynamic>{'key': 'value'});

      expect(event.toString(), equals('SemanticsEvent(focus, nodeId: null)'));
    });

    test('supports different event types', () {
      const focusEvent = SemanticsEvent(type: 'focus', data: <String, dynamic>{});

      const announceEvent = SemanticsEvent(
        type: 'announce',
        data: <String, dynamic>{'message': 'Hello'},
      );

      expect(focusEvent.type, equals('focus'));
      expect(announceEvent.type, equals('announce'));
    });

    test('supports complex data structures', () {
      const event = SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{
          'nested': <String, dynamic>{'key': 'value', 'number': 42},
          'list': <int>[1, 2, 3],
        },
      );

      expect(event.data['nested']['key'], equals('value'));
      expect(event.data['nested']['number'], equals(42));
      expect(event.data['list'], equals(<int>[1, 2, 3]));
    });

    test('supports empty data', () {
      const event = SemanticsEvent(type: 'focus', data: <String, dynamic>{});

      expect(event.data, isEmpty);
      expect(event.type, equals('focus'));
    });
  });

  group('SemanticsEventCallback', () {
    test('callback typedef accepts SemanticsEvent', () {
      SemanticsEvent? receivedEvent;

      void callback(SemanticsEvent event) {
        receivedEvent = event;
      }

      // Verify the callback can be assigned to SemanticsEventCallback
      final SemanticsEventCallback typedCallback = callback;

      const testEvent = SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'test': true},
        nodeId: 456,
      );

      typedCallback(testEvent);

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.type, equals('focus'));
      expect(receivedEvent!.nodeId, equals(456));
      expect(receivedEvent!.data['test'], isTrue);
    });

    test('callback can handle multiple event types', () {
      final List<SemanticsEvent> receivedEvents = <SemanticsEvent>[];

      void callback(SemanticsEvent event) {
        receivedEvents.add(event);
      }

      final SemanticsEventCallback typedCallback = callback;

      const focusEvent = SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'focus': true},
        nodeId: 1,
      );

      const announceEvent = SemanticsEvent(
        type: 'announce',
        data: <String, dynamic>{'message': 'Hello'},
        nodeId: 2,
      );

      typedCallback(focusEvent);
      typedCallback(announceEvent);

      expect(receivedEvents, hasLength(2));
      expect(receivedEvents[0].type, equals('focus'));
      expect(receivedEvents[1].type, equals('announce'));
    });

    test('callback can be null', () {
      SemanticsEventCallback? nullCallback;

      expect(nullCallback, isNull);

      // Assigning a callback should work
      nullCallback = (SemanticsEvent event) {};
      expect(nullCallback, isNotNull);

      // Setting back to null should work
      nullCallback = null;
      expect(nullCallback, isNull);
    });
  });
}
