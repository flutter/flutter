// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:sky' show Point, Offset, Size, Rect, Color, Paint, Path;

import 'package:sky/base/image_resource.dart';
import 'package:sky/painting/shadows.dart';

/// An immutable set of offsets in each of the four cardinal directions
///
/// Typically used for an offset from each of the four sides of a box. For
/// example, the padding inside a box can be represented using this class.
class EdgeDims {
  // TODO(abarth): Remove this constructor or rename it to EdgeDims.fromTRBL.
  /// Constructs an EdgeDims from offsets from the top, right, bottom and left
  const EdgeDims(this.top, this.right, this.bottom, this.left);

  /// Constructs an EdgeDims where all the offsets are value
  const EdgeDims.all(double value)
      : top = value, right = value, bottom = value, left = value;

  /// Constructs an EdgeDims with only the given values non-zero
  const EdgeDims.only({ this.top: 0.0,
                        this.right: 0.0,
                        this.bottom: 0.0,
                        this.left: 0.0 });

  /// Constructs an EdgeDims with symmetrical vertical and horizontal offsets
  const EdgeDims.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : top = vertical, left = horizontal, bottom = vertical, right = horizontal;

  /// The offset from the top
  final double top;

  /// The offset from the right
  final double right;

  /// The offset from the bottom
  final double bottom;

  /// The offset from the left
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

  /// An EdgeDims with zero offsets in each direction
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

/// A side of a border of a box
class BorderSide {
  const BorderSide({
    this.color: const Color(0xFF000000),
    this.width: 1.0
  });

  /// The color of this side of the border
  final Color color;

  /// The width of this side of the border
  final double width;

  /// A black border side of zero width
  static const none = const BorderSide(width: 0.0);

  int get hashCode {
    int value = 373;
    value = 37 * value * color.hashCode;
    value = 37 * value * width.hashCode;
    return value;
  }
  String toString() => 'BorderSide($color, $width)';
}

/// A border of a box, comprised of four sides
class Border {
  const Border({
    this.top: BorderSide.none,
    this.right: BorderSide.none,
    this.bottom: BorderSide.none,
    this.left: BorderSide.none
  });

  /// A uniform border with all sides the same color and width
  factory Border.all({
    Color color: const Color(0xFF000000),
    double width: 1.0
  }) {
    BorderSide side = new BorderSide(color: color, width: width);
    return new Border(top: side, right: side, bottom: side, left: side);
  }

  /// The top side of this border
  final BorderSide top;

  /// The right side of this border
  final BorderSide right;

  /// The bottom side of this border
  final BorderSide bottom;

  /// The left side of this border
  final BorderSide left;

  /// The widths of the sides of this border represented as an EdgeDims
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

/// A shadow cast by a box
///
/// Note: BoxShadow can cast non-rectangular shadows if the box is
/// non-rectangular (e.g., has a border radius or a circular shape).
class BoxShadow {
  const BoxShadow({
    this.color,
    this.offset,
    this.blur
  });

  /// The color of the shadow
  final Color color;

  /// The displacement of the shadow from the box
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the box's shape
  final double blur;

  /// Returns a new box shadow with its offset and blur scaled by the given factor
  BoxShadow scale(double factor) {
    return new BoxShadow(
      color: color,
      offset: offset * factor,
      blur: blur * factor
    );
  }

  /// Linearly interpolate between two box shadows
  ///
  /// If either box shadow is null, this function linearly interpolates from a
  /// a box shadow that matches the other box shadow in color but has a zero
  /// offset and a zero blur.
  static BoxShadow lerp(BoxShadow a, BoxShadow b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return new BoxShadow(
      color: Color.lerp(a.color, b.color, t),
      offset: Offset.lerp(a.offset, b.offset, t),
      blur: sky.lerpDouble(a.blur, b.blur, t)
    );
  }

  /// Linearly interpolate between two lists of box shadows
  ///
  /// If the lists differ in length, excess items are lerped with null.
  static List<BoxShadow> lerpList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      a = new List<BoxShadow>();
    if (b == null)
      b = new List<BoxShadow>();
    List<BoxShadow> result = new List<BoxShadow>();
    int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; ++i)
      result.add(BoxShadow.lerp(a[i], b[i], t));
    for (int i = commonLength; i < a.length; ++i)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; ++i)
      result.add(b[i].scale(t));
    return result;
  }

  String toString() => 'BoxShadow($color, $offset, $blur)';
}

