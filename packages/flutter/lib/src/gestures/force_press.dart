
import 'dart:ui' show Offset;

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

enum _ForceState {
  ready,
  possible,
  accepted,
  started,
  peaked,
}


/// Details object for callbacks that use [GestureForcePressStartCallback],
/// [GestureForcePressPeakCallback] or [GestureForcePressEndCallback].
///
/// See also:
///
///  * [ForcePressGestureRecognizer.onStart], [ForcePressGestureRecognizer.onPeak],
///    and [ForcePressGestureRecognizer.onEnd] which use [ForcePressDetails].
///  * [ForcePressUpdateDetails], the details for [ForcePressUpdateCallback].
class ForcePressDetails {
  /// Creates details for a [GestureForcePressStartCallback],
  /// [GestureForcePressPeakCallback] or [GestureForcePressEndCallback].
  ///
  /// The [globalPosition] argument must not be null.
  ForcePressDetails({
    this.globalPosition = Offset.zero,
    this.sourceTimeStamp,
  }) : assert(globalPosition != null);

  /// The global position at which the function was called.
  final Offset globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;
}

/// Details object for callbacks that use [GestureForcePressUpdateCallback].
///
/// See also:
///
///  * [ForcePressGestureRecognizer.onUpdate], which uses [ForcePressUpdateCallback].
///  * [ForcePressDetails], the details for [GestureForcePressStartCallback],
///    [GestureForcePressPeakCallback] and [GestureForcePressEndCallback].
class ForcePressUpdateDetails {
  /// Creates details for a [GestureForcePressUpdateCallback].
  ///
  /// The [globalPosition] argument must not be null.
  ForcePressUpdateDetails({
    this.globalPosition = Offset.zero,
    this.pressure = 0.0,
    this.sourceTimeStamp,
  }) : assert(globalPosition != null),
       assert(pressure != null);

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The pressure of the pointer on the screen.
  final double pressure;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;
}

/// Signature used by a [ForcePressGestureRecognizer] for when a pointer has
/// pressed with at least [ForcePressGestureRecognizer.startPressure].
typedef GestureForcePressStartCallback = void Function(ForcePressDetails details);

/// Signature used by [ForcePressGestureRecognizer] for when a pointer that has
/// pressed with at least [ForcePressGestureRecognizer.peakPressure].
typedef GestureForcePressPeakCallback = void Function(ForcePressDetails details);

/// Signature used by [ForcePressGestureRecognizer] during the frames
/// after the triggering of a [ForcePressGestureRecognizer.onStart] callback.
typedef GestureForcePressUpdateCallback = void Function(ForcePressUpdateDetails details);

/// Signature for when the pointer that previously triggered a
/// [ForcePressGestureRecognizer.onStart] callback is no longer in contact
/// with the screen.
typedef GestureForcePressEndCallback = void Function(ForcePressDetails details);

