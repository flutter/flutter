// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'scroll_metrics.dart';

const double _kMinThumbExtent = 18.0;
const Duration _kDefaultThumbFadeDuration = const Duration(milliseconds: 300);
const Duration _kDefaultTimeToFade = const Duration(milliseconds: 600);

/// A [CustomPainter] for painting scrollbars.
///
/// See also:
///
///  * [Scrollbar] for a widget showing a scrollbar around a [Scrollable] in the
///    Material Design style.
///  * [CupertinoScrollbar] for a widget showing a scrollbar around a
///    [Scrollable] in the iOS style.
class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  ScrollbarPainter({
    @required TickerProvider vsync,
    @required this.thickness,
    @required this.crossAxisMargin,
    this.mainAxisMargin: 0.0,
    this.radius,
    this.minLength: _kMinThumbExtent,
    this.timeToFadeout: _kDefaultTimeToFade,
    this.fadeoutDuration: _kDefaultThumbFadeDuration,
  })
      : assert(vsync != null),
        assert(thickness != null),
        assert(mainAxisMargin != null),
        assert(minLength != null),
        assert(timeToFadeout != null),
        assert(fadeoutDuration != null) {
    _fadeController = new AnimationController(duration: fadeoutDuration, vsync: vsync);
    _opacity = new CurvedAnimation(parent: _fadeController, curve: Curves.fastOutSlowIn)
      ..addListener(notifyListeners);
  }

  /// Thickness of the scrollbar in its cross-axis in pixels. Mustn't be null.
  final double thickness;

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  final Radius radius;

  /// Distance from the scrollbar's side to the nearest edge in pixels. Musn't
  /// be null.
  final double crossAxisMargin;

  /// Distance from the scrollbar's start and end to the edge of the viewport in
  /// pixels. Mustn't be null.
  final double mainAxisMargin;

  /// The smallest size the scrollbar can shrink to when the total scrollable
  /// extent is large and the current visible viewport is small. Mustn't be
  /// null.
  final double minLength;

  /// [Duration] the scrollbar is immobile before starting to fade out. Mustn't be
  /// null.
  final Duration timeToFadeout;

  /// [Duration] of the fade out animation once started. Mustn't be null.
  final Duration fadeoutDuration;

  // Animation of the main axis direction.
  AnimationController _fadeController;
  Animation<double> _opacity;

  // Fade-out timer.
  Timer _fadeOut;

  /// [Color] of the thumb.
  final Color color;

  final TextDirection textDirection;

  @override
  void dispose() {
    _fadeOut?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  ScrollMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;

  /// Update with new [ScrollMetrics]. The scrollbar will show and redraw itself
  /// based on these new metrics.
  ///
  /// The scrollbar will remain on screen.
  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    if (_fadeController.status == AnimationStatus.completed) {
      notifyListeners();
    } else if (_fadeController.status != AnimationStatus.forward) {
      _fadeController.forward();
    }
    _fadeOut?.cancel();
  }

  /// Signal that the scrollbar can start to fade after the specified [timeToFadeout].
  void scheduleFade() {
    _fadeOut?.cancel();
    _fadeOut = new Timer(timeToFadeout, _startFadeOut);
  }

  void _startFadeOut() {
    _fadeOut = null;
    _fadeController.reverse();
  }

  Paint get _paint {
    return new Paint()..color = color.withOpacity(color.opacity * _opacity.value);
  }

  double _getThumbX(Size size) {
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return crossAxisMargin;
      case TextDirection.ltr:
        return size.width - thickness - crossAxisMargin;
    }
    return null;
  }

  void _paintVerticalThumb(Canvas canvas, Size size, double thumbOffset, double thumbExtent) {
    final Offset thumbOrigin = new Offset(_getThumbX(size), thumbOffset);
    final Size thumbSize = new Size(thickness, thumbExtent);
    final Rect thumbRect = thumbOrigin & thumbSize;
    if (radius == null)
      canvas.drawRect(thumbRect, _paint);
    else
      canvas.drawRRect(new RRect.fromRectAndRadius(thumbRect, radius), _paint);
  }

  void _paintHorizontalThumb(Canvas canvas, Size size, double thumbOffset, double thumbExtent) {
    final Offset thumbOrigin = new Offset(thumbOffset, size.height - thickness);
    final Size thumbSize = new Size(thumbExtent, thickness);
    final Rect thumbRect = thumbOrigin & thumbSize;
    if (radius == null)
      canvas.drawRect(thumbRect, _paint);
    else
      canvas.drawRRect(new RRect.fromRectAndRadius(thumbRect, radius), _paint);
  }

  void _paintThumb(
    double before,
    double inside,
    double after,
    double viewport,
    Canvas canvas,
    Size size,
    void painter(Canvas canvas, Size size, double thumbOffset, double thumbExtent),
  ) {
    // Establish the minimum size possible.
    double thumbExtent = math.min(viewport, minLength);
    if (before + inside + after > 0.0) {
      final double fractionVisible = inside / (before + inside + after);
      thumbExtent = math.max(
        thumbExtent,
        viewport * fractionVisible - 2 * mainAxisMargin,
      );
    }

    final double fractionPast = before / (before + after);
    final double thumbOffset = (before + after > 0.0)
        ? fractionPast * (viewport - thumbExtent - 2 * mainAxisMargin) + mainAxisMargin
        : mainAxisMargin;

    painter(canvas, size, thumbOffset, thumbExtent);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null || _lastMetrics == null || _opacity.value == 0.0)
      return;
    switch (_lastAxisDirection) {
      case AxisDirection.down:
        _paintThumb(_lastMetrics.extentBefore, _lastMetrics.extentInside, _lastMetrics.extentAfter, size.height, canvas, size, _paintVerticalThumb);
        break;
      case AxisDirection.up:
        _paintThumb(_lastMetrics.extentAfter, _lastMetrics.extentInside, _lastMetrics.extentBefore, size.height, canvas, size, _paintVerticalThumb);
        break;
      case AxisDirection.right:
        _paintThumb(_lastMetrics.extentBefore, _lastMetrics.extentInside, _lastMetrics.extentAfter, size.width, canvas, size, _paintHorizontalThumb);
        break;
      case AxisDirection.left:
        _paintThumb(_lastMetrics.extentAfter, _lastMetrics.extentInside, _lastMetrics.extentBefore, size.width, canvas, size, _paintHorizontalThumb);
        break;
    }
  }

  @override
  bool hitTest(Offset position) => null;

  @override
  bool shouldRepaint(ScrollbarPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback get semanticsBuilder => null;
}