/// A 2D gradient
abstract class Gradient {
  sky.Shader createShader();
}

/// A 2D linear gradient
class LinearGradient extends Gradient {
  LinearGradient({
    this.begin,
    this.end,
    this.colors,
    this.stops,
    this.tileMode: sky.TileMode.clamp
  }) {
    assert(colors.length == stops.length);
  }

  /// The point at which stop 0.0 of the gradient is placed
  final Point begin;

  /// The point at which stop 1.0 of the gradient is placed
  final Point end;

  /// The colors the gradient should obtain at each of the stops
  ///
  /// Note: This list must have the same length as [stops].
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote fractions of the vector from start to end
  ///
  /// Note: This list must have the same length as [colors].
  final List<double> stops;

  /// How this gradient should tile the plane
  final sky.TileMode tileMode;

  sky.Shader createShader() {
    return new sky.Gradient.linear([begin, end], this.colors,
                                   this.stops, this.tileMode);
  }

  String toString() {
    return 'LinearGradient($begin, $end, $colors, $stops, $tileMode)';
  }
}

/// A 2D radial gradient
class RadialGradient extends Gradient {
  RadialGradient({
    this.center,
    this.radius,
    this.colors,
    this.stops,
    this.tileMode: sky.TileMode.clamp
  });

  /// The center of the gradient
  final Point center;

  /// The radius at which stop 1.0 is placed
  final double radius;

  /// The colors the gradient should obtain at each of the stops
  ///
  /// Note: This list must have the same length as [stops].
  final List<Color> colors;

  /// A list of values from 0.0 to 1.0 that denote concentric rings
  ///
  /// The rings are centered at [center] and have a radius equal to the value of
  /// the stop times [radius].
  ///
  /// Note: This list must have the same length as [colors].
  final List<double> stops;

  /// How this gradient should tile the plane
  final sky.TileMode tileMode;

  sky.Shader createShader() {
    return new sky.Gradient.radial(center, radius, colors, stops, tileMode);
  }

  String toString() {
    return 'RadialGradient($center, $radius, $colors, $stops, $tileMode)';
  }
}

/// How an image should be inscribed into a box
enum ImageFit {
  /// Fill the box by distorting the image's aspect ratio
  fill,

  /// As large as possible while still containing the image entirely within the box
  contain,

  /// As small as possible while still covering the entire box
  cover,

  /// Center the image within the box and discard any portions of the image that
  /// lie outside the box
  none,

  /// Center the image within the box and, if necessary, scale the image down to
  /// ensure that the image fits within the box
  scaleDown
}

/// How to paint any portions of a box not covered by an image
enum ImageRepeat {
  /// Repeat the image in both the x and y directions until the box is filled
  repeat,

  /// Repeat the image in the x direction until the box is filled horizontally
  repeatX,

  /// Repeat the image in the y direction until the box is filled vertically
  repeatY,

  /// Leave uncovered poritions of the box transparent
  noRepeat
}

/// Paint an image into the given rectangle in the canvas
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

/// A background image for a box
class BackgroundImage {
  /// How the background image should be inscribed into the box
  final ImageFit fit;

  /// How to paint any portions of the box not covered by the background image
  final ImageRepeat repeat;

  /// A color filter to apply to the background image before painting it
  final sky.ColorFilter colorFilter;

  BackgroundImage({
    ImageResource image,
    this.fit: ImageFit.scaleDown,
    this.repeat: ImageRepeat.noRepeat,
    this.colorFilter
  }) : _imageResource = image;

  sky.Image _image;
  /// The image to be painted into the background
  sky.Image get image => _image;

  ImageResource _imageResource;

  final List<BackgroundImageChangeListener> _listeners =
      new List<BackgroundImageChangeListener>();

  /// Call listener when the background images changes (e.g., arrives from the network)
  void addChangeListener(BackgroundImageChangeListener listener) {
    // We add the listener to the _imageResource first so that the first change
    // listener doesn't get callback synchronously if the image resource is
    // already resolved.
    if (_listeners.isEmpty)
      _imageResource.addListener(_handleImageChanged);
    _listeners.add(listener);
  }

