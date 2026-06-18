// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap can be created with SwipeEdge.none (2) at progress 0.5', () async {
    // Index 2 maps to SwipeEdge.none.
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': null,
      'progress': 0.5,
      'swipeEdge': 2,
    });

    expect(event.swipeEdge.toString(), 'SwipeEdge.none');
    expect(event.isButtonEvent, isFalse);
  });

  test('fromMap can be created with SwipeEdge.none (2) at progress 0.0', () async {
    // Index 2 maps to SwipeEdge.none.
    final event = PredictiveBackEvent.fromMap(const <String?, Object?>{
      'touchOffset': null,
      'progress': 0.0,
      'swipeEdge': 2,
    });

    expect(event.swipeEdge.toString(), 'SwipeEdge.none');
    expect(event.isButtonEvent, isFalse);
  });
}
