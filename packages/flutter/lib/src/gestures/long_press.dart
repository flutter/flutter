// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Callback signature for [LongPressGestureRecognizer.onLongPress].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
typedef GestureLongPressCallback = void Function();

/// Callback signature for [LongPressGestureRecognizer.onLongPressUp].
///
/// Called when a pointer stops contacting the screen after a long press
/// gesture was detected.
typedef GestureLongPressUpCallback = void Function();

/// Callback signature for [LongPressGestureRecognizer.onLongPressStart].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time. Also reports the long press down
/// position.
typedef GestureLongPressStartCallback = void Function(LongPressStartDetails details);

/// Callback signature for [LongPressGestureRecognizer.onLongPressMoveUpdate].
///
/// Called when a pointer is moving after being held in contact at the same
/// location for a long period of time. Reports the new position and its offset
/// from the original down position.
typedef GestureLongPressMoveUpdateCallback = void Function(LongPressMoveUpdateDetails details);

/// Callback signature for [LongPressGestureRecognizer.onLongPressEnd].
///
/// Called when a pointer stops contacting the screen after a long press
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
  /// The [globalPosition] and [buttons] arguments must not be null.
  const LongPressStartDetails({
    this.globalPosition = Offset.zero,
    this.buttons = kPrimaryButton,
  }) : assert(globalPosition != null),
       assert(buttons != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The buttons pressed when the pointer contacted the screen.
  final int buttons;
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
  /// The [globalPosition], [offsetFromOrigin] and [buttons] arguments must not be null.
  const LongPressMoveUpdateDetails({
    this.globalPosition = Offset.zero,
    this.offsetFromOrigin = Offset.zero,
    this.buttons = kPrimaryButton,
  }) : assert(globalPosition != null),
       assert(offsetFromOrigin != null),
       assert(buttons != null);

  /// The global position of the pointer when it triggered this update.
  final Offset globalPosition;

  /// A delta offset from the point where the long press drag initially contacted
  /// the screen to the point where the pointer is currently located (the
  /// present [globalPosition]) when this callback is triggered.
  final Offset offsetFromOrigin;

  /// The buttons pressed when the pointer contacted the screen (changing buttons
  /// during a long press cancels the gesture.)
  final int buttons;
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
  /// The [globalPosition] and [buttons] arguments must not be null.
  const LongPressEndDetails({
    this.globalPosition = Offset.zero,
    this.buttons = kPrimaryButton,
  }) : assert(globalPosition != null),
       assert(buttons != null);

  /// The global position at which the pointer lifted from the screen.
  final Offset globalPosition;

  /// The buttons pressed when the pointer contacted the screen (changing buttons
  /// during a long press cancels the gesture.)
  final int buttons;
}

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
///
/// The gesture must not deviate in position from its touch down point for 500ms
/// until it's recognized. Once the gesture is accepted, the finger can be
/// moved, triggering [onLongPressMoveUpdate] callbacks, unless the
/// [postAcceptSlopTolerance] constructor argument is specified.
///
/// The gesture must keep consistent buttons throughout its lifespan. It will
/// record the buttons from the first [PointerDownEvent], and subsequent
/// [PointerMoveEvent]s with different buttons will lead to termination of the gesture.
/// 
/// The buttons of [PointerDownEvent] must contain one and only one button.
/// For example, since stylus touching the screen is also counted as a button,
/// a stylus tap while pressing any physical button will not be recognized.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPressStart] callback after creating this
  /// object.
  ///
  /// The [postAcceptSlopTolerance] argument can be used to specify a maximum
  /// allowed distance for the gesture to deviate from the starting point once
  /// the long press has triggered. If the gesture deviates past that point,
  /// subsequent callbacks ([onLongPressMoveUpdate], [onLongPressUp],
  /// [onLongPressEnd]) will stop. Defaults to null, which means the gesture
  /// can be moved without limit once the long press is accepted.
  LongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
  }) : super(
    deadline: kLongPressTimeout,
    postAcceptSlopTolerance: postAcceptSlopTolerance,
    kind: kind,
    debugOwner: debugOwner,
  );

  bool _longPressAccepted = false;
  Offset _longPressOrigin;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is rejected and canceled.
  int _initialButtons;

  /// Called when a long press gesture has been recognized.
  ///
  /// See also:
  ///
  ///  * [onLongPressStart], which has the same timing but has data for the
  ///    press location.
  GestureLongPressCallback onLongPress;

  /// Callback for long press start with gesture location.
  ///
  /// See also:
  ///
  ///  * [onLongPress], which has the same timing but without the location data.
  GestureLongPressStartCallback onLongPressStart;

  /// Callback for moving the gesture after the long press is recognized.
  GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;

  /// Called when the pointer stops contacting the screen after the long-press.
  ///
  /// See also:
  ///
  ///  * [onLongPressEnd], which has the same timing but has data for the up
  ///    gesture location.
  GestureLongPressUpCallback onLongPressUp;

  /// Callback for long press end with gesture location.
  ///
  /// See also:
  ///
  ///  * [onLongPressUp], which has the same timing but without the location data.
  GestureLongPressEndCallback onLongPressEnd;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!isSingleButton(event.buttons)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void didExceedDeadline() {
    // Exceeding the deadline puts the gesture in accepted state.
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
          buttons: _initialButtons,
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
              buttons: _initialButtons,
            ));
          });
        }
      } else {
        // Pointer is lifted before timeout.
        resolve(GestureDisposition.rejected);
      }
      _reset();
    } else if (event is PointerCancelEvent) {
      _reset();
    } else if (event is PointerDownEvent) {
      // The first touch.
      _longPressOrigin = event.position;
      _initialButtons = event.buttons;
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer);
      } else if (_longPressAccepted && onLongPressMoveUpdate != null) {
        invokeCallback<void>('onLongPressMoveUpdate', () {
          onLongPressMoveUpdate(LongPressMoveUpdateDetails(
            globalPosition: event.position,
            offsetFromOrigin: event.position - _longPressOrigin,
            buttons: _initialButtons,
          ));
        });
      }
    }
  }

  void _reset() {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _initialButtons = null;
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_longPressAccepted && disposition == GestureDisposition.rejected) {
      // This can happen if the gesture has been terminated. For example when
      // the buttons have been changed.
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {
    // Winning the arena isn't important here since it may happen from a sweep.
    // Explicitly exceeding the deadline puts the gesture in accepted state.
  }

  @override
  String get debugDescription => 'long press';
}
