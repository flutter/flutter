// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:sky/base/image_resource.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/shadows.dart';

class EdgeDims {
  // used for e.g. padding
  const EdgeDims(this.top, this.right, this.bottom, this.left);
  const EdgeDims.all(double value)
      : top = value, right = value, bottom = value, left = value;
  const EdgeDims.only({ this.top: 0.0,
                        this.right: 0.0,
                        this.bottom: 0.0,
                        this.left: 0.0 });
  const EdgeDims.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : top = vertical, left = horizontal, bottom = vertical, right = horizontal;

  final double top;
  final double right;
  final double bottom;
  final double left;

  bool operator ==(other) {
    if (identical(this, other))
      return true;
    return other is EdgeDims
        && top == other.top
        && right == other.right
        && bottom == other.bottom
        && left == other.left;
  }

  EdgeDims operator+(EdgeDims other) {
    return new EdgeDims(top + other.top,
                        right + other.right,
                        bottom + other.bottom,
                        left + other.left);
  }

  EdgeDims operator-(EdgeDims other) {
    return new EdgeDims(top - other.top,
                        right - other.right,
                        bottom - other.bottom,
                        left - other.left);
  }

  static const EdgeDims zero = const EdgeDims(0.0, 0.0, 0.0, 0.0);

  int get hashCode {
    int value = 373;
    value = 37 * value + top.hashCode;
    value = 37 * value + left.hashCode;
    value = 37 * value + bottom.hashCode;
    value = 37 * value + right.hashCode;
    return value;
  }
  String toString() => "EdgeDims($top, $right, $bottom, $left)";
}

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

  factory Border.all({
    Color color: const Color(0xFF000000),
    double width: 1.0
  }) {
    BorderSide side = new BorderSide(color: color, width: width);
    return new Border(top: side, right: side, bottom: side, left: side);
  }

  final BorderSide top;
  final BorderSide right;
  final BorderSide bottom;
  final BorderSide left;

  EdgeDims get dimensions {
    return new EdgeDims(top.width, right.width, bottom.width, left.width);
  }

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

  BoxShadow scale(double factor) {
    return new BoxShadow(
      color: color,
      offset: offset * factor,
      blur: blur * factor
    );
  }

  String toString() => 'BoxShadow($color, $offset, $blur)';
}

BoxShadow lerpBoxShadow(BoxShadow a, BoxShadow b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    return b.scale(t);
  if (b == null)
    return a.scale(1.0 - t);
  return new BoxShadow(
    color: lerpColor(a.color, b.color, t),
    offset: lerpOffset(a.offset, b.offset, t),
    blur: lerpNum(a.blur, b.blur, t)
  );
}

List<BoxShadow> lerpListBoxShadow(List<BoxShadow> a, List<BoxShadow> b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    a = new List<BoxShadow>();
  if (b == null)
    b = new List<BoxShadow>();
  List<BoxShadow> result = new List<BoxShadow>();
  int commonLength = math.min(a.length, b.length);
  for (int i = 0; i < commonLength; ++i)
    result.add(lerpBoxShadow(a[i], b[i], t));
  for (int i = commonLength; i < a.length; ++i)
    result.add(a[i].scale(1.0 - t));
  for (int i = commonLength; i < b.length; ++i)
    result.add(b[i].scale(t));
  return result;
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

  final List<Point> endPoints;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;

  sky.Shader createShader() {
    return new sky.Gradient.linear(this.endPoints, this.colors,
                                   this.colorStops, this.tileMode);
  }

  String toString() {
    return 'LinearGradient($endPoints, $colors, $colorStops, $tileMode)';
  }
}

class RadialGradient extends Gradient {
  RadialGradient({
    this.center,
    this.radius,
    this.colors,
    this.colorStops,
    this.tileMode: sky.TileMode.clamp
  });

  final Point center;
  final double radius;
  final List<Color> colors;
  final List<double> colorStops;
  final sky.TileMode tileMode;

  sky.Shader createShader() {
    return new sky.Gradient.radial(this.center, this.radius, this.colors,
                                   this.colorStops, this.tileMode);
  }

