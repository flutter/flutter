// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'binding.dart';
import 'events.dart';

/// The callback for a winning [PointerGestureArenaMember]
typedef PointerGestureResolvedCallback = void Function(PointerEvent event);

/// A mediator for resolving pointer gesture events, which are discrete and
/// thus resolve immediately, in an arena, to ensure that they are not handled
/// by multiple widgets.
///
/// Unlike a [GestureRecognizer], a [PointerGestureArenaMember] always accepts
/// the event. This means that the first [PointerGestureArenaMember] created
/// for any given pointer gesture event will always be the winner of the arena.
class PointerGestureArenaMember implements GestureArenaMember {
  /// Creates a new arena member, which immediately enters itself in the
  /// pointerGestureArena and accepts the pointer gesture.
  PointerGestureArenaMember(
      this.event, this.acceptCallback, this.rejectCallback) {
    GestureBinding.instance.pointerGestureArena
        .add(event.pointer, this)
        .resolve(GestureDisposition.accepted);
  }

  /// The event for the pointer gesture.
  PointerEvent event;

  /// The callback to call if [acceptGesture] is called.
  PointerGestureResolvedCallback acceptCallback;

  /// The callback to call if [rejectGesture] is called.
  VoidCallback rejectCallback;

  @override
  void acceptGesture(int pointer) {
    acceptCallback(event);
  }

  @override
  void rejectGesture(int pointer) {
    rejectCallback();
  }
}
