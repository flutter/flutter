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

  test('fromMap throws when given invalid progress', () async {
    expect(
      () => PredictiveBackEvent.fromMap(const <String?, Object?>{
        'touchOffset': <double>[0.0, 100.0],
        'progress': 2.0,
        'swipeEdge': 1,
      }),
      throwsAssertionError,
    );
  });

  test('fromMap maps unknown swipeEdge to SwipeEdge.none', () async {
    // Android may send unknown swipeEdge indices (e.g. 2) for future edge types.
    // Values beyond the known range are mapped to SwipeEdge.none
    // rather than throwing a RangeError.
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

  test('fromMap can be created with double values for swipeEdge', () async {
    final eventLeft = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0.0,
    });
    expect(eventLeft.swipeEdge, SwipeEdge.left);

    final eventRight = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 1.0,
    });
    expect(eventRight.swipeEdge, SwipeEdge.right);

    final eventNone = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 2.0,
    });
    expect(eventNone.swipeEdge, SwipeEdge.none);
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
    // Case 1: SwipeEdge.none
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

    // Case 3: touchOffset is zero and progress is 0.0
    final event3 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[0.0, 0.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event3.isButtonEvent, isTrue);

    // Case 4: Actual gesture
    final event4 = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': <double>[100.0, 100.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    expect(event4.isButtonEvent, isFalse);
  });
}
