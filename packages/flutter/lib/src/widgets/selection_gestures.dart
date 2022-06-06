// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:async/async.dart';

import 'package:flutter/foundation.dart';//for shiftaware
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';//for shiftaware

class SelectionGestures extends StatefulWidget {
  const SelectionGestures({
    super.key,
    this.manager,
    required this.child,
    required this.gestures,
    this.behavior
  });

  final SelectionGesturesManager? manager;

  final Map<Type, ContextGestureRecognizerFactory> gestures;

  final Widget child;

  final HitTestBehavior? behavior;

  static SelectionGesturesManager of(BuildContext context) {
    assert(context != null);
    final _SelectionGesturesMarker? inherited = context.dependOnInheritedWidgetOfExactType<_SelectionGesturesMarker>();
    assert(() {
      if (inherited == null) {
        throw FlutterError(
            'Unable to find a SelectionGestures widget in the context.\n'
        );
      }
      return true;
    }());
    return inherited!.manager;
  }

  @override
  State<SelectionGestures> createState() => _SelectionGesturesState();
}

class _SelectionGesturesState extends State<SelectionGestures> {
  SelectionGesturesManager? _internalManager;
  SelectionGesturesManager get manager => widget.manager ?? _internalManager!;

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) {
      _internalManager = SelectionGesturesManager();
    }
    manager.gestures = widget.gestures;
  }

  @override
  void dispose() {
    _internalManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionGesturesMarker(
      manager: manager,
      child: widget.child,
    );
  }
}

class SelectionGesturesManager extends ChangeNotifier {
  SelectionGesturesManager({
    Map<Type, ContextGestureRecognizerFactory> gestures = const <Type, ContextGestureRecognizerFactory>{},
  })  : assert(gestures != null),
        _gestures = gestures;

  Map<Type, ContextGestureRecognizerFactory> _gestures = <Type, ContextGestureRecognizerFactory>{};
  Map<Type, ContextGestureRecognizerFactory> get gestures => _gestures;
  set gestures(Map<Type, ContextGestureRecognizerFactory> gestures) {
    _gestures = gestures;
  }

  @protected
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for (final GestureRecognizer recognizer in recognizers.values) {
      recognizer.addPointer(event);
    }
  }
}

class _SelectionGesturesMarker extends InheritedNotifier<SelectionGesturesManager> {
  const _SelectionGesturesMarker({
    required SelectionGesturesManager manager,
    required Widget child
  }) : super(notifier: manager, child: child);

  SelectionGesturesManager get manager => super.notifier!;
}

typedef ContextGestureRecognizerFactoryConstructor<T extends GestureRecognizer> = T Function(BuildContext context);

typedef ContextGestureRecognizerFactoryInitializer<T extends GestureRecognizer> = void Function(T instance, BuildContext context);

class ContextGestureRecognizerFactoryWithHandlers<T extends GestureRecognizer> extends ContextGestureRecognizerFactory<T> {
  /// Creates a gesture recognizer factory with the given callbacks.
  ///
  /// The arguments must not be null.
  const ContextGestureRecognizerFactoryWithHandlers(this._constructor, this._initializer)
      : assert(_constructor != null),
        assert(_initializer != null);

  final ContextGestureRecognizerFactoryConstructor<T> _constructor;

  final ContextGestureRecognizerFactoryInitializer<T> _initializer;

  @override
  T constructor(BuildContext context) => _constructor(context);

  @override
  void initializer(T instance, BuildContext context) => _initializer(instance, context);
}

@optionalTypeArgs
abstract class ContextGestureRecognizerFactory<T extends GestureRecognizer> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ContextGestureRecognizerFactory();

  /// Must return an instance of T.
  T constructor(BuildContext context);

  /// Must configure the given instance (which will have been created by
  /// `constructor`).
  ///
  /// This normally means setting the callbacks.
  void initializer(T instance, BuildContext context);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T, 'ContextGestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

typedef ConsecutiveSelectionTapGestureTapDownCallback = void Function(TapDownDetails details, int tapCount);
typedef ConsecutiveSelectionTapGestureTapUpCallback = void Function(TapUpDetails details, int tapCount);

