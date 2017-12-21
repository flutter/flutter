// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'scroll_metrics.dart';

const double _kMinThumbExtent = 18.0;

/// A [CustomPainter] for painting scrollbars.
///
/// Unlike [CustomPainter]s that subclasses [CustomPainter] and only repaint
/// when [shouldRepaint] returns true (which requires this [CustomPainter] to
/// be rebuilt), this painter has the added optimization of repainting and not
/// rebuilding when:
///
///  * the scroll position changes; and
///  * when the scrollbar fades away.
///
/// Calling [update] with the new [ScrollMetrics] will repaint the new scrollbar
/// position.
///
/// Updating the value on the provided [fadeoutOpacityAnimation] will repaint
/// with the new opacity.
///
/// You must call [dispose] on this [ScrollbarPainter] when it's no longer used.
///
/// See also:
///
///  * [Scrollbar] for a widget showing a scrollbar around a [Scrollable] in the
///    Material Design style.
///  * [CupertinoScrollbar] for a widget showing a scrollbar around a
///    [Scrollable] in the iOS style.
class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  ScrollbarPainter({
    @required this.color,
    @required this.textDirection,
    @required this.thickness,
    @required this.fadeoutOpacityAnimation,
    this.mainAxisMargin: 0.0,
    this.crossAxisMargin: 0.0,
    this.radius,
    this.minLength: _kMinThumbExtent,
  }) : assert(color != null),
       assert(textDirection != null),
       assert(thickness != null),
       assert(fadeoutOpacityAnimation != null),
       assert(mainAxisMargin != null),
       assert(crossAxisMargin != null),
       assert(minLength != null) {
    fadeoutOpacityAnimation.addListener(notifyListeners);
  }

  /// [Color] of the thumb. Mustn't be null.
  final Color color;

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Mustn't be null.
  final TextDirection textDirection;

  /// Thickness of the scrollbar in its cross-axis in pixels. Mustn't be null.
  final double thickness;

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  /// Distance from the scrollbar's start and end to the edge of the viewport in
  /// pixels. Mustn't be null.
  final double mainAxisMargin;

  /// Distance from the scrollbar's side to the nearest edge in pixels. Musn't
  /// be null.
  final double crossAxisMargin;

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  final Radius radius;

  /// The smallest size the scrollbar can shrink to when the total scrollable
  /// extent is large and the current visible viewport is small. Mustn't be
  /// null.
  final double minLength;

  ScrollMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;

  /// Update with new [ScrollMetrics]. The scrollbar will show and redraw itself
  /// based on these new metrics.
  ///
  /// The scrollbar will remain on screen.
  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    notifyListeners();
  }

  Paint get _paint {
    return new Paint()..color =
        color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  double _getThumbX(Size size) {
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return crossAxisMargin;
      case TextDirection.ltr:
        return size.width - thickness - crossAxisMargin;
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

  void _paintThumb(
    double before,
    double inside,
    double after,
    double viewport,
    Canvas canvas,
    Size size,
    void painter(Canvas canvas, Size size, double thumbOffset, double thumbExtent),
  ) {
    // Establish the minimum size possible.
    double thumbExtent = math.min(viewport, minLength);
    if (before + inside + after > 0.0) {
      final double fractionVisible = inside / (before + inside + after);
      thumbExtent = math.max(
        thumbExtent,
        viewport * fractionVisible - 2 * mainAxisMargin,
      );
    }

    final double fractionPast = before / (before + after);
    final double thumbOffset = (before + after > 0.0)
        ? fractionPast * (viewport - thumbExtent - 2 * mainAxisMargin) + mainAxisMargin
        : mainAxisMargin;

    painter(canvas, size, thumbOffset, thumbExtent);
  }

  @override
  void dispose() {
    fadeoutOpacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null
        || _lastMetrics == null
        || fadeoutOpacityAnimation.value == 0.0)
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

  // Scrollbars are (currently) not interactive.
  @override
  bool hitTest(Offset position) => null;

  @override
  bool shouldRepaint(ScrollbarPainter old) {
    // Should repaint if any properties changed.
    return color != old.color
        || textDirection != old.textDirection
        || thickness != old.thickness
        || fadeoutOpacityAnimation != old.fadeoutOpacityAnimation
        || mainAxisMargin != old.mainAxisMargin
        || crossAxisMargin != old.crossAxisMargin
        || radius != old.radius
        || minLength != old.minLength;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback get semanticsBuilder => null;
}