/// Recognizes a force press on devices that have force sensors.
///
/// Only the force from a single pointer is used to invoke events.
class ForcePressGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Creates a force press gesture recognizer.
  ///
  /// The [startPressure] defaults to 0.4, and [peakPressure] defaults to 0.85
  /// where a value of 0.0 is no pressure and a value of 1.0 is maximum pressure.
  ForcePressGestureRecognizer({
    this.startPressure = 0.4,
    this.peakPressure = 0.85,
    Object debugOwner,
  }) : assert(startPressure != null),
       assert(peakPressure != null),
       super(debugOwner: debugOwner);

  /// A pointer is in contact with the screen and has just pressed with a force
  /// exceeding the [startPressure].
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [ForcePressDetails] object.
  GestureForcePressStartCallback onStart;

  /// A pointer is in contact with the screen and is either moving on the plane
  /// of the screen, pressing the screen with varying forces or both
  /// simultaneously.
  ///
  /// This callback will be invoked for every frame after the invocation of
  /// [onStart] no matter what the pressure is during this time period. The
  /// position and pressure of the pointer is provided in the callback's
  /// `details` argument, which is a [ForcePressUpdateDetails] object.
  GestureForcePressUpdateCallback onUpdate;

  /// A pointer is in contact with the screen and has just pressed with a force
  /// exceeding the [peakPressure].
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [ForcePressDetails] object.
  GestureForcePressPeakCallback onPeak;

  /// A pointer is no longer in contact with the screen.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [ForcePressDetails] object.
  GestureForcePressEndCallback onEnd;

  /// The pressure of the press required to initiate a force press.
  ///
  /// A value of 0.0 is no pressure, and 1.0 is maximum pressure.
  double startPressure;

  /// The pressure of the press required to peak a force press.
  ///
  /// A value of 0.0 is no pressure, and 1.0 is maximum pressure.
  double peakPressure;

  Duration _lastTimeStamp;
  Offset _lastPosition;
  _ForceState _state = _ForceState.ready;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    if (_state == _ForceState.ready) {
      _state = _ForceState.possible;
      _lastPosition = event.position;
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _ForceState.ready);
    // A static pointer with changes in pressure creates PointerMoveEvent events.
    if (event is PointerMoveEvent || event is PointerDownEvent) {
      final double pressure = _inverseLerp(event.pressureMin, event.pressureMax, event.pressure);
      if (_state == _ForceState.possible) {
        _lastTimeStamp = event.timeStamp;
        _lastPosition = event.position;
        if (pressure > startPressure) {
          _state = _ForceState.started;
          resolve(GestureDisposition.accepted);
        } else if (event.delta.distanceSquared > kTouchSlop)
          resolve(GestureDisposition.rejected);
      } else if (_state == _ForceState.accepted || _state == _ForceState.peaked || _state == _ForceState.started) {
        // Two separate if conditionals so that update will be called during the same frame as start.
        if (pressure > startPressure && _state != _ForceState.started && _state != _ForceState.peaked) {
          _state = _ForceState.started;
          _gestureStarted();
        }
        if (_state == _ForceState.started || _state == _ForceState.peaked) {
          if (onPeak != null && pressure > peakPressure && _state != _ForceState.peaked) {
            _state = _ForceState.peaked;
            invokeCallback<void>('onPeak', () => onPeak(ForcePressDetails(
              globalPosition: event.position,
              sourceTimeStamp: event.timeStamp,
            )));
          }
          if (onUpdate != null) {
            invokeCallback<void>('onUpdate', () => onUpdate(ForcePressUpdateDetails(
              sourceTimeStamp: event.timeStamp,
              pressure: pressure,
              globalPosition: event.position,
            )));
          }
        }
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
    _lastTimeStamp = event.timeStamp;
    _lastPosition = event.position;
  }

  void _gestureStarted() {
    final Duration timestamp = _lastTimeStamp;
    final Offset position = _lastPosition;
    _lastTimeStamp = null;
    _lastPosition = null;

    invokeCallback<void>('onStart', () => onStart(ForcePressDetails(
      sourceTimeStamp: timestamp,
      globalPosition: position,
    )));
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != _ForceState.accepted) {
      _state = _ForceState.accepted;
      if (onStart != null && _state == _ForceState.started) {
        _gestureStarted();
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    final bool wasAccepted = _state == _ForceState.started || _state == _ForceState.peaked;
    _state = _ForceState.ready;
    if (_state == _ForceState.possible) {
      resolve(GestureDisposition.rejected);
      return;
    }

    final Duration timestamp = _lastTimeStamp;
    final Offset position = _lastPosition;
    _lastTimeStamp = null;
    _lastPosition = null;
    if (wasAccepted && onEnd != null) {
      invokeCallback<void>('onEnd', () => onEnd(ForcePressDetails(
        sourceTimeStamp: timestamp,
        globalPosition: position,
      )));
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
    didStopTrackingLastPointer(pointer);
  }

  double _inverseLerp(double min, double max, double t) {
    return (t - min) / (max - min);
  }

  @override
  String get debugDescription => 'forcepress';
}
