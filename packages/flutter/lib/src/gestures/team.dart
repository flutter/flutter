// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'binding.dart';

class _CombiningGestureArenaEntry implements GestureArenaEntry {
  _CombiningGestureArenaEntry(this._combiner, this._member);

  final _CombiningGestureArenaMember _combiner;
  final GestureArenaMember _member;

  @override
  void resolve(GestureDisposition disposition) {
    _combiner._resolve(_member, disposition);
  }
}

class _CombiningGestureArenaMember extends GestureArenaMember {
  _CombiningGestureArenaMember(this._owner, this._pointer);

  final GestureArenaTeam _owner;
  final List<GestureArenaMember> _members = <GestureArenaMember>[];
  final int _pointer;

  bool _resolved = false;
  GestureArenaMember _winner;
  GestureArenaEntry _entry;

  @override
  void acceptGesture(int pointer) {
    assert(_pointer == pointer);
    assert(_winner != null || _members.isNotEmpty);
    _close();
    _winner ??= _members[0];
    for (GestureArenaMember member in _members) {
      if (member != _winner)
        member.rejectGesture(pointer);
    }
    _winner.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    assert(_pointer == pointer);
    _close();
    for (GestureArenaMember member in _members)
      member.rejectGesture(pointer);
  }

  void _close() {
    assert(!_resolved);
    _resolved = true;
    _CombiningGestureArenaMember combiner = _owner._combiners.remove(_pointer);
    assert(combiner == this);
  }

  GestureArenaEntry _add(int pointer, GestureArenaMember member) {
    assert(!_resolved);
    assert(_pointer == pointer);
    _members.add(member);
    _entry ??= GestureBinding.instance.gestureArena.add(pointer, this);
    return new _CombiningGestureArenaEntry(this, member);
  }

  void _resolve(GestureArenaMember member, GestureDisposition disposition) {
    if (_resolved)
      return;
    if (disposition == GestureDisposition.rejected) {
      _members.remove(member);
      member.rejectGesture(_pointer);
      if (_members.isEmpty)
        _entry.resolve(disposition);
    } else {
      assert(disposition == GestureDisposition.accepted);
      _winner ??= member;
      _entry.resolve(disposition);
    }
  }
}

/// A group of [GestureArenaMember] objects that are competing as a unit in the [GestureArenaManager].
///
/// Normally, a recognizer competes directly in the [GestureArenaManager] to
/// recognize a sequence of pointer events as a gesture. With a
/// [GestureArenaTeam], recognizers can compete in the arena in a group with
/// other recognizers.
///
/// To assign a gesture recognizer to a team, see
/// [OneSequenceGestureRecognizer.team].
class GestureArenaTeam {
  final Map<int, _CombiningGestureArenaMember> _combiners = new Map<int, _CombiningGestureArenaMember>();

  /// Adds a new member to the arena on behalf of this team.
  ///
  /// Used by [GestureRecognizer] subclasses that wish to compete in the arena
  /// using this team.
  ///
  /// To assign a gesture recognizer to a team, see
  /// [OneSequenceGestureRecognizer.team].
  GestureArenaEntry add(int pointer, GestureArenaMember member) {
    _CombiningGestureArenaMember combiner = _combiners.putIfAbsent(
        pointer, () => new _CombiningGestureArenaMember(this, pointer));
    return combiner._add(pointer, member);
  }
}
