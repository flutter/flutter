// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'binding.dart';
import 'events.dart';

/// The callback for a winning [PointerSignalArenaMember]
typedef PointerSignalResolvedCallback = void Function(PointerEvent event);

/// Represents an object participating in a pointer signal arena.
///
/// An object interested in handling a pointer signal event should create
/// an instance of this class to enter itself in the arena for that event. The
/// provided callback will be called if it successfully claims the event.
class PointerSignalArenaMember {
  /// Creates a new arena member, which immediately enters itself in the
  /// pointerSignalArena.
  PointerSignalArenaMember(this.event, this.acceptCallback) {
    GestureBinding.instance.pointerSignalArena.add(event, this);
  }

  /// The event for the pointer signal.
  PointerEvent event;

  /// The callback to call if [acceptSignal] is called.
  PointerSignalResolvedCallback acceptCallback;

  /// Called when this member wins the arena for the given pointer event.
  void acceptSignal() {
    acceptCallback(event);
  }
}

class _PointerSignalArena {
  final List<PointerSignalArenaMember> members = <PointerSignalArenaMember>[];
  bool isOpen = true;

  void add(PointerSignalArenaMember member) {
    assert(isOpen);
    members.add(member);
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    if (members.isEmpty) {
      buffer.write('<empty>');
    } else {
      buffer.write(members.join(', '));
    }
    if (isOpen) {
      buffer.write(' [open]');
    }
    return buffer.toString();
  }
}

/// An arena for use with pointer signal events.
///
/// Pointer signals are immediate, so unlike a gesture arena it always resolves
/// when the arena closes.
class PointerSignalArenaManager {
  final Map<PointerSignalEvent, _PointerSignalArena> _arenas =
      <PointerSignalEvent, _PointerSignalArena>{};

  /// Adds a new member to the arena.
  void add(PointerSignalEvent event, PointerSignalArenaMember member) {
    final _PointerSignalArena state = _arenas.putIfAbsent(event, () {
      return _PointerSignalArena();
    });
    state.add(member);
  }

  /// Prevents new members from entering the arena, and resolves it.
  ///
  /// Called after the framework has finished dispatching the pointer signal
  /// event.
  ///
  /// Currently, the resolution is always that the first entry in the arena
  /// wins.
  void close(PointerSignalEvent event) {
    final _PointerSignalArena state = _arenas[event];
    if (state == null)
      return; // This arena either never existed or has been resolved.
    state.isOpen = false;
    state.members.first.acceptSignal();
    _arenas.remove(event);
  }
}
