// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import 'animation.dart';
import 'animation_style.dart';
import 'curves.dart';
import 'listener_helpers.dart';

export 'package:flutter/physics.dart' show Simulation, SpringDescription;
export 'package:flutter/scheduler.dart' show TickerFuture, TickerProvider;

export 'animation.dart' show Animation, AnimationStatus;
export 'curves.dart' show Curve;

// Examples can assume:
// late AnimationController _controller, fadeAnimationController, sizeAnimationController;
// late bool dismissed;
// void setState(VoidCallback fn) { }

/// The direction in which an animation is running.
enum _AnimationDirection {
  /// The animation is running from beginning to end.
  forward,

  /// The animation is running backwards, from end to beginning.
  reverse,
}

final SpringDescription _kFlingSpringDescription = SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 500.0,
);

const Tolerance _kFlingTolerance = Tolerance(
  velocity: double.infinity,
  distance: 0.01,
);

/// Configures how an [AnimationController] behaves when animations are
/// disabled.
///
/// When [AccessibilityFeatures.disableAnimations] is true, the device is asking
/// Flutter to reduce or disable animations as much as possible. To honor this,
/// we reduce the duration and the corresponding number of frames for
/// animations. This enum is used to allow certain [AnimationController]s to opt
/// out of this behavior.
///
/// For example, the [AnimationController] which controls the physics simulation
/// for a scrollable list will have [AnimationBehavior.preserve], so that when
/// a user attempts to scroll it does not jump to the end/beginning too quickly.
enum AnimationBehavior {
  /// The [AnimationController] will reduce its duration when
  /// [AccessibilityFeatures.disableAnimations] is true.
  normal,

  /// The [AnimationController] will preserve its behavior.
  ///
  /// This is the default for repeating animations in order to prevent them from
  /// flashing rapidly on the screen if the widget does not take the
  /// [AccessibilityFeatures.disableAnimations] flag into account.
  preserve;

  /// Whether animations should be enabled, based on the configured behavior
  /// and the [AccessibilityFeatures.disableAnimations] flag.
  bool get enableAnimations => switch (this) {
    normal   => !SemanticsBinding.instance.disableAnimations,
    preserve => true,
  };
}