  String toString() {
    return 'RadialGradient($center, $radius, $colors, $colorStops, $tileMode)';
  }
}

enum ImageFit { fill, contain, cover, none, scaleDown }

enum ImageRepeat { repeat, repeatX, repeatY, noRepeat }

void paintImage({
  sky.Canvas canvas,
  Rect rect,
  sky.Image image,
  sky.ColorFilter colorFilter,
  fit: ImageFit.scaleDown,
  repeat: ImageRepeat.noRepeat,
  double positionX: 0.5,
  double positionY: 0.5
}) {
  Size bounds = rect.size;
  Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
  Size sourceSize;
  Size destinationSize;
  switch(fit) {
    case ImageFit.fill:
      sourceSize = imageSize;
      destinationSize = bounds;
      break;
    case ImageFit.contain:
      sourceSize = imageSize;
      if (bounds.width / bounds.height > sourceSize.width / sourceSize.height)
        destinationSize = new Size(sourceSize.width * bounds.height / sourceSize.height, bounds.height);
      else
        destinationSize = new Size(bounds.width, sourceSize.height * bounds.width / sourceSize.width);
      break;
    case ImageFit.cover:
      if (bounds.width / bounds.height > imageSize.width / imageSize.height)
        sourceSize = new Size(imageSize.width, imageSize.width * bounds.height / bounds.width);
      else
        sourceSize = new Size(imageSize.height * bounds.width / bounds.height, imageSize.height);
      destinationSize = bounds;
      break;
    case ImageFit.none:
      sourceSize = new Size(math.min(imageSize.width, bounds.width),
                            math.min(imageSize.height, bounds.height));
      destinationSize = sourceSize;
      break;
    case ImageFit.scaleDown:
      sourceSize = imageSize;
      destinationSize = bounds;
      if (sourceSize.height > destinationSize.height)
        destinationSize = new Size(sourceSize.width * destinationSize.height / sourceSize.height, sourceSize.height);
      if (sourceSize.width > destinationSize.width)
        destinationSize = new Size(destinationSize.width, sourceSize.height * destinationSize.width / sourceSize.width);
      break;
  }
  // TODO(abarth): Implement |repeat|.
  Paint paint = new Paint();
  if (colorFilter != null)
    paint.setColorFilter(colorFilter);
  double dx = (bounds.width - destinationSize.width) * positionX;
  double dy = (bounds.height - destinationSize.height) * positionY;
  Point destinationPosition = rect.topLeft + new Offset(dx, dy);
  canvas.drawImageRect(image, Point.origin & sourceSize, destinationPosition & destinationSize, paint);
}

typedef void BackgroundImageChangeListener();

class BackgroundImage {
  final ImageFit fit;
  final ImageRepeat repeat;
  final sky.ColorFilter colorFilter;

  BackgroundImage({
    ImageResource image,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat,
    this.colorFilter
  }) : _imageResource = image;

  sky.Image _image;
  sky.Image get image => _image;

  ImageResource _imageResource;

  final List<BackgroundImageChangeListener> _listeners =
      new List<BackgroundImageChangeListener>();

  void addChangeListener(BackgroundImageChangeListener listener) {
    // We add the listener to the _imageResource first so that the first change
    // listener doesn't get callback synchronously if the image resource is
    // already resolved.
    if (_listeners.isEmpty)
      _imageResource.addListener(_handleImageChanged);
    _listeners.add(listener);
  }

  void removeChangeListener(BackgroundImageChangeListener listener) {
    _listeners.remove(listener);
    // We need to remove ourselves as listeners from the _imageResource so that
    // we're not kept alive by the image_cache.
    if (_listeners.isEmpty)
      _imageResource.removeListener(_handleImageChanged);
  }