  /// No longer call listener when the background image changes
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

// TODO(abarth): Rename to BoxShape?
/// A 2D geometrical shape
enum Shape {
  /// An axis-aligned, 2D rectangle
  rectangle,

  /// A 2D locus of points equidistant from a single point
  circle
}

/// An immutable description of how to paint a box
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

  /// The color to fill in the background of the box
  ///
  /// The color is filled into the shape of the box (e.g., either a rectangle,
  /// potentially with a border radius, or a circle).
  final Color backgroundColor;

  /// An image to paint above the background color
  final BackgroundImage backgroundImage;

  /// A border to draw above the background
  final Border border;

  /// If non-null, the corners of this box are rounded by this radius
  ///
  /// Applies only to boxes with rectangular shapes.
  final double borderRadius;

  /// A list of shadows cast by this box behind the background
  final List<BoxShadow> boxShadow;

  /// A graident to use when filling the background
  final Gradient gradient;

  /// The shape to fill the background color into and to cast as a shadow
  final Shape shape;

  /// Returns a new box decoration that is scalled by the given factor
  BoxDecoration scale(double factor) {
    // TODO(abarth): Scale ALL the things.
    return new BoxDecoration(
      backgroundColor: Color.lerp(null, backgroundColor, factor),
      backgroundImage: backgroundImage,
      border: border,
      borderRadius: sky.lerpDouble(null, borderRadius, factor),
      boxShadow: BoxShadow.lerpList(null, boxShadow, factor),
      gradient: gradient,
      shape: shape
    );
  }

  /// Linearly interpolate between two box decorations
  ///
  /// Interpolates each parameter of the box decoration separately.
  static BoxDecoration lerp(BoxDecoration a, BoxDecoration b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    // TODO(abarth): lerp ALL the fields.
    return new BoxDecoration(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      backgroundImage: b.backgroundImage,
      border: b.border,
      borderRadius: sky.lerpDouble(a.borderRadius, b.borderRadius, t),
      boxShadow: BoxShadow.lerpList(a.boxShadow, b.boxShadow, t),
      gradient: b.gradient,
      shape: b.shape
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

/// An object that paints a [BoxDecoration] into a canvas
class BoxPainter {
  BoxPainter(BoxDecoration decoration) : _decoration = decoration {
    assert(decoration != null);
  }

  BoxDecoration _decoration;
  /// The box decoration to paint
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

  double _getEffectiveBorderRadius(Rect rect) {
    double shortestSide = rect.shortestSide;
    // In principle, we should use shortestSide / 2.0, but we don't want to
    // run into floating point rounding errors. Instead, we just use
    // shortestSide and let sky.Canvas do any remaining clamping.
    return _decoration.borderRadius > shortestSide ? shortestSide : _decoration.borderRadius;
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
          if (_decoration.borderRadius == null) {
            canvas.drawRect(rect, _backgroundPaint);
          } else {
            double radius = _getEffectiveBorderRadius(rect);
            canvas.drawRRect(new sky.RRect()..setRectXY(rect, radius, radius), _backgroundPaint);
          }
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
    assert(_decoration.shape == Shape.rectangle); // TODO(ianh): Support non-uniform borders on circles.

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
    double radius = _getEffectiveBorderRadius(rect);

    sky.RRect outer = new sky.RRect()..setRectXY(rect, radius, radius);
    sky.RRect inner = new sky.RRect()..setRectXY(rect.deflate(width), radius - width, radius - width);
    canvas.drawDRRect(outer, inner, new Paint()..color = color);
  }

  void _paintBorderWithCircle(sky.Canvas canvas, Rect rect) {
    assert(_hasUniformBorder);
    assert(_decoration.shape == Shape.circle);
    assert(_decoration.borderRadius == null);
    double width = _decoration.border.top.width;
    if (width <= 0.0) {
      return;
    }
    Paint paint = new Paint()
      ..color = _decoration.border.top.color
      ..strokeWidth = width
      ..setStyle(sky.PaintingStyle.stroke);
    Point center = rect.center;
    double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(center, radius, paint);
  }

  /// Paint the box decoration into the given location on the given canvas
  void paint(sky.Canvas canvas, Rect rect) {
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintBorder(canvas, rect);
  }
}
