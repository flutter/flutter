// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:sky' show Point, Size, Rect, Color, Paint, Path;
import 'shadows.dart';

class BorderSide {
  const BorderSide({
    this.color: const Color(0xFF000000),
    this.width: 1.0
  });
  final Color color;
  final double width;

  static const none = const BorderSide(width: 0.0);

  int get hashCode {
    int value = 373;
    value = 37 * value * color.hashCode;
    value = 37 * value * width.hashCode;
    return value;
  }
  String toString() => 'BorderSide($color, $width)';
}

class Border {
  const Border({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none
  });

  const Border.all(BorderSide side) :
    top = side,
    right = side,
    bottom = side,
    left = side;

  final BorderSide top;
  final BorderSide right;
  final BorderSide bottom;
  final BorderSide left;

  int get hashCode {
    int value = 373;
    value = 37 * value * top.hashCode;
    value = 37 * value * right.hashCode;
    value = 37 * value * bottom.hashCode;
    value = 37 * value * left.hashCode;
    return value;
  }
  String toString() => 'Border($top, $right, $bottom, $left)';
}

class BoxShadow {
  const BoxShadow({
    this.color,
    this.offset,
    this.blur
  });

  final Color color;
  final Size offset;
  final double blur;

  String toString() => 'BoxShadow($color, $offset, $blur)';
}

abstract class Gradient {
  sky.Shader createShader();
}

class LinearGradient extends Gradient {
  LinearGradient({
    this.endPoints,
    this.colors,
    this.colorStops,
    this.tileMode: sky.TileMode.clamp
  });

  String toString() =>
      'LinearGradient($endPoints, $colors, $colorStops, $tileMode)';

  sky.Shader createShader() {
    return new sky.Gradient.Linear(this.endPoints, this.colors, this.colorStops,
                                   this.tileMode);
  }

  final List<Point> endPoints;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;
}

class RadialGradient extends Gradient {
  RadialGradient({
    this.center,
    this.radius,
    this.colors,
    this.colorStops,
    this.tileMode: sky.TileMode.clamp
  });

  String toString() =>
      'RadialGradient($center, $radius, $colors, $colorStops, $tileMode)';

  sky.Shader createShader() {
    return new sky.Gradient.Radial(this.center, this.radius, this.colors,
                                   this.colorStops, this.tileMode);
  }

  final Point center;
  final double radius;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;
}

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  const BoxDecoration({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient
  });

  final Color backgroundColor;
  final double borderRadius;
  final Border border;
  final List<BoxShadow> boxShadow;
  final Gradient gradient;

  String toString([String prefix = '']) {
    List<String> result = [];
    if (backgroundColor != null)
      result.add('${prefix}backgroundColor: $backgroundColor');
    if (border != null)
      result.add('${prefix}border: $border');
    if (borderRadius != null)
      result.add('${prefix}borderRadius: $borderRadius');
    if (boxShadow != null)
      result.add('${prefix}boxShadow: ${boxShadow.map((shadow) => shadow.toString())}');
    if (gradient != null)
      result.add('${prefix}gradient: $gradient');
    if (result.isEmpty)
      return '${prefix}<no decorations specified>';
    return result.join('\n');
  }
}

class BoxPainter {
  BoxPainter(BoxDecoration decoration) : _decoration = decoration {
    assert(decoration != null);
  }

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  void set decoration (BoxDecoration value) {
    assert(value != null);
    if (value == _decoration)
      return;
    _decoration = value;
    _cachedBackgroundPaint = null;
  }

  Paint _cachedBackgroundPaint;
  Paint get _backgroundPaint {
    if (_cachedBackgroundPaint == null) {
      Paint paint = new Paint();

      if (_decoration.backgroundColor != null)
        paint.color = _decoration.backgroundColor;

      if (_decoration.boxShadow != null) {
        var builder = new ShadowDrawLooperBuilder();
        for (BoxShadow boxShadow in _decoration.boxShadow)
          builder.addShadow(boxShadow.offset, boxShadow.color, boxShadow.blur);
        paint.setDrawLooper(builder.build());
      }

      if (_decoration.gradient != null)
        paint.setShader(_decoration.gradient.createShader());

      _cachedBackgroundPaint = paint;
    }

    return _cachedBackgroundPaint;
  }

  void paint(sky.Canvas canvas, Rect rect) {
    if (_decoration.backgroundColor != null || _decoration.boxShadow != null ||
        _decoration.gradient != null) {
      if (_decoration.borderRadius == null)
        canvas.drawRect(rect, _backgroundPaint);
      else
        canvas.drawRRect(new sky.RRect()..setRectXY(rect, _decoration.borderRadius, _decoration.borderRadius), _backgroundPaint);
    }

    if (_decoration.border != null) {
      assert(_decoration.borderRadius == null); // TODO(abarth): Implement borders with border radius.

      assert(_decoration.border.top != null);
      assert(_decoration.border.right != null);
      assert(_decoration.border.bottom != null);
      assert(_decoration.border.left != null);

      Paint paint = new Paint();
      Path path;

      paint.color = _decoration.border.top.color;
      path = new Path();
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.left + _decoration.border.left.width, rect.top + _decoration.border.top.width);
      path.lineTo(rect.right - _decoration.border.right.width, rect.top + _decoration.border.top.width);
      path.lineTo(rect.right, rect.top);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.right.color;
      path = new Path();
      path.moveTo(rect.right, rect.top);
      path.lineTo(rect.right - _decoration.border.right.width, rect.top + _decoration.border.top.width);
      path.lineTo(rect.right - _decoration.border.right.width, rect.bottom - _decoration.border.bottom.width);
      path.lineTo(rect.right, rect.bottom);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.bottom.color;
      path = new Path();
      path.moveTo(rect.right, rect.bottom);
      path.lineTo(rect.right - _decoration.border.right.width, rect.bottom - _decoration.border.bottom.width);
      path.lineTo(rect.left + _decoration.border.left.width, rect.bottom - _decoration.border.bottom.width);
      path.lineTo(rect.left, rect.bottom);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = _decoration.border.left.color;
      path = new Path();
      path.moveTo(rect.left, rect.bottom);
      path.lineTo(rect.left + _decoration.border.left.width, rect.bottom - _decoration.border.bottom.width);
      path.lineTo(rect.left + _decoration.border.left.width, rect.top + _decoration.border.top.width);
      path.lineTo(rect.left, rect.top);
      path.close();
      canvas.drawPath(path, paint);
    }
  }
}
