// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'material.dart';

RectCallback _getClipCallback(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback) {
  if (rectCallback != null) {
    assert(containedInkWell);
    return rectCallback;
  }
  if (containedInkWell)
    return () => Offset.zero & referenceBox.size;
  return null;
}

double _getTargetRadius(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback, Offset position) {
  final Size size = rectCallback != null ? rectCallback().size : referenceBox.size;
  final double d1 = size.bottomRight(Offset.zero).distance;
  final double d2 = (size.topRight(Offset.zero) - size.bottomLeft(Offset.zero)).distance;
  return math.max(d1, d2) / 2.0;
}

class _InkRippleFactory extends InteractiveInkFeatureFactory {
  const _InkRippleFactory();

  @override
  InteractiveInkFeature create({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    @required Offset position,
    @required Color color,
    @required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    ShapeBorder customBorder,
    double radius,
    VoidCallback onRemoved,
  }) {
    return InkRipple(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
      textDirection: textDirection,
    );
  }
}

/// A visual reaction on a piece of [Material] to user input.
///
/// A circular ink feature whose origin starts at the input touch point and
/// whose radius expands from 60% of the final radius. The splash origin
/// animates to the center of its [referenceBox].
///
/// This object is rarely created directly. Instead of creating an ink ripple,
/// consider using an [InkResponse] or [InkWell] widget, which uses
/// gestures (such as tap and long-press) to trigger ink splashes. This class
/// is used when the [Theme]'s [ThemeData.splashFactory] is [InkRipple.splashFactory].
///
/// See also:
///
///  * [InkSplash], which is an ink splash feature that expands less
///    aggressively than the ripple.
///  * [InkResponse], which uses gestures to trigger ink highlights and ink
///    splashes in the parent [Material].
///  * [InkWell], which is a rectangular [InkResponse] (the most common type of
///    ink response).
///  * [Material], which is the widget on which the ink splash is painted.
///  * [InkHighlight], which is an ink feature that emphasizes a part of a
///    [Material].
class InkRipple extends InteractiveInkFeature {
  /// Begin a ripple, centered at [position] relative to [referenceBox].
  ///
  /// The [controller] argument is typically obtained via
  /// `Material.of(context)`.
  ///
  /// If [containedInkWell] is true, then the ripple will be sized to fit
  /// the well rectangle, then clipped to it when drawn. The well
  /// rectangle is the box returned by [rectCallback], if provided, or
  /// otherwise is the bounds of the [referenceBox].
  ///
  /// If [containedInkWell] is false, then [rectCallback] should be null.
  /// The ink ripple is clipped only to the edges of the [Material].
  /// This is the default.
  ///
  /// When the ripple is removed, [onRemoved] will be called.
  InkRipple({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    @required Offset position,
    @required Color color,
    @required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    ShapeBorder customBorder,
    double radius,
    VoidCallback onRemoved,
  }) : assert(color != null),
       assert(position != null),
       assert(textDirection != null),
       _position = position,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _customBorder = customBorder,
       _textDirection = textDirection,
       _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback),
       super(controller: controller, referenceBox: referenceBox, color: color, onRemoved: onRemoved)
  {
    assert(_borderRadius != null);

    // Immediately begin fading-in the initial splash.
    _fadeInController = AnimationController(duration: fadeInDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _fadeIn = _fadeInController.drive(getFadeInTween(color));

    // Controls the splash radius and its center. Starts upon confirm.
    _radiusController = AnimationController(duration: unconfirmedRadiusDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _radius = _radiusController.drive(
      getRadiusTween(radius ?? _getTargetRadius(referenceBox, containedInkWell, rectCallback, position))
    );

    // Controls the splash radius and its center. Starts upon confirm however its
    // Interval delays changes until the radius expansion has completed.
    _fadeOutController = AnimationController(duration: fadeOutDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleFadeStatusChanged);
    _fadeOut = _fadeOutController.drive(getFadeOutTween(color));

    controller.addInkFeature(this);
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final ShapeBorder _customBorder;
  final RectCallback _clipCallback;
  final TextDirection _textDirection;

  Animation<double> _radius;
  AnimationController _radiusController;

  Animation<double> _fadeIn;
  AnimationController _fadeInController;

  Animation<double> _fadeOut;
  AnimationController _fadeOutController;

  /// Used to specify this type of ink splash for an [InkWell], [InkResponse]
  /// or material [Theme].
  static const InteractiveInkFeatureFactory splashFactory = _InkRippleFactory();

  /// Duration of the radius animation that begins when this [InkRipple]
  /// is constructed.
  ///
  /// See also:
  ///
  /// * [confirmedRadiusDuration], the duration of the radius animation
  ///   is changed to this value upon [confirm].
  /// * [getRadiusTween], which defines the radius animation.
  @protected
  Duration get unconfirmedRadiusDuration => const Duration(seconds: 1);

  /// Update to [unconfirmedRadiusDuration] that's applied upon [confirm].
  ///
  /// See also:
  ///
  /// * [unconfirmedRadiusDuration], which is the initial duration of the
  ///   radius animation.
  /// * [getRadiusTween], which defines the radius animation.
  @protected
  Duration get confirmedRadiusDuration => const Duration(milliseconds: 225);

  /// Returns a [Tween] that defines how the ripple's radius changes
  /// over [unconfirmedRadiusDuration] upon tap down and
  /// [confirmedRadiusDuration] upon tap up.
  ///
  /// The [targetRadius] is either the `radius` constructor parameter or
  /// a computed value that's large enough to cover the [InkWell] based
  /// on `referenceBox`, `rectCallback`, and `containedInkWell`.
  ///
  /// By default the initial splash diameter is 60% of the target
  /// diameter, final diameter is 10dps larger than the target diameter.
  @protected
  Animatable<double> getRadiusTween(double targetRadius) {
    return Tween<double>(
      begin: targetRadius * 0.30,
      end: targetRadius + 5.0,
    ).chain(CurveTween(curve: Curves.ease));
  }

  /// The duration of the ripple fade-in animation defined by [getFadeInTween].
  ///
  /// The fade-in starts when this [InkRipple] is constructed; at the same
  /// time as the ripple radius animation defined by [getRadiusTween]
  /// and [unconfirmedRadiusDuration].
  @protected
  Duration get fadeInDuration => const Duration(milliseconds: 75);

  /// Defines the animated opacity value for the ripple's [color] when
  /// the animation fades in.
  ///
  /// The fade-in animation's duration is [fadeInDuration]. The fade-in starts
  /// when this [InkRipple] is constructed. It starts at the same as the
  /// animation defined by [getRadiusTween].
  ///
  /// Returns a linear [Tween] that begins at `0.0` and ends at `color.opacity`.
  Animatable<double> getFadeInTween(Color color) {
    return Tween<double>(
      begin: 0,
      end: color.opacity,
    );
  }

  /// The duration of the ripple fade-out animation defined by [getFadeOutTween].
  ///
  /// The fade-out starts when [confirm] is called.
  Duration get fadeOutDuration => const Duration(milliseconds: 375);

  /// Defines the animated opacity value for the ripple's [color] when
  /// the animation fades out.
  ///
  /// The fade-out animation's duration is [fadeOutDuration]. The fade-out starts
  /// when [confirm] is called.
  ///
  /// Returns a linear [Tween] that begins at `color.opacity` and ends
  /// at `0.0`.
  Animatable<double> getFadeOutTween(Color color) {
    final double fadeTime = fadeOutDuration.inMilliseconds.toDouble();
    final double radiusTime = confirmedRadiusDuration.inMilliseconds.toDouble();
    return Tween<double>(
      begin: color.opacity,
      end: 0,
    ).chain(
      // The fade out typically begins 225ms after the _fadeOutController starts
      // to ensure that the radius animation has completed. See confirm().
      CurveTween(curve: Interval(math.min(1.0, radiusTime / fadeTime), 1.0))
    );
  }

  /// The new duration of the [getFadeOutTween] if [cancel] is called before
  /// the fade-out animation has completed.
  Duration get cancelDuration => const Duration(milliseconds: 75);

  @override
  void confirm() {
    _radiusController
      ..duration = confirmedRadiusDuration
      ..forward();
    // This confirm may have been preceded by a cancel.
    _fadeInController.forward();
    _fadeOutController
      ..animateTo(1.0, duration: fadeOutDuration);
  }

  @override
  void cancel() {
    _fadeInController.stop();
    // Watch out: setting _fadeOutController's value to 1.0 will
    // trigger a call to _handleFadeStatusChanged() which will
    // dispose _fadeOutController.
    final double fadeOutValue = 1.0 - _fadeInController.value;
    _fadeOutController.value = fadeOutValue;
    if (fadeOutValue < 1.0)
      _fadeOutController.animateTo(1.0, duration: cancelDuration);
  }

  void _handleFadeStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      dispose();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final double opacity = _fadeInController.isAnimating ? _fadeIn.value : _fadeOut.value;
    final Paint paint = Paint()..color = color.withOpacity(opacity);
    // Splash moves to the center of the reference box.
    final Offset center = Offset.lerp(
      _position,
      referenceBox.size.center(Offset.zero),
      Curves.ease.transform(_radiusController.value),
    );
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    canvas.save();
    if (originOffset == null) {
      canvas.transform(transform.storage);
    } else {
      canvas.translate(originOffset.dx, originOffset.dy);
    }
    if (_clipCallback != null) {
      final Rect rect = _clipCallback();
      if (_customBorder != null) {
        canvas.clipPath(_customBorder.getOuterPath(rect, textDirection: _textDirection));
      } else if (_borderRadius != BorderRadius.zero) {
        canvas.clipRRect(RRect.fromRectAndCorners(
          rect,
          topLeft: _borderRadius.topLeft, topRight: _borderRadius.topRight,
          bottomLeft: _borderRadius.bottomLeft, bottomRight: _borderRadius.bottomRight,
        ));
      } else {
        canvas.clipRect(rect);
      }
    }
    canvas.drawCircle(center, _radius.value, paint);
    canvas.restore();
  }
}