  void _handleImageChanged(sky.Image resolvedImage) {
    if (resolvedImage == null)
      return;
    _image = resolvedImage;
    final List<BackgroundImageChangeListener> localListeners =
        new List<BackgroundImageChangeListener>.from(_listeners);
    for (BackgroundImageChangeListener listener in localListeners) {
      listener();
    }
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

  BoxDecoration scale(double factor) {
    // TODO(abarth): Scale ALL the things.
    return new BoxDecoration(
      backgroundColor: lerpColor(null, backgroundColor, factor),
      backgroundImage: backgroundImage,
      border: border,
      borderRadius: lerpNum(null, borderRadius, factor),
      boxShadow: lerpListBoxShadow(null, boxShadow, factor),
      gradient: gradient,
      shape: shape
    );
  }

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

BoxDecoration lerpBoxDecoration(BoxDecoration a, BoxDecoration b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    return b.scale(t);
  if (b == null)
    return a.scale(1.0 - t);
  // TODO(abarth): lerp ALL the fields.
  return new BoxDecoration(
    backgroundColor: lerpColor(a.backgroundColor, b.backgroundColor, t),
    backgroundImage: b.backgroundImage,
    border: b.border,
    borderRadius: lerpNum(a.borderRadius, b.borderRadius, t),
    boxShadow: lerpListBoxShadow(a.boxShadow, b.boxShadow, t),
    gradient: b.gradient,
    shape: b.shape
  );
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

  bool get _hasUniformBorder {
    Color color = _decoration.border.top.color;
    bool hasUniformColor =
      _decoration.border.right.color == color &&
      _decoration.border.bottom.color == color &&
      _decoration.border.left.color == color;

    if (!hasUniformColor)
      return false;

    double width = _decoration.border.top.width;
    bool hasUniformWidth =
      _decoration.border.right.width == width &&
      _decoration.border.bottom.width == width &&
      _decoration.border.left.width == width;

    return hasUniformWidth;
  }

  void _paintBackgroundColor(sky.Canvas canvas, Rect rect) {
    if (_decoration.backgroundColor != null ||
        _decoration.boxShadow != null ||
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
    final BackgroundImage backgroundImage = _decoration.backgroundImage;
    if (backgroundImage == null)
      return;
    sky.Image image = backgroundImage.image;
    if (image == null)
      return;
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      colorFilter: backgroundImage.colorFilter,
      fit:  backgroundImage.fit,
      repeat: backgroundImage.repeat
    );
  }

  void _paintBorder(sky.Canvas canvas, Rect rect) {
    if (_decoration.border == null)
      return;

    if (_hasUniformBorder) {
      if (_decoration.borderRadius != null) {
        _paintBorderWithRadius(canvas, rect);
        return;
      }
      if (_decoration.shape == Shape.circle) {
        _paintBorderWithCircle(canvas, rect);
        return;
      }
    }

    assert(_decoration.borderRadius == null); // TODO(abarth): Support non-uniform rounded borders.
    assert(_decoration.shape == Shape.rectangle); // TODO(ianh): Support borders on circles.

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

  void _paintBorderWithRadius(sky.Canvas canvas, Rect rect) {
    assert(_hasUniformBorder);
    assert(_decoration.shape == Shape.rectangle);
    Color color = _decoration.border.top.color;
    double width = _decoration.border.top.width;
    double radius = _decoration.borderRadius;

    sky.RRect outer = new sky.RRect()..setRectXY(rect, radius, radius);
    sky.RRect inner = new sky.RRect()..setRectXY(rect.deflate(width), radius - width, radius - width);
    canvas.drawDRRect(outer, inner, new Paint()..color = color);
  }

  void _paintBorderWithCircle(sky.Canvas canvas, Rect rect) {
    assert(_hasUniformBorder);
    assert(_decoration.shape == Shape.circle);
    assert(_decoration.borderRadius == null);
    double width = _decoration.border.top.width;
    Paint paint = new Paint()
      ..color = _decoration.border.top.color
      ..strokeWidth = width
      ..setStyle(sky.PaintingStyle.stroke);
    Point center = rect.center;
    double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(center, radius, paint);
  }

  void paint(sky.Canvas canvas, Rect rect) {
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintBorder(canvas, rect);
  }
}
