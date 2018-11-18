
import 'dart:ui' show Offset;

import 'arena.dart';
import 'events.dart';
import 'recognizer.dart';
import 'tap.dart';

enum _ForceState {
  ready,
  possible,
  accepted,
}

///
class ForcePressDetails {
  /// Creates details for a [GestureForcePressStartCallback],
  /// [GestureForcePressPeakCallback] and [GestureForcePressEndCallback].
  ///
  /// The [globalPosition] argument must not be null.
  ForcePressDetails({
    this.globalPosition = Offset.zero,
    this.sourceTimeStamp,
  })
    : assert(globalPosition != null);

  /// The global position at which the function was called.
  final Offset globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  final Duration sourceTimeStamp;
}

///
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

/// Signature used by [ForcePressGestureRecognizer] for when a pointer has
/// pressed with sufficient force to initiate a force press gesture.
typedef GestureForcePressStartCallback = void Function(ForcePressDetails details);

/// Signature used by [ForcePressGestureRecognizer] for when a pointer that has
/// initiated a force press has peaked in pressure.
typedef GestureForcePressPeakCallback = void Function(ForcePressDetails details);

/// Signature used by [ForcePressGestureRecognizer] for the duration of time
/// after the initiation of the force touch and before the peak.
typedef GestureForcePressUpdateCallback = void Function(ForcePressUpdateDetails details);

/// Signature for when the pointer that previously triggered a
/// [GestureMultiTapDownCallback] will not end up causing a tap.
typedef GestureForcePressEndCallback = void Function(ForcePressDetails details);

///
class ForcePressGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Creates a multi-tap gesture recognizer.
  ///
  /// The [longTapDelay] defaults to [Duration.zero], which means
  /// [onLongTapDown] is called immediately after [onTapDown].
  ForcePressGestureRecognizer({
    this.startPressure = .4,
    this.peakPressure = .99,
    Object debugOwner,
  }) : assert(startPressure != null),
       assert(peakPressure != null),
       super(debugOwner: debugOwner);

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  GestureForcePressStartCallback onStart;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  GestureForcePressPeakCallback onPeak;

  /// A tap has occurred.
  GestureForcePressUpdateCallback onUpdate;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  GestureForcePressEndCallback onEnd;

  /// The pressure of the press required to initiate a force
  /// press.
  ///
  /// A value of 0.0 is no pressure, and 1.0 is maximum pressure.
  double startPressure;

  /// The pressure of the press required to peak a force press.
  ///
  /// A value of 0.0 is no pressure, and 1.0 is maximum pressure.
  double peakPressure;

  Duration _lastTimeStamp;
  Offset _lastPosition;
  _ForceState _state;

  @override
  void addPointer(PointerEvent event) {
    if (_state == _ForceState.ready) {
      _state = _ForceState.possible;
      _lastPosition = event.position;
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _ForceState.ready);

    if (event is PointerMoveEvent || event is PointerDownEvent) {
      if (_state == _ForceState.possible) {
        final double pressure = _inverseLerp(event.pressureMin, event.pressureMax, event.pressure);

        if (_state == _ForceState.accepted) {
          if (onUpdate != null &&
              pressure >= startPressure && pressure <= peakPressure) {
            invokeCallback<void>('onUpdate', () => onUpdate(ForcePressUpdateDetails(
              sourceTimeStamp: event.timeStamp,
              pressure: pressure,
              globalPosition: event.position,
            )));
          } else if (onPeak != null && pressure > peakPressure) {
            invokeCallback<void>('onPeak', () => onPeak(ForcePressDetails(
              globalPosition: event.position,
              sourceTimeStamp: event.timeStamp,
            )));
          } else if (onEnd != null && pressure < startPressure ) {
            invokeCallback<void>('onEnd', () => onEnd(ForcePressDetails(
              globalPosition: event.position,
              sourceTimeStamp: event.timeStamp,
            )));
          }
        } else {
          if (pressure > startPressure) {
            _lastTimeStamp = event.timeStamp;
            _lastPosition = event.position;
            resolve(GestureDisposition.accepted);
          }
        }
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
    _lastTimeStamp = event.timeStamp;
    _lastPosition = event.position;
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != _ForceState.accepted) {
      _state = _ForceState.accepted;
      final Duration timestamp = _lastTimeStamp;
      final Offset position = _lastPosition;
      _lastTimeStamp = null;
      _lastPosition = null;
      if (onStart != null) {
        invokeCallback<void>('onStart', () => onStart(ForcePressDetails(
          sourceTimeStamp: timestamp,
          globalPosition: position,
        )));
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_state == _ForceState.possible) {
      resolve(GestureDisposition.rejected);
      _state = _ForceState.ready;
    }
    final bool wasAccepted = _state == _ForceState.accepted;
    _state = _ForceState.ready;

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
    didStopTrackingLastPointer(pointer);
  }

  double _inverseLerp(double min, double max, double t) {
    return (t - min) / (max - min);
  }

  @override
  String get debugDescription => 'forcepress';
}