import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/indicator_effect.dart';

/// Basic implementation of [IndicatorPainter] that holds some shared
/// properties and behaviors between different painters
abstract class BasicIndicatorPainter extends IndicatorPainter {
  /// The count of pages
  final int count;

  /// The provided effect is passed to this super class
  /// to make some calculations and paint still dots
  final BasicIndicatorEffect _effect;

  /// Inactive dot paint or base paint in one-color effects.
  final Paint dotPaint;

  /// The Radius of all dots
  final Radius dotRadius;

  /// Default constructor
  BasicIndicatorPainter(
    double offset,
    this.count,
    this._effect,
  )   : dotRadius = Radius.circular(_effect.radius),
        dotPaint = Paint()
          ..color = _effect.dotColor
          ..style = _effect.paintStyle
          ..strokeWidth = _effect.strokeWidth,
        super(offset);

  /// The distance between dot lefts
  double get distance => _effect.dotWidth + _effect.spacing;

  /// Paints [count] number of dots with no animation
  ///
  /// Meant to be used by  effects that only
  /// animate the active dot
  void paintStillDots(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final rect = buildStillDot(i, size);
      canvas.drawRRect(rect, dotPaint);
    }
  }

  /// Builds a single still dot
  RRect buildStillDot(int i, Size size) {
    final xPos = (i * distance);
    final yPos = size.height / 2;
    final bounds = Rect.fromLTRB(
      xPos,
      yPos - _effect.dotHeight / 2,
      xPos + _effect.dotWidth,
      yPos + _effect.dotHeight / 2,
    );
    var rect = RRect.fromRectAndRadius(bounds, dotRadius);
    return rect;
  }

  /// Masks spaces between dots
  ///
  /// used by under-layer effects like WormType.underground
  void maskStillDots(Size size, Canvas canvas) {
    var path = Path()..addRect((const Offset(0, 0) & size));
    for (var i = 0; i < count; i++) {
      path = Path.combine(PathOperation.difference, path,
          Path()..addRRect(buildStillDot(i, size)));
    }
    canvas.drawPath(path, Paint()..blendMode = BlendMode.clear);
  }

  /// Calculates the shape of a dot while portal-traveling
  /// form last-to-first dot or form first-to-last dot
  RRect calcPortalTravel(Size size, double offset, double dotOffset) {
    final yPos = size.height / 2;
    var width = dotOffset * (_effect.dotHeight / 2);
    var height = dotOffset * (_effect.dotWidth / 2);
    var xPos = offset;
    return RRect.fromLTRBR(
      xPos - height,
      yPos - width,
      xPos + height,
      yPos + width,
      Radius.circular(dotRadius.x * dotOffset),
    );
  }
}

/// A basic abstract implementation of [customPainter]
/// to avoid overriding [shouldRepaint] in every painter
abstract class IndicatorPainter extends CustomPainter {
  /// The raw offset from the [PageController].page
  final double offset;

  /// Default constructor
  const IndicatorPainter(this.offset);

  @override
  bool shouldRepaint(IndicatorPainter oldDelegate) {
    /// only repaint if the offset changes
    return oldDelegate.offset != offset;
  }
}
