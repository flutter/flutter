// Copyright 2014 The Flutter Authors. All rights reserved.
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
  GestureArenaMember? _winner;
  GestureArenaEntry? _entry;

  @override
  void acceptGesture(int pointer) {
    assert(_pointer == pointer);
    assert(_winner != null || _members.isNotEmpty);
    _close();
    _winner ??= _owner.captain ?? _members[0];
    for (final GestureArenaMember member in _members) {
      if (member != _winner)
        member.rejectGesture(pointer);
    }
    _winner!.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    assert(_pointer == pointer);
    _close();
    for (final GestureArenaMember member in _members)
      member.rejectGesture(pointer);
  }

  void _close() {
    assert(!_resolved);
    _resolved = true;
    final _CombiningGestureArenaMember? combiner = _owner._combiners.remove(_pointer);
    assert(combiner == this);
  }

  GestureArenaEntry _add(int pointer, GestureArenaMember member) {
    assert(!_resolved);
    assert(_pointer == pointer);
    _members.add(member);
    _entry ??= GestureBinding.instance!.gestureArena.add(pointer, this);
    return _CombiningGestureArenaEntry(this, member);
  }

  void _resolve(GestureArenaMember member, GestureDisposition disposition) {
    if (_resolved)
      return;
    if (disposition == GestureDisposition.rejected) {
      _members.remove(member);
      member.rejectGesture(_pointer);
      if (_members.isEmpty)
        _entry!.resolve(disposition);
    } else {
      assert(disposition == GestureDisposition.accepted);
      _winner ??= _owner.captain ?? member;
      _entry!.resolve(disposition);
    }
  }
}

/// A group of [GestureArenaMember] objects that are competing as a unit in the
/// [GestureArenaManager].
///
/// Normally, a recognizer competes directly in the [GestureArenaManager] to
/// recognize a sequence of pointer events as a gesture. With a
/// [GestureArenaTeam], recognizers can compete in the arena in a group with
/// other recognizers. Arena teams may have a captain which wins the arena on
/// behalf of its team.
///
/// When gesture recognizers are in a team together without a captain, then once
/// there are no other competing gestures in the arena, the first gesture to
/// have been added to the team automatically wins, instead of the gestures
/// continuing to compete against each other.
///
/// When gesture recognizers are in a team with a captain, then once one of the
/// team members claims victory or there are no other competing gestures in the
/// arena, the captain wins the arena, and all other team members lose.
///
/// For example, [Slider] uses a team without a captain to support both a
/// [HorizontalDragGestureRecognizer] and a [TapGestureRecognizer], but without
/// the drag recognizer having to wait until the user has dragged outside the
/// slop region of the tap gesture before triggering. Since they compete as a
/// team, as soon as any other recognizers are out of the arena, the drag
/// recognizer wins, even if the user has not actually dragged yet. On the other
/// hand, if the tap can win outright, before the other recognizers are taken
/// out of the arena (e.g. if the slider is in a vertical scrolling list and the
/// user places their finger on the touch surface then lifts it, so that neither
/// the horizontal nor vertical drag recognizers can claim victory) the tap
/// recognizer still actually wins, despite being in the team.
///
/// [AndroidView] uses a team with a captain to decide which gestures are
/// forwarded to the native view. For example if we want to forward taps and
/// vertical scrolls to a native Android view, [TapGestureRecognizer]s and
/// [VerticalDragGestureRecognizer] are added to a team with a captain(the captain is set to be a
/// gesture recognizer that never explicitly claims the gesture).
/// The captain allows [AndroidView] to know when any gestures in the team has been
/// recognized (or all other arena members are out), once the captain wins the
/// gesture is forwarded to the Android view.
///
/// To assign a gesture recognizer to a team, set
/// [OneSequenceGestureRecognizer.team] to an instance of [GestureArenaTeam].
class GestureArenaTeam {
  final Map<int, _CombiningGestureArenaMember> _combiners = <int, _CombiningGestureArenaMember>{};

  /// A member that wins on behalf of the entire team.
  ///
  /// If not null, when any one of the [GestureArenaTeam] members claims victory
  /// the captain accepts the gesture.
  /// If null, the member that claims a victory accepts the gesture.
  GestureArenaMember? captain;

  /// Adds a new member to the arena on behalf of this team.
  ///
  /// Used by [GestureRecognizer] subclasses that wish to compete in the arena
  /// using this team.
  ///
  /// To assign a gesture recognizer to a team, see
  /// [OneSequenceGestureRecognizer.team].
  GestureArenaEntry add(int pointer, GestureArenaMember member) {
    final _CombiningGestureArenaMember combiner = _combiners.putIfAbsent(
        pointer, () => _CombiningGestureArenaMember(this, pointer));
    return combiner._add(pointer, member);
  }
}
