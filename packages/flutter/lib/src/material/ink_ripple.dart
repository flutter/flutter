// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';

const Duration _kUnconfirmedRippleDuration = const Duration(seconds: 1);
const Duration _kFadeInDuration = const Duration(milliseconds: 75);
const Duration _kRadiusDuration = const Duration(milliseconds: 225);
const Duration _kFadeOutDuration = const Duration(milliseconds: 450);
const Duration _kCancelDuration = const Duration(milliseconds: 75);

// The fade out begins 300ms after the _fadeOutController starts. See confirm().
const double _kFadeOutIntervalStart = 300.0 / 450.0;

const double _kRippleConfirmedVelocity = 1.0; // logical pixels per millisecond

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
  if (containedInkWell) {
    final Size size = rectCallback != null ? rectCallback().size : referenceBox.size;
    return _getRippleRadiusForPositionInSize(size, position);
  }
  return Material.defaultSplashRadius;
}

double _getRippleRadiusForPositionInSize(Size bounds, Offset position) {
  final double d1 = (position - bounds.topLeft(Offset.zero)).distance;
  final double d2 = (position - bounds.topRight(Offset.zero)).distance;
  final double d3 = (position - bounds.bottomLeft(Offset.zero)).distance;
  final double d4 = (position - bounds.bottomRight(Offset.zero)).distance;
  return math.max(math.max(d1, d2), math.max(d3, d4)).ceilToDouble();
}

/// A visual reaction on a piece of [Material] to user input.
///
/// A circular in feature whose origin starts at the input touch point and
/// whose radius expands from 60% of the final radius. The splash's origin
/// animates to the center.
///
/// This object is rarely created directly. Instead of creating an ink ripple
/// directly, consider using an [InkResponse] or [InkWell] widget, which uses
/// gestures (such as tap and long-press) to trigger ink splashes. This class
/// is used when the [Theme]'s [ThemeData.splashType] is [InkSplashType.ripple].
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
 class InkRipple extends InkFeature {
  /// Begin a ripple, centered at position relative to [referenceBox].
  ///
  /// The [controller] argument is typically obtained via
  /// `Material.of(context)`.
  ///
  /// If `containedInkWell` is true, then the ripple will be sized to fit
  /// the well rectangle, then clipped to it when drawn. The well
  /// rectangle is the box returned by `rectCallback`, if provided, or
  /// otherwise is the bounds of the [referenceBox].
  ///
  /// If `containedInkWell` is false, then `rectCallback` should be null.
  /// The ink ripple is clipped only to the edges of the [Material].
  /// This is the default.
  ///
  /// When the ripple is removed, `onRemoved` will be called.
  InkRipple({
    @required MaterialInkController controller,

    @required RenderBox referenceBox,
    Offset position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    BorderRadius borderRadius: BorderRadius.zero,
    double radius,
    VoidCallback onRemoved,
  }) : _position = position,
       _borderRadius = borderRadius,
       _targetRadius = radius ?? _getTargetRadius(referenceBox, containedInkWell, rectCallback, position),
       _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback),
       super(controller: controller, referenceBox: referenceBox, color: color, onRemoved: onRemoved)
  {
    assert(_borderRadius != null);

    // Immediately begin fading-in the initial splash.
    _fadeInController = new AnimationController(duration: _kFadeInDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _fadeIn = new IntTween(
      begin: 0,
      end: color.alpha,
    ).animate(_fadeInController);

    // Controls the splash radius and its center. Starts upon confirm.
    _radiusController = new AnimationController(duration: _kUnconfirmedRippleDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
     // Initial splash diamater is 60% of the target diameter, final
     // diameter is 10dps larger than the target diameter.
    _radius = new Tween<double>(
      begin: _targetRadius * 0.30,
      end: _targetRadius + 5.0,
    ).animate(
      new CurvedAnimation(
        parent: _radiusController,
        curve: Curves.ease,
      )
    );

    // Controls the splash radius and its center. Starts upon confirm however its
    // Interval delays changes until the radius expansion has completed.
    _fadeOutController = new AnimationController(duration: _kFadeOutDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged);
    _fadeOut = new IntTween(
      begin: color.alpha,
      end: 0,
    ).animate(
      new CurvedAnimation(
        parent: _fadeOutController,
        curve: const Interval(_kFadeOutIntervalStart, 1.0)
      ),
    );

    controller.addInkFeature(this);
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback _clipCallback;

  Animation<double> _radius;
  AnimationController _radiusController;

  Animation<int> _fadeIn;
  AnimationController _fadeInController;

  Animation<int> _fadeOut;
  AnimationController _fadeOutController;

  /// The user input is confirmed.
  ///
  /// Causes the reaction to propagate faster across the material.
  @override
  void confirm() {
    _radiusController
      ..duration = _kRadiusDuration
      ..forward();
    _fadeOutController.forward();
  }

  @override
  void cancel() {
    _fadeInController.stop();
    _fadeOutController.animateTo(1.0, duration: _kCancelDuration);
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
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

  RRect _clipRRectFromRect(Rect rect) {
    return new RRect.fromRectAndCorners(
      rect,
      topLeft: _borderRadius.topLeft, topRight: _borderRadius.topRight,
      bottomLeft: _borderRadius.bottomLeft, bottomRight: _borderRadius.bottomRight,
    );
  }

  void _clipCanvasWithRect(Canvas canvas, Rect rect, {Offset offset}) {
    Rect clipRect = rect;
    if (offset != null) {
      clipRect = clipRect.shift(offset);
    }
    if (_borderRadius != BorderRadius.zero) {
      canvas.clipRRect(_clipRRectFromRect(clipRect));
    } else {
      canvas.clipRect(clipRect);
    }
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final int alpha = _fadeInController.isAnimating ? _fadeIn.value : _fadeOut.value;
    final Paint paint = new Paint()..color = color.withAlpha(alpha);
    // Splash moves to the center of the reference box.
    final Offset center = Offset.lerp(
      _position,
      referenceBox.size.center(Offset.zero),
      Curves.ease.transform(_radiusController.value),
    );
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      if (_clipCallback != null) {
        _clipCanvasWithRect(canvas, _clipCallback());
      }
      canvas.drawCircle(center, _radius.value, paint);
      canvas.restore();
    } else {
      if (_clipCallback != null) {
        canvas.save();
        _clipCanvasWithRect(canvas, _clipCallback(), offset: originOffset);
      }
      canvas.drawCircle(center + originOffset, _radius.value, paint);
      if (_clipCallback != null)
        canvas.restore();
    }
  }
}
