// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

final MaskFilter _kShadowMaskFilter = new MaskFilter.blur(BlurStyle.normal, BoxShadow.convertRadiusToSigma(1.0));

class CupertinoThumbPainter {
  CupertinoThumbPainter({
    this.color: const Color(0xFFFFFFFF),
    this.shadowColor: const Color(0x2C000000),
  });

  final Color color;
  final Color shadowColor;

  static const double radius = 14.0;
  static const double extension = 7.0;

  void paint(Canvas canvas, Rect rect) {
    final RRect rrect = new RRect.fromRectAndRadius(rect, new Radius.circular(rect.shortestSide / 2.0));

    Paint paint = new Paint()
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