class SelectionConsecutiveTapGestureRecognizer extends BaseTapGestureRecognizer {
  /// Creates a consecutive tap gesture recognizer.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  SelectionConsecutiveTapGestureRecognizer({ super.debugOwner, super.supportedDevices });

  /// A pointer has contacted the screen at a particular location with a primary
  /// button, which might be the start of a tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called next.
  /// Otherwise, [onTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapDown], which exposes this callback.
  ConsecutiveSelectionTapGestureTapDownCallback? onTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a primary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it
  /// or has previously won, immediately followed by [onTap].
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTapUp], which exposes this callback.
  ConsecutiveSelectionTapGestureTapUpCallback? onTapUp;

  /// A pointer has stopped contacting the screen, which is recognized as a tap
  /// of a primary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it
  /// or has previously won, immediately following [onTapUp].
  ///
  /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTap], a similar callback but for a secondary button.
  ///  * [onTapUp], which has the same timing but with details.
  ///  * [GestureDetector.onTap], which exposes this callback.
  GestureTapCallback? onTap;

  /// A pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  ///
  /// This triggers once the gesture loses the arena if [onTapDown] has
  /// previously been triggered.
  ///
  /// If this recognizer wins the arena, [onTapUp] and [onTap] are called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
  ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
  ///  * [GestureDetector.onTapCancel], which exposes this callback.
  GestureTapCancelCallback? onTapCancel;

  /// A pointer has stopped contacting the screen, which is recognized as a tap
  /// of a secondary button.
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it or
  /// has previously won, immediately following [onSecondaryTapUp].
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], which has the same timing but with details.
  ///  * [GestureDetector.onSecondaryTap], which exposes this callback.
  GestureTapCallback? onSecondaryTap;

  /// A pointer has contacted the screen at a particular location with a
  /// secondary button, which might be the start of a secondary tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// next. Otherwise, [onSecondaryTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapDown], a similar callback but for a primary button.
  ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapDown], which exposes this callback.
  GestureTapDownCallback? onSecondaryTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a secondary button.
  ///
  /// This triggers on the up event if the recognizer wins the arena with it
  /// or has previously won.
  ///
  /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
  ///    pass any details about the tap.
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onSecondaryTapUp], which exposes this callback.
  GestureTapUpCallback? onSecondaryTapUp;

  /// A pointer that previously triggered [onSecondaryTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers once the gesture loses the arena if [onSecondaryTapDown]
  /// has previously been triggered.
  ///
  /// If this recognizer wins the arena, [onSecondaryTapUp] is called instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapCancel], a similar callback but for a primary button.
  ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
  ///  * [GestureDetector.onSecondaryTapCancel], which exposes this callback.
  GestureTapCancelCallback? onSecondaryTapCancel;

  /// A pointer has contacted the screen at a particular location with a
  /// tertiary button, which might be the start of a tertiary tap.
  ///
  /// This triggers after the down event, once a short timeout ([deadline]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
  /// next. Otherwise, [onTertiaryTapUp] is called next.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTapDown], a similar callback but for a primary button.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTertiaryTapDown], which exposes this callback.
  GestureTapDownCallback? onTertiaryTapDown;

  /// A pointer has stopped contacting the screen at a particular location,
  /// which is recognized as a tap of a tertiary button.
  ///
  /// This triggers on the up event if the recognizer wins the arena with it
  /// or has previously won.
  ///
  /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
  /// instead.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [GestureDetector.onTertiaryTapUp], which exposes this callback.
  GestureTapUpCallback? onTertiaryTapUp;

  /// A pointer that previously triggered [onTertiaryTapDown] will not end up
  /// causing a tap.
  ///
  /// This triggers once the gesture loses the arena if [onTertiaryTapDown]
  /// has previously been triggered.
  ///
  /// If this recognizer wins the arena, [onTertiaryTapUp] is called instead.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapCancel], a similar callback but for a primary button.
  ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
  ///  * [GestureDetector.onTertiaryTapCancel], which exposes this callback.
  GestureTapCancelCallback? onTertiaryTapCancel;

  // For consecutive tap
  RestartableTimer? _consecutiveTapTimer;
  Offset? _lastTapOffset;
  int _tapCount = 0;

  bool _isWithinConsecutiveTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  void _consecutiveTapTimeout() {
    _consecutiveTapTimer = null;
    _lastTapOffset = null;
    _tapCount = 0;
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onTapDown == null &&
            onTap == null &&
            onTapUp == null &&
            onTapCancel == null) {
          return false;
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTap == null &&
            onSecondaryTapDown == null &&
            onSecondaryTapUp == null &&
            onSecondaryTapCancel == null) {
          return false;
        }
        break;
      case kTertiaryButton:
        if (onTertiaryTapDown == null &&
            onTertiaryTapUp == null &&
            onTertiaryTapCancel == null) {
          return false;
        }
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @protected
  @override
  void handleTapDown({required PointerDownEvent down}) {
    final TapDownDetails details = TapDownDetails(
      globalPosition: down.position,
      localPosition: down.localPosition,
      kind: getKindForPointer(down.pointer),
    );

    if (_lastTapOffset == null) {
      _tapCount += 1;
      _lastTapOffset = details.globalPosition;
    } else {
      if (_consecutiveTapTimer != null && _isWithinConsecutiveTapTolerance(details.globalPosition)) {
        _tapCount += 1;
        _consecutiveTapTimer!.reset();
      }
    }

    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapDown != null) {
          invokeCallback<void>(
              'onTapDown', () => onTapDown!(details, _tapCount));
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null) {
          invokeCallback<void>(
              'onSecondaryTapDown', () => onSecondaryTapDown!(details));
        }
        break;
      case kTertiaryButton:
        if (onTertiaryTapDown != null) {
          invokeCallback<void>(
              'onTertiaryTapDown', () => onTertiaryTapDown!(details));
        }
        break;
      default:
    }
  }

  @protected
  @override
  void handleTapUp({ required PointerDownEvent down, required PointerUpEvent up}) {
    final TapUpDetails details = TapUpDetails(
      kind: up.kind,
      globalPosition: up.position,
      localPosition: up.localPosition,
    );

    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapUp != null) {
          invokeCallback<void>('onTapUp', () => onTapUp!(details, _tapCount));
        }
        if (onTap != null) {
          invokeCallback<void>('onTap', onTap!);
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapUp != null) {
          invokeCallback<void>(
              'onSecondaryTapUp', () => onSecondaryTapUp!(details));
        }
        if (onSecondaryTap != null) {
          invokeCallback<void>('onSecondaryTap', () => onSecondaryTap!());
        }
        break;
      case kTertiaryButton:
        if (onTertiaryTapUp != null) {
          invokeCallback<void>(
              'onTertiaryTapUp', () => onTertiaryTapUp!(details));
        }
        break;
      default:
    }

    if (_consecutiveTapTimer == null) {
      _consecutiveTapTimer = RestartableTimer(kDoubleTapTimeout, _consecutiveTapTimeout);
    }

  }

  @protected
  @override
  void handleTapCancel({ required PointerDownEvent down, PointerCancelEvent? cancel, required String reason }) {
    final String note = reason == '' ? reason : '$reason ';
    switch (down.buttons) {
      case kPrimaryButton:
        if (onTapCancel != null) {
          invokeCallback<void>('${note}onTapCancel', onTapCancel!);
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapCancel != null) {
          invokeCallback<void>(
              '${note}onSecondaryTapCancel', onSecondaryTapCancel!);
        }
        break;
      case kTertiaryButton:
        if (onTertiaryTapCancel != null) {
          invokeCallback<void>(
              '${note}onTertiaryTapCancel', onTertiaryTapCancel!);
        }
        break;
      default:
    }
  }

  @override
  String get debugDescription => 'tap';
}

