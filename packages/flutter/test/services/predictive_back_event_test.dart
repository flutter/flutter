// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJSON can be created with valid JSON - SwipeEdge.left', () async {
    final PredictiveBackEvent event = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(event.swipeEdge, SwipeEdge.left);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromJSON can be created with valid JSON - SwipeEdge.right', () async {
    final PredictiveBackEvent event = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.swipeEdge, SwipeEdge.right);
    expect(event.isButtonEvent, isFalse);
  });

  test('fromJSON can be created with valid JSON - isButtonEvent zero position', () async {
    final PredictiveBackEvent event = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 0.0,
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromJSON can be created with valid JSON - isButtonEvent null position', () async {
    final PredictiveBackEvent event = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'progress': 0.0,
      'swipeEdge': 1,
    });
    expect(event.isButtonEvent, isTrue);
  });

  test('fromJSON throws when given invalid progress', () async {
    expect(
      () => PredictiveBackEvent.fromJSON(const <String, dynamic>{
        'x': 0.0,
        'y': 100.0,
        'progress': 2.0,
        'swipeEdge': 1,
      }),
      throwsAssertionError,
    );
  });

  test('fromJSON throws when given invalid swipeEdge', () async {
    expect(
      () => PredictiveBackEvent.fromJSON(const <String, dynamic>{
        'x': 0.0,
        'y': 100.0,
        'progress': 0.0,
        'swipeEdge': 2,
      }),
      throwsRangeError,
    );
  });

  test('equality when created with the same parameters', () async {
    final PredictiveBackEvent eventA = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final PredictiveBackEvent eventB = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, equals(eventB));
    expect(eventA.hashCode, equals(eventB.hashCode));
    expect(eventA.toString(), equals(eventB.toString()));
  });

  test('when created with different parameters', () async {
    final PredictiveBackEvent eventA = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 0.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    final PredictiveBackEvent eventB = PredictiveBackEvent.fromJSON(const <String, dynamic>{
      'x': 1.0,
      'y': 100.0,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(eventA, isNot(equals(eventB)));
    expect(eventA.hashCode, isNot(equals(eventB.hashCode)));
    expect(eventA.toString(), isNot(equals(eventB.toString())));
  });
}
