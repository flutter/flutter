// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

export 'dart:ui' show Offset, PointerDeviceKind;

export 'events.dart' show PointerDownEvent, PointerEvent, PointerPanZoomStartEvent;
export 'recognizer.dart' show DragStartBehavior;
export 'velocity_tracker.dart' show Velocity;


/// The possible states of a [ScaleGestureRecognizer].
enum _ScaleState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The sequence of pointer events seen thus far is consistent with a scale
  /// gesture but the gesture has not been accepted definitively.
  possible,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture.
  accepted,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture and the pointers established a focal point
  /// and initial scale.
  started,
}

class _PointerPanZoomData {
  _PointerPanZoomData({
    required this.focalPoint,
    required this.scale,
    required this.rotation
  });
  Offset focalPoint;
  double scale;
  double rotation;

  @override
  String toString() => '_PointerPanZoomData(focalPoint: $focalPoint, scale: $scale, angle: $rotation)';
}

/// Details for [GestureScaleStartCallback].
class ScaleStartDetails {
  /// Creates details for [GestureScaleStartCallback].
  ///
  /// The [focalPoint] argument must not be null.
  ScaleStartDetails({ this.focalPoint = Offset.zero, Offset? localFocalPoint, this.pointerCount = 0 })
    : assert(focalPoint != null), localFocalPoint = localFocalPoint ?? focalPoint;

  /// The initial focal point of the pointers in contact with the screen.
  ///
  /// Reported in global coordinates.
  ///
  /// See also:
  ///
  ///  * [localFocalPoint], which is the same value reported in local
  ///    coordinates.
  final Offset focalPoint;

  /// The initial focal point of the pointers in contact with the screen.
  ///
  /// Reported in local coordinates. Defaults to [focalPoint] if not set in the
  /// constructor.
  ///
  /// See also:
  ///
  ///  * [focalPoint], which is the same value reported in global
  ///    coordinates.
  final Offset localFocalPoint;

  /// The number of pointers being tracked by the gesture recognizer.
  ///
  /// Typically this is the number of fingers being used to pan the widget using the gesture
  /// recognizer.
  final int pointerCount;

  @override
  String toString() => 'ScaleStartDetails(focalPoint: $focalPoint, localFocalPoint: $localFocalPoint, pointersCount: $pointerCount)';
}

/// Details for [GestureScaleUpdateCallback].
class ScaleUpdateDetails {
  /// Creates details for [GestureScaleUpdateCallback].
  ///
  /// The [focalPoint], [scale], [horizontalScale], [verticalScale], [rotation]
  /// arguments must not be null. The [scale], [horizontalScale], and [verticalScale]
  /// argument must be greater than or equal to zero.
  ScaleUpdateDetails({
    this.focalPoint = Offset.zero,
    Offset? localFocalPoint,
    this.scale = 1.0,
    this.horizontalScale = 1.0,
    this.verticalScale = 1.0,
    this.rotation = 0.0,
    this.pointerCount = 0,
    this.focalPointDelta = Offset.zero,
  }) : assert(focalPoint != null),
       assert(focalPointDelta != null),
       assert(scale != null && scale >= 0.0),
       assert(horizontalScale != null && horizontalScale >= 0.0),
       assert(verticalScale != null && verticalScale >= 0.0),
       assert(rotation != null),
       localFocalPoint = localFocalPoint ?? focalPoint;

  /// The amount the gesture's focal point has moved in the coordinate space of
  /// the event receiver since the previous update.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset focalPointDelta;

  /// The focal point of the pointers in contact with the screen.
  ///
  /// Reported in global coordinates.
  ///
  /// See also:
  ///
  ///  * [localFocalPoint], which is the same value reported in local
  ///    coordinates.
  final Offset focalPoint;

  /// The focal point of the pointers in contact with the screen.
  ///
  /// Reported in local coordinates. Defaults to [focalPoint] if not set in the
  /// constructor.
  ///
  /// See also:
  ///
  ///  * [focalPoint], which is the same value reported in global
  ///    coordinates.
  final Offset localFocalPoint;

  /// The scale implied by the average distance between the pointers in contact
  /// with the screen.
  ///
  /// This value must be greater than or equal to zero.
  ///
  /// See also:
  ///
  ///  * [horizontalScale], which is the scale along the horizontal axis.
  ///  * [verticalScale], which is the scale along the vertical axis.
  final double scale;

  /// The scale implied by the average distance along the horizontal axis
  /// between the pointers in contact with the screen.
  ///
  /// This value must be greater than or equal to zero.
  ///
  /// See also:
  ///
  ///  * [scale], which is the general scale implied by the pointers.
  ///  * [verticalScale], which is the scale along the vertical axis.
  final double horizontalScale;

  /// The scale implied by the average distance along the vertical axis
  /// between the pointers in contact with the screen.
  ///
  /// This value must be greater than or equal to zero.
  ///
  /// See also:
  ///
  ///  * [scale], which is the general scale implied by the pointers.
  ///  * [horizontalScale], which is the scale along the horizontal axis.
  final double verticalScale;

  /// The angle implied by the first two pointers to enter in contact with
  /// the screen.
  ///
  /// Expressed in radians.
  final double rotation;

  /// The number of pointers being tracked by the gesture recognizer.
  ///
  /// Typically this is the number of fingers being used to pan the widget using the gesture
  /// recognizer.
  final int pointerCount;

  @override
  String toString() => 'ScaleUpdateDetails('
    'focalPoint: $focalPoint,'
    ' localFocalPoint: $localFocalPoint,'
    ' scale: $scale,'
    ' horizontalScale: $horizontalScale,'
    ' verticalScale: $verticalScale,'
    ' rotation: $rotation,'
    ' pointerCount: $pointerCount,'
    ' focalPointDelta: $focalPointDelta)';
}

/// Details for [GestureScaleEndCallback].
class ScaleEndDetails {
  /// Creates details for [GestureScaleEndCallback].
  ///
  /// The [velocity] argument must not be null.
  ScaleEndDetails({ this.velocity = Velocity.zero, this.pointerCount = 0 })
    : assert(velocity != null);

  /// The velocity of the last pointer to be lifted off of the screen.
  final Velocity velocity;

  /// The number of pointers being tracked by the gesture recognizer.
  ///
  /// Typically this is the number of fingers being used to pan the widget using the gesture
  /// recognizer.
  final int pointerCount;

  @override
  String toString() => 'ScaleEndDetails(velocity: $velocity, pointerCount: $pointerCount)';
}

/// Signature for when the pointers in contact with the screen have established
/// a focal point and initial scale of 1.0.
typedef GestureScaleStartCallback = void Function(ScaleStartDetails details);

/// Signature for when the pointers in contact with the screen have indicated a
/// new focal point and/or scale.
typedef GestureScaleUpdateCallback = void Function(ScaleUpdateDetails details);

/// Signature for when the pointers are no longer in contact with the screen.
typedef GestureScaleEndCallback = void Function(ScaleEndDetails details);

bool _isFlingGesture(Velocity velocity) {
  assert(velocity != null);
  final double speedSquared = velocity.pixelsPerSecond.distanceSquared;
  return speedSquared > kMinFlingVelocity * kMinFlingVelocity;
}


/// Defines a line between two pointers on screen.
///
/// [_LineBetweenPointers] is an abstraction of a line between two pointers in
/// contact with the screen. Used to track the rotation of a scale gesture.
class _LineBetweenPointers {

  /// Creates a [_LineBetweenPointers]. None of the [pointerStartLocation], [pointerStartId]
  /// [pointerEndLocation] and [pointerEndId] must be null. [pointerStartId] and [pointerEndId]
  /// should be different.
  _LineBetweenPointers({
    this.pointerStartLocation = Offset.zero,
    this.pointerStartId = 0,
    this.pointerEndLocation = Offset.zero,
    this.pointerEndId = 1,
  }) : assert(pointerStartLocation != null && pointerEndLocation != null),
       assert(pointerStartId != null && pointerEndId != null),
       assert(pointerStartId != pointerEndId);

  // The location and the id of the pointer that marks the start of the line.
  final Offset pointerStartLocation;
  final int pointerStartId;

  // The location and the id of the pointer that marks the end of the line.
  final Offset pointerEndLocation;
  final int pointerEndId;

}


/// Recognizes a scale gesture.
///
/// [ScaleGestureRecognizer] tracks the pointers in contact with the screen and
/// calculates their focal point, indicated scale, and rotation. When a focal
/// pointer is established, the recognizer calls [onStart]. As the focal point,
/// scale, rotation change, the recognizer calls [onUpdate]. When the pointers
/// are no longer in contact with the screen, the recognizer calls [onEnd].
class ScaleGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Create a gesture recognizer for interactions intended for scaling content.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  ScaleGestureRecognizer({
    super.debugOwner,
    @Deprecated(
      'Migrate to supportedDevices. '
      'This feature was deprecated after v2.3.0-1.0.pre.',
    )
    super.kind,
    super.supportedDevices,
    this.dragStartBehavior = DragStartBehavior.down,
  }) : assert(dragStartBehavior != null);

  /// Determines what point is used as the starting point in all calculations
  /// involving this gesture.
  ///
  /// When set to [DragStartBehavior.down], the scale is calculated starting
  /// from the position where the pointer first contacted the screen.
  ///
  /// When set to [DragStartBehavior.start], the scale is calculated starting
  /// from the position where the scale gesture began. The scale gesture may
  /// begin after the time that the pointer first contacted the screen if there
  /// are multiple listeners competing for the gesture. In that case, the
  /// gesture arena waits to determine whether or not the gesture is a scale
  /// gesture before giving the gesture to this GestureRecognizer. This happens
  /// in the case of nested GestureDetectors, for example.
  ///
  /// Defaults to [DragStartBehavior.down].
  ///
  /// See also:
  ///
  /// * https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation,
  ///   which provides more information about the gesture arena.
  DragStartBehavior dragStartBehavior;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  ///
  /// This won't be called until the gesture arena has determined that this
  /// GestureRecognizer has won the gesture.
  ///
  /// See also:
  ///
  /// * https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation,
  ///   which provides more information about the gesture arena.
  GestureScaleStartCallback? onStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  GestureScaleUpdateCallback? onUpdate;

  /// The pointers are no longer in contact with the screen.
  GestureScaleEndCallback? onEnd;

  _ScaleState _state = _ScaleState.ready;

  Matrix4? _lastTransform;

  late Offset _initialFocalPoint;
  Offset? _currentFocalPoint;
  late double _initialSpan;
  late double _currentSpan;
  late double _initialHorizontalSpan;
  late double _currentHorizontalSpan;
  late double _initialVerticalSpan;
  late double _currentVerticalSpan;
  late Offset _localFocalPoint;
  _LineBetweenPointers? _initialLine;
  _LineBetweenPointers? _currentLine;
  final Map<int, Offset> _pointerLocations = <int, Offset>{};
  final List<int> _pointerQueue = <int>[]; // A queue to sort pointers in order of entrance
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};
  late Offset _delta;
  final Map<int, _PointerPanZoomData> _pointerPanZooms = <int, _PointerPanZoomData>{};
  double _initialPanZoomScaleFactor = 1;
  double _initialPanZoomRotationFactor = 0;

  double get _pointerScaleFactor => _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;

  double get _pointerHorizontalScaleFactor => _initialHorizontalSpan > 0.0 ? _currentHorizontalSpan / _initialHorizontalSpan : 1.0;

  double get _pointerVerticalScaleFactor => _initialVerticalSpan > 0.0 ? _currentVerticalSpan / _initialVerticalSpan : 1.0;

  double get _scaleFactor {
    double scale = _pointerScaleFactor;
    for (final _PointerPanZoomData p in _pointerPanZooms.values) {
      scale *= p.scale / _initialPanZoomScaleFactor;
    }
    return scale;
  }

  double get _horizontalScaleFactor {
    double scale = _pointerHorizontalScaleFactor;
    for (final _PointerPanZoomData p in _pointerPanZooms.values) {
      scale *= p.scale / _initialPanZoomScaleFactor;
    }
    return scale;
  }

  double get _verticalScaleFactor {
    double scale = _pointerVerticalScaleFactor;
    for (final _PointerPanZoomData p in _pointerPanZooms.values) {
      scale *= p.scale / _initialPanZoomScaleFactor;
    }
    return scale;
  }

  int get _pointerCount {
    return _pointerPanZooms.length + _pointerQueue.length;
  }

  double _computeRotationFactor() {
    double factor = 0.0;
    if (_initialLine != null && _currentLine != null) {
      final double fx = _initialLine!.pointerStartLocation.dx;
      final double fy = _initialLine!.pointerStartLocation.dy;
      final double sx = _initialLine!.pointerEndLocation.dx;
      final double sy = _initialLine!.pointerEndLocation.dy;

      final double nfx = _currentLine!.pointerStartLocation.dx;
      final double nfy = _currentLine!.pointerStartLocation.dy;
      final double nsx = _currentLine!.pointerEndLocation.dx;
      final double nsy = _currentLine!.pointerEndLocation.dy;

      final double angle1 = math.atan2(fy - sy, fx - sx);
      final double angle2 = math.atan2(nfy - nsy, nfx - nsx);

      factor = angle2 - angle1;
    }
    for (final _PointerPanZoomData p in _pointerPanZooms.values) {
      factor += p.rotation;
    }
    factor -= _initialPanZoomRotationFactor;
    return factor;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _velocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind);
    if (_state == _ScaleState.ready) {
      _state = _ScaleState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _initialHorizontalSpan = 0.0;
      _currentHorizontalSpan = 0.0;
      _initialVerticalSpan = 0.0;
      _currentVerticalSpan = 0.0;
    }
  }

  @override
  bool isPointerPanZoomAllowed(PointerPanZoomStartEvent event) => true;

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    super.addAllowedPointerPanZoom(event);
    startTrackingPointer(event.pointer, event.transform);
    _velocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind);
    if (_state == _ScaleState.ready) {
      _state = _ScaleState.possible;
      _initialPanZoomScaleFactor = 1.0;
      _initialPanZoomRotationFactor = 0.0;
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _ScaleState.ready);
    bool didChangeConfiguration = false;
    bool shouldStartIfAccepted = false;
    if (event is PointerMoveEvent) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer]!;
      if (!event.synthesized) {
        tracker.addPosition(event.timeStamp, event.position);
      }
      _pointerLocations[event.pointer] = event.position;
      shouldStartIfAccepted = true;
      _lastTransform = event.transform;
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
      _pointerQueue.add(event.pointer);
      didChangeConfiguration = true;
      shouldStartIfAccepted = true;
      _lastTransform = event.transform;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
      _pointerQueue.remove(event.pointer);
      didChangeConfiguration = true;
      _lastTransform = event.transform;
    } else if (event is PointerPanZoomStartEvent) {
      assert(_pointerPanZooms[event.pointer] == null);
      _pointerPanZooms[event.pointer] = _PointerPanZoomData(
        focalPoint: event.position,
        scale: 1,
        rotation: 0
      );
      didChangeConfiguration = true;
      shouldStartIfAccepted = true;
    } else if (event is PointerPanZoomUpdateEvent) {
      assert(_pointerPanZooms[event.pointer] != null);
      if (!event.synthesized) {
        _velocityTrackers[event.pointer]!.addPosition(event.timeStamp, event.pan);
      }
      _pointerPanZooms[event.pointer] = _PointerPanZoomData(
        focalPoint: event.position + event.pan,
        scale: event.scale,
        rotation: event.rotation
      );
      _lastTransform = event.transform;
      shouldStartIfAccepted = true;
    } else if (event is PointerPanZoomEndEvent) {
      assert(_pointerPanZooms[event.pointer] != null);
      _pointerPanZooms.remove(event.pointer);
      didChangeConfiguration = true;
    }

    _updateLines();
    _update();

    if (!didChangeConfiguration || _reconfigure(event.pointer)) {
      _advanceStateMachine(shouldStartIfAccepted, event.kind);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  void _update() {
    final Offset? previousFocalPoint = _currentFocalPoint;

    // Compute the focal point
    Offset focalPoint = Offset.zero;
    for (final int pointer in _pointerLocations.keys) {
      focalPoint += _pointerLocations[pointer]!;
    }
    for (final _PointerPanZoomData p in _pointerPanZooms.values) {
      focalPoint += p.focalPoint;
    }
    _currentFocalPoint = _pointerCount > 0 ? focalPoint / _pointerCount.toDouble() : Offset.zero;

    if (previousFocalPoint == null) {
      _localFocalPoint = PointerEvent.transformPosition(
        _lastTransform,
        _currentFocalPoint!,
      );
      _delta = Offset.zero;
    } else {
      final Offset localPreviousFocalPoint = _localFocalPoint;
      _localFocalPoint = PointerEvent.transformPosition(
        _lastTransform,
        _currentFocalPoint!,
      );
      _delta = _localFocalPoint - localPreviousFocalPoint;
    }

    final int count = _pointerLocations.keys.length;

    Offset pointerFocalPoint = Offset.zero;
    for (final int pointer in _pointerLocations.keys) {
      pointerFocalPoint += _pointerLocations[pointer]!;
    }
    if (count > 0) {
      pointerFocalPoint = pointerFocalPoint / count.toDouble();
    }

    // Span is the average deviation from focal point. Horizontal and vertical
    // spans are the average deviations from the focal point's horizontal and
    // vertical coordinates, respectively.
    double totalDeviation = 0.0;
    double totalHorizontalDeviation = 0.0;
    double totalVerticalDeviation = 0.0;
    for (final int pointer in _pointerLocations.keys) {
      totalDeviation += (pointerFocalPoint - _pointerLocations[pointer]!).distance;
      totalHorizontalDeviation += (pointerFocalPoint.dx - _pointerLocations[pointer]!.dx).abs();
      totalVerticalDeviation += (pointerFocalPoint.dy - _pointerLocations[pointer]!.dy).abs();
    }
    _currentSpan = count > 0 ? totalDeviation / count : 0.0;
    _currentHorizontalSpan = count > 0 ? totalHorizontalDeviation / count : 0.0;
    _currentVerticalSpan = count > 0 ? totalVerticalDeviation / count : 0.0;
  }

  /// Updates [_initialLine] and [_currentLine] accordingly to the situation of
  /// the registered pointers.
  void _updateLines() {
    final int count = _pointerLocations.keys.length;
    assert(_pointerQueue.length >= count);
    /// In case of just one pointer registered, reconfigure [_initialLine]
    if (count < 2) {
      _initialLine = _currentLine;
    } else if (_initialLine != null &&
      _initialLine!.pointerStartId == _pointerQueue[0] &&
      _initialLine!.pointerEndId == _pointerQueue[1]) {
      /// Rotation updated, set the [_currentLine]
      _currentLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
    } else {
      /// A new rotation process is on the way, set the [_initialLine]
      _initialLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
      _currentLine = _initialLine;
    }
  }

  bool _reconfigure(int pointer) {
    _initialFocalPoint = _currentFocalPoint!;
    _initialSpan = _currentSpan;
    _initialLine = _currentLine;
    _initialHorizontalSpan = _currentHorizontalSpan;
    _initialVerticalSpan = _currentVerticalSpan;
    if (_pointerPanZooms.isEmpty) {
      _initialPanZoomScaleFactor = 1.0;
      _initialPanZoomRotationFactor = 0.0;
    } else {
      _initialPanZoomScaleFactor = _scaleFactor / _pointerScaleFactor;
      _initialPanZoomRotationFactor = _pointerPanZooms.values.map((_PointerPanZoomData x) => x.rotation).reduce((double a, double b) => a + b);
    }
    if (_state == _ScaleState.started) {
      if (onEnd != null) {
        final VelocityTracker tracker = _velocityTrackers[pointer]!;

        Velocity velocity = tracker.getVelocity();
        if (_isFlingGesture(velocity)) {
          final Offset pixelsPerSecond = velocity.pixelsPerSecond;
          if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity) {
            velocity = Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity);
          }
          invokeCallback<void>('onEnd', () => onEnd!(ScaleEndDetails(velocity: velocity, pointerCount: _pointerCount)));
        } else {
          invokeCallback<void>('onEnd', () => onEnd!(ScaleEndDetails(pointerCount: _pointerCount)));
        }
      }
      _state = _ScaleState.accepted;
      return false;
    }
    return true;
  }

  void _advanceStateMachine(bool shouldStartIfAccepted, PointerDeviceKind pointerDeviceKind) {
    if (_state == _ScaleState.ready) {
      _state = _ScaleState.possible;
    }

    if (_state == _ScaleState.possible) {
      final double spanDelta = (_currentSpan - _initialSpan).abs();
      final double focalPointDelta = (_currentFocalPoint! - _initialFocalPoint).distance;
      if (spanDelta > computeScaleSlop(pointerDeviceKind) || focalPointDelta > computePanSlop(pointerDeviceKind, gestureSettings) || math.max(_scaleFactor / _pointerScaleFactor, _pointerScaleFactor / _scaleFactor) > 1.05) {
        resolve(GestureDisposition.accepted);
      }
    } else if (_state.index >= _ScaleState.accepted.index) {
      resolve(GestureDisposition.accepted);
    }

    if (_state == _ScaleState.accepted && shouldStartIfAccepted) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
    }

    if (_state == _ScaleState.started && onUpdate != null) {
      invokeCallback<void>('onUpdate', () {
        onUpdate!(ScaleUpdateDetails(
          scale: _scaleFactor,
          horizontalScale: _horizontalScaleFactor,
          verticalScale: _verticalScaleFactor,
          focalPoint: _currentFocalPoint!,
          localFocalPoint: _localFocalPoint,
          rotation: _computeRotationFactor(),
          pointerCount: _pointerCount,
          focalPointDelta: _delta,
        ));
      });
    }
  }

  void _dispatchOnStartCallbackIfNeeded() {
    assert(_state == _ScaleState.started);
    if (onStart != null) {
      invokeCallback<void>('onStart', () {
        onStart!(ScaleStartDetails(
          focalPoint: _currentFocalPoint!,
          localFocalPoint: _localFocalPoint,
          pointerCount: _pointerCount,
        ));
      });
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_state == _ScaleState.possible) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
      if (dragStartBehavior == DragStartBehavior.start) {
        _initialFocalPoint = _currentFocalPoint!;
        _initialSpan = _currentSpan;
        _initialLine = _currentLine;
        _initialHorizontalSpan = _currentHorizontalSpan;
        _initialVerticalSpan = _currentVerticalSpan;
        if (_pointerPanZooms.isEmpty) {
          _initialPanZoomScaleFactor = 1.0;
          _initialPanZoomRotationFactor = 0.0;
        } else {
          _initialPanZoomScaleFactor = _scaleFactor / _pointerScaleFactor;
          _initialPanZoomRotationFactor = _pointerPanZooms.values.map((_PointerPanZoomData x) => x.rotation).reduce((double a, double b) => a + b);
        }
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    _pointerPanZooms.remove(pointer);
    _pointerLocations.remove(pointer);
    _pointerQueue.remove(pointer);
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_state) {
      case _ScaleState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case _ScaleState.ready:
        assert(false); // We should have not seen a pointer yet
        break;
      case _ScaleState.accepted:
        break;
      case _ScaleState.started:
        assert(false); // We should be in the accepted state when user is done
        break;
    }
    _state = _ScaleState.ready;
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  String get debugDescription => 'scale';
}
