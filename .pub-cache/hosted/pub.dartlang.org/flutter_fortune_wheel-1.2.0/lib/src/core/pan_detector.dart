part of 'core.dart';

/// A class representing the current state of a [PanAwareBuilder].
///
/// See also:
///  * [PanPhysics], a base class for implementing pan behavior
@immutable
class PanState {
  /// Is set to true if a user is currently panning on the screen.
  final bool isPanning;

  /// The distance traveled in pixels since panning started.
  final double distance;

  /// Is set to true if panning resulted in a fling gesture.
  final bool wasFlung;

  const PanState({
    this.distance = 0.0,
    this.isPanning = false,
    this.wasFlung = false,
  });

  /// Returns a copy of this [PanState] instance updated with the given values.
  PanState copyWith({
    bool? isPanning,
    double? distance,
    bool? wasFlung,
  }) =>
      PanState(
        distance: distance ?? this.distance,
        isPanning: isPanning ?? this.isPanning,
        wasFlung: wasFlung ?? this.wasFlung,
      );

  @override
  int get hashCode => hash3(distance, isPanning, wasFlung);

  @override
  bool operator ==(Object other) {
    return other is PanState &&
        distance == other.distance &&
        isPanning == other.isPanning &&
        wasFlung == other.wasFlung;
  }

  @override
  String toString() {
    return "PanState ${{
      "distance": distance,
      "isPanning": isPanning,
      "wasFlung": wasFlung,
    }}";
  }
}

/// Base class for handling pan events and translating them to distances.
///
/// Implementations should react to pan events by implementing [handlePanStart],
/// [handlePanUpdate] and [handlePanEnd] and update the [value] with a
/// corresponding [PanState].
///
/// Since this is a subclass of [ValueNotifier], listeners will be notified,
/// when a new [value] is set.
abstract class PanPhysics extends ValueNotifier<PanState> {
  /// The default duration for pan distances to return to zero.
  static const Duration kDefaultDuration = Duration(milliseconds: 300);

  /// The default curve for pan distances to return to zero.
  static const Curve kDefaultCurve = Curves.linear;

  /// The size of the area to be panned.
  ///
  /// This value is only required by some implementations, e.g.
  /// [CircularPanPhysics].It is set by [PanAwareBuilder]. Therefore users must
  /// not update it manually.
  Size size = Size(0.0, 0.0);

  /// {@template flutter_fortune_wheel.PanPhysics.duration}
  /// The animation duration used for returning a [PanState.distance] to zero.
  ///
  /// Defaults to [PanPhysics.kDefaultDuration].
  /// {@endtemplate}
  Duration get duration;

  /// {@template flutter_fortune_wheel.PanPhysics.curve}
  /// The type of curve to use for easing the animation when returning
  /// [PanState.distance] to zero.
  ///
  /// Defaults to [PanPhysics.kDefaultCurve].
  /// {@endtemplate}
  Curve get curve;

  PanPhysics() : super(PanState());

  /// {@template flutter_fortune_wheel.PanPhysics.handlePanStart}
  /// Is called when the start of a pan gesture is detected.
  ///
  /// See also:
  ///  * [GestureDetector.onPanStart], which this method is passed to
  /// {@endtemplate}
  void handlePanStart(DragStartDetails details);

  /// {@template flutter_fortune_wheel.PanPhysics.handlePanUpdate}
  /// Is called when a pan gesture is updated.
  ///
  /// See also:
  ///  * [GestureDetector.onPanUpdate], which this method is passed to
  /// {@endtemplate}
  void handlePanUpdate(DragUpdateDetails details);

  /// {@template flutter_fortune_wheel.PanPhysics.handlePanEnd}
  /// Is called when the end of a pan gesture is detected.
  ///
  /// See also:
  ///  * [GestureDetector.onPanEnd], which this method is passed to
  /// {@endtemplate}
  void handlePanEnd(DragEndDetails details);
}

class NoPanPhysics extends PanPhysics {
  /// {@macro flutter_fortune_wheel.PanPhysics.duration}
  final Duration duration = Duration.zero;

  /// {@macro flutter_fortune_wheel.PanPhysics.curve}
  final Curve curve = PanPhysics.kDefaultCurve;

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanStart}
  @override
  void handlePanEnd(DragEndDetails details) {}

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanUpdate}
  @override
  void handlePanStart(DragStartDetails details) {}

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanEnd}
  @override
  void handlePanUpdate(DragUpdateDetails details) {}
}

/// Calculates panned distances by assuming a circular shape.
///
/// This requires [size] to be set to the available area for detecting on which
/// side of the circle a pan event occurs.
///
/// For more details on the actual implementation, you can refer to this
/// [article](https://fireship.io/snippets/circular-drag-flutter/).
///
/// See also:
///  * [DirectionalPanPhysics], which is an alternative implementation
class CircularPanPhysics extends PanPhysics {
  /// {@macro flutter_fortune_wheel.PanPhysics.duration}
  final Duration duration;

  /// {@macro flutter_fortune_wheel.PanPhysics.curve}
  final Curve curve;

