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
  ScrollbarPainter({
    @required TickerProvider vsync,
    @required this.thickness,
    @required this.distanceFromEdge,
    this.radius,
    this.timeToFadeout: _kDefaultTimeToFade,
    this.fadeoutDuration: _kDefaultThumbFadeDuration,
  }) : assert(vsync != null) {
    _fadeController = new AnimationController(duration: fadeoutDuration, vsync: vsync);
    _opacity = new CurvedAnimation(parent: _fadeController, curve: Curves.fastOutSlowIn)
      ..addListener(notifyListeners);
  }

  /// Thickness of the scrollbar in its cross-axis in pixels.
  double thickness;

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  Radius radius;

  /// Distance from the scrollbar's nearest edge in pixels.
  double distanceFromEdge;

  /// Duration the scrollbar is immobile before starting to fade out.
  Duration timeToFadeout;

  /// Duration of the fade out animation once started.
  Duration fadeoutDuration;

  // animation of the main axis direction
  AnimationController _fadeController;
  Animation<double> _opacity;

  // fade-out timer
  Timer _fadeOut;

  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(value != null);
    if (_color == value)
      return;
    _color = value;
    notifyListeners();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value)
      return;
    _textDirection = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _fadeOut?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  ScrollMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;

  void update(ScrollMetrics metrics, AxisDirection axisDirection) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    if (_fadeController.status == AnimationStatus.completed) {
      notifyListeners();
    } else if (_fadeController.status != AnimationStatus.forward) {
      _fadeController.forward();
    }
    _fadeOut?.cancel();
    _fadeOut = new Timer(timeToFadeout, startFadeOut);
  }

  void startFadeOut() {
    _fadeOut = null;
    _fadeController.reverse();
  }

  Paint get _paint => new Paint()..color = color.withOpacity(_opacity.value);

  double _getThumbX(Size size) {
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return distanceFromEdge;
      case TextDirection.ltr:
        return size.width - thickness - distanceFromEdge;
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

  void _paintThumb(double before, double inside, double after, double viewport, Canvas canvas, Size size,
                   void painter(Canvas canvas, Size size, double thumbOffset, double thumbExtent)) {
    double thumbExtent = math.min(viewport, _kMinThumbExtent);
    if (before + inside + after > 0.0)
      thumbExtent = math.max(thumbExtent, viewport * inside / (before + inside + after));

    final double thumbOffset = (before + after > 0.0) ?
        before * (viewport - thumbExtent) / (before + after) : 0.0;

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
}