typedef ShiftAwareGestureDragDownCallback = void Function(DragDownDetails details, bool isShiftTapping);
typedef ShiftAwareGestureDragStartCallback = void Function(DragStartDetails details, bool isShiftTapping);
typedef ShiftAwareGestureDragUpdateCallback = void Function(DragUpdateDetails updateDetails, DragStartDetails startDetails, bool isShiftTapping);
typedef ShiftAwareGestureDragEndCallback = void Function(DragEndDetails details, bool isShiftTapping);

enum _DragState {
  ready,
  possible,
  accepted,
}

abstract class ShiftAwareDragGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Initialize the object.
  ///
  /// [dragStartBehavior] must not be null.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  ShiftAwareDragGestureRecognizer({
    super.debugOwner,
    @Deprecated(
      'Migrate to supportedDevices. '
      'This feature was deprecated after v2.3.0-1.0.pre.',
    )
    super.kind,
    this.dragStartBehavior = DragStartBehavior.start,
    this.velocityTrackerBuilder = _defaultBuilder,
    super.supportedDevices,
  }) : assert(dragStartBehavior != null);

  static VelocityTracker _defaultBuilder(PointerEvent event) => VelocityTracker.withKind(event.kind);

  /// Configure the behavior of offsets passed to [onStart].
  ///
  /// If set to [DragStartBehavior.start], the [onStart] callback will be called
  /// with the position of the pointer at the time this gesture recognizer won
  /// the arena. If [DragStartBehavior.down], [onStart] will be called with
  /// the position of the first detected down event for the pointer. When there
  /// are no other gestures competing with this gesture in the arena, there's
  /// no difference in behavior between the two settings.
  ///
  /// For more information about the gesture arena:
  /// https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// ## Example:
  ///
  /// A [HorizontalDragGestureRecognizer] and a [VerticalDragGestureRecognizer]
  /// compete with each other. A finger presses down on the screen with
  /// offset (500.0, 500.0), and then moves to position (510.0, 500.0) before
  /// the [HorizontalDragGestureRecognizer] wins the arena. With
  /// [dragStartBehavior] set to [DragStartBehavior.down], the [onStart]
  /// callback will be called with position (500.0, 500.0). If it is
  /// instead set to [DragStartBehavior.start], [onStart] will be called with
  /// position (510.0, 500.0).
  DragStartBehavior dragStartBehavior;

  /// A pointer has contacted the screen with a primary button and might begin
  /// to move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragDownDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragDownDetails], which is passed as an argument to this callback.
  ShiftAwareGestureDragDownCallback? onDown;

  /// A pointer has contacted the screen with a primary button and has begun to
  /// move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragStartDetails] object. The [dragStartBehavior]
  /// determines this position.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragStartDetails], which is passed as an argument to this callback.
  ShiftAwareGestureDragStartCallback? onStart;

  /// A pointer that is in contact with the screen with a primary button and
  /// moving has moved again.
  ///
  /// The distance traveled by the pointer since the last update is provided in
  /// the callback's `details` argument, which is a [DragUpdateDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragUpdateDetails], which is passed as an argument to this callback.
  ShiftAwareGestureDragUpdateCallback? onUpdate;

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  ///
  /// The velocity is provided in the callback's `details` argument, which is a
  /// [DragEndDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragEndDetails], which is passed as an argument to this callback.
  ShiftAwareGestureDragEndCallback? onEnd;

  /// The pointer that previously triggered [onDown] did not complete.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  GestureDragCancelCallback? onCancel;

  /// The minimum distance an input pointer drag must have moved to
  /// to be considered a fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis. If null then [kTouchSlop] is used.
  double? minFlingDistance;

  /// The minimum velocity for an input pointer drag to be considered fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis. If null then [kMinFlingVelocity]
  /// is used.
  double? minFlingVelocity;

  /// Fling velocity magnitudes will be clamped to this value.
  ///
  /// If null then [kMaxFlingVelocity] is used.
  double? maxFlingVelocity;

  /// Determines the type of velocity estimation method to use for a potential
  /// drag gesture, when a new pointer is added.
  ///
  /// To estimate the velocity of a gesture, [DragGestureRecognizer] calls
  /// [velocityTrackerBuilder] when it starts to track a new pointer in
  /// [addAllowedPointer], and add subsequent updates on the pointer to the
  /// resulting velocity tracker, until the gesture recognizer stops tracking
  /// the pointer. This allows you to specify a different velocity estimation
  /// strategy for each allowed pointer added, by changing the type of velocity
  /// tracker this [GestureVelocityTrackerBuilder] returns.
  ///
  /// If left unspecified the default [velocityTrackerBuilder] creates a new
  /// [VelocityTracker] for every pointer added.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker], a velocity tracker that uses least squares estimation
  ///    on the 20 most recent pointer data samples. It's a well-rounded velocity
  ///    tracker and is used by default.
  ///  * [IOSScrollViewFlingVelocityTracker], a specialized velocity tracker for
  ///    determining the initial fling velocity for a [Scrollable] on iOS, to
  ///    match the native behavior on that platform.
  GestureVelocityTrackerBuilder velocityTrackerBuilder;

  // For shift aware.
  static bool get _isShiftPressed {
    return HardwareKeyboard.instance.logicalKeysPressed
        .any(<LogicalKeyboardKey>{
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    }.contains);
  }

  bool _isShiftTapping = false;

  // Saved DragStart state.
  DragStartDetails? _lastDragStartDetails;

  _DragState _state = _DragState.ready;
  late OffsetPair _initialPosition;
  late OffsetPair _pendingDragOffset;
  Duration? _lastPendingEventTimestamp;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;
  Matrix4? _lastTransform;

  /// Distance moved in the global coordinate space of the screen in drag direction.
  ///
  /// If drag is only allowed along a defined axis, this value may be negative to
  /// differentiate the direction of the drag.
  late double _globalDistanceMoved;

  /// Determines if a gesture is a fling or not based on velocity.
  ///
  /// A fling calls its gesture end callback with a velocity, allowing the
  /// provider of the callback to respond by carrying the gesture forward with
  /// inertia, for example.
  bool isFlingGesture(VelocityEstimate estimate, PointerDeviceKind kind);

  Offset _getDeltaForDetails(Offset delta);
  double? _getPrimaryValueFromOffset(Offset value);
  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop);

  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (_initialButtons == null) {
      switch (event.buttons) {
        case kPrimaryButton:
          if (onDown == null &&
              onStart == null &&
              onUpdate == null &&
              onEnd == null &&
              onCancel == null) {
            return false;
          }
          break;
        default:
          return false;
      }
    } else {
      // There can be multiple drags simultaneously. Their effects are combined.
      if (event.buttons != _initialButtons) {
        return false;
      }
    }
    return super.isPointerAllowed(event as PointerDownEvent);
  }

  void _addPointer(PointerEvent event) {
    _velocityTrackers[event.pointer] = velocityTrackerBuilder(event);
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
      _pendingDragOffset = OffsetPair.zero;
      _globalDistanceMoved = 0.0;
      _lastPendingEventTimestamp = event.timeStamp;
      _lastTransform = event.transform;
      _checkDown();
    } else if (_state == _DragState.accepted) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_state == _DragState.ready) {
      _initialButtons = event.buttons;
    }
    _addPointer(event);
  }

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    super.addAllowedPointerPanZoom(event);
    startTrackingPointer(event.pointer, event.transform);
    if (_state == _DragState.ready) {
      _initialButtons = kPrimaryButton;
    }
    _addPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (!event.synthesized &&
        (event is PointerDownEvent ||
            event is PointerMoveEvent ||
            event is PointerPanZoomStartEvent ||
            event is PointerPanZoomUpdateEvent)) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer]!;
      assert(tracker != null);
      if (event is PointerPanZoomStartEvent) {
        tracker.addPosition(event.timeStamp, Offset.zero);
      } else if (event is PointerPanZoomUpdateEvent) {
        tracker.addPosition(event.timeStamp, event.pan);
      } else {
        tracker.addPosition(event.timeStamp, event.localPosition);
      }
    }
    if (event is PointerMoveEvent && event.buttons != _initialButtons) {
      _giveUpPointer(event.pointer);
      return;
    }
    if (event is PointerMoveEvent || event is PointerPanZoomUpdateEvent) {
      final Offset delta = (event is PointerMoveEvent) ? event.delta : (event as PointerPanZoomUpdateEvent).panDelta;
      final Offset localDelta = (event is PointerMoveEvent) ? event.localDelta : (event as PointerPanZoomUpdateEvent).localPanDelta;
      final Offset position = (event is PointerMoveEvent) ? event.position : (event.position + (event as PointerPanZoomUpdateEvent).pan);
      final Offset localPosition = (event is PointerMoveEvent) ? event.localPosition : (event.localPosition + (event as PointerPanZoomUpdateEvent).localPan);
      if (_state == _DragState.accepted) {
        _checkUpdate(
          sourceTimeStamp: event.timeStamp,
          delta: _getDeltaForDetails(localDelta),
          primaryDelta: _getPrimaryValueFromOffset(localDelta),
          globalPosition: position,
          localPosition: localPosition,
        );
      } else {
        _pendingDragOffset += OffsetPair(local: localDelta, global: delta);
        _lastPendingEventTimestamp = event.timeStamp;
        _lastTransform = event.transform;
        final Offset movedLocally = _getDeltaForDetails(localDelta);
        final Matrix4? localToGlobalTransform = event.transform == null ? null : Matrix4.tryInvert(event.transform!);
        _globalDistanceMoved += PointerEvent.transformDeltaViaPositions(
            transform: localToGlobalTransform,
            untransformedDelta: movedLocally,
            untransformedEndPosition: localPosition
        ).distance * (_getPrimaryValueFromOffset(movedLocally) ?? 1).sign;
        if (_hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop)) {
          resolve(GestureDisposition.accepted);
        }
      }
    }
    if (event is PointerUpEvent || event is PointerCancelEvent || event is PointerPanZoomEndEvent) {
      _giveUpPointer(event.pointer);
    }
  }

  final Set<int> _acceptedActivePointers = <int>{};

  @override
  void acceptGesture(int pointer) {
    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);
    if (_state != _DragState.accepted) {
      _state = _DragState.accepted;
      final OffsetPair delta = _pendingDragOffset;
      final Duration timestamp = _lastPendingEventTimestamp!;
      final Matrix4? transform = _lastTransform;
      final Offset localUpdateDelta;
      switch (dragStartBehavior) {
        case DragStartBehavior.start:
          _initialPosition = _initialPosition + delta;
          localUpdateDelta = Offset.zero;
          break;
        case DragStartBehavior.down:
          localUpdateDelta = _getDeltaForDetails(delta.local);
          break;
      }
      _pendingDragOffset = OffsetPair.zero;
      _lastPendingEventTimestamp = null;
      _lastTransform = null;
      _checkStart(timestamp, pointer);
      if (localUpdateDelta != Offset.zero && onUpdate != null) {
        final Matrix4? localToGlobal = transform != null ? Matrix4.tryInvert(transform) : null;
        final Offset correctedLocalPosition = _initialPosition.local + localUpdateDelta;
        final Offset globalUpdateDelta = PointerEvent.transformDeltaViaPositions(
          untransformedEndPosition: correctedLocalPosition,
          untransformedDelta: localUpdateDelta,
          transform: localToGlobal,
        );
        final OffsetPair updateDelta = OffsetPair(local: localUpdateDelta, global: globalUpdateDelta);
        final OffsetPair correctedPosition = _initialPosition + updateDelta; // Only adds delta for down behaviour
        _checkUpdate(
          sourceTimeStamp: timestamp,
          delta: localUpdateDelta,
          primaryDelta: _getPrimaryValueFromOffset(localUpdateDelta),
          globalPosition: correctedPosition.global,
          localPosition: correctedPosition.local,
        );
      }
      // This acceptGesture might have been called only for one pointer, instead
      // of all pointers. Resolve all pointers to `accepted`. This won't cause
      // infinite recursion because an accepted pointer won't be accepted again.
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _giveUpPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    assert(_state != _DragState.ready);
    switch(_state) {
      case _DragState.ready:
        break;

      case _DragState.possible:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _DragState.accepted:
        _checkEnd(pointer);
        break;
    }
    _velocityTrackers.clear();
    _initialButtons = null;
    _state = _DragState.ready;
  }

  void _giveUpPointer(int pointer) {
    stopTrackingPointer(pointer);
    // If we never accepted the pointer, we reject it since we are no longer
    // interested in winning the gesture arena for it.
    if (!_acceptedActivePointers.remove(pointer)) {
      resolvePointer(pointer, GestureDisposition.rejected);
    }
  }

  void _checkDown() {
    assert(_initialButtons == kPrimaryButton);
    if (_isShiftPressed) {
      _isShiftTapping = true;
    }
    if (onDown != null) {
      final DragDownDetails details = DragDownDetails(
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
      );
      invokeCallback<void>('onDown', () => onDown!(details, _isShiftTapping));
    }
  }

  void _checkStart(Duration timestamp, int pointer) {
    assert(_initialButtons == kPrimaryButton);
    if (_isShiftPressed) {
      _isShiftTapping = true;
    }
    if (onStart != null) {
      final DragStartDetails details = DragStartDetails(
        sourceTimeStamp: timestamp,
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
        kind: getKindForPointer(pointer),
      );
      _lastDragStartDetails = details;
      invokeCallback<void>('onStart', () => onStart!(details, _isShiftTapping));
    }
  }

  void _checkUpdate({
    Duration? sourceTimeStamp,
    required Offset delta,
    double? primaryDelta,
    required Offset globalPosition,
    Offset? localPosition,
  }) {
    assert(_initialButtons == kPrimaryButton);
    if (onUpdate != null) {
      final DragUpdateDetails details = DragUpdateDetails(
        sourceTimeStamp: sourceTimeStamp,
        delta: delta,
        primaryDelta: primaryDelta,
        globalPosition: globalPosition,
        localPosition: localPosition,
      );
      invokeCallback<void>('onUpdate', () => onUpdate!(details, _lastDragStartDetails!, _isShiftTapping));
    }
  }

  void _checkEnd(int pointer) {
    assert(_initialButtons == kPrimaryButton);
    if (onEnd == null) {
      return;
    }

    final VelocityTracker tracker = _velocityTrackers[pointer]!;
    assert(tracker != null);

    final DragEndDetails details;
    final String Function() debugReport;

    final VelocityEstimate? estimate = tracker.getVelocityEstimate();
    if (estimate != null && isFlingGesture(estimate, tracker.kind)) {
      final Velocity velocity = Velocity(pixelsPerSecond: estimate.pixelsPerSecond)
          .clampMagnitude(minFlingVelocity ?? kMinFlingVelocity, maxFlingVelocity ?? kMaxFlingVelocity);
      details = DragEndDetails(
        velocity: velocity,
        primaryVelocity: _getPrimaryValueFromOffset(velocity.pixelsPerSecond),
      );
      debugReport = () {
        return '$estimate; fling at $velocity.';
      };
    } else {
      details = DragEndDetails(
        primaryVelocity: 0.0,
      );
      debugReport = () {
        if (estimate == null) {
          return 'Could not estimate velocity.';
        }
        return '$estimate; judged to not be a fling.';
      };
    }
    invokeCallback<void>('onEnd', () => onEnd!(details, _isShiftTapping), debugReport: debugReport);
    _isShiftTapping = false;
    _lastDragStartDetails = null;
  }

  void _checkCancel() {
    assert(_initialButtons == kPrimaryButton);
    if (onCancel != null) {
      invokeCallback<void>('onCancel', onCancel!);
    }
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<DragStartBehavior>('start behavior', dragStartBehavior));
  }
}

/// Recognizes movement both horizontally and vertically.
///
/// See also:
///
///  * [PanGestureRecognizer], for a similar recognizer that
///    is not shift aware.
class ShiftAwarePanGestureRecognizer extends ShiftAwareDragGestureRecognizer {
  /// Create a gesture recognizer for tracking movement on a plane.
  ShiftAwarePanGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  });

  @override
  bool isFlingGesture(VelocityEstimate estimate, PointerDeviceKind kind) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? computeHitSlop(kind, gestureSettings);
    return estimate.pixelsPerSecond.distanceSquared > minVelocity * minVelocity
        && estimate.offset.distanceSquared > minDistance * minDistance;
  }

  @override
  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() > computePanSlop(pointerDeviceKind, gestureSettings);
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => delta;

  @override
  double? _getPrimaryValueFromOffset(Offset value) => null;

  @override
  String get debugDescription => 'pan';
}

/// Custom [SelectionGesturesManager] example, that logs the [PointerEvent]s.
class LoggingSelectionGesturesManager extends SelectionGesturesManager {
  @override
  void handlePointerDown(BuildContext context, PointerDownEvent event, Map<Type, GestureRecognizer> recognizers) {
    for(GestureRecognizer recognizer in recognizers.values) {
      if (recognizer.isPointerAllowed(event)) {
        print('Handled text selection gesture $recognizer $event in $context');
      }
    }
    super.handlePointerDown(context, event, recognizers);
  }
}