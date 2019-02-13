// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'events.dart';

/// The callback to register with a [PointerSignalArenaManager] to express
/// interest in a pointer signal event.
typedef PointerSignalArenaCallback = void Function(PointerSignalEvent event);

/// An arena for use with pointer signal events.
///
/// Objects interested in a [PointerSignalEvent] should register a callback to
/// be called if they win the arena. Currently, the resolution is always that
/// the first entry in the arena wins.
///
/// Pointer signals are immediate, so unlike a gesture arena it always resolves
/// when the arena closes.
class PointerSignalArenaManager {
  final List<PointerSignalArenaCallback> _members =
      <PointerSignalArenaCallback>[];

  PointerSignalEvent _currentEvent;

  /// Adds a new member to the arena.
  void add(PointerSignalEvent event, PointerSignalArenaCallback member) {
    assert(_currentEvent == null || _currentEvent == event);
    _currentEvent = event;
    _members.add(member);
  }

  /// Resolves the arena, calling the winner if any.
  ///
  /// Called after the framework has finished dispatching the pointer signal
  /// event.
  ///
  void close(PointerSignalEvent event) {
    if (_members.isEmpty) {
      return;
    }
    assert(_currentEvent == event);
    (_members.first)(event);
    _members.clear();
    _currentEvent = null;
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    if (_members.isEmpty) {
      buffer.write('<empty>');
    } else {
      buffer.write(_members.join(', '));
    }
    return buffer.toString();
  }
}
