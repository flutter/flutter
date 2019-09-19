// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Details for [GestureTapDownCallback], such as position
///
/// See also:
///
///  * [GestureDetector.onTapDown], which receives this information.
///  * [TapGestureRecognizer], which passes this information to one of its callbacks.
class TapDownDetails {
  /// Creates details for a [GestureTapDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDownDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
    this.kind,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind kind;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;
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
  /// The [globalPosition] argument must not be null.
  TapUpDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;
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
/// [GestureArenaManager].
///
/// [TapGestureRecognizer] considers all the pointers involved in the pointer
/// event sequence as contributing to one gesture. For this reason, extra
/// pointer interactions during a tap sequence are not recognized as additional
/// taps. For example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
///
/// [TapGestureRecognizer] competes on pointer events of [kPrimaryButton] only
/// when it has at least one non-null `onTap*` callback, and events of
/// [kSecondaryButton] only when it has at least one non-null `onSecondaryTap*`
/// callback. If it has no callbacks, it is a no-op.
///
/// See also:
///
///  * [GestureDetector.onTap], which uses this recognizer.
///  * [MultiTapGestureRecognizer]
class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a tap gesture recognizer.
  TapGestureRecognizer({ Object debugOwner }) : super(deadline: kPressTimeout, debugOwner: debugOwner);

  /// A pointer that might cause a tap of a primary button has contacted the
  /// screen at a particular location.
  ///
  /// This triggers once a short timeout ([deadline]) has elapsed, or once
  /// the gestures has won the arena, whichever comes first.
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called next.
  /// Otherwise, [onTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapDown], which exposes this callback.
  GestureTapDownCallback onTapDown;

  /// A pointer that will trigger a tap of a primary button has stopped
  /// contacting the screen at a particular location.
  ///
  /// This triggers once the gesture has won the arena, immediately before
  /// [onTap].
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapUp], which exposes this callback.
  GestureTapUpCallback onTapUp;

  /// A tap of a primary button has occurred.
  ///
  /// This triggers once the gesture has won the arena, immediately after
  /// [onTapUp].
  ///
  /// If the gesture doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onTapUp], which has the same timing but with details.
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
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
  ///  * [GestureDetector.onTapCancel], which exposes this callback.
  GestureTapCancelCallback onTapCancel;

  /// A pointer that might cause a tap of a secondary button has contacted the
  /// screen at a particular location.
  ///
  /// This triggers once a short timeout ([deadline]) has elapsed, or once
  /// the gestures has won the arena, whichever comes first.
  ///
  /// If the gesture doesn't win the arena, [onSecondaryTapCancel] is called next.
  /// Otherwise, [onSecondaryTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onPrimaryTapDown], a similar callback but for a primary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapDown], which exposes this callback.
  GestureTapDownCallback onSecondaryTapDown;

  /// A pointer that will trigger a tap of a secondary button has stopped
  /// contacting the screen at a particular location.
  ///
  /// This triggers once the gesture has won the arena.
  ///
  /// If the gesture doesn't win the arena, [onSecondaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onPrimaryTapUp], a similar callback but for a primary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapUp], which exposes this callback.
  GestureTapUpCallback onSecondaryTapUp;

  /// The pointer that previously triggered [onSecondaryTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers if the gesture loses the arena.
  ///
  /// If the gesture wins the arena, [onSecondaryTapUp] is called instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onPrimaryTapCancel], a similar callback but for a primary button.
  ///  * [GestureDetector.onTapCancel], which exposes this callback.
  GestureTapCancelCallback onSecondaryTapCancel;

  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;
  OffsetPair _finalPosition;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int _initialButtons;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onTapDown == null &&
            onTap == null &&
            onTapUp == null &&
            onTapCancel == null)
          return false;
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown == null &&
            onSecondaryTapUp == null &&
            onSecondaryTapCancel == null)
          return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    // `_initialButtons` must be assigned here instead of `handlePrimaryPointer`,
    // because `acceptGesture` might be called before `handlePrimaryPointer`,
    // which relies on `_initialButtons` to create `TapDownDetails`.
    _initialButtons = event.buttons;
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition = OffsetPair(global: event.position, local: event.localPosition);
      _checkUp();
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      if (_sentTapDown) {
        _checkCancel('');
      }
      _reset();
    } else if (event.buttons != _initialButtons) {
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(primaryPointer);
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArenaForPrimaryPointer && disposition == GestureDisposition.rejected) {
      // This can happen if the gesture has been canceled. For example, when
      // the pointer has exceeded the touch slop, the buttons have been changed,
      // or if the recognizer is disposed.
      assert(_sentTapDown);
      _checkCancel('spontaneous ');
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void didExceedDeadlineWithEvent(PointerDownEvent event) {
    _checkDown(event.pointer);
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer == primaryPointer) {
      _checkDown(pointer);
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
      if (_sentTapDown)
        _checkCancel('forced ');
      _reset();
    }
  }

  void _checkDown(int pointer) {
    if (_sentTapDown) {
      return;
    }
    final TapDownDetails details = TapDownDetails(
      globalPosition: initialPosition.global,
      localPosition: initialPosition.local,
      kind: getKindForPointer(pointer),
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null)
          invokeCallback<void>('onTapDown', () => onTapDown(details));
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null)
          invokeCallback<void>('onSecondaryTapDown',
            () => onSecondaryTapDown(details));
        break;
      default:
    }
    _sentTapDown = true;
  }

  void _checkUp() {
    if (!_wonArenaForPrimaryPointer || _finalPosition == null) {
      return;
    }
    final TapUpDetails details = TapUpDetails(
      globalPosition: _finalPosition.global,
      localPosition: _finalPosition.local,
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null)
          invokeCallback<void>('onTapUp', () => onTapUp(details));
        if (onTap != null)
          invokeCallback<void>('onTap', onTap);
        break;
      case kSecondaryButton:
        if (onSecondaryTapUp != null)
          invokeCallback<void>('onSecondaryTapUp',
            () => onSecondaryTapUp(details));
        break;
      default:
    }
    _reset();
  }

  void _checkCancel(String note) {
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapCancel != null)
          invokeCallback<void>('${note}onTapCancel', onTapCancel);
        break;
      case kSecondaryButton:
        if (onSecondaryTapCancel != null)
          invokeCallback<void>('${note}onSecondaryTapCancel',
            onSecondaryTapCancel);
        break;
      default:
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _finalPosition = null;
    _initialButtons = null;
  }

  @override
  String get debugDescription => 'tap';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('wonArenaForPrimaryPointer', value: _wonArenaForPrimaryPointer, ifTrue: 'won arena'));
    properties.add(DiagnosticsProperty<Offset>('finalPosition', _finalPosition?.global, defaultValue: null));
    properties.add(DiagnosticsProperty<Offset>('finalLocalPosition', _finalPosition?.local, defaultValue: _finalPosition?.global));
    properties.add(FlagProperty('sentTapDown', value: _sentTapDown, ifTrue: 'sent tap down'));
    // TODO(tongmu): Add property _initialButtons and update related tests
  }
}
