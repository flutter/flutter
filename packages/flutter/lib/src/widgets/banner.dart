// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic.dart';
import 'framework.dart';

enum BannerLocation { topRight, topLeft, bottomRight, bottomLeft }

class BannerPainter extends CustomPainter {
  const BannerPainter({
    this.message,
    this.location
  });

  final String message;
  final BannerLocation location;

  static const Color kColor = const Color(0xA0B71C1C);
  static const double kOffset = 40.0; // distance to bottom of banner, at a 45 degree angle inwards
  static const double kHeight = 12.0; // height of banner
  static const double kBottomOffset = kOffset + 0.707 * kHeight; // offset plus sqrt(2)/2 * banner height
  static const double kFontSize = kHeight * 0.85;
  static const double kShadowBlur = 4.0; // shadow blur sigma
  static final Rect kRect = new Rect.fromLTWH(-kOffset, kOffset - kHeight, kOffset * 2.0, kHeight);
  static const TextStyle kTextStyles = const TextStyle(
    color: const Color(0xFFFFFFFF),
    fontSize: kFontSize,
    fontWeight: FontWeight.w900,
    textAlign: TextAlign.center,
    height: 1.0
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintShadow = new Paint()
      ..color = const Color(0x7F000000)
      ..maskFilter = new MaskFilter.blur(BlurStyle.normal, kShadowBlur);
    final Paint paintBanner = new Paint()
      ..color = kColor;
    canvas
      ..translate(_translationX(size.width), _translationY(size.height))
      ..rotate(_rotation)
      ..drawRect(kRect, paintShadow)
      ..drawRect(kRect, paintBanner);

    final TextPainter textPainter = new TextPainter()
      ..text = new TextSpan(style: kTextStyles, text: message)
      ..layout(maxWidth: kOffset * 2.0);

    textPainter.paint(canvas, kRect.topLeft.toOffset() + new Offset(0.0, (kRect.height - textPainter.height) / 2.0));
  }

  @override
  bool shouldRepaint(BannerPainter oldPainter) => false;

  @override
  bool hitTest(Point position) => false;

  double _translationX(double width) {
    switch (location) {
      case BannerLocation.bottomRight:
        return width - kBottomOffset;
      case BannerLocation.topRight:
        return width;
      case BannerLocation.bottomLeft:
        return kBottomOffset;
      case BannerLocation.topLeft:
        return 0.0;
    }
  }

  double _translationY(double height) {
    switch (location) {
      case BannerLocation.bottomRight:
      case BannerLocation.bottomLeft:
        return height - kBottomOffset;
      case BannerLocation.topRight:
      case BannerLocation.topLeft:
        return 0.0;
    }
  }

  double get _rotation {
    switch (location) {
      case BannerLocation.bottomLeft:
      case BannerLocation.topRight:
        return math.PI / 4.0;
      case BannerLocation.bottomRight:
      case BannerLocation.topLeft:
        return -math.PI / 4.0;
    }
  }
}

class Banner extends StatelessWidget {
  Banner({
    Key key,
    this.child,
    this.message,
    this.location
  }) : super(key: key);

  final Widget child;
  final String message;
  final BannerLocation location;

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      foregroundPainter: new BannerPainter(message: message, location: location),
      child: child
    );
  }
}

/// Displays a banner saying "SLOW MODE" when running in checked mode.
/// Does nothing in release mode.
class CheckedModeBanner extends StatelessWidget {
  CheckedModeBanner({
    Key key,
    this.child
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    assert(() {
      result = new Banner(
        child: result,
        message: 'SLOW MODE',
        location: BannerLocation.topRight);
      return true;
    });
    return result;
  }
}