/// An object that drives [Animation]s.
///
/// This class provides a shared interface for [AnimationController] and
/// [ValueAnimation], and manages the lifecycle of their [Ticker].
///
/// Typically an animator is of the type `Animation<double>`,
/// but a [ValueAnimation] can be used for a variety of types that define a
/// [LerpCallback], including [Color],  and [EdgeInsets].
///
/// The `Animator` itself can be used as an animation
abstract class Animator<AnimationType, ThisType> extends Animation<AnimationType>
with AnimationEagerListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin
implements StyledAnimation<AnimationType> {
  /// Initializes the [Ticker] for subclasses.
  Animator({
    required TickerProvider vsync,
    Curve? curve,
    Duration? duration,
    Curve? reverseCurve,
    Duration? reverseDuration,
    this.animationBehavior = AnimationBehavior.normal,
    this.debugLabel,
  }) : _curve = curve,
       _duration = duration,
       _reverseCurve = reverseCurve,
       _reverseDuration = reverseDuration {
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/animation.dart',
        className: '$ThisType',
        object: this,
      );
    }
    _ticker = vsync.createTicker(_tick);
    if (vsync is AnimationProvider) {
      vsync.registerAnimation(this);
    }
  }

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [AnimationController.unbounded] constructor.
  final AnimationBehavior animationBehavior;

  Ticker? _ticker;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick)..absorbTicker(oldTicker);
  }

  /// Whether this animator is currently animating in either the forward or reverse direction.
  ///
  /// This is separate from whether it is actively ticking. An animator's
  /// ticker might get muted, in which case its callbacks will no longer fire
  /// even though time is continuing to pass. See [Ticker.muted] and [TickerMode].
  ///
  /// If the animator was stopped (e.g. with [stop] or by setting a new [value]),
  /// [isAnimating] will return `false` but the [status] will not change,
  /// so the value of [AnimationStatus.isAnimating] might still be `true`.
  @override
  bool get isAnimating => _ticker?.isActive ?? false;

  /// Defines the [TickerCallback] used by this animation's [Ticker].
  @protected
  void _tick(Duration elapsed);

  /// {@template flutter.animation.Animator.stop}
  /// Stops running this animation.
  ///
  /// This does not trigger any notifications. The animation stops in its
  /// current state.
  ///
  /// By default, the most recently returned [TickerFuture] is marked as having
  /// been canceled, meaning the future never completes and its
  /// [TickerFuture.orCancel] derivative future completes with a [TickerCanceled]
  /// error. By passing the `canceled` argument with the value false, this is
  /// reversed, and the futures complete successfully.
  /// {@endtemplate}
  @mustCallSuper
  void stop({ bool canceled = true }) {
    assert(debugCheckNotDisposed('stop'));
    _ticker!.stop(canceled: canceled);
  }

  /// The curve to use for [animateTo].
  ///
  /// Defaults to the [AnimationStyle.fallbackCurve].
  Curve get curve => _curve ?? _style.curve ?? AnimationStyle.fallbackCurve;
  Curve? _curve;
  set curve(Curve? value) {
    _curve = value;
  }

  /// The length of time this animation should last.
  ///
  /// If [reverseDuration] is specified, then [duration] is only used when going
  /// forward. Otherwise, it specifies the duration going in both directions.
  Duration get duration => _duration ?? _style.duration ?? AnimationStyle.fallbackDuration;
  Duration? _duration;
  set duration(Duration? value) {
    _duration = value;
  }

  /// The curve to use for [animateBack].
  ///
  /// Defaults to the [AnimationStyle.fallbackCurve].
  Curve get reverseCurve => _reverseCurve ?? _style.reverseCurve ?? AnimationStyle.fallbackCurve;
  Curve? _reverseCurve;
  set reverseCurve(Curve? value) {
    _reverseCurve = value;
  }

  /// The length of time this animation should last when going in reverse.
  ///
  /// The value of [duration] is used if [reverseDuration] is not specified or
  /// set to null.
  Duration get reverseDuration => _reverseDuration ?? _duration ?? _style.reverseDuration ?? AnimationStyle.fallbackDuration;
  Duration? _reverseDuration;
  set reverseDuration(Duration? value) {
    _reverseDuration = value;
  }

  AnimationStyle _style = const AnimationStyle();

  @override
  void updateStyle(AnimationStyle newStyle) => _style = newStyle;

  /// Animate from one value to another, in a "forward direction".
  ///
  /// {@template flutter.animation.Animator.ticker_canceled}
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  /// {@endtemplate}
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse]
  /// regardless of whether `target` < [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.dismissed].
  ///
  /// If the `target` argument is the same as the current [value] of the
  /// animation, then this won't animate, and the returned [TickerFuture] will
  /// be already complete.
  TickerFuture animateTo(AnimationType target, {AnimationType? from, Duration? duration, Curve? curve});

  /// Animate from one value to another, in a "backward direction".
  ///
  /// The [status] will be [AnimationStatus.reverse] while the transition is
  /// in progress and [AnimationStatus.dismissed] when it ends.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse]
  /// regardless of whether `target` < [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.dismissed].
  ///
  /// If the `target` argument is the same as the current [value] of the
  /// animation, then this won't animate, and the returned [TickerFuture] will
  /// be already complete.
  TickerFuture animateBack(AnimationType target, {AnimationType? from, Duration? duration, Curve? curve});

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$ThisType.dispose() called more than once.'),
          ErrorDescription('A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<ThisType>(
            'The following $runtimeType object was disposed multiple times',
            this as ThisType,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _ticker!.dispose();
    _ticker = null;
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }

  /// In debug mode, throws an assertion error if this animator's [dispose] method
  /// has been called.
  @protected
  bool debugCheckNotDisposed(String methodName) {
    assert(
      _ticker != null,
      '$ThisType.$methodName() called after $ThisType.dispose()\n'
      '$ThisType methods should not be used after calling dispose.',
    );
    return true;
  }

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying animator instances in debug output.
  final String? debugLabel;

  @override
  String toStringDetails() {
    final String value = switch (this.value) {
      final double number => number.toStringAsFixed(3),
      _                   => this.value.toString(),
    };
    final String paused = isAnimating ? '' : '; paused';
    final String ticker = _ticker == null ? '; DISPOSED' : (_ticker!.muted ? '; silenced' : '');
    String label = '';
    assert(() {
      if (debugLabel != null) {
        label = '; for $debugLabel';
      }
      return true;
    }());
    return '${super.toStringDetails()} $value$paused$ticker$label';
  }
}

