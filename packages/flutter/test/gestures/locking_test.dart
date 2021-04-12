// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback? callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (callback != null)
      callback?.call(event);
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
      ui.window.onPointerDataPacket?.call(packet);
      callback();
    });
  }
}

late TestGestureFlutterBinding _binding;

void main() {
  _binding = TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);

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
    expect(events[0], isA<PointerDownEvent>());
    expect(events[1], isA<PointerUpEvent>());
  });
}
