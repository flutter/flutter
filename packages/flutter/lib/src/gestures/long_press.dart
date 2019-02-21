// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Signature for when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
typedef GestureLongPressCallback = void Function();

/// Signature for when a pointer stops contacting the screen after a long press
/// gesture was detected.
typedef GestureLongPressUpCallback = void Function();

/// Signature for when a pointer has remained in contact with the screen at the
/// same location for a long period of time. Also reports the long press down
/// position.
typedef GestureLongPressStartCallback = void Function(LongPressStartDetails details);

/// Signature from a [LongPressGestureRecognizer] when a pointer is moving
/// after being held in contact at the same location for a long period of time.
typedef GestureLongPressMoveUpdateCallback = void Function(LongPressMoveUpdateDetails details);

/// Signature for when a pointer stops contacting the screen after a long press
/// gesture was detected. Also reports the position where the pointer stopped
/// contacting the screen.
typedef GestureLongPressEndCallback = void Function(LongPressEndDetails details);

/// Details for callbacks that use [GestureLongPressStartCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressStart], which uses [GestureLongPressStartCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback]
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback].
class LongPressStartDetails {
  /// Creates the details for a [GestureLongPressStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const LongPressStartDetails({ this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Details for callbacks that use [GestureLongPressMoveUpdateCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressMoveUpdate], which uses [GestureLongPressMoveUpdateCallback].
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback]
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
class LongPressMoveUpdateDetails {
  /// Creates the details for a [GestureLongPressMoveUpdateCallback].
  ///
  /// The [globalPosition] and [offsetFromOrigin] arguments must not be null.
  const LongPressMoveUpdateDetails({
    this.globalPosition = Offset.zero,
    this.offsetFromOrigin = Offset.zero,
  }) : assert(globalPosition != null),
       assert(offsetFromOrigin != null);

  /// The global position of the pointer when it triggered this update.
  final Offset globalPosition;

  /// A delta offset from the point where the long press drag initially contacted
  /// the screen to the point where the pointer is currently located when
  /// this callback is triggered.
  final Offset offsetFromOrigin;
}

/// Details for callbacks that use [GestureLongPressEndCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressEnd], which uses [GestureLongPressEndCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback]
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
class LongPressEndDetails {
  /// Creates the details for a [GestureLongPressEndCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const LongPressEndDetails({ this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// The global position at which the pointer lifted from the screen.
  final Offset globalPosition;
}

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
///
/// The gesture must not deviate in position from its touch down point for 500ms
/// until it's recognized. Once the gesture is accepted, the finger can be
/// moved, triggering [onLongPressMoveUpdate] callbacks.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPressStart] callback after creating this
  /// object.
  ///
  /// The [postAcceptSlopTolerance] argument can be used to specify a maximum
  /// allowed distance for the gesture to deviate from the starting point once
  /// the long press has triggered. If the gesture deviates past that point,
  /// subsequent callbacks will stop.
  LongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    Object debugOwner,
  }) : super(
    deadline: kLongPressTimeout,
    postAcceptSlopTolerance: postAcceptSlopTolerance,
    debugOwner: debugOwner,
  );

  bool _longPressAccepted = false;

  Offset _longPressOrigin;

  /// Called when a long press gesture has been recognized.
  GestureLongPressCallback onLongPress;

   /// Called when a long press gesture has been recognized. Similar
   /// to [onLongPress] but also reports the original touch down position.
  GestureLongPressStartCallback onLongPressStart;

  /// Called as the primary pointer is dragged after the long press.
  GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;

  /// Called when the pointer stops contacting the screen after the long-press
  /// gesture has been recognized. Similar to [onLongPressUp] but also reports
  /// the touch up position.
  GestureLongPressEndCallback onLongPressEnd;

  /// Called when the pointer stops contacting the screen after the long-press
  /// gesture has been recognized.
  GestureLongPressUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer);
    if (onLongPress != null) {
      invokeCallback<void>('onLongPress', onLongPress);
    }
    if (onLongPressStart != null) {
      invokeCallback<void>('onLongPressStart', () {
        onLongPressStart(LongPressStartDetails(
          globalPosition: _longPressOrigin,
        ));
      });
    }
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true) {
        if (onLongPressUp != null) {
          invokeCallback<void>('onLongPressUp', onLongPressUp);
        }
        if (onLongPressEnd != null) {
          invokeCallback<void>('onLongPressEnd', () {
            onLongPressEnd(LongPressEndDetails(
              globalPosition: event.position,
            ));
          });
        }
        _longPressAccepted = false;
      } else {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerDownEvent || event is PointerCancelEvent) {
      // The first touch.
      _longPressAccepted = false;
      _longPressOrigin = event.position;
    } else if (event is PointerMoveEvent && _longPressAccepted && onLongPressMoveUpdate != null) {
      invokeCallback<void>('onLongPressMoveUpdate', () {
        onLongPressMoveUpdate(LongPressMoveUpdateDetails(
          globalPosition: event.position,
          offsetFromOrigin: event.position - _longPressOrigin,
        ));
      });
    }
  }

  @override
  void acceptGesture(int pointer) {
    // Winning the arena isn't important here since it may happen from a sweep.
    // Explicitly exceeding the deadline puts the gesture in accepted state.
  }

  @override
  String get debugDescription => 'long press';
}
