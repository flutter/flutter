// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum GestureDisposition {
  accepted,
  rejected
}

/// Represents an object participating in an arena.
///
/// Receives callbacks from the GestureArena to notify the object when it wins
/// or loses a gesture negotiation. Exactly one of [acceptGesture] or
/// [rejectGesture] will be called for each arena key this member was added to,
/// regardless of what caused the arena to be resolved. For example, if a
/// member resolves the arena itself, that member still receives an
/// [acceptGesture] callback.
abstract class GestureArenaMember {
  /// Called when this member wins the arena for the given key.
  void acceptGesture(Object key);

  /// Called when this member loses the arena for the given key.
  void rejectGesture(Object key);
}

/// An interface to information to an arena
///
/// A given [GestureArenaMember] can have multiple entries in multiple arenas
/// with different keys.
class GestureArenaEntry {
  GestureArenaEntry._(this._arena, this._key, this._member);

  final GestureArena _arena;
  final Object _key;
  final GestureArenaMember _member;

  /// Call this member to claim victory (with accepted) or admit defeat (with rejected).
  ///
  /// It's fine to attempt to resolve an arena that is already resolved.
  void resolve(GestureDisposition disposition) {
    _arena._resolve(_key, _member, disposition);
  }
}

/// The first member to accept or the last member to not to reject wins.
class GestureArena {
  final Map<Object, List<GestureArenaMember>> _arenas = new Map<Object, List<GestureArenaMember>>();

  static final GestureArena instance = new GestureArena();

  GestureArenaEntry add(Object key, GestureArenaMember member) {
    List<GestureArenaMember> members = _arenas.putIfAbsent(key, () => new List<GestureArenaMember>());
    members.add(member);
    return new GestureArenaEntry._(this, key, member);
  }

  void _resolve(Object key, GestureArenaMember member, GestureDisposition disposition) {
    List<GestureArenaMember> members = _arenas[key];
    if (members == null)
      return;  // This arena has already resolved.
    assert(members != null);
    assert(members.contains(member));
    if (disposition == GestureDisposition.rejected) {
      members.remove(member);
      member.rejectGesture(key);
      if (members.length == 1) {
        _arenas.remove(key);
        members.first.acceptGesture(key);
      } else if (members.isEmpty) {
        _arenas.remove(key);
      }
    } else {
      assert(disposition == GestureDisposition.accepted);
      _arenas.remove(key);
      for (GestureArenaMember rejectedMember in members) {
        if (rejectedMember != member)
          rejectedMember.rejectGesture(key);
      }
      member.acceptGesture(key);
    }
  }
}
