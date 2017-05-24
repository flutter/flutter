// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'colors.dart';

final MaskFilter _kShadowMaskFilter = new MaskFilter.blur(BlurStyle.normal, BoxShadow.convertRadiusToSigma(1.0));

/// Paints an iOS-style slider thumb.
///
/// Used by [CupertinoSwitch] and [CupertinoSlider].
class CupertinoThumbPainter {
  /// Creates an object that paints an iOS-style slider thumb.
  CupertinoThumbPainter({
    this.color: CupertinoColors.white,
    this.shadowColor: const Color(0x2C000000),
  });

  /// The color of the interior of the thumb.
  final Color color;

  /// The color of the shadow case by the thumb.
  final Color shadowColor;

  /// Half the default diameter of the thumb.
  static const double radius = 14.0;

  /// The default amount the thumb should be extended horizontally when pressed.
  static const double extension = 7.0;

  /// Paints the thumb onto the given canvas in the given rectangle.
  ///
  /// Consider using [radius] and [extension] when deciding how large a
  /// rectangle to use for the thumb.
  void paint(Canvas canvas, Rect rect) {
    final RRect rrect = new RRect.fromRectAndRadius(rect, new Radius.circular(rect.shortestSide / 2.0));

    final Paint paint = new Paint()
      ..color = shadowColor
      ..maskFilter = _kShadowMaskFilter;
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect.shift(const Offset(0.0, 3.0)), paint);

    paint
      ..color = color
      ..maskFilter = null;
    canvas.drawRRect(rrect, paint);
  }
}
