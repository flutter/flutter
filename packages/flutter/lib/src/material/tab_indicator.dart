// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Used with [TabBar.indicatorShape] to draw a horizontal line below the
/// selected tab
///
/// The line is inset from the tab's boundary by [padding]. The [borderSide]
/// defines the line's color and weight.
///
/// The [TabBar.indicatorSize] property can be used to define the
/// tab's boundary in terms of its (centered) widget, [TabIndicatorSize.label],
/// or the the entire tab, [TabIndicatorSize.tab].
class UnderlineTabIndicator extends ShapeBorder {
  /// Create an underline style tab indicator.
  ///
  /// The [borderSide] and [padding] arguments must not be null.
  const UnderlineTabIndicator({
    this.borderSide: const BorderSide(width: 2.0, color: Colors.white),
    this.padding: EdgeInsets.zero,
  }) : assert(borderSide != null), assert(padding != null);

  /// The color and weight of the line drawn below the selected tab.
  final BorderSide borderSide;

  /// Locates the [borderSide] style selected tab underline relative to the
  /// tab's boundary.
  ///
  /// The [TabBar.indicatorSize] property can be used to define the
  /// tab's boundary in terms of its (centered) widget, [TabIndicatorSize.label],
  /// or the the entire tab, [TabIndicatorSize.tab].
  final EdgeInsetsGeometry padding;

  @override
  EdgeInsetsGeometry get dimensions {
    return padding.subtract(new EdgeInsets.only(bottom: borderSide.width));
  }

  @override
  UnderlineTabIndicator scale(double t) {
    return new UnderlineTabIndicator(
      borderSide: borderSide.scale(t),
      padding: padding * t,
    );
  }

  Rect _indicatorRectFor(Rect rect, TextDirection textDirection) {
    assert(rect != null);
    assert(textDirection != null);
    final Rect indicator = padding.resolve(textDirection).deflateRect(rect);
    return new Rect.fromLTWH(
      indicator.left,
      indicator.bottom - borderSide.width,
      indicator.width,
      borderSide.width,
    );
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(_indicatorRectFor(rect, textDirection).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(_indicatorRectFor(rect, textDirection));
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is UnderlineTabIndicator) {
      return new UnderlineTabIndicator(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        padding: EdgeInsetsGeometry.lerp(a.padding, padding, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is UnderlineTabIndicator) {
      return new UnderlineTabIndicator(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        padding: EdgeInsetsGeometry.lerp(padding, b.padding, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    final Rect indicator = _indicatorRectFor(rect, textDirection).deflate(borderSide.width / 2.0);
    canvas.drawLine(indicator.bottomLeft, indicator.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final UnderlineTabIndicator typedOther = other;
    return typedOther.borderSide == borderSide && typedOther.padding == padding;
  }

  @override
  int get hashCode => hashValues(borderSide, padding);
}
