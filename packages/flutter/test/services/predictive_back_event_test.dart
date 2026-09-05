// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap can be created with valid Map - SwipeEdge.left', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event.swipeEdge, SwipeEdge.left);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromMap can be created with valid Map - SwipeEdge.right', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.swipeEdge, SwipeEdge.right);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromMap can be created with valid Map - isButtonEvent zero position', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromMap can be created with valid Map - isButtonEvent null position', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': null,
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromMap throws when given progress above 1.0', () async {
    expect(
      () => PredictiveBackEvent.fromMap(const <String?, Object?>{
        'touchOffset': <double>[0.0, 100.0],
        'progress': 2.0,
        'swipeEdge': 1,
      }),
      throwsAssertionError,
    );
  });

  test('fromMap throws when given progress below 0.0', () async {
    expect(
      () => PredictiveBackEvent.fromMap(const <String?, Object?>{
        'touchOffset': <double>[0.0, 100.0],
        'progress': -0.1,
        'swipeEdge': 1,
      }),
      throwsAssertionError,
    );
  });

  test('fromMap maps swipeEdge 2 (EDGE_NONE) to SwipeEdge.none', () async {
    // Android's BackEvent.EDGE_NONE has value 2, and is sent when the back
    // gesture is triggered by a button press rather than a swipe gesture.
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 2,
    });
    expect(event.swipeEdge, SwipeEdge.none);
  });

  test('fromMap maps negative swipeEdge to SwipeEdge.none', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': -1,
    });
    expect(event.swipeEdge, SwipeEdge.none);
  });

  test('fromMap maps large swipeEdge index to SwipeEdge.none', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 99,
    });
    expect(event.swipeEdge, SwipeEdge.none);
  });

  test('equality when created with the same parameters', () async {
    final eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, equals(eventB));
    expect(eventA.hashCode, equals(eventB.hashCode));
    expect(eventA.toString(), equals(eventB.toString()));
  });

  test('when created with different parameters', () async {
    final eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, isNot(equals(eventB)));
    expect(eventA.hashCode, isNot(equals(eventB.hashCode)));
    expect(eventA.toString(), isNot(equals(eventB.toString())));
  });

  test('isButtonEvent detection', () async {
    // Case 1: SwipeEdge.none always indicates a button event
    final event1 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.0,
      'swipeEdge': 2,
    });
    expect(event1.isButtonEvent, isTrue);

    // Case 2: touchOffset is null
    final event2 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': null,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event2.isButtonEvent, isTrue);

    // Case 3: touchOffset is Offset.zero and progress is 0.0
    final event3 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event3.isButtonEvent, isTrue);

    // Case 4: Actual swipe gesture — non-zero offset and non-zero progress
    final event4 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[100.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    expect(event4.isButtonEvent, isFalse);

    // Case 5: Offset.zero but progress is non-zero — not a button event
    final event5 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    expect(event5.isButtonEvent, isFalse);

    // Case 6: Non-zero offset but progress is 0.0 — not a button event
    final event6 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[50.0, 50.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event6.isButtonEvent, isFalse);
  });

  test('equality with identical object', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    // ignore: unrelated_type_equality_checks
    expect(event == event, isTrue);
  });

  test('inequality with different runtimeType', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    // ignore: unrelated_type_equality_checks
    expect(event == 'not an event', isFalse);
  });

  test('inequality when progress differs', () async {
    final eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    expect(eventA, isNot(equals(eventB)));
    expect(eventA.hashCode, isNot(equals(eventB.hashCode)));
  });

  test('inequality when swipeEdge differs', () async {
    final eventA = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    final eventB = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 1,
    });
    expect(eventA, isNot(equals(eventB)));
    expect(eventA.hashCode, isNot(equals(eventB.hashCode)));
  });

  test('fromMap maps SwipeEdge.none and verifies SwipeEdge.none isButtonEvent', () async {
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[50.0, 50.0],
      'progress': 0.5,
      'swipeEdge': 2,
    });
    expect(event.swipeEdge, SwipeEdge.none);
    // SwipeEdge.none always means button event, even with non-zero offset/progress
    expect(event.isButtonEvent, isTrue);
  });
}
