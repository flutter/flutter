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

/// The base class of gesture recognizers that recognize taps.
///
/// Gesture recognizers take part in gesture arenas to enable potential gestures
/// to be disambiguated from each other. This process is managed by a
/// [GestureArenaManager].
///
/// A tap is defined as a sequence of events that starts with a down, followed
/// by optional moves, then ends with an up. All move events must contain the
/// same `buttons` with the down event, and must not be too far from the initial
/// position. The gesture is rejected on any violation, a cancel event, or
/// if any other gesture wins the arena. It is accepted only when it is the last
/// member of the arena.
///
/// [BaseTapGestureRecognizer] considers all the pointers involved in the pointer
/// event sequence as contributing to one gesture. For this reason, extra
/// pointer interactions during a tap sequence are not recognized as additional
/// taps. For example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
///
/// [BaseTapGestureRecognizer] can not be directly used, since it does not
/// define which buttons to accept, or what to do when a tap happens. If you
/// want to build a custom tap recognizer, extend this class by overriding
/// [isPointerAllowed] and the handler methods.
///
/// See also:
///
///  * [TapGestureRecognizer], a ready-to-use tap recognizer that recognizes
///    taps of the primary button and taps of the secondary button.
///  * [ModalBarrier], a widget that uses a custom tap recognizer that accepts
///    any buttons.
abstract class BaseTapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a tap gesture recognizer.
  BaseTapGestureRecognizer({ Object debugOwner, Duration deadline = kPressTimeout })
    : super(deadline: deadline, debugOwner: debugOwner);

  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;

  PointerDownEvent _down;
  PointerUpEvent _up;

  /// A pointer that might cause a tap has contacted the screen.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// The parameter `down` is the down event of the primary pointer that started
  /// the tap sequence.
  ///
  /// If the gesture doesn't win the arena, [handleTapUp] is called next.
  /// Otherwise, [handleTapCancel] is called next.
  @protected
  void handleTapDown({ PointerDownEvent down });

  /// A pointer that will trigger a tap has stopped contacting the screen.
  ///
  /// This triggers on the up event, if the gesture wins the arena with it
  /// or has previously won.
  ///
  /// The parameter `down` is the down event of the primary pointer that started
  /// the tap sequence, and `up` is the up event that ended the tap sequence.
  ///
  /// If the gesture doesn't win the arena, [handleTapCancel] is called
  /// instead.
  @protected
  void handleTapUp({ PointerDownEvent down, PointerUpEvent up });

  /// The pointer that previously triggered [handleTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers once the gesture loses the arena, if [handleTapDown] has
  /// been previously triggered.
  ///
  /// The parameter `down` is the down event of the primary pointer that started
  /// the tap sequence; `cancel` is the cancel event, which might be null;
  /// `reason` is a short description of the cause if `cancel` is null, which
  /// can be `"forced"` if other gestures won the arena, or `"spontaneous"`
  /// otherwise.
  ///
  /// If the gesture wins the arena, [onSecondaryTapUp] is called instead.
  @protected
  void handleTapCancel({ PointerDownEvent down, PointerCancelEvent cancel, String reason });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (state == GestureRecognizerState.ready) {
      // `_down` must be assigned in this method instead of `handlePrimaryPointer`,
      // because `acceptGesture` might be called before `handlePrimaryPointer`,
      // which relies on `_down` to call `_delegate.onDown`.
      _down = event;
    }
    super.addAllowedPointer(event);
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _up = event;
      _checkUp();
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      if (_sentTapDown) {
        _checkCancel(event, '');
      }
      _reset();
    } else if (event.buttons != _down.buttons) {
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
      _checkCancel(null, 'spontaneous');
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void didExceedDeadlineWithEvent(PointerDownEvent event) {
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
      if (_sentTapDown)
        _checkCancel(null, 'forced');
      _reset();
    }
  }

  void _checkDown() {
    if (_sentTapDown) {
      return;
    }
    handleTapDown(down: _down);
    _sentTapDown = true;
  }

  void _checkUp() {
    if (!_wonArenaForPrimaryPointer || _up == null) {
      return;
    }
    handleTapUp(down: _down, up: _up);
    _reset();
  }

  void _checkCancel(PointerCancelEvent event, String note) {
    handleTapCancel(down: _down, cancel: event, reason: note);
  }

  void _reset() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _up = null;
    _down = null;
  }

  @override
  String get debugDescription => 'base tap';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('wonArenaForPrimaryPointer', value: _wonArenaForPrimaryPointer, ifTrue: 'won arena'));
    properties.add(DiagnosticsProperty<Offset>('finalPosition', _up?.position, defaultValue: null));
    properties.add(DiagnosticsProperty<Offset>('finalLocalPosition', _up?.localPosition, defaultValue: _up?.position));
    properties.add(DiagnosticsProperty<int>('button', _down?.buttons, defaultValue: null));
    properties.add(FlagProperty('sentTapDown', value: _sentTapDown, ifTrue: 'sent tap down'));
  }
}

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
class TapGestureRecognizer extends BaseTapGestureRecognizer {
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
  /// This triggers once the pointer has stopped contacting the screen, if the
  /// gesture has won the arena, immediately before [onTap].
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
  /// This triggers once the pointer has stopped contacting the screen, if the
  /// gesture has won the arena, immediately after [onTapUp].
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
  /// This triggers once the gesture loses the arena, if [onTapDown] has
  /// previously been triggered.
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

  @protected
  @override
  void handleTapDown({PointerDownEvent down}) {
    final TapDownDetails details = TapDownDetails(
      globalPosition: down.position,
      localPosition: down.localPosition,
      kind: getKindForPointer(down.pointer),
    );
    switch (down.buttons) {
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
  }

  @protected
  @override
  void handleTapUp({PointerDownEvent down, PointerUpEvent up}) {
    final TapUpDetails details = TapUpDetails(
      globalPosition: up.position,
      localPosition: up.localPosition,
    );
    switch (down.buttons) {
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
  }

  @protected
  @override
  void handleTapCancel({PointerDownEvent down, PointerCancelEvent cancel, String reason}) {
    final String note = reason == '' ? reason : ' $reason';
    switch (down.buttons) {
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

  @override
  String get debugDescription => 'tap';
}
