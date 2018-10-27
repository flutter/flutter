// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Details for [GestureTapDownCallback], such as position.
///
/// See also:
///
///  * [GestureDetector.onTapDown], which receives this information.
///  * [TapGestureRecognizer], which passes this information to one of its callbacks.
class TapDownDetails {
  /// Creates details for a [GestureTapDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDownDetails({ this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Signature for when a pointer that might cause a tap has contacted the
/// screen.
///
/// The position at which the pointer contacted the screen is available in the
/// `details`.
///
/// See also:
///
///  * [GestureDetector.onTapDown], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
typedef GestureTapDownCallback = void Function(TapDownDetails details);

/// Details for [GestureTapUpCallback], such as position.
///
/// See also:
///
///  * [GestureDetector.onTapUp], which receives this information.
///  * [TapGestureRecognizer], which passes this information to one of its callbacks.
class TapUpDetails {
  /// Creates details for a [GestureTapUpCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapUpDetails({ this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Signature for when a pointer that will trigger a tap has stopped contacting
/// the screen.
///
/// The position at which the pointer stopped contacting the screen is available
/// in the `details`.
///
/// See also:
///
///  * [GestureDetector.onTapUp], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
typedef GestureTapUpCallback = void Function(TapUpDetails details);

/// Signature for when a tap has occurred.
///
/// See also:
///
///  * [GestureDetector.onTap], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
typedef GestureTapCallback = void Function();

/// Signature for when the pointer that previously triggered a
/// [GestureTapDownCallback] will not end up causing a tap.
///
/// See also:
///
///  * [GestureDetector.onTapCancel], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
typedef GestureTapCancelCallback = void Function();

/// Recognizes taps.
///
/// Gesture recognizers take part in gesture arenas to enable potential gestures
/// to be disambiguated from each other. This process is managed by a
/// [GestureArenaManager] (q.v.).
///
/// [TapGestureRecognizer] considers all the pointers involved in the pointer
/// event sequence as contributing to one gesture. For this reason, extra
/// pointer interactions during a tap sequence are not recognized as additional
/// taps. For example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
///
/// The lifecycle of events for a tap gesture is as follows:
///
/// * [onTapDown], which triggers after a short timeout ([deadline]) even if the
///   gesture has not won its arena yet.
/// * [onTapUp] and [onTap], which trigger when the pointer is released if the
///   gesture wins the arena.
/// * [onTapCancel], which triggers instead of [onTapUp] and [onTap] in the case
///   of the gesture not winning the arena.
///
/// See also:
///
///  * [GestureDetector.onTap], which uses this recognizer.
///  * [MultiTapGestureRecognizer]
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a tap gesture recognizer.
  TapGestureRecognizer({ Object debugOwner }) : super(deadline: kPressTimeout, debugOwner: debugOwner);

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  ///
  /// This triggers before the gesture has won the arena, after a short timeout
  /// ([deadline]).
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called next.
  /// Otherwise, [onTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [GestureDetector.onTapDown], which exposes this callback.
  GestureTapDownCallback onTapDown;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  ///
  /// This triggers once the gesture has won the arena, immediately before
  /// [onTap].
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [GestureDetector.onTapUp], which exposes this callback.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  GestureTapUpCallback onTapUp;

  /// A tap has occurred.
  ///
  /// This triggers once the gesture has won the arena, immediately after
  /// [onTapUp].
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [GestureDetector.onTap], which exposes this callback.
  GestureTapCallback onTap;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  ///
  /// This triggers if the gesture loses the arena.
  ///
  /// If the gesture wins the arena, [onTapUp] and [onTap] are called instead.
  ///
  /// See also:
  ///
  ///  * [GestureDetector.onTapCancel], which exposes this callback.
  GestureTapCancelCallback onTapCancel;

  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;
  Offset _finalPosition;

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition = event.position;
      _checkUp();
    } else if (event is PointerCancelEvent) {
      _reset();
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArenaForPrimaryPointer && disposition == GestureDisposition.rejected) {
      // This can happen if the superclass decides the primary pointer
      // exceeded the touch slop, or if the recognizer is disposed.
      if (onTapCancel != null)
        invokeCallback<void>('spontaneous onTapCancel', onTapCancel);
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void didExceedDeadline() {
    _checkDown();
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer == primaryPointer) {
      _checkDown();
      _wonArenaForPrimaryPointer = true;
      _checkUp();
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      // Another gesture won the arena.
      assert(state != GestureRecognizerState.possible);
      if (onTapCancel != null)
        invokeCallback<void>('forced onTapCancel', onTapCancel);
      _reset();
    }
  }

  void _checkDown() {
    if (!_sentTapDown) {
      if (onTapDown != null)
        invokeCallback<void>('onTapDown', () { onTapDown(TapDownDetails(globalPosition: initialPosition)); });
      _sentTapDown = true;
    }
  }

  void _checkUp() {
    if (_wonArenaForPrimaryPointer && _finalPosition != null) {
      resolve(GestureDisposition.accepted);
      if (!_wonArenaForPrimaryPointer || _finalPosition == null) {
        // It is possible that resolve has just recursively called _checkUp
        // (see https://github.com/flutter/flutter/issues/12470).
        // In that case _wonArenaForPrimaryPointer will be false (as _checkUp
        // calls _reset) and we return here to avoid double invocation of the
        // tap callbacks.
        return;
      }
      if (onTapUp != null)
        invokeCallback<void>('onTapUp', () { onTapUp(TapUpDetails(globalPosition: _finalPosition)); });
      if (onTap != null)
        invokeCallback<void>('onTap', onTap);
      _reset();
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _finalPosition = null;
  }

  @override
  String get debugDescription => 'tap';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('wonArenaForPrimaryPointer', value: _wonArenaForPrimaryPointer, ifTrue: 'won arena'));
    properties.add(DiagnosticsProperty<Offset>('finalPosition', _finalPosition, defaultValue: null));
    properties.add(FlagProperty('sentTapDown', value: _sentTapDown, ifTrue: 'sent tap down'));
  }
}
