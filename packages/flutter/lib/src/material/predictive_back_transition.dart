import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A widget that applies Android-style predictive-back transform to `child`.
class PredictiveBackSharedElementTransition extends StatelessWidget {
  /// Creates a predictive back shared element transition.
  ///
  /// The [progress] animation drives the transform (scale + translation).
  /// Use [startBackEvent] and [currentBackEvent] to compute Y-shift from the
  /// user's touch movement and the [SwipeEdge] from [currentBackEvent] to
  /// determine the X direction. Defaults: [useXShift]=true, [useYShift]=true,
  /// [useInterpolation]=true. If [alignment] is omitted, the transform uses
  /// `Alignment.center`.
  const PredictiveBackSharedElementTransition({
    super.key,
    required this.progress,
    required this.startBackEvent,
    required this.currentBackEvent,
    this.alignment,
    this.useXShift = true,
    this.useYShift = true,
    this.useInterpolation = true,
    required this.child,
  });

  /// Animation that drives the transform applied to [child].
  ///
  /// The animation's current `value` (typically in the range `0.0`..`1.0`)
  /// is used to compute scale and shifts. When [useInterpolation] is `true`
  /// the implementation applies the Android back-gesture curve to the raw
  /// `value` before computing the transform.
  final Animation<double> progress;

  /// The initial back gesture event when the gesture began.
  ///
  /// Used as a reference point for computing the Y-axis shift based on how far
  /// the touch point has moved since the gesture started. May be `null` if
  /// such data is not available.
  final PredictiveBackEvent? startBackEvent;

  /// The most recent back gesture event.
  ///
  /// Provides the current touch offset and swipe edge (left/right) which are
  /// used to compute direction and magnitude of X/Y shifts. May be `null`.
  final PredictiveBackEvent? currentBackEvent;

  /// If non-null, the alignment for the transform applied to [child].
  ///
  /// Defaults to `Alignment.center` when omitted.
  final Alignment? alignment;

  /// Whether to apply horizontal (X) shifting to the [child].
  ///
  /// When `true` the widget computes a small horizontal translation in the
  /// direction of the back gesture to match Android's predictive back motion.
  final bool useXShift;

  /// Whether to apply vertical (Y) shifting to the [child].
  ///
  /// When `true` the widget computes a small vertical translation based on the
  /// difference between [currentBackEvent] and [startBackEvent].
  final bool useYShift;

  /// Whether to apply the Android back-gesture interpolator to [progress].
  ///
  /// When `true` the gesture progress is transformed with [kCurve] to better
  /// match the decelerated feel of the native Android motion.
  final bool useInterpolation;

  /// The widget below this widget in the tree to which the transform is applied.
  final Widget child;

  // Constants as per the motion specs
  // https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#motion-specs
  static const double _kMinScale = 0.90;
  static const double _kDivisionFactor = 20.0;
  static const double _kMargin = 8.0;

  /// Curve used to interpolate the raw gesture progress to match Android's
  /// back-gesture deceleration/interpolation.
  ///
  /// This curve is applied when [useInterpolation] is `true` so the visual
  /// motion more closely follows the native Android behaviour.
  //  https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/core/java/android/view/animation/BackGestureInterpolator.java
  static const Curve kCurve = Cubic(0.1, 0.1, 0.0, 1.0);

  double get _gestureProgress =>
      useInterpolation ? kCurve.transform(progress.value) : progress.value;

  double _calcXShift(BuildContext context) {
    final RenderObject? renderObject = context.findRenderObject();
    final double width = renderObject is RenderBox ? renderObject.size.width : MediaQuery.widthOf(context);

    final double maxShift = (width / _kDivisionFactor) - _kMargin;

    final SwipeEdge? swipeEdge = currentBackEvent?.swipeEdge;

    final double direction = (swipeEdge == SwipeEdge.right) ? -1.0 : 1.0;

    return direction * maxShift * _gestureProgress;
  }

  double _calcYShift(BuildContext context) {
    final RenderBox? renderObject = context.findRenderObject() as RenderBox?;
    final double height = renderObject?.size.height ?? MediaQuery.heightOf(context);

    final double startTouchY = startBackEvent?.touchOffset?.dy ?? 0;
    final double currentTouchY = currentBackEvent?.touchOffset?.dy ?? 0;

    final double yShiftMax = (height / _kDivisionFactor) - _kMargin;

    // Apply the decelerated gesture progress to the Y-shift so the preview is
    // more apparent at the start (matches Android docs recommendation).
    final double progressAdjustedYShiftMax = yShiftMax * _gestureProgress;

    final double rawYShift = currentTouchY - startTouchY;
    final double easedYShift =
        // This curve was eyeballed on a Pixel 9 running Android 16.
        Curves.easeOut.transform(clampDouble(rawYShift.abs() / height, 0.0, 1.0)) *
        rawYShift.sign *
        progressAdjustedYShiftMax;

    return clampDouble(easedYShift, -progressAdjustedYShiftMax, progressAdjustedYShiftMax);
  }

  double _calcScale() => 1 - (1 - _kMinScale) * _gestureProgress;

  Matrix4 _createTransformMatrix(BuildContext context) {
    final double scale = _calcScale();
    final double xShift = useXShift ? _calcXShift(context) : 0;
    final double yShift = useYShift ? _calcYShift(context) : 0;

    return Matrix4.identity()
      ..scale(scale, scale, 1.0)
      ..translate(xShift, yShift);
  }

  @override
  Widget build(BuildContext context) {
    return MatrixTransition(
      animation: progress,
      alignment: alignment ?? Alignment.center,
      onTransform: (_) => _createTransformMatrix(context),
      child: child,
    );
  }
}
