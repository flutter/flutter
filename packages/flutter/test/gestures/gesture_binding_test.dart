// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mojo/bindings.dart' as mojo_bindings;
import 'package:sky_services/pointer/pointer.mojom.dart';
import 'package:test/test.dart';

typedef void HandleEventCallback(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (callback != null)
      callback(event);
    super.handleEvent(event, entry);
  }
}

TestGestureFlutterBinding _binding = new TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  if (_binding == null)
    _binding = new TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer tap events', () {
    mojo_bindings.Encoder encoder = new mojo_bindings.Encoder();

    PointerPacket packet = new PointerPacket();
    packet.pointers = <Pointer>[new Pointer(), new Pointer()];
    packet.pointers[0].type = PointerType.down;
    packet.pointers[0].kind = PointerKind.touch;
    packet.pointers[1].type = PointerType.up;
    packet.pointers[1].kind = PointerKind.touch;
    packet.encode(encoder);

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerPacket(encoder.message.buffer);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer cancel events', () {
    mojo_bindings.Encoder encoder = new mojo_bindings.Encoder();

    PointerPacket packet = new PointerPacket();
    packet.pointers = <Pointer>[new Pointer(), new Pointer()];
    packet.pointers[0].type = PointerType.down;
    packet.pointers[0].kind = PointerKind.touch;
    packet.pointers[1].type = PointerType.cancel;
    packet.pointers[1].kind = PointerKind.touch;
    packet.encode(encoder);

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerPacket(encoder.message.buffer);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });
}