/// A controller for an animation.
///
/// This class lets you perform tasks such as:
///
/// * Play an animation [forward] or in [reverse], or [stop] an animation.
/// * Set the animation to a specific [value].
/// * Define the [upperBound] and [lowerBound] values of an animation.
/// * Create a [fling] animation effect using a physics simulation.
///
/// By default, an [AnimationController] linearly produces values that range
/// from 0.0 to 1.0, during a given duration.
///
/// When the animation is actively animating, the animation controller generates
/// a new value each time the device running your app is ready to display a new
/// frame (typically, this rate is around 60–120 values per second).
/// If the animation controller is associated with a [State]
/// through a [TickerProvider], then its updates will be silenced when that
/// [State]'s subtree is disabled as defined by [TickerMode]; time will still
/// elapse, and methods like [forward] and [stop] can still be called and
/// will change the value, but the controller will not generate new values
/// on its own.
///
/// ## Ticker providers
///
/// An [AnimationController] needs a [TickerProvider], which is configured using
/// the `vsync` argument on the constructor.
/// The constructor uses the [TickerProvider] to create a [Ticker], which
/// the [AnimationController] uses to step through the animation it controls.
///
/// For advice on obtaining a ticker provider, see [TickerProvider].
/// Typically the relevant [State] serves as the ticker provider,
/// after applying a suitable mixin (like [SingleTickerProviderStateMixin])
/// to cause the [State] subclass to implement [TickerProvider].
///
/// ## Life cycle
///
/// An [AnimationController] should be [dispose]d when it is no longer needed.
/// This reduces the likelihood of leaks. When used with a [StatefulWidget], it
/// is common for an [AnimationController] to be created in the
/// [State.initState] method and then disposed in the [State.dispose] method.
///
/// ## Using [Future]s with [AnimationController]
///
/// The methods that start animations return a [TickerFuture] object which
/// completes when the animation completes successfully, and never throws an
/// error; if the animation is canceled, the future never completes. This object
/// also has a [TickerFuture.orCancel] property which returns a future that
/// completes when the animation completes successfully, and completes with an
/// error when the animation is aborted.
///
/// This can be used to write code such as the `fadeOutAndUpdateState` method
/// below.
///
/// {@tool snippet}
///
/// Here is a stateful `Foo` widget. Its [State] uses the
/// [SingleTickerProviderStateMixin] to implement the necessary
/// [TickerProvider], creating its controller in the [State.initState] method
/// and disposing of it in the [State.dispose] method. The duration of the
/// controller is configured from a property in the `Foo` widget; as that
/// changes, the [State.didUpdateWidget] method is used to update the
/// controller.
///
/// ```dart
/// class Foo extends StatefulWidget {
///   const Foo({ super.key, required this.duration });
///
///   final Duration duration;
///
///   @override
///   State<Foo> createState() => _FooState();
/// }
///
/// class _FooState extends State<Foo> with SingleTickerProviderStateMixin {
///   late AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(
///       vsync: this, // the SingleTickerProviderStateMixin
///       duration: widget.duration,
///     );
///   }
///
///   @override
///   void didUpdateWidget(Foo oldWidget) {
///     super.didUpdateWidget(oldWidget);
///     _controller.duration = widget.duration;
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(); // ...
///   }
/// }
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// The following method (for a [State] subclass) drives two animation
/// controllers using Dart's asynchronous syntax for awaiting [Future] objects:
///
/// ```dart
/// Future<void> fadeOutAndUpdateState() async {
///   try {
///     await fadeAnimationController.forward().orCancel;
///     await sizeAnimationController.forward().orCancel;
///     setState(() {
///       dismissed = true;
///     });
///   } on TickerCanceled {
///     // the animation got canceled, probably because we were disposed
///   }
/// }
/// ```
/// {@end-tool}
///
/// The assumption in the code above is that the animation controllers are being
/// disposed in the [State] subclass' override of the [State.dispose] method.
/// Since disposing the controller cancels the animation (raising a
/// [TickerCanceled] exception), the code here can skip verifying whether
/// [State.mounted] is still true at each step. (Again, this assumes that the
/// controllers are created in [State.initState] and disposed in
/// [State.dispose], as described in the previous section.)
///
/// {@tool dartpad}
/// This example shows how to use [AnimationController] and
/// [SlideTransition] to create an animated digit like you might find
/// on an old pinball machine our your car's odometer.  New digit
/// values slide into place from below, as the old value slides
/// upwards and out of view. Taps that occur while the controller is
/// already animating cause the controller's
/// [AnimationController.duration] to be reduced so that the visuals
/// don't fall behind.
///
/// ** See code in examples/api/lib/animation/animation_controller/animated_digit.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Tween], the base class for converting an [AnimationController] to a
///    range of values of other types.
class AnimationController extends Animator<double, AnimationController> {
  /// Creates an animation controller.
  ///
  /// * `value` is the initial value of the animation. If defaults to the lower
  ///   bound.
  ///
  /// * [duration] is the length of time this animation should last.
  ///
  /// * [debugLabel] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * [lowerBound] is the smallest value this animation can obtain and the
  ///   value at which this animation is deemed to be dismissed.
  ///
  /// * [upperBound] is the largest value this animation can obtain and the
  ///   value at which this animation is deemed to be completed.
  ///
  /// * `vsync` is the required [TickerProvider] for the current context. It can
  ///   be changed by calling [resync]. See [TickerProvider] for advice on
  ///   obtaining a ticker provider.
  AnimationController({
    required super.vsync,
    double? value,
    super.curve,
    super.duration,
    super.reverseCurve,
    super.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    super.animationBehavior,
    super.debugLabel,
  }) : assert(upperBound >= lowerBound) {
    _internalSetValue(value ?? lowerBound);
  }

  /// Creates an animation controller with no upper or lower bound for its
  /// value.
  ///
  /// * [value] is the initial value of the animation.
  ///
  /// * [duration] is the length of time this animation should last.
  ///
  /// * [debugLabel] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * `vsync` is the required [TickerProvider] for the current context. It can
  ///   be changed by calling [resync]. See [TickerProvider] for advice on
  ///   obtaining a ticker provider.
  ///
  /// This constructor is most useful for animations that will be driven using a
  /// physics simulation, especially when the physics simulation has no
  /// pre-determined bounds.
  AnimationController.unbounded({
    required super.vsync,
    double value = 0.0,
    super.curve,
    super.duration,
    super.reverseCurve,
    super.reverseDuration,
    super.animationBehavior = AnimationBehavior.preserve,
    super.debugLabel,
  }) : lowerBound = double.negativeInfinity,
       upperBound = double.infinity {
    _internalSetValue(value);
  }

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// Returns an [Animation<double>] for this animation controller, so that a
  /// pointer to this object can be passed around without allowing users of that
  /// pointer to mutate the [AnimationController] state.
  Animation<double> get view => this;

  Simulation? _simulation;

  /// The current value of the animation.
  ///
  /// Setting this value notifies all the listeners that the value
  /// changed.
  ///
  /// Setting this value also stops the controller if it is currently
  /// running; if this happens, it also notifies all the status
  /// listeners.
  @override
  double get value => _value;
  late double _value;
  /// Stops the animation controller and sets the current value of the
  /// animation.
  ///
  /// The new value is clamped to the range set by [lowerBound] and
  /// [upperBound].
  ///
  /// Value listeners are notified even if this does not change the value.
  /// Status listeners are notified if the animation was previously playing.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  ///
  /// See also:
  ///
  ///  * [reset], which is equivalent to setting [value] to [lowerBound].
  ///  * [stop], which aborts the animation without changing its value or status
  ///    and without dispatching any notifications other than completing or
  ///    canceling the [TickerFuture].
  ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
  ///    which start the animation controller.
  set value(double newValue) {
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  /// Sets the controller's value to [lowerBound], stopping the animation (if
  /// in progress), and resetting to its beginning point, or dismissed state.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  ///
  /// See also:
  ///
  ///  * [value], which can be explicitly set to a specific value as desired.
  ///  * [forward], which starts the animation in the forward direction.
  ///  * [stop], which aborts the animation without changing its value or status
  ///    and without dispatching any notifications other than completing or
  ///    canceling the [TickerFuture].
  void reset() {
    value = lowerBound;
  }

  /// The rate of change of [value] per second.
  ///
  /// If [isAnimating] is false, then [value] is not changing and the rate of
  /// change is zero.
  double get velocity {
    if (!isAnimating) {
      return 0.0;
    }
    return _simulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() / Duration.microsecondsPerSecond);
  }

