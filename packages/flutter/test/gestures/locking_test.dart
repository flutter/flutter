// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (callback != null)
      callback(event);
    super.handleEvent(event, entry);
  }

  static const ui.PointerDataPacket packet = ui.PointerDataPacket(
    data: <ui.PointerData>[
      ui.PointerData(change: ui.PointerChange.down),
      ui.PointerData(change: ui.PointerChange.up),
    ],
  );

  Future<void> test(VoidCallback callback) {
    assert(callback != null);
    return _binding.lockEvents(() async {
      ui.window.onPointerDataPacket(packet);
      callback();
    });
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer events are locked during reassemble', () async {
    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;
    bool tested = false;
    await _binding.test(() {
      expect(events.length, 0);
      tested = true;
    });
    expect(tested, isTrue);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });
}
