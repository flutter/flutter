// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Details for [GestureTapDownCallback], such as position.
class TapDownDetails {
  /// Creates details for a [GestureTapDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDownDetails({ this.globalPosition: Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Signature for when a pointer that might cause a tap has contacted the
/// screen.
///
/// The position at which the pointer contacted the screen is available in the
/// `details`.
typedef void GestureTapDownCallback(TapDownDetails details);

/// Details for [GestureTapUpCallback], such as position.
class TapUpDetails {
  /// Creates details for a [GestureTapUpCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapUpDetails({ this.globalPosition: Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Signature for when a pointer that will trigger a tap has stopped contacting
/// the screen.
///
/// The position at which the pointer stopped contacting the screen is available
/// in the `details`.
typedef void GestureTapUpCallback(TapUpDetails details);

/// Signature for when a tap has occurred.
typedef void GestureTapCallback();

/// Signature for when the pointer that previously triggered a
/// [GestureTapDownCallback] will not end up causing a tap.
typedef void GestureTapCancelCallback();

/// Recognizes taps.
///
/// [TapGestureRecognizer] considers all the pointers involved in the pointer
/// event sequence as contributing to one gesture. For this reason, extra
/// pointer interactions during a tap sequence are not recognized as additional
/// taps. For example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
///
/// See also:
///
///  * [MultiTapGestureRecognizer]
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a tap gesture recognizer.
  TapGestureRecognizer() : super(deadline: kPressTimeout);

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  GestureTapDownCallback onTapDown;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  GestureTapUpCallback onTapUp;

  /// A tap has occurred.
  GestureTapCallback onTap;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  GestureTapCancelCallback onTapCancel;

  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;
  Offset _finalPosition;

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition = event.position;
      _checkUp();
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArenaForPrimaryPointer && disposition == GestureDisposition.rejected) {
      // This can happen if the superclass decides the primary pointer
      // exceeded the touch slop, or if the recognizer is disposed.
      if (onTapCancel != null)
        invokeCallback<Null>('spontaneous onTapCancel', onTapCancel);
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
        invokeCallback<Null>('forced onTapCancel', onTapCancel);
      _reset();
    }
  }

  void _checkDown() {
    if (!_sentTapDown) {
      if (onTapDown != null)
        invokeCallback<Null>('onTapDown', () { onTapDown(new TapDownDetails(globalPosition: initialPosition)); });
      _sentTapDown = true;
    }
  }

  void _checkUp() {
    if (_wonArenaForPrimaryPointer && _finalPosition != null) {
      resolve(GestureDisposition.accepted);
      if (onTapUp != null)
        invokeCallback<Null>('onTapUp', () { onTapUp(new TapUpDetails(globalPosition: _finalPosition)); });
      if (onTap != null)
        invokeCallback<Null>('onTap', onTap);
      _reset();
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _finalPosition = null;
  }

  @override
  String toStringShort() => 'tap';
}
