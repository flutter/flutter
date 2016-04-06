// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

const double _kMinIndicatorLength = 0.0;
const double _kMaxIndicatorLength = 64.0;
const double _kMinIndicatorOpacity = 0.0;
const double _kMaxIndicatorOpacity = 0.25;
const Duration _kIndicatorVanishDuration = const Duration(milliseconds: 200);
const Duration _kIndicatorTimeoutDuration = const Duration(seconds: 1);
final Tween<double> _kIndicatorOpacity = new Tween<double>(begin: 0.0, end: 0.3);

typedef Color GetOverscrollIndicatorColor();

class OverscrollPainter extends ScrollableListPainter {
  OverscrollPainter({ GetOverscrollIndicatorColor getIndicatorColor }) {
    this.getIndicatorColor = getIndicatorColor ?? _defaultIndicatorColor;
  }

  GetOverscrollIndicatorColor getIndicatorColor;
  bool _indicatorActive = false;
  AnimationController _indicatorLength;
  Timer _indicatorTimer;

  Color _defaultIndicatorColor() => const Color(0xFF00FF00);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_indicatorLength == null || (scrollOffset >= _minScrollOffset && scrollOffset <= _maxScrollOffset))
      return;

    final double rectBias = _indicatorLength.value / 2.0;
    final double arcBias = _indicatorLength.value;
    final Rect viewportRect = offset & viewportSize;

    final Path path = new Path();
    switch(scrollDirection) {
      case Axis.vertical:
        final double width = viewportRect.width;
        if (scrollOffset < _minScrollOffset) {
          path.moveTo(viewportRect.left, viewportRect.top);
          path.relativeLineTo(width, 0.0);
          path.relativeLineTo(0.0, rectBias);
          path.relativeQuadraticBezierTo(width / -2.0, arcBias, -width, 0.0);
        } else {
          path.moveTo(viewportRect.left, viewportRect.bottom);
          path.relativeLineTo(width, 0.0);
          path.relativeLineTo(0.0, -rectBias);
          path.relativeQuadraticBezierTo(width / -2.0, -arcBias, -width, 0.0);
        }
        break;
      case Axis.horizontal:
        final double height = viewportRect.height;
        if (scrollOffset < _minScrollOffset) {
          path.moveTo(viewportRect.left, viewportRect.top);
          path.relativeLineTo(0.0, height);
          path.relativeLineTo(rectBias, 0.0);
          path.relativeQuadraticBezierTo(arcBias, height / -2.0, 0.0, -height);
        } else {
          path.moveTo(viewportRect.right, viewportRect.top);
          path.relativeLineTo(0.0, height);
          path.relativeLineTo(-rectBias, 0.0);
          path.relativeQuadraticBezierTo(-arcBias, height / -2.0, 0.0, -height);
        }
        break;
    }
    path.close();

    final double t = (_indicatorLength.value - _kMinIndicatorLength) / (_kMaxIndicatorLength - _kMinIndicatorLength);
    final Paint paint = new Paint()
      ..color = getIndicatorColor().withOpacity(_kIndicatorOpacity.lerp(Curves.easeIn.transform(t)));
    context.canvas.drawPath(path, paint);
  }

  void _hide() {
    _indicatorTimer?.cancel();
    _indicatorTimer = null;
    _indicatorActive = false;
    _indicatorLength?.reverse();
  }

  double get _minScrollOffset => 0.0;

  double get _maxScrollOffset {
    switch(scrollDirection) {
      case Axis.vertical:
        return contentExtent - viewportSize.height;
      case Axis.horizontal:
        return contentExtent - viewportSize.width;
    }
  }

  @override
  void scrollStarted() {
    _indicatorActive = true;
    _indicatorLength ??= new AnimationController(
      lowerBound: _kMinIndicatorLength,
      upperBound: _kMaxIndicatorLength,
      duration: _kIndicatorVanishDuration
    )
    ..addListener(() {
      renderObject?.markNeedsPaint();
    });
  }

  @override
  void set scrollOffset (double value) {
    if (_indicatorActive &&
        (value < _minScrollOffset || value > _maxScrollOffset) &&
        ((value - scrollOffset).abs() > kPixelScrollTolerance.distance)) {
      _indicatorTimer?.cancel();
      _indicatorTimer = new Timer(_kIndicatorTimeoutDuration, _hide);
      _indicatorLength.value = value < _minScrollOffset ? _minScrollOffset - value : value - _maxScrollOffset;
    }
    super.scrollOffset = value;
  }

  @override
  void scrollEnded() {
    _hide();
  }

  @override
  void detach() {
    super.detach();
    _indicatorTimer?.cancel();
    _indicatorTimer = null;
    _indicatorLength?.stop();
  }
}