  CircularPanPhysics({
    this.duration = PanPhysics.kDefaultDuration,
    this.curve = PanPhysics.kDefaultCurve,
  });

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanStart}
  void handlePanStart(DragStartDetails details) {
    value = PanState(isPanning: true);
  }

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanUpdate}
  void handlePanUpdate(DragUpdateDetails details) {
    final center = Offset(
      size.width / 2,
      _math.min(size.width, size.height) / 2,
    );
    final onTop = details.localPosition.dy <= center.dy;
    final onLeftSide = details.localPosition.dx <= center.dx;
    final onRightSide = !onLeftSide;
    final onBottom = !onTop;

    final panUp = details.delta.dy <= 0.0;
    final panLeft = details.delta.dx <= 0.0;
    final panRight = !panLeft;
    final panDown = !panUp;

    final yChange = details.delta.dy.abs();
    final xChange = details.delta.dx.abs();

    final verticalRotation = (onRightSide && panDown) || (onLeftSide && panUp)
        ? yChange
        : yChange * -1;

    final horizontalRotation =
        (onTop && panRight) || (onBottom && panLeft) ? xChange : xChange * -1;

    final rotationalChange = verticalRotation + horizontalRotation;

    value = value.copyWith(distance: value.distance + rotationalChange);
  }

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanEnd}
  void handlePanEnd(DragEndDetails details) {
    if (value.distance.abs() > 100 &&
        details.velocity.pixelsPerSecond.distance.abs() > 300) {
      value = value.copyWith(isPanning: false, wasFlung: true);
    } else {
      value = value.copyWith(isPanning: false);
    }
  }
}

/// Calculates panned distances by only considering movements along one axis.
///
/// Either horizontal or vertical movements are used for distance calculations,
/// depending on the used constructor: [DirectionalPanPhysics.horizontal] or
/// [DirectionalPanPhysics.vertical].
class DirectionalPanPhysics extends PanPhysics {
  final double _direction;

  double _startPosition = 0.0;

  /// {@macro flutter_fortune_wheel.PanPhysics.curve}
  final Curve curve;

  /// {@macro flutter_fortune_wheel.PanPhysics.duration}
  final Duration duration;

  double _getOffset(Offset offset) => _direction < 0 ? offset.dy : offset.dx;

  DirectionalPanPhysics._({
    required this.curve,
    required double direction,
    required this.duration,
  }) : _direction = direction;

  DirectionalPanPhysics.horizontal({
    Curve curve = PanPhysics.kDefaultCurve,
    Duration duration = PanPhysics.kDefaultDuration,
  }) : this._(
          curve: curve,
          direction: 1.0,
          duration: duration,
        );

  DirectionalPanPhysics.vertical({
    Curve curve = PanPhysics.kDefaultCurve,
    Duration duration = PanPhysics.kDefaultDuration,
  }) : this._(
          curve: curve,
          direction: -1.0,
          duration: duration,
        );

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanStart}
  void handlePanStart(DragStartDetails details) {
    _startPosition = _getOffset(details.globalPosition);
    value = PanState(isPanning: true);
  }

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanUpdate}
  void handlePanUpdate(DragUpdateDetails details) {
    final currentPosition = _getOffset(details.globalPosition);
    final distance = currentPosition - _startPosition;
    value = value.copyWith(distance: distance);
  }

  /// {@macro flutter_fortune_wheel.PanPhysics.handlePanEnd}
  void handlePanEnd(DragEndDetails details) {
    final velocity = _getOffset(details.velocity.pixelsPerSecond);
    if (value.distance.abs() > 100 && velocity.abs() > 300) {
      value = value.copyWith(isPanning: false, wasFlung: true);
    } else {
      value = value.copyWith(isPanning: false);
    }
  }
}

/// A widget builder, which is aware of pan gestures and handles them.
///
/// Pan events are handled by the underlying [physics]. Whenever a new
/// [PanState] is available, the given [builder] is called wit the new
/// information.
///
/// If a new state signals that a fling/swipe gesture occurred by setting
/// [PanState.wasFlung] to true, the [onFling] callback is called.
///
/// See also:
///  * [PanPhysics], which implements pan behavior
class PanAwareBuilder extends HookWidget {
  /// The builder, which is called with the current [PanState] whenever it
  /// changes.
  final Widget Function(BuildContext, PanState) builder;

  /// The [PanPhysics] to be used for calculating pan states.
  final PanPhysics physics;

  /// The [HitTestBehavior] to be used by the underlying [GestureDetector].
  final HitTestBehavior? behavior;

  /// The callback to be called whenever a fling/swipe gesture is detected.
  final VoidCallback? onFling;

  PanAwareBuilder({
    required this.builder,
    required this.physics,
    this.behavior,
    this.onFling,
  });

  @override
  Widget build(BuildContext context) {
    var panState = useValueListenable(physics);
    final returnAnimCtrl = useAnimationController(duration: physics.duration);
    final returnAnim = CurvedAnimation(
      parent: returnAnimCtrl,
      curve: physics.curve,
    );

    useValueChanged(panState.isPanning, (bool oldValue, Future<void>? _) async {
      if (!oldValue) {
        returnAnimCtrl.reset();
      } else {
        await returnAnimCtrl.forward(from: 0.0);
      }
    });

    useValueChanged(panState.wasFlung, (bool oldValue, Future<void>? _) async {
      if (panState.wasFlung) {
        await Future.microtask(() => onFling?.call());
      }
    });

    return LayoutBuilder(builder: (context, constraints) {
      physics.size = Size(constraints.maxWidth, constraints.maxHeight);

      return GestureDetector(
        behavior: behavior,
        onPanStart: physics.handlePanStart,
        onPanUpdate: physics.handlePanUpdate,
        onPanEnd: physics.handlePanEnd,
        child: AnimatedBuilder(
            animation: returnAnim,
            builder: (context, _) {
              final mustApplyEasing = returnAnimCtrl.isAnimating ||
                  returnAnimCtrl.status == AnimationStatus.completed;

              if (mustApplyEasing) {
                panState = panState.copyWith(
                  distance: panState.distance * (1 - returnAnim.value),
                );
              }

              return Builder(
                builder: (context) => builder(context, panState),
              );
            }),
      );
    });
  }
}
