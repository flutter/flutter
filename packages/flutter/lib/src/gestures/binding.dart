// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:mojo/bindings.dart' as mojo_bindings;
import 'package:mojo/core.dart' as mojo_core;
import 'package:sky_services/pointer/pointer.mojom.dart';

import 'arena.dart';
import 'converter.dart';
import 'events.dart';
import 'hit_test.dart';
import 'pointer_router.dart';

abstract class Gesturer extends BindingBase implements HitTestTarget, HitTestable {

  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onPointerPacket = _handlePointerPacket;
  }

  static Gesturer _instance;
  static Gesturer get instance => _instance;

  void _handlePointerPacket(ByteData serializedPacket) {
    final mojo_bindings.Message message = new mojo_bindings.Message(
      serializedPacket,
      <mojo_core.MojoHandle>[],
      serializedPacket.lengthInBytes,
      0
    );
    final PointerPacket packet = PointerPacket.deserialize(message);
    for (PointerEvent event in PointerEventConverter.expand(packet.pointers))
      _handlePointerEvent(event);
  }

  /// A router that routes all pointer events received from the engine.
  final PointerRouter pointerRouter = new PointerRouter();

  /// The gesture arenas used for disambiguating the meaning of sequences of
  /// pointer events.
  final GestureArena gestureArena = new GestureArena();

  /// State for all pointers which are currently down.
  ///
  /// The state of hovering pointers is not tracked because that would require
  /// hit-testing on every frame.
  Map<int, HitTestResult> _hitTests = <int, HitTestResult>{};

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      assert(!_hitTests.containsKey(event.pointer));
      HitTestResult result = new HitTestResult();
      hitTest(result, event.position);
      _hitTests[event.pointer] = result;
    } else if (event is! PointerUpEvent) {
      assert(event.down == _hitTests.containsKey(event.pointer));
      if (!event.down)
        return; // we currently ignore add, remove, and hover move events
    }
    assert(_hitTests[event.pointer] != null);
    dispatchEvent(event, _hitTests[event.pointer]);
    if (event is PointerUpEvent) {
      assert(_hitTests.containsKey(event.pointer));
      _hitTests.remove(event.pointer);
    }
  }

  /// Determine which [HitTestTarget] objects are located at a given position.
  void hitTest(HitTestResult result, Point position) {
    result.add(new HitTestEntry(this));
  }

  /// Dispatch the given event to the path of the given hit test result
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    assert(result != null);
    for (HitTestEntry entry in result.path)
      entry.target.handleEvent(event, entry);
  }

  void handleEvent(PointerEvent event, HitTestEntry entry) {
    pointerRouter.route(event);
    if (event is PointerDownEvent) {
      gestureArena.close(event.pointer);
    } else if (event is PointerUpEvent) {
      gestureArena.sweep(event.pointer);
    }
  }
}
