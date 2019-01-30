// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'colors.dart';

/// Paints an iOS-style slider thumb.
///
/// Used by [CupertinoSwitch] and [CupertinoSlider].
class CupertinoThumbPainter {
  /// Creates an object that paints an iOS-style slider thumb.
  CupertinoThumbPainter({
    this.color = CupertinoColors.white,
    this.shadowColor = const Color(0x2C000000),
  }) : _shadowPaint = BoxShadow(
         color: shadowColor,
         blurRadius: 1.0,
       ).toPaint();

  /// The color of the interior of the thumb.
  final Color color;

  /// The color of the shadow case by the thumb.
  final Color shadowColor;

  /// The paint used to draw the shadow case by the thumb.
  final Paint _shadowPaint;

  /// Half the default diameter of the thumb.
  static const double radius = 14.0;

  /// The default amount the thumb should be extended horizontally when pressed.
  static const double extension = 7.0;

  /// Paints the thumb onto the given canvas in the given rectangle.
  ///
  /// Consider using [radius] and [extension] when deciding how large a
  /// rectangle to use for the thumb.
  void paint(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.shortestSide / 2.0),
    );

    canvas.drawRRect(rrect, _shadowPaint);
    canvas.drawRRect(rrect.shift(const Offset(0.0, 3.0)), _shadowPaint);
    canvas.drawRRect(rrect, Paint()..color = color);
  }
}
