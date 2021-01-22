// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:vector_math/vector_math_64.dart';

import 'arena.dart';
import 'binding.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';
import 'recognizer.dart';
import 'tap.dart';

/// Signature for callback when the user has tapped the screen at the same
/// location twice in quick succession.
///
/// See also:
///
///  * [GestureDetector.onDoubleTap], which matches this signature.
typedef GestureDoubleTapCallback = void Function();

/// Signature used by [MultiTapGestureRecognizer] for when a pointer that might
/// cause a tap has contacted the screen at a particular location.
typedef GestureMultiTapDownCallback = void Function(int pointer, TapDownDetails details);

/// Signature used by [MultiTapGestureRecognizer] for when a pointer that will
/// trigger a tap has stopped contacting the screen at a particular location.
typedef GestureMultiTapUpCallback = void Function(int pointer, TapUpDetails details);

/// Signature used by [MultiTapGestureRecognizer] for when a tap has occurred.
typedef GestureMultiTapCallback = void Function(int pointer);

/// Signature for when the pointer that previously triggered a
/// [GestureMultiTapDownCallback] will not end up causing a tap.
typedef GestureMultiTapCancelCallback = void Function(int pointer);

/// CountdownZoned tracks whether the specified duration has elapsed since
/// creation, honoring [Zone].
class _CountdownZoned {
  _CountdownZoned({ required Duration duration })
       : assert(duration != null) {
    Timer(duration, _onTimeout);
  }

  bool _timeout = false;

  bool get timeout => _timeout;

  void _onTimeout() {
    _timeout = true;
  }
}

/// TapTracker helps track individual tap sequences as part of a
/// larger gesture.
class _TapTracker {
  _TapTracker({
    required PointerDownEvent event,
    required this.entry,
    required Duration doubleTapMinTime,
  }) : assert(doubleTapMinTime != null),
       assert(event != null),
       assert(event.buttons != null),
       pointer = event.pointer,
       _initialGlobalPosition = event.position,
       initialButtons = event.buttons,
       _doubleTapMinTimeCountdown = _CountdownZoned(duration: doubleTapMinTime);

  final int pointer;
  final GestureArenaEntry entry;
  final Offset _initialGlobalPosition;
  final int initialButtons;
  final _CountdownZoned _doubleTapMinTimeCountdown;

  bool _isTrackingPointer = false;

  void startTrackingPointer(PointerRoute route, Matrix4? transform) {
    if (!_isTrackingPointer) {
      _isTrackingPointer = true;
      GestureBinding.instance!.pointerRouter.addRoute(pointer, route, transform);
    }
  }

  void stopTrackingPointer(PointerRoute route) {
    if (_isTrackingPointer) {
      _isTrackingPointer = false;
      GestureBinding.instance!.pointerRouter.removeRoute(pointer, route);
    }
  }

  bool isWithinGlobalTolerance(PointerEvent event, double tolerance) {
    final Offset offset = event.position - _initialGlobalPosition;
    return offset.distance <= tolerance;
  }

  bool hasElapsedMinTime() {
    return _doubleTapMinTimeCountdown.timeout;
  }

  bool hasSameButton(PointerDownEvent event) {
    return event.buttons == initialButtons;
  }
}

/// Recognizes when the user has tapped the screen at the same location twice in
/// quick succession.
///
/// [DoubleTapGestureRecognizer] competes on pointer events of [kPrimaryButton]
/// only when it has a non-null callback. If it has no callbacks, it is a no-op.
///
class DoubleTapGestureRecognizer extends GestureRecognizer {
  /// Create a gesture recognizer for double taps.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.kind}
  DoubleTapGestureRecognizer({
    Object? debugOwner,
    PointerDeviceKind? kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  // Implementation notes:
  //
  // The double tap recognizer can be in one of four states. There's no
  // explicit enum for the states, because they are already captured by
  // the state of existing fields. Specifically:
  //
  // 1. Waiting on first tap: In this state, the _trackers list is empty, and
  //    _firstTap is null.
  // 2. First tap in progress: In this state, the _trackers list contains all
  //    the states for taps that have begun but not completed. This list can
  //    have more than one entry if two pointers begin to tap.
  // 3. Waiting on second tap: In this state, one of the in-progress taps has
  //    completed successfully. The _trackers list is again empty, and
  //    _firstTap records the successful tap.
  // 4. Second tap in progress: Much like the "first tap in progress" state, but
  //    _firstTap is non-null. If a tap completes successfully while in this
  //    state, the callback is called and the state is reset.
  //
  // There are various other scenarios that cause the state to reset:
  //
  // - All in-progress taps are rejected (by time, distance, pointercancel, etc)
  // - The long timer between taps expires
  // - The gesture arena decides we have been rejected wholesale

  /// A pointer has contacted the screen with a primary button at the same
  /// location twice in quick succession, which might be the start of a double
  /// tap.
  ///
  /// This triggers immediately after the down event of the second tap.
  ///
  /// If this recognizer doesn't win the arena, [onDoubleTapCancel] is called
  /// next. Otherwise, [onDoubleTap] is called next.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onDoubleTapDown], which exposes this callback.
  GestureTapDownCallback? onDoubleTapDown;

  /// Called when the user has tapped the screen with a primary button at the
  /// same location twice in quick succession.
  ///
  /// This triggers when the pointer stops contacting the device after the
  /// second tap.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [GestureDetector.onDoubleTap], which exposes this callback.
  GestureDoubleTapCallback? onDoubleTap;

  /// A pointer that previously triggered [onDoubleTapDown] will not end up
  /// causing a double tap.
  ///
  /// This triggers once the gesture loses the arena if [onDoubleTapDown] has
  /// previously been triggered.
  ///
  /// If this recognizer wins the arena, [onDoubleTap] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [GestureDetector.onDoubleTapCancel], which exposes this callback.
  GestureTapCancelCallback? onDoubleTapCancel;

  Timer? _doubleTapTimer;
  _TapTracker? _firstTap;
  final Map<int, _TapTracker> _trackers = <int, _TapTracker>{};

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (_firstTap == null) {
      switch (event.buttons) {
        case kPrimaryButton:
          if (onDoubleTapDown == null &&
              onDoubleTap == null &&
              onDoubleTapCancel == null)
            return false;
          break;
        default:
          return false;
      }
    }
    return super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_firstTap != null) {
      if (!_firstTap!.isWithinGlobalTolerance(event, kDoubleTapSlop)) {
        // Ignore out-of-bounds second taps.
        return;
      } else if (!_firstTap!.hasElapsedMinTime() || !_firstTap!.hasSameButton(event)) {
        // Restart when the second tap is too close to the first (touch screens
        // often detect touches intermittently), or when buttons mismatch.
        _reset();
        return _trackTap(event);
      } else if (onDoubleTapDown != null) {
        final TapDownDetails details = TapDownDetails(
          globalPosition: event.position,
          localPosition: event.localPosition,
          kind: getKindForPointer(event.pointer),
        );
        invokeCallback<void>('onDoubleTapDown', () => onDoubleTapDown!(details));
      }
    }
    _trackTap(event);
  }

  void _trackTap(PointerDownEvent event) {
    _stopDoubleTapTimer();
    final _TapTracker tracker = _TapTracker(
      event: event,
      entry: GestureBinding.instance!.gestureArena.add(event.pointer, this),
      doubleTapMinTime: kDoubleTapMinTime,
    );
    _trackers[event.pointer] = tracker;
    tracker.startTrackingPointer(_handleEvent, event.transform);
  }

  void _handleEvent(PointerEvent event) {
    final _TapTracker tracker = _trackers[event.pointer]!;
    if (event is PointerUpEvent) {
      if (_firstTap == null)
        _registerFirstTap(tracker);
      else
        _registerSecondTap(tracker);
    } else if (event is PointerMoveEvent) {
      if (!tracker.isWithinGlobalTolerance(event, kDoubleTapTouchSlop))
        _reject(tracker);
    } else if (event is PointerCancelEvent) {
      _reject(tracker);
    }
  }

  @override
  void acceptGesture(int pointer) { }

  @override
  void rejectGesture(int pointer) {
    _TapTracker? tracker = _trackers[pointer];
    // If tracker isn't in the list, check if this is the first tap tracker
    if (tracker == null &&
        _firstTap != null &&
        _firstTap!.pointer == pointer)
      tracker = _firstTap;
    // If tracker is still null, we rejected ourselves already
    if (tracker != null)
      _reject(tracker);
  }

  void _reject(_TapTracker tracker) {
    _trackers.remove(tracker.pointer);
    tracker.entry.resolve(GestureDisposition.rejected);
    _freezeTracker(tracker);
    if (_firstTap != null) {
      if (tracker == _firstTap) {
        _reset();
      } else {
        _checkCancel();
        if (_trackers.isEmpty)
          _reset();
      }
    }
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }

  void _reset() {
    _stopDoubleTapTimer();
    if (_firstTap != null) {
      if (_trackers.isNotEmpty)
        _checkCancel();
      // Note, order is important below in order for the resolve -> reject logic
      // to work properly.
      final _TapTracker tracker = _firstTap!;
      _firstTap = null;
      _reject(tracker);
      GestureBinding.instance!.gestureArena.release(tracker.pointer);
    }
    _clearTrackers();
  }

  void _registerFirstTap(_TapTracker tracker) {
    _startDoubleTapTimer();
    GestureBinding.instance!.gestureArena.hold(tracker.pointer);
    // Note, order is important below in order for the clear -> reject logic to
    // work properly.
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    _clearTrackers();
    _firstTap = tracker;
  }

  void _registerSecondTap(_TapTracker tracker) {
    _firstTap!.entry.resolve(GestureDisposition.accepted);
    tracker.entry.resolve(GestureDisposition.accepted);
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    _checkUp(tracker.initialButtons);
    _reset();
  }

  void _clearTrackers() {
    _trackers.values.toList().forEach(_reject);
    assert(_trackers.isEmpty);
  }

  void _freezeTracker(_TapTracker tracker) {
    tracker.stopTrackingPointer(_handleEvent);
  }

  void _startDoubleTapTimer() {
    _doubleTapTimer ??= Timer(kDoubleTapTimeout, _reset);
  }

  void _stopDoubleTapTimer() {
    if (_doubleTapTimer != null) {
      _doubleTapTimer!.cancel();
      _doubleTapTimer = null;
    }
  }

  void _checkUp(int buttons) {
    assert(buttons == kPrimaryButton);
    if (onDoubleTap != null)
      invokeCallback<void>('onDoubleTap', onDoubleTap!);
  }

  void _checkCancel() {
    if (onDoubleTapCancel != null)
      invokeCallback<void>('onDoubleTapCancel', onDoubleTapCancel!);
  }

  @override
  String get debugDescription => 'double tap';
}

/// TapGesture represents a full gesture resulting from a single tap sequence,
/// as part of a [MultiTapGestureRecognizer]. Tap gestures are passive, meaning
/// that they will not preempt any other arena member in play.
class _TapGesture extends _TapTracker {

  _TapGesture({
    required this.gestureRecognizer,
    required PointerEvent event,
    required Duration longTapDelay,
  }) : _lastPosition = OffsetPair.fromEventPosition(event),
       super(
    event: event as PointerDownEvent,
    entry: GestureBinding.instance!.gestureArena.add(event.pointer, gestureRecognizer),
    doubleTapMinTime: kDoubleTapMinTime,
  ) {
    startTrackingPointer(handleEvent, event.transform);
    if (longTapDelay > Duration.zero) {
      _timer = Timer(longTapDelay, () {
        _timer = null;
        gestureRecognizer._dispatchLongTap(event.pointer, _lastPosition);
      });
    }
  }

  final MultiTapGestureRecognizer gestureRecognizer;

  bool _wonArena = false;
  Timer? _timer;

  OffsetPair _lastPosition;
  OffsetPair? _finalPosition;

  void handleEvent(PointerEvent event) {
    assert(event.pointer == pointer);
    if (event is PointerMoveEvent) {
      if (!isWithinGlobalTolerance(event, computeHitSlop(event.kind)))
        cancel();
      else
        _lastPosition = OffsetPair.fromEventPosition(event);
    } else if (event is PointerCancelEvent) {
      cancel();
    } else if (event is PointerUpEvent) {
      stopTrackingPointer(handleEvent);
      _finalPosition = OffsetPair.fromEventPosition(event);
      _check();
    }
  }

  @override
  void stopTrackingPointer(PointerRoute route) {
    _timer?.cancel();
    _timer = null;
    super.stopTrackingPointer(route);
  }

