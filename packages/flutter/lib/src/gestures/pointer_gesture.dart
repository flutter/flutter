// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'binding.dart';
import 'events.dart';

/// The callback for a winning [PointerSignalArenaMember]
typedef PointerSignalResolvedCallback = void Function(PointerEvent event);

/// A mediator for resolving pointer signal events, which are discrete and
/// thus resolve immediately, in an arena, to ensure that they are not handled
/// by multiple widgets.
///
/// Unlike a [GestureRecognizer], a [PointerSignalArenaMember] always accepts
/// the event. This means that the first [PointerSignalArenaMember] created
/// for any given pointer signal event will always be the winner of the arena.
class PointerSignalArenaMember implements GestureArenaMember {
  /// Creates a new arena member, which immediately enters itself in the
  /// pointerSignalArena and accepts the pointer signal.
  PointerSignalArenaMember(
      this.event, this.acceptCallback, this.rejectCallback) {
    GestureBinding.instance.pointerSignalArena
        .add(event.pointer, this)
        .resolve(GestureDisposition.accepted);
  }

  /// The event for the pointer signal.
  PointerEvent event;

  /// The callback to call if [acceptGesture] is called.
  PointerSignalResolvedCallback acceptCallback;

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
