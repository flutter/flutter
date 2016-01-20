// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const double _kMinScrollbarThumbLength = 18.0;
const double _kScrollbarThumbGirth = 6.0;
const Duration _kScrollbarThumbFadeDuration = const Duration(milliseconds: 300);

class ScrollbarPainter extends ScrollableListPainter {

  double _opacity = 0.0;
  int get _alpha => (_opacity * 0xFF).round();

  // TODO(hansmuller): thumb color should come from ThemeData.
  Color get thumbColor => const Color(0xFF9E9E9E);

  void paintThumb(PaintingContext context, Rect thumbBounds) {
    final Paint paint = new Paint()..color = thumbColor.withAlpha(_alpha);
    context.canvas.drawRect(thumbBounds, paint);
  }

  void paintScrollbar(PaintingContext context, Offset offset) {
    final Rect viewportBounds = offset & viewportSize;
    Point thumbOrigin;
    Size thumbSize;

    switch (scrollDirection) {
      case Axis.vertical:
        double thumbHeight = viewportBounds.height * viewportBounds.height / contentExtent;
        thumbHeight = thumbHeight.clamp(_kMinScrollbarThumbLength, viewportBounds.height);
        final double maxThumbTop = viewportBounds.height - thumbHeight;
        double thumbTop = (scrollOffset / (contentExtent - viewportBounds.height)) * maxThumbTop;
        thumbTop = viewportBounds.top + thumbTop.clamp(0.0, maxThumbTop);
        thumbOrigin = new Point(viewportBounds.right - _kScrollbarThumbGirth, thumbTop);
        thumbSize = new Size(_kScrollbarThumbGirth, thumbHeight);
        break;
      case Axis.horizontal:
        double thumbWidth = viewportBounds.width * viewportBounds.width / contentExtent;
        thumbWidth = thumbWidth.clamp(_kMinScrollbarThumbLength, viewportBounds.width);
        final double maxThumbLeft = viewportBounds.width - thumbWidth;
        double thumbLeft = (scrollOffset / (contentExtent - viewportBounds.width)) * maxThumbLeft;
        thumbLeft = viewportBounds.left + thumbLeft.clamp(0.0, maxThumbLeft);
        thumbOrigin = new Point(thumbLeft, viewportBounds.height - _kScrollbarThumbGirth);
        thumbSize = new Size(thumbWidth, _kScrollbarThumbGirth);
        break;
    }

    paintThumb(context, thumbOrigin & thumbSize);
  }

  void paint(PaintingContext context, Offset offset) {
    if (_alpha == 0)
      return;
    paintScrollbar(context, offset);
  }

  AnimationController _fade;

  Future scrollStarted() {
    if (_fade == null) {
      _fade = new AnimationController(duration: _kScrollbarThumbFadeDuration);
      CurvedAnimation curve = new CurvedAnimation(parent: _fade, curve: Curves.ease);
      curve.addListener(() {
        _opacity = curve.value;
        renderObject?.markNeedsPaint();
      });
    }
    return _fade.forward();
  }

  Future scrollEnded() {
    return _fade.reverse();
  }

  void detach() {
    super.detach();
    _fade?.stop();
  }
}
