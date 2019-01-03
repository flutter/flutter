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

/// Signature for when a pointer stops contacting the screen after a long press gesture was detected.
typedef GestureLongPressUpCallback = void Function();

/// Signature from a [LongPressDragGestureRecognizer] when a pointer has remained
/// in contact with the screen at the same location for a long period of time.
typedef GestureLongPressDragDownCallback = void Function(GestureLongPressDragDownDetails details);

/// Signature from a [LongPressDragGestureRecognizer] when a pointer is moving
/// after being herd in contact at the same location for a long period of time.
typedef GestureLongPressDragUpdateCallback = void Function(GestureLongPressDragUpdateDetails details);

/// Signature from a [LongPressDragGestureRecognizer] after a pointer stops
/// contacting the screen. The contact stop position may be different from the
/// contact start position.
typedef GestureLongPressDragUpCallback = void Function(GestureLongPressDragUpDetails details);

/// Details for callbacks that use [GestureLongPressDragDownCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressDown], which uses [GestureLongPressDragDownCallback].
///  * [GestureLongPressDragUpdateDetails], the details for [GestureLongPressDragUpdateCallback]
///  * [GestureLongPressDragUpDetails], the details for [GestureLongPressDragUpCallback].
class GestureLongPressDragDownDetails {
  /// Creates the details for a [GestureLongPressDragDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  GestureLongPressDragDownDetails({ this.sourceTimeStamp, this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Details for callbacks that use [GestureLongPressDragUpdateCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressDrag], which uses [GestureLongPressDragUpdateCallback].
///  * [GestureLongPressDragUpDetails], the details for [GestureLongPressDragUpCallback]
///  * [GestureLongPressDragDownDetails], the details for [GestureLongPressDragDownCallback].
class GestureLongPressDragUpdateDetails {
  /// Creates the details for a [GestureLongPressDragUpdateCallback].
  ///
  /// The [globalPosition] and [offsetFromOrigin] arguments must not be null.
  GestureLongPressDragUpdateDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    this.offsetFromOrigin = Offset.zero,
  }) : assert(globalPosition != null),
       assert(offsetFromOrigin != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// A delta offset from the point where the long press drag initially contacted
  /// the screen.
  final Offset offsetFromOrigin;
}

/// Details for callbacks that use [GestureLongPressDragUpCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressUp], which uses [GestureLongPressDragUpCallback].
///  * [GestureLongPressDragUpdateDetails], the details for [GestureLongPressDragUpdateCallback]
///  * [GestureLongPressDragDownDetails], the details for [GestureLongPressDragDownCallback].
class GestureLongPressDragUpDetails {
  /// Creates the details for a [GestureLongPressDragUpCallback].
  ///
  /// The [globalPosition] argument must not be null.
  GestureLongPressDragUpDetails({ this.sourceTimeStamp, this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPress] callback after creating this object.
  LongPressGestureRecognizer({ Object debugOwner })
    : super(deadline: kLongPressTimeout, debugOwner: debugOwner);

  bool _longPressAccepted = false;

  /// Called when a long press gesture has been recognized.
  GestureLongPressCallback onLongPress;

  /// Called when the pointer stops contacting the screen after the long-press gesture has been recognized.
  GestureLongPressUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    if (onLongPress != null) {
      invokeCallback<void>('onLongPress', onLongPress);
    }
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true && onLongPressUp != null) {
        _longPressAccepted = false;
        invokeCallback<void>('onLongPressUp', onLongPressUp);
      } else {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerDownEvent || event is PointerCancelEvent) {
      // the first touch, initialize the  flag with false
      _longPressAccepted = false;
    }
  }

  @override
  String get debugDescription => 'long press';
}

/// Recognizes long presses that can be subsequently dragged around.
///
/// Similar to a [LongPressGestureRecognizer] where a press has to be held down
/// at the same location for a long period of time. However, after
/// [onLongPressDown] is triggered after the hold threshold, drags will not
/// subsequently cancel the gesture while it's still held. The [onLongPressDrag]
/// callback will be called as the drag moves.
///
/// See also:
///
///  * [LongPressGestureRecognizer], which cannot be dragged during the gesture.
class LongPressDragGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press-drag gesture recognizer.
  ///
  /// Consider assigning the [onLongPressDrag] callback after creating this object.
  LongPressDragGestureRecognizer({ Object debugOwner }) : super(
    deadline: kLongPressTimeout,
    // Since it's a drag gesture, no travel distance will cause it to get
    // rejected after the long-press is accepted.
    postAcceptSlopTolerance: null,
    debugOwner: debugOwner,
  );

  bool _longPressAccepted = false;

  Offset _longPressOrigin;

  Duration _longPressDownTimestamp;

  /// Called when a long press gesture has been recognized.
  GestureLongPressDragDownCallback onLongPressDown;

  /// Called as the primary pointer is dragged after the long press.
  GestureLongPressDragUpdateCallback onLongPressDrag;

  /// Called when the pointer stops contacting the screen after the
  /// long-press gesture has been recognized.
  GestureLongPressDragUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer);
    if (onLongPressDown != null) {
      invokeCallback<void>('onLongPressDown', () => onLongPressDown(
        GestureLongPressDragDownDetails(
          sourceTimeStamp: _longPressDownTimestamp,
          globalPosition: _longPressOrigin,
        ),
      ));
    }
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true && onLongPressUp != null) {
        _longPressAccepted = false;
        invokeCallback<void>('onLongPressUp', () => onLongPressUp(
          GestureLongPressDragUpDetails(
            sourceTimeStamp: event.timeStamp,
            globalPosition: event.position,
          ),
        ));
      } else {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerDownEvent) {
      // The first touch, initialize the flag with false.
      _longPressAccepted = false;
      _longPressDownTimestamp = event.timeStamp;
      _longPressOrigin = event.position;
    } else if (event is PointerMoveEvent && _longPressAccepted && onLongPressDrag != null) {
      invokeCallback<void>('onLongPressDrag', () => onLongPressDrag(
        GestureLongPressDragUpdateDetails(
          sourceTimeStamp: event.timeStamp,
          globalPosition: event.position,
          offsetFromOrigin: event.position - _longPressOrigin,
        ),
      ));
    }
  }

  @override
  void acceptGesture(int pointer) {
    // Winning the arena isn't important here since it may happen from a sweep.
    // Explicitly exceeding the deadline puts the gesture in accepted state.
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _longPressDownTimestamp = null;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  String get debugDescription => 'long press drag';
}
