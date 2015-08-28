// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum GestureDisposition {
  accepted,
  rejected
}

abstract class GestureArenaMember {
  /// Called when this member wins the arena.
  void acceptGesture(Object key);

  /// Called when this member loses the arena.
  void rejectGesture(Object key);
}

class GestureArenaEntry {
  GestureArenaEntry._(this._arena, this._key, this._member);

  final GestureArena _arena;
  final Object _key;
  final GestureArenaMember _member;

  /// Call this member to claim victory (with accepted) or admit defeat (with rejected).
  void resolve(GestureDisposition disposition) {
    _arena._resolve(_key, _member, disposition);
  }
}

/// The first member to accept or the last member to not to reject wins.
class GestureArena {
  final Map<Object, List<GestureArenaMember>> _arenas = new Map<Object, List<GestureArenaMember>>();

  GestureArenaEntry add(Object key, GestureArenaMember member) {
    List<GestureArenaMember> members = _arenas.putIfAbsent(key, () => new List<GestureArenaMember>());
    members.add(member);
    return new GestureArenaEntry._(this, key, member);
  }

  void _resolve(Object key, GestureArenaMember member, GestureDisposition disposition) {
    List<GestureArenaMember> members = _arenas[key];
    assert(members != null);
    assert(members.contains(member));
    if (disposition == GestureDisposition.rejected) {
      members.remove(member);
      if (members.length == 1) {
        _arenas.remove(key);
        members.first.acceptGesture(key);
      } else if (members.isEmpty) {
        _arenas.remove(key);
      }
    } else {
      assert(disposition == GestureDisposition.accepted);
      List<GestureArenaMember> members = _arenas[key];
      _arenas.remove(key);
      for (GestureArenaMember rejectedMember in members) {
        if (rejectedMember != member)
          rejectedMember.rejectGesture(key);
      }
      member.acceptGesture(key);
    }
  }
}
