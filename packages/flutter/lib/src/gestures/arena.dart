// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether the gesture was accepted or rejected.
enum GestureDisposition {
  /// This gesture was accepted as the interpretation of the user's input.
  accepted,

  /// This gesture was rejected as the interpretation  of the user's input.
  rejected,
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

/// An interface to information to an arena.
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

class _GestureArenaState {
  final List<GestureArenaMember> members = new List<GestureArenaMember>();
  bool isOpen = true;
  bool isHeld = false;
  bool hasPendingSweep = false;

  /// If a gesture attempts to win while the arena is still open, it becomes the
  /// "eager winnner". We look for an eager winner when closing the arena to new
  /// participants, and if there is one, we resolve the arena it its favour at
  /// that time.
  GestureArenaMember eagerWinner;

  void add(GestureArenaMember member) {
    assert(isOpen);
    members.add(member);
  }
}

/// The first member to accept or the last member to not to reject wins.
///
/// See [https://flutter.io/gestures/#gesture-disambiguation] for more
/// information about the role this class plays in the gesture system.
class GestureArena {
  final Map<Object, _GestureArenaState> _arenas = new Map<Object, _GestureArenaState>();

  /// Adds a new member (e.g., gesture recognizer) to the arena.
  GestureArenaEntry add(Object arenaKey, GestureArenaMember member) {
    _GestureArenaState state = _arenas.putIfAbsent(arenaKey, () => new _GestureArenaState());
    state.add(member);
    return new GestureArenaEntry._(this, arenaKey, member);
  }

  /// Prevents new members from entering the arena.
  ///
  /// Called after the framework has finished dispatching the pointer down event.
  void close(Object arenaKey) {
    _GestureArenaState state = _arenas[arenaKey];
    if (state == null)
      return;  // This arena either never existed or has been resolved.
    state.isOpen = false;
    _tryToResolveArena(arenaKey, state);
  }

  /// Forces resolution of the arena, giving the win to the first member.
  void sweep(Object arenaKey) {
    _GestureArenaState state = _arenas[arenaKey];
    if (state == null)
      return;  // This arena either never existed or has been resolved.
    assert(!state.isOpen);
    if (state.isHeld) {
      state.hasPendingSweep = true;
      return;  // This arena is being held for a long-lived member
    }
    _arenas.remove(arenaKey);
    if (!state.members.isEmpty) {
      // First member wins
      state.members.first.acceptGesture(arenaKey);
      // Give all the other members the bad news
      for (int i = 1; i < state.members.length; i++)
        state.members[i].rejectGesture(arenaKey);
    }
  }

  /// Prevents the arena from being swept.
  void hold(Object key) {
    _GestureArenaState state = _arenas[key];
    if (state == null)
      return;  // This arena either never existed or has been resolved.
    state.isHeld = true;
  }

  /// Releases a hold, allowing the arena to be swept.
  ///
  /// If a sweep was attempted on a held arena, the sweep will be done
  /// on release.
  void release(Object arenaKey) {
    _GestureArenaState state = _arenas[arenaKey];
    if (state == null)
      return;  // This arena either never existed or has been resolved.
    state.isHeld = false;
    if (state.hasPendingSweep)
      sweep(arenaKey);
  }

  void _tryToResolveArena(Object arenaKey, _GestureArenaState state) {
    assert(_arenas[arenaKey] == state);
    assert(!state.isOpen);
    if (state.members.length == 1) {
      _arenas.remove(arenaKey);
      state.members.first.acceptGesture(arenaKey);
    } else if (state.members.isEmpty) {
      _arenas.remove(arenaKey);
    } else if (state.eagerWinner != null) {
      _resolveInFavorOf(arenaKey, state, state.eagerWinner);
    }
  }

  void _resolve(Object arenaKey, GestureArenaMember member, GestureDisposition disposition) {
    _GestureArenaState state = _arenas[arenaKey];
    if (state == null)
      return;  // This arena has already resolved.
    assert(state.members.contains(member));
    if (disposition == GestureDisposition.rejected) {
      state.members.remove(member);
      member.rejectGesture(arenaKey);
      if (!state.isOpen)
        _tryToResolveArena(arenaKey, state);
    } else {
      assert(disposition == GestureDisposition.accepted);
      if (state.isOpen) {
        state.eagerWinner ??= member;
      } else {
        _resolveInFavorOf(arenaKey, state, member);
      }
    }
  }

  void _resolveInFavorOf(Object arenaKey, _GestureArenaState state, GestureArenaMember member) {
    assert(state == _arenas[arenaKey]);
    assert(state != null);
    assert(state.eagerWinner == null || state.eagerWinner == member);
    assert(!state.isOpen);
    _arenas.remove(arenaKey);
    for (GestureArenaMember rejectedMember in state.members) {
      if (rejectedMember != member)
        rejectedMember.rejectGesture(arenaKey);
    }
    member.acceptGesture(arenaKey);
  }
}