  void accept() {
    _wonArena = true;
    _check();
  }

  void reject() {
    stopTrackingPointer(handleEvent);
    gestureRecognizer._dispatchCancel(pointer);
  }

  void cancel() {
    // If we won the arena already, then entry is resolved, so resolving
    // again is a no-op. But we still need to clean up our own state.
    if (_wonArena)
      reject();
    else
      entry.resolve(GestureDisposition.rejected); // eventually calls reject()
  }

  void _check() {
    if (_wonArena && _finalPosition != null)
      gestureRecognizer._dispatchTap(pointer, _finalPosition!);
  }
}

/// Recognizes taps on a per-pointer basis.
///
/// [MultiTapGestureRecognizer] considers each sequence of pointer events that
/// could constitute a tap independently of other pointers: For example, down-1,
/// down-2, up-1, up-2 produces two taps, on up-1 and up-2.
///
/// See also:
///
///  * [TapGestureRecognizer]
class MultiTapGestureRecognizer extends GestureRecognizer {
  /// Creates a multi-tap gesture recognizer.
  ///
  /// The [longTapDelay] defaults to [Duration.zero], which means
  /// [onLongTapDown] is called immediately after [onTapDown].
  MultiTapGestureRecognizer({
    this.longTapDelay = Duration.zero,
    Object? debugOwner,
    PointerDeviceKind? kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  GestureMultiTapDownCallback? onTapDown;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  GestureMultiTapUpCallback? onTapUp;

  /// A tap has occurred.
  GestureMultiTapCallback? onTap;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  GestureMultiTapCancelCallback? onTapCancel;

  /// The amount of time between [onTapDown] and [onLongTapDown].
  Duration longTapDelay;

  /// A pointer that might cause a tap is still in contact with the screen at a
  /// particular location after [longTapDelay].
  GestureMultiTapDownCallback? onLongTapDown;

  final Map<int, _TapGesture> _gestureMap = <int, _TapGesture>{};

  @override
  void addAllowedPointer(PointerEvent event) {
    assert(!_gestureMap.containsKey(event.pointer));
    _gestureMap[event.pointer] = _TapGesture(
      gestureRecognizer: this,
      event: event,
      longTapDelay: longTapDelay,
    );
    if (onTapDown != null)
      invokeCallback<void>('onTapDown', () {
        onTapDown!(event.pointer, TapDownDetails(
          globalPosition: event.position,
          localPosition: event.localPosition,
          kind: event.kind,
        ));
      });
  }

  @override
  void acceptGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]!.accept();
  }

  @override
  void rejectGesture(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap[pointer]!.reject();
    assert(!_gestureMap.containsKey(pointer));
  }

  void _dispatchCancel(int pointer) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap.remove(pointer);
    if (onTapCancel != null)
      invokeCallback<void>('onTapCancel', () => onTapCancel!(pointer));
  }

  void _dispatchTap(int pointer, OffsetPair position) {
    assert(_gestureMap.containsKey(pointer));
    _gestureMap.remove(pointer);
    if (onTapUp != null)
      invokeCallback<void>('onTapUp', () {
        onTapUp!(pointer, TapUpDetails(
          kind: getKindForPointer(pointer),
          localPosition: position.local,
          globalPosition: position.global,
        ));
      });
    if (onTap != null)
      invokeCallback<void>('onTap', () => onTap!(pointer));
  }

  void _dispatchLongTap(int pointer, OffsetPair lastPosition) {
    assert(_gestureMap.containsKey(pointer));
    if (onLongTapDown != null)
      invokeCallback<void>('onLongTapDown', () {
        onLongTapDown!(
          pointer,
          TapDownDetails(
            globalPosition: lastPosition.global,
            localPosition: lastPosition.local,
            kind: getKindForPointer(pointer),
          ),
        );
      });
  }

  @override
  void dispose() {
    final List<_TapGesture> localGestures = List<_TapGesture>.from(_gestureMap.values);
    for (final _TapGesture gesture in localGestures)
      gesture.cancel();
    // Rejection of each gesture should cause it to be removed from our map
    assert(_gestureMap.isEmpty);
    super.dispose();
  }

  @override
  String get debugDescription => 'multitap';
}
