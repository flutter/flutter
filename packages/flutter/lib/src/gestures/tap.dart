// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Signature for when a pointer that might cause a tap has contacted the screen
/// at a particular location.
typedef void GestureTapDownCallback(Point globalPosition);

/// Signature for when a pointer that will trigger a tap has stopped contacting
/// the screen at a particular location.
typedef void GestureTapUpCallback(Point globalPosition);

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
/// taps. Fo example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
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
  bool _wonArena = false;
  Point _finalPosition;

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition = event.position;
      _checkUp();
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArena && disposition == GestureDisposition.rejected) {
      if (onTapCancel != null)
        onTapCancel();
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
      _wonArena = true;
      _checkUp();
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      assert(state == GestureRecognizerState.defunct);
      if (onTapCancel != null)
        onTapCancel();
      _reset();
    }
  }

  void _checkDown() {
    if (!_sentTapDown) {
      if (onTapDown != null)
        onTapDown(initialPosition);
      _sentTapDown = true;
    }
  }

  void _checkUp() {
    if (_wonArena && _finalPosition != null) {
      resolve(GestureDisposition.accepted);
      if (onTapUp != null)
        onTapUp(_finalPosition);
      if (onTap != null)
        onTap();
      _reset();
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArena = false;
    _finalPosition = null;
  }

  @override
  String toStringShort() => 'tap';
}
