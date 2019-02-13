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

/// Signature from a [LongPressDragGestureRecognizer] when a pointer has remained
/// in contact with the screen at the same location for a long period of time.
typedef GestureLongPressDragStartCallback = void Function(GestureLongPressDragStartDetails details);

/// Signature from a [LongPressDragGestureRecognizer] when a pointer is moving
/// after being held in contact at the same location for a long period of time.
typedef GestureLongPressDragUpdateCallback = void Function(GestureLongPressDragUpdateDetails details);

/// Signature from a [LongPressDragGestureRecognizer] after a pointer stops
/// contacting the screen.
///
/// The contact stop position may be different from the contact start position.
typedef GestureLongPressDragUpCallback = void Function(GestureLongPressDragUpDetails details);

/// Details for callbacks that use [GestureLongPressDragStartCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressStart], which uses [GestureLongPressDragStartCallback].
///  * [GestureLongPressDragUpdateDetails], the details for [GestureLongPressDragUpdateCallback]
///  * [GestureLongPressDragUpDetails], the details for [GestureLongPressDragUpCallback].
class GestureLongPressDragStartDetails {
  /// Creates the details for a [GestureLongPressDragStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const GestureLongPressDragStartDetails({ this.sourceTimeStamp, this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered by proxied events such as accessibility.
  ///
  /// See also:
  ///
  ///  * [PointerEvent.synthesized] for details on synthesized pointer events.
  final Duration sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;
}

/// Details for callbacks that use [GestureLongPressDragUpdateCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressDragUpdate], which uses [GestureLongPressDragUpdateCallback].
///  * [GestureLongPressDragUpDetails], the details for [GestureLongPressDragUpCallback]
///  * [GestureLongPressDragStartDetails], the details for [GestureLongPressDragStartCallback].
class GestureLongPressDragUpdateDetails {
  /// Creates the details for a [GestureLongPressDragUpdateCallback].
  ///
  /// The [globalPosition] and [offsetFromOrigin] arguments must not be null.
  const GestureLongPressDragUpdateDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    this.offsetFromOrigin = Offset.zero,
  }) : assert(globalPosition != null),
       assert(offsetFromOrigin != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered by proxied events such as accessibility.
  ///
  /// See also:
  ///
  ///  * [PointerEvent.synthesized] for details on synthesized pointer events.
  final Duration sourceTimeStamp;

  /// The global position of the pointer when it triggered this update.
  final Offset globalPosition;

  /// A delta offset from the point where the long press drag initially contacted
  /// the screen to the point where the pointer is currently located when
  /// this callback is triggered.
  final Offset offsetFromOrigin;
}

/// Details for callbacks that use [GestureLongPressDragUpCallback].
///
/// See also:
///
///  * [LongPressDragGestureRecognizer.onLongPressUp], which uses [GestureLongPressDragUpCallback].
///  * [GestureLongPressDragUpdateDetails], the details for [GestureLongPressDragUpdateCallback]
///  * [GestureLongPressDragStartDetails], the details for [GestureLongPressDragStartCallback].
class GestureLongPressDragUpDetails {
  /// Creates the details for a [GestureLongPressDragUpCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const GestureLongPressDragUpDetails({ this.sourceTimeStamp, this.globalPosition = Offset.zero })
    : assert(globalPosition != null);

  /// Recorded timestamp of the source pointer event that triggered the press
  /// event.
  ///
  /// Could be null if triggered by proxied events such as accessibility.
  ///
  /// See also:
  ///
  ///  * [PointerEvent.synthesized] for details on synthesized pointer events.
  final Duration sourceTimeStamp;

  /// The global position at which the pointer lifted from the screen.
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

  /// Called when the pointer stops contacting the screen after the long-press
  /// gesture has been recognized.
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
/// at the same location for a long period of time. However drag events that
/// occur after the long-press hold threshold has past will not cancel the
/// gesture. The [onLongPressDragUpdate] callback will be called until an up
/// event occurs.
///
/// See also:
///
///  * [LongPressGestureRecognizer], which cancels its gesture if a drag event
///    occurs at any point during the long-press.
class LongPressDragGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press-drag gesture recognizer.
  ///
  /// Consider assigning the [onLongPressStart], [onLongPressDragUpdate] and
  /// the [onLongPressUp] callbacks after creating this object.
  LongPressDragGestureRecognizer({ Object debugOwner }) : super(
    deadline: kLongPressTimeout,
    // Since it's a drag gesture, no travel distance will cause it to get
    // rejected after the long-press is accepted.
    postAcceptSlopTolerance: null,
    debugOwner: debugOwner,
  );

  bool _longPressAccepted = false;

  Offset _longPressOrigin;

  Duration _longPressStartTimestamp;

  /// Called when a long press gesture has been recognized.
  GestureLongPressDragStartCallback onLongPressStart;

  /// Called as the primary pointer is dragged after the long press.
  GestureLongPressDragUpdateCallback onLongPressDragUpdate;

  /// Called when the pointer stops contacting the screen after the
  /// long-press gesture has been recognized.
  GestureLongPressDragUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer);
    if (onLongPressStart != null) {
      invokeCallback<void>('onLongPressStart', () {
        onLongPressStart(GestureLongPressDragStartDetails(
          sourceTimeStamp: _longPressStartTimestamp,
          globalPosition: _longPressOrigin,
        ));
      });
    }
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true && onLongPressUp != null) {
        _longPressAccepted = false;
        invokeCallback<void>('onLongPressUp', () {
          onLongPressUp(GestureLongPressDragUpDetails(
            sourceTimeStamp: event.timeStamp,
            globalPosition: event.position,
          ));
        });
      } else {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerDownEvent) {
      // The first touch.
      _longPressAccepted = false;
      _longPressStartTimestamp = event.timeStamp;
      _longPressOrigin = event.position;
    } else if (event is PointerMoveEvent && _longPressAccepted && onLongPressDragUpdate != null) {
      invokeCallback<void>('onLongPressDrag', () {
        onLongPressDragUpdate(GestureLongPressDragUpdateDetails(
          sourceTimeStamp: event.timeStamp,
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
  void didStopTrackingLastPointer(int pointer) {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _longPressStartTimestamp = null;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  String get debugDescription => 'long press drag';
}