  void _internalSetValue(double newValue) {
    _value = clampDouble(newValue, lowerBound, upperBound);
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = switch (_direction) {
        _AnimationDirection.forward => AnimationStatus.forward,
        _AnimationDirection.reverse => AnimationStatus.reverse,
      };
    }
  }

  /// The amount of time that has passed between the time the animation started
  /// and the most recent tick of the animation.
  ///
  /// If the controller is not animating, the last elapsed duration is null.
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  _AnimationDirection _direction = _AnimationDirection.forward;

  @override
  AnimationStatus get status => _status;
  late AnimationStatus _status;

  /// Starts running this animation forwards (towards the end).
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  ///
  /// During the animation, [status] is reported as [AnimationStatus.forward],
  /// which switches to [AnimationStatus.completed] when [upperBound] is
  /// reached at the end of the animation.
  TickerFuture forward({ double? from }) {
    assert(debugCheckNotDisposed('forward'));
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(upperBound);
  }

  /// Starts running this animation in reverse (towards the beginning).
  ///
  /// Returns a [TickerFuture] that completes when the animation is dismissed.
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse],
  /// which switches to [AnimationStatus.dismissed] when [lowerBound] is
  /// reached at the end of the animation.
  TickerFuture reverse({ double? from }) {
    assert(debugCheckNotDisposed('reverse'));
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(lowerBound);
  }

  /// Toggles the direction of this animation, based on whether it [isForwardOrCompleted].
  ///
  /// Specifically, this function acts the same way as [reverse] if the [status] is
  /// either [AnimationStatus.forward] or [AnimationStatus.completed], and acts as
  /// [forward] for [AnimationStatus.reverse] or [AnimationStatus.dismissed].
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  TickerFuture toggle({ double? from }) {
    assert(debugCheckNotDisposed('toggle'));
    _direction = isForwardOrCompleted ? _AnimationDirection.reverse : _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(
      switch (_direction) {
        _AnimationDirection.forward => upperBound,
        _AnimationDirection.reverse => lowerBound,
      },
      from: from,
    );
  }

  @override
  TickerFuture animateTo(double target, {double? from, Duration? duration, Curve? curve}) {
    assert(debugCheckNotDisposed('animateTo'));
    _direction = _AnimationDirection.forward;
    return _animateToInternal(target, from: from, duration: duration, curve: curve);
  }

  @override
  TickerFuture animateBack(double target, {double? from, Duration? duration, Curve? curve}) {
    assert(debugCheckNotDisposed('animateBack'));
    _direction = _AnimationDirection.reverse;
    return _animateToInternal(target, from: from, duration: duration, curve: curve);
  }

  TickerFuture _animateToInternal(double target, {double? from, Duration? duration, Curve? curve}) {
    if (from != null) {
      value = from;
    }
    // Ideally, the framework would be able to handle zero duration animations;
    // however, the common pattern of an eternally repeating animation might
    // cause an endless loop if it weren't delayed for at least one frame.
    // Consequently, we run the animation at 5% of the normal duration to
    // limit most animations to a single frame.
    final double scale = animationBehavior.enableAnimations ? 1.0 : 0.05;
    Duration? simulationDuration = duration;
    if (simulationDuration == null) {
      final double range = upperBound - lowerBound;
      final double remainingFraction = range.isFinite ? (target - _value).abs() / range : 1.0;
      final Duration directionDuration =
          _direction == _AnimationDirection.reverse
              ? reverseDuration
              : this.duration;
      simulationDuration = directionDuration * remainingFraction;
    } else if (target == value) {
      // Already at target, don't animate.
      simulationDuration = Duration.zero;
    }
    stop();
    if (simulationDuration == Duration.zero) {
      if (value != target) {
        _value = clampDouble(target, lowerBound, upperBound);
        notifyListeners();
      }
      _status = (_direction == _AnimationDirection.forward) ?
        AnimationStatus.completed :
        AnimationStatus.dismissed;
      _checkStatusChanged();
      return TickerFuture.complete();
    }
    assert(simulationDuration > Duration.zero);
    assert(!isAnimating);
    return _startSimulation(
      _InterpolationSimulation(_value, target, simulationDuration, curve ?? Curves.linear, scale),
    );
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  ///
  /// Defaults to repeating between the [lowerBound] and [upperBound] of the
  /// [AnimationController] when no explicit value is set for [min] and [max].
  ///
  /// With [reverse] set to true, instead of always starting over at [min]
  /// the starting value will alternate between [min] and [max] values on each
  /// repeat. The [status] will be reported as [AnimationStatus.reverse] when
  /// the animation runs from [max] to [min].
  ///
  /// Each run of the animation will have a duration of `period`. If `period` is not
  /// provided, [duration] will be used instead, which has to be set before [repeat] is
  /// called either in the constructor or later by using the [duration] setter.
  ///
  /// If a value is passed to [count], the animation will perform that many
  /// iterations before stopping. Otherwise, the animation repeats indefinitely.
  ///
  /// Returns a [TickerFuture] that never completes, unless a [count] is specified.
  /// The [TickerFuture.orCancel] future completes with an error when the animation is
  /// stopped (e.g. with [stop]).
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;
    assert(() {
      if (period == null) {
        throw FlutterError(
          'AnimationController.repeat() called without an explicit period and with no default Duration.\n'
          'Either the "period" argument to the repeat() method should be provided, or the '
          '"duration" property should be set, either in the constructor or later, before '
          'calling the repeat() function.',
        );
      }
      return true;
    }());
    assert(debugCheckNotDisposed('stop'));
    assert(max >= min);
    assert(max <= upperBound && min >= lowerBound);
    assert(count == null || count > 0, 'Count shall be greater than zero if not null');
    stop();
    return _startSimulation(_RepeatingSimulation(_value, min, max, reverse, period, _directionSetter, count));
  }

  void _directionSetter(_AnimationDirection direction) {
    _direction = direction;
    _status = (_direction == _AnimationDirection.forward) ?
      AnimationStatus.forward :
      AnimationStatus.reverse;
    _checkStatusChanged();
  }

  /// Drives the animation with a spring (within [lowerBound] and [upperBound])
  /// and initial velocity.
  ///
  /// If velocity is positive, the animation will complete, otherwise it will
  /// dismiss. The velocity is specified in units per second. If the
  /// [SemanticsBinding.disableAnimations] flag is set, the velocity is somewhat
  /// arbitrarily multiplied by 200.
  ///
  /// The [springDescription] parameter can be used to specify a custom
  /// [SpringType.criticallyDamped] or [SpringType.overDamped] spring with which
  /// to drive the animation. By default, a [SpringType.criticallyDamped] spring
  /// is used. See [SpringDescription.withDampingRatio] for how to create a
  /// suitable [SpringDescription].
  ///
  /// The resulting spring simulation cannot be of type [SpringType.underDamped];
  /// such a spring would oscillate rather than fling.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  TickerFuture fling({ double velocity = 1.0, SpringDescription? springDescription, AnimationBehavior? animationBehavior }) {
    springDescription ??= _kFlingSpringDescription;
    _direction = velocity < 0.0 ? _AnimationDirection.reverse : _AnimationDirection.forward;
    final double target = velocity < 0.0 ? lowerBound - _kFlingTolerance.distance
                                         : upperBound + _kFlingTolerance.distance;
    final AnimationBehavior behavior = animationBehavior ?? this.animationBehavior;
    // This is arbitrary (it was chosen because it worked for the drawer widget).
    final double scale = behavior.enableAnimations ? 1.0 : 200.0;
    final SpringSimulation simulation = SpringSimulation(springDescription, value, target, velocity * scale)
      ..tolerance = _kFlingTolerance;
    assert(
      simulation.type != SpringType.underDamped,
      'The specified spring simulation is of type SpringType.underDamped.\n'
      'An underdamped spring results in oscillation rather than a fling. '
      'Consider specifying a different springDescription, or use animateWith() '
      'with an explicit SpringSimulation if an underdamped spring is intentional.',
    );
    stop();
    return _startSimulation(simulation);
  }

  /// Drives the animation according to the given simulation.
  ///
  /// {@template flutter.animation.AnimationController.animateWith}
  /// The values from the simulation are clamped to the [lowerBound] and
  /// [upperBound]. To avoid this, consider creating the [AnimationController]
  /// using the [AnimationController.unbounded] constructor.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  /// {@endtemplate}
  ///
  /// {@macro flutter.animation.AnimationController.ticker_canceled}
  ///
  /// The [status] is always [AnimationStatus.forward] for the entire duration
  /// of the simulation.
  ///
  /// See also:
  ///
  ///  * [animateBackWith], which is like this method but the status is always
  ///    [AnimationStatus.reverse].
  TickerFuture animateWith(Simulation simulation) {
    assert(
      _ticker != null,
      'AnimationController.animateWith() called after AnimationController.dispose()\n'
      'AnimationController methods should not be used after calling dispose.',
    );
    stop();
    _direction = _AnimationDirection.forward;
    return _startSimulation(simulation);
  }

  /// Drives the animation according to the given simulation with a [status] of
  /// [AnimationStatus.reverse].
  ///
  /// {@macro flutter.animation.AnimationController.animateWith}
  ///
  /// {@macro flutter.animation.AnimationController.ticker_canceled}
  ///
  /// The [status] is always [AnimationStatus.reverse] for the entire duration
  /// of the simulation.
  ///
  /// See also:
  ///
  ///  * [animateWith], which is like this method but the status is always
  ///    [AnimationStatus.forward].
  TickerFuture animateBackWith(Simulation simulation) {
    assert(
      _ticker != null,
      'AnimationController.animateWith() called after AnimationController.dispose()\n'
      'AnimationController methods should not be used after calling dispose.',
    );
    stop();
    _direction = _AnimationDirection.reverse;
    return _startSimulation(simulation);
  }

  TickerFuture _startSimulation(Simulation simulation) {
    assert(!isAnimating);
    _simulation = simulation;
    _lastElapsedDuration = Duration.zero;
    _value = clampDouble(simulation.x(0.0), lowerBound, upperBound);
    final TickerFuture result = _ticker!.start();
    _status = (_direction == _AnimationDirection.forward) ?
      AnimationStatus.forward :
      AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  /// {@macro flutter.animation.Animator.stop}
  ///
  /// See also:
  ///
  ///  * [reset], which stops the animation and resets it to the [lowerBound],
  ///    and which does send notifications.
  ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
  ///    which restart the animation controller.
  @override
  void stop({bool canceled = true}) {
    super.stop(canceled: canceled);
    _simulation = null;
    _lastElapsedDuration = null;
  }

  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    final AnimationStatus newStatus = status;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  @protected
  @override
  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double elapsedInSeconds = elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);
    _value = clampDouble(_simulation!.x(elapsedInSeconds), lowerBound, upperBound);
    if (_simulation!.isDone(elapsedInSeconds)) {
      _status = (_direction == _AnimationDirection.forward) ?
        AnimationStatus.completed :
        AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }
}

class _InterpolationSimulation extends Simulation {
  _InterpolationSimulation(this._begin, this._end, Duration duration, this._curve, double scale)
    : assert(duration.inMicroseconds > 0),
      _durationInSeconds = (duration.inMicroseconds * scale) / Duration.microsecondsPerSecond;

  final double _durationInSeconds;
  final double _begin;
  final double _end;
  final Curve _curve;

  @override
  double x(double timeInSeconds) {
    final double t = clampDouble(timeInSeconds / _durationInSeconds, 0.0, 1.0);
    return switch (t) {
      0.0 => _begin,
      1.0 => _end,
      _ => _begin + (_end - _begin) * _curve.transform(t),
    };
  }

  @override
  double dx(double timeInSeconds) {
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) / (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

typedef _DirectionSetter = void Function(_AnimationDirection direction);

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(
    double initialValue,
    this.min,
    this.max,
    this.reverse,
    Duration period,
    this.directionSetter,
    this.count,
  )  : assert(
          count == null || count > 0,
          'Count shall be greater than zero if not null',
        ),
        _periodInSeconds = period.inMicroseconds / Duration.microsecondsPerSecond,
        _initialT = (max == min) ? 0.0 : ((clampDouble(initialValue, min, max) - min) / (max - min)) * (period.inMicroseconds / Duration.microsecondsPerSecond) {
    assert(_periodInSeconds > 0.0);
    assert(_initialT >= 0.0);
  }

  final double min;
  final double max;
  final bool reverse;
  final int? count;
  final _DirectionSetter directionSetter;

  final double _periodInSeconds;
  final double _initialT;

  late final double _exitTimeInSeconds = (count! * _periodInSeconds) - _initialT;

  @override
  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);

