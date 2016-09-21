// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mojo/bindings.dart' as mojo_bindings;
import 'package:flutter_services/pointer.dart';
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
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer move events', () {
    mojo_bindings.Encoder encoder = new mojo_bindings.Encoder();

    PointerPacket packet = new PointerPacket();
    packet.pointers = <Pointer>[new Pointer(), new Pointer(), new Pointer()];
    packet.pointers[0].type = PointerType.down;
    packet.pointers[0].kind = PointerKind.touch;
    packet.pointers[1].type = PointerType.move;
    packet.pointers[1].kind = PointerKind.touch;
    packet.pointers[2].type = PointerType.up;
    packet.pointers[2].kind = PointerKind.touch;
    packet.encode(encoder);

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerPacket(encoder.message.buffer);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Synthetic move events', () {
    mojo_bindings.Encoder encoder = new mojo_bindings.Encoder();

    PointerPacket packet = new PointerPacket();
    packet.pointers = <Pointer>[new Pointer(), new Pointer()];
    packet.pointers[0]
      ..type = PointerType.down
      ..kind = PointerKind.touch
      ..x = 1.0
      ..y = 3.0;
    packet.pointers[1]
      ..type = PointerType.up
      ..kind = PointerKind.touch
      ..x = 10.0
      ..y = 15.0;
    packet.encode(encoder);

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) => events.add(event);

    ui.window.onPointerPacket(encoder.message.buffer);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[1].delta, equals(const Offset(9.0, 12.0)));
    expect(events[2].runtimeType, equals(PointerUpEvent));
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
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can cancel pointers', () {
    mojo_bindings.Encoder encoder = new mojo_bindings.Encoder();

    PointerPacket packet = new PointerPacket();
    packet.pointers = <Pointer>[new Pointer(), new Pointer()];
    packet.pointers[0].type = PointerType.down;
    packet.pointers[0].kind = PointerKind.touch;
    packet.pointers[1].type = PointerType.up;
    packet.pointers[1].kind = PointerKind.touch;
    packet.encode(encoder);

    List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) {
      events.add(event);
      if (event is PointerDownEvent)
        _binding.cancelPointer(event.pointer);
    };

    ui.window.onPointerPacket(encoder.message.buffer);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });
}
