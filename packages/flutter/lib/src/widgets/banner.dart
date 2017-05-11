// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';

const double _kOffset = 40.0; // distance to bottom of banner, at a 45 degree angle inwards
const double _kHeight = 12.0; // height of banner
const double _kBottomOffset = _kOffset + 0.707 * _kHeight; // offset plus sqrt(2)/2 * banner height
final Rect _kRect = new Rect.fromLTWH(-_kOffset, _kOffset - _kHeight, _kOffset * 2.0, _kHeight);

const Color _kColor = const Color(0xA0B71C1C);
const TextStyle _kTextStyle = const TextStyle(
  color: const Color(0xFFFFFFFF),
  fontSize: _kHeight * 0.85,
  fontWeight: FontWeight.w900,
  height: 1.0
);

/// Where to show a [Banner].
enum BannerLocation {
  /// Show the banner in the top right corner.
  topRight,

  /// Show the banner in the top left corner.
  topLeft,

  /// Show the banner in the bottom right corner.
  bottomRight,

  /// Show the banner in the bottom left corner.
  bottomLeft,
}

/// Paints a [Banner].
class BannerPainter extends CustomPainter {
  /// Creates a banner painter.
  ///
  /// The [message] and [location] arguments must not be null.
  BannerPainter({
    @required this.message,
    @required this.location,
    this.color: _kColor,
    this.textStyle: _kTextStyle,
  }) {
    assert(message != null);
    assert(location != null);
    assert(color != null);
    assert(textStyle != null);
  }

  /// The message to show in the banner.
  final String message;

  /// Where to show the banner (e.g., the upper right corder).
  final BannerLocation location;

  /// The color to paint behind the [message].
  ///
  /// Defaults to a dark red.
  final Color color;

  /// The text style to use for the [message].
  ///
  /// Defaults to bold, white text.
  final TextStyle textStyle;

  bool _prepared = false;
  TextPainter _textPainter;
  Paint _paintShadow;
  Paint _paintBanner;

  void _prepare() {
    _paintShadow = new Paint()
      ..color = const Color(0x7F000000)
      ..maskFilter = new MaskFilter.blur(BlurStyle.normal, 4.0);
    _paintBanner = new Paint()
      ..color = color;
    _textPainter = new TextPainter(
      text: new TextSpan(style: textStyle, text: message),
      textAlign: TextAlign.center,
    );
    _prepared = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!_prepared)
      _prepare();
    canvas
      ..translate(_translationX(size.width), _translationY(size.height))
      ..rotate(_rotation)
      ..drawRect(_kRect, _paintShadow)
      ..drawRect(_kRect, _paintBanner);
    final double width = _kOffset * 2.0;
    _textPainter.layout(minWidth: width, maxWidth: width);
    _textPainter.paint(canvas, _kRect.topLeft + new Offset(0.0, (_kRect.height - _textPainter.height) / 2.0));
  }

  @override
  bool shouldRepaint(BannerPainter oldPainter) {
    return message != oldPainter.message
        || location != oldPainter.location
        || color != oldPainter.color
        || textStyle != oldPainter.textStyle;
  }

  @override
  bool hitTest(Offset position) => false;

  double _translationX(double width) {
    assert(location != null);
    switch (location) {
      case BannerLocation.bottomRight:
        return width - _kBottomOffset;
      case BannerLocation.topRight:
        return width;
      case BannerLocation.bottomLeft:
        return _kBottomOffset;
      case BannerLocation.topLeft:
        return 0.0;
    }
    return null;
  }

  double _translationY(double height) {
    assert(location != null);
    switch (location) {
      case BannerLocation.bottomRight:
      case BannerLocation.bottomLeft:
        return height - _kBottomOffset;
      case BannerLocation.topRight:
      case BannerLocation.topLeft:
        return 0.0;
    }
    return null;
  }

  double get _rotation {
    assert(location != null);
    switch (location) {
      case BannerLocation.bottomLeft:
      case BannerLocation.topRight:
        return math.PI / 4.0;
      case BannerLocation.bottomRight:
      case BannerLocation.topLeft:
        return -math.PI / 4.0;
    }
    return null;
  }
}

/// Displays a diagonal message above the corner of another widget.
///
/// Useful for showing the execution mode of an app (e.g., that asserts are
/// enabled.)
///
/// See also:
///
///  * [CheckedModeBanner].
class Banner extends StatelessWidget {
  /// Creates a banner.
  ///
  /// The [message] and [location] arguments must not be null.
  const Banner({
    Key key,
    this.child,
    @required this.message,
    @required this.location,
    this.color: _kColor,
    this.textStyle: _kTextStyle,
  }) : assert(message != null),
       assert(location != null),
       assert(color != null),
       assert(textStyle != null),
       super(key: key);

  /// The widget to show behind the banner.
  final Widget child;

  /// The message to show in the banner.
  final String message;

  /// Where to show the banner (e.g., the upper right corder).
  final BannerLocation location;

  /// The color of the banner.
  final Color color;

  /// The style of the text shown on the banner.
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      foregroundPainter: new BannerPainter(
        message: message,
        location: location,
        color: color,
        textStyle: textStyle,
      ),
      child: child,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$message"');
    description.add('$location');
    description.add('$color');
    '$textStyle'.split('\n').map((String value) => 'text $value').forEach(description.add);
  }
}

/// Displays a [Banner] saying "SLOW MODE" when running in checked mode.
/// [MaterialApp] builds one of these by default.
/// Does nothing in release mode.
class CheckedModeBanner extends StatelessWidget {
  /// Creates a checked mode banner.
  const CheckedModeBanner({
    Key key,
    @required this.child
  }) : super(key: key);

  /// The widget to show behind the banner.
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

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    String message = 'disabled';
    assert(() {
      message = '"SLOW MODE"';
      return true;
    });
    description.add(message);
  }
}
