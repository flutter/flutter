// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic.dart';
import 'framework.dart';

class _CheckedModeBannerPainter extends CustomPainter {
  const _CheckedModeBannerPainter();

  static const Color kColor = const Color(0xA0B71C1C);
  static const double kOffset = 40.0; // distance to bottom of banner, at a 45 degree angle inwards from the top right corner
  static const double kHeight = 12.0; // height of banner
  static const Offset kTextAlign = const Offset(0.0, -3.0); // offset to move text up
  static const double kFontSize = kHeight * 0.85;
  static const double kShadowBlur = 4.0; // shadow blur sigma
  static final Rect kRect = new Rect.fromLTWH(-kOffset, kOffset-kHeight, kOffset * 2.0, kHeight);
  static const TextStyle kTextStyles = const TextStyle(
    color: const Color(0xFFFFFFFF),
    fontSize: kFontSize,
    fontWeight: FontWeight.w900,
    textAlign: TextAlign.center
  );

  static final TextPainter textPainter = new TextPainter()
    ..text = new TextSpan(style: kTextStyles, text: 'SLOW MODE')
    ..maxWidth = kOffset * 2.0
    ..maxHeight = kHeight
    ..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintShadow = new Paint()
      ..color = const Color(0x7F000000)
      ..maskFilter = new MaskFilter.blur(BlurStyle.normal, kShadowBlur);
    final Paint paintBanner = new Paint()
      ..color = kColor;
    canvas
     ..translate(size.width, 0.0)
     ..rotate(math.PI/4)
     ..drawRect(kRect, paintShadow)
     ..drawRect(kRect, paintBanner);
    textPainter.paint(canvas, kRect.topLeft.toOffset() + kTextAlign);
  }

  @override
  bool shouldRepaint(_CheckedModeBannerPainter oldPainter) => false;

  @override
  bool hitTest(Point position) => false;
}

/// Displays a banner saying "CHECKED" when running in checked mode.
/// Does nothing in release mode.
class CheckedModeBanner extends StatelessWidget {
  CheckedModeBanner({
    Key key,
    this.child
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    assert(() {
      result = new CustomPaint(
        foregroundPainter: const _CheckedModeBannerPainter(),
        child: result
      );
      return true;
    });
    return result;
  }
}