    final double totalTimeInSeconds = timeInSeconds + _initialT;
    final double t = (totalTimeInSeconds / _periodInSeconds) % 1.0;
    final bool isPlayingReverse = (totalTimeInSeconds ~/ _periodInSeconds).isOdd;

    if (reverse && isPlayingReverse) {
      directionSetter(_AnimationDirection.reverse);
      return ui.lerpDouble(max, min, t)!;
    } else {
      directionSetter(_AnimationDirection.forward);
      return ui.lerpDouble(min, max, t)!;
    }
  }

  @override
  double dx(double timeInSeconds) => (max - min) / _periodInSeconds;

  @override
  bool isDone(double timeInSeconds) {
    // if [timeInSeconds] elapsed the [_exitTimeInSeconds] && [count] is not null,
    // consider marking the simulation as "DONE"
    return count != null && (timeInSeconds >= _exitTimeInSeconds);
  }
}

/// Function signature for linear interpolation.
///
/// This signature is designed to match existing "lerp" functions;
/// for example, [Color.lerp] can qualify as a `LerpCallback<Color>`
/// or `LerpCallback<Color?>`.
typedef LerpCallback<T> = T? Function(T a, T b, double t);

/// A [ValueListenable] whose [value] updates each frame
/// over the specified [duration] to create a continuous visual transition.
class ValueAnimationBase<T> extends Animator<T, ValueAnimationBase<T>> {
  /// Creates a [ValueListenable] that smoothly animates between values.
  ///
  /// {@macro flutter.animation.ValueAnimation.value_setter}
  ValueAnimationBase.lerpWith({
    required AnimationProvider super.vsync,
    required T initialValue,
    super.duration,
    super.curve,
    required this.lerp,
    super.animationBehavior,
    super.debugLabel
  }) : _from = initialValue,
       _target = initialValue,
       _value = initialValue;

  /// A function to use for linear interpolation between [value]s.
  ///
  /// {@tool snippet}
  /// Rather than creating a [LerpCallback] for the animation, consider
  /// using the predefined function for that type. For example, [Color.lerp]
  /// can be used for a `ValueAnimation<Color>`.
  ///
  /// ```dart
  /// class _MyState extends State<StatefulWidget> with SingleTickerProviderMixin {
  ///   late final ValueAnimation<Color> colorAnimation = ValueAnimation<Color>(
  ///     tickerProvider: this,
  ///     initialValue: Colors.black,
  ///     duration: Durations.medium1,
  ///     lerp: Color.lerp,
  ///   );
  ///
  ///   // ...
  /// }
  /// ```
  /// {@end-tool}
  final LerpCallback<T> lerp;

  T _from;
  T _target;
  T _value;

  @override
  T get value => _value;

  /// {@template flutter.animation.ValueAnimation.value_setter}
  /// Rather than updating immediately, changes to the [value] will *animate*
  /// each time a new target is set, using the provided [duration], [curve],
  /// and [lerp] callback.
  /// {@endtemplate}
  ///
  /// To cause an immediate change to the value, consider calling [animateTo]
  /// or [animateBack] with a non-null `from` parameter, or calling [jumpTo].
  set value(T newTarget) {
    animateTo(newTarget);
  }

  TickerFuture _animate(
    T target, {
    T? from,
    Duration? duration,
    Curve? curve,
    required _AnimationDirection direction,
  }) {
    stop();

    if (duration != null) {
      this.duration = duration;
    }
    if (curve != null) {
      this.curve = curve;
    }
    if (from == null && target == value) {
      return TickerFuture.complete();
    }
    if (this.duration == Duration.zero || !animationBehavior.enableAnimations) {
      value = target;
      _statusUpdate(AnimationStatus.completed);
      return TickerFuture.complete();
    }

    _from = from ?? value;
    _target = target;
    _value = lerp(_from, _target, 0) as T;
    final TickerFuture result = _ticker!.start();
    _statusUpdate(switch (direction) {
      _AnimationDirection.forward => AnimationStatus.forward,
      _AnimationDirection.reverse => AnimationStatus.reverse,
    });
    return result;
  }

  @override
  TickerFuture animateTo(T target, {T? from, Duration? duration, Curve? curve}) {
    assert(debugCheckNotDisposed('animateTo'));
    return _animate(
      target,
      from: from,
      duration: duration,
      curve: curve,
      direction: _AnimationDirection.forward,
    );
  }

  @override
  TickerFuture animateBack(T target, {T? from, Duration? duration, Curve? curve}) {
    assert(debugCheckNotDisposed('animateBack'));
    return _animate(
      target,
      from: from,
      duration: duration,
      curve: curve,
      direction: _AnimationDirection.reverse,
    );
  }

  /// Immediately set a new value.
  ///
  /// {@macro flutter.animation.Animator.ticker_canceled}
  void jumpTo(T target) {
    stop();
    _from = _value = _target = target;
    notifyListeners();
  }

  @protected
  @override
  void _tick(Duration elapsed) {
    late final double progress = elapsed.inMicroseconds / duration.inMicroseconds;

    if (_value == _target || progress >= 1.0) {
      _value = _target;
      _statusUpdate(AnimationStatus.completed);
      stop(canceled: false);
    } else {
      final double t = curve.transform(math.max(progress, 0.0));
      _value = lerp(_from, _target, t) as T;
    }
    notifyListeners();
  }

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status = AnimationStatus.dismissed;
  void _statusUpdate(AnimationStatus value) {
    if (value == _status) {
      return;
    }
    _status = value;
    notifyStatusListeners(value);
  }
}
