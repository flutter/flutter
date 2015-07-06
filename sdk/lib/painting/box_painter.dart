// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import '../base/lerp.dart';
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
  final Offset offset;
  final double blur;

  String toString() => 'BoxShadow($color, $offset, $blur)';
}

BoxShadow lerpBoxShadow(BoxShadow a, BoxShadow b, double t) {
  return new BoxShadow(
      color: lerpColor(a.color, b.color, t),
      offset: lerpOffset(a.offset, b.offset, t),
      blur: lerpNum(a.blur, b.blur, t));
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
    return new sky.Gradient.linear(this.endPoints, this.colors, this.colorStops,
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
    return new sky.Gradient.radial(this.center, this.radius, this.colors,
                                   this.colorStops, this.tileMode);
  }

  final Point center;
  final double radius;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;
}

enum BackgroundFit { fill, contain, cover, none, scaleDown }

enum BackgroundRepeat { repeat, repeatX, repeatY, noRepeat }

// TODO(jackson): We should abstract this out into a separate class
// that handles the image caching and so forth, which has callbacks
// for "size changed" and "image changed". This would also enable us
// to do animated images.

class BackgroundImage {
  final BackgroundFit fit;
  final BackgroundRepeat repeat;
  BackgroundImage({
    Future<sky.Image> image,
    this.fit: BackgroundFit.scaleDown,
    this.repeat: BackgroundRepeat.noRepeat
  }) {
    image.then((resolvedImage) {
      if (resolvedImage == null)
        return;
      _image = resolvedImage;
      _size = new Size(resolvedImage.width.toDouble(), resolvedImage.height.toDouble());
      for (Function listener in _listeners) {
        listener();
      }
    });
  }

  sky.Image _image;
  sky.Image get image => _image;

  Size _size;

  final List<Function> _listeners = new List<Function>();

  void addChangeListener(Function listener) {
    _listeners.add(listener);
  }

  void removeChangeListener(Function listener) {
    _listeners.remove(listener);
  }

  String toString() => 'BackgroundImage($fit, $repeat)';
}

enum Shape { rectangle, circle }

// This must be immutable, because we won't notice when it changes
class BoxDecoration {
  const BoxDecoration({
    this.backgroundColor, // null = don't draw background color
    this.backgroundImage, // null = don't draw background image
    this.border, // null = don't draw border
    this.borderRadius, // null = use more efficient background drawing; note that this must be null for circles
    this.boxShadow, // null = don't draw shadows
    this.gradient, // null = don't allocate gradient objects
    this.shape: Shape.rectangle
  });

  final Color backgroundColor;
  final BackgroundImage backgroundImage;
  final double borderRadius;
  final Border border;
  final List<BoxShadow> boxShadow;
  final Gradient gradient;
  final Shape shape;

  String toString([String prefix = '']) {
    List<String> result = [];
    if (backgroundColor != null)
      result.add('${prefix}backgroundColor: $backgroundColor');
    if (backgroundImage != null)
      result.add('${prefix}backgroundImage: $backgroundImage');
    if (border != null)
      result.add('${prefix}border: $border');
    if (borderRadius != null)
      result.add('${prefix}borderRadius: $borderRadius');
    if (boxShadow != null)
      result.add('${prefix}boxShadow: ${boxShadow.map((shadow) => shadow.toString())}');
    if (gradient != null)
      result.add('${prefix}gradient: $gradient');
    if (shape != Shape.rectangle)
      result.add('${prefix}shape: $shape');
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

  void _paintBackgroundColor(sky.Canvas canvas, Rect rect) {
    if (_decoration.backgroundColor != null || _decoration.boxShadow != null ||
        _decoration.gradient != null) {
      switch (_decoration.shape) {
        case Shape.circle:
          assert(_decoration.borderRadius == null);
          Point center = rect.center;
          double radius = rect.shortestSide / 2.0;
          canvas.drawCircle(center, radius, _backgroundPaint);
          break;
        case Shape.rectangle:
          if (_decoration.borderRadius == null)
            canvas.drawRect(rect, _backgroundPaint);
          else
            canvas.drawRRect(new sky.RRect()..setRectXY(rect, _decoration.borderRadius, _decoration.borderRadius), _backgroundPaint);
          break;
      }
    }
  }

  void _paintBackgroundImage(sky.Canvas canvas, Rect rect) {
    if (_decoration.backgroundImage == null)
      return;
    sky.Image image = _decoration.backgroundImage.image;
    if (image != null) {
      Size bounds = rect.size;
      Size imageSize = _decoration.backgroundImage._size;
      Size src;
      Size dst;
      switch(_decoration.backgroundImage.fit) {
        case BackgroundFit.fill:
          src = imageSize;
          dst = bounds;
          break;
        case BackgroundFit.contain:
          src = imageSize;
          if (bounds.width / bounds.height > src.width / src.height) {
            dst = new Size(bounds.width, src.height * bounds.width / src.width);
          } else {
            dst = new Size(src.width * bounds.height / src.height, bounds.height);
          }
          break;
        case BackgroundFit.cover:
          if (bounds.width / bounds.height > imageSize.width / imageSize.height) {
            src = new Size(imageSize.width, imageSize.width * bounds.height / bounds.width);
          } else {
            src = new Size(imageSize.height * bounds.width / bounds.height, imageSize.height);
          }
          dst = bounds;
          break;
        case BackgroundFit.none:
          src = new Size(math.min(imageSize.width, bounds.width),
                         math.min(imageSize.height, bounds.height));
          dst = src;
          break;
        case BackgroundFit.scaleDown:
          src = imageSize;
          dst = bounds;
          if (src.height > dst.height) {
            dst = new Size(src.width * dst.height / src.height, src.height);
          }
          if (src.width > dst.width) {
            dst = new Size(dst.width, src.height * dst.width / src.width);
          }
          break;
      }
      canvas.drawImageRect(image, Point.origin & src, rect.topLeft & dst, new Paint());
    }
  }

  void _paintBorder(sky.Canvas canvas, Rect rect) {
    if (_decoration.border == null)
      return;

    assert(_decoration.borderRadius == null); // TODO(abarth): Implement borders with border radius.
    assert(_decoration.shape == Shape.rectangle); // TODO(ianh): Implement borders on circles.

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

  void paint(sky.Canvas canvas, Rect rect) {
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintBorder(canvas, rect);
  }
}
