// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'decoration.dart';
import 'edge_dims.dart';

export 'edge_dims.dart' show EdgeDims;

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

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BorderSide)
      return false;
    final BorderSide typedOther = other;
    return color == typedOther.color &&
           width == typedOther.width;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + color.hashCode;
    value = 37 * value + width.hashCode;
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
    return new EdgeDims.TRBL(top.width, right.width, bottom.width, left.width);
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Border)
      return false;
    final Border typedOther = other;
    return top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom &&
           left == typedOther.left;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + top.hashCode;
    value = 37 * value + right.hashCode;
    value = 37 * value + bottom.hashCode;
    value = 37 * value + left.hashCode;
    return value;
  }

  String toString() => 'Border($top, $right, $bottom, $left)';
}

/// A shadow cast by a box
///
/// Note: BoxShadow can cast non-rectangular shadows if the box is
/// non-rectangular (e.g., has a border radius or a circular shape).
/// This class is similar to CSS box-shadow.
class BoxShadow {
  const BoxShadow({
    this.color,
    this.offset,
    this.blurRadius,
    this.spreadRadius: 0.0
  });

  /// The color of the shadow
  final Color color;

  /// The displacement of the shadow from the box
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the box's shape
  final double blurRadius;

  final double spreadRadius;

  // See SkBlurMask::ConvertRadiusToSigma()
  double get _blurSigma => blurRadius * 0.57735 + 0.5;

  /// Returns a new box shadow with its offset, blurRadius, and spreadRadius scaled by the given factor
  BoxShadow scale(double factor) {
    return new BoxShadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor
    );
  }

  /// Linearly interpolate between two box shadows
  ///
  /// If either box shadow is null, this function linearly interpolates from a
  /// a box shadow that matches the other box shadow in color but has a zero
  /// offset and a zero blurRadius.
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
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t),
      spreadRadius: ui.lerpDouble(a.spreadRadius, b.spreadRadius, t)
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

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BoxShadow)
      return false;
    final BoxShadow typedOther = other;
    return color == typedOther.color &&
           offset == typedOther.offset &&
           blurRadius == typedOther.blurRadius &&
           spreadRadius == typedOther.spreadRadius;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + color.hashCode;
    value = 37 * value + offset.hashCode;
    value = 37 * value + blurRadius.hashCode;
    value = 37 * value + spreadRadius.hashCode;
    return value;
  }

  String toString() => 'BoxShadow($color, $offset, $blurRadius, $spreadRadius)';
}

/// A 2D gradient
abstract class Gradient {
  const Gradient();
  ui.Shader createShader();
}

/// A 2D linear gradient
class LinearGradient extends Gradient {
  const LinearGradient({
    this.begin,
    this.end,
    this.colors,
    this.stops,
    this.tileMode: ui.TileMode.clamp
  });

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
  /// Note: If specified, this list must have the same length as [colors]. Otherwise the colors
  /// are distributed evenly between [begin] and [end].
  final List<double> stops;

  /// How this gradient should tile the plane
  final ui.TileMode tileMode;

  ui.Shader createShader() {
    return new ui.Gradient.linear(<Point>[begin, end], this.colors, this.stops, this.tileMode);
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! LinearGradient)
      return false;
    final LinearGradient typedOther = other;
    if (begin != typedOther.begin ||
        end != typedOther.end ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + begin.hashCode;
    value = 37 * value + end.hashCode;
    value = 37 * value + tileMode.hashCode;
    if (colors != null) {
      for (int i = 0; i < colors.length; i += 1)
        value = 37 * value + colors[i].hashCode;
    } else {
      value = 37 * value + null.hashCode;
    }
    if (stops != null) {
      for (int i = 0; i < stops.length; i += 1)
        value = 37 * value + stops[i].hashCode;
    } else {
      value = 37 * value + null.hashCode;
    }
    return value;
  }

  String toString() {
    return 'LinearGradient($begin, $end, $colors, $stops, $tileMode)';
  }
}

/// A 2D radial gradient
class RadialGradient extends Gradient {
  const RadialGradient({
    this.center,
    this.radius,
    this.colors,
    this.stops,
    this.tileMode: ui.TileMode.clamp
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
  final ui.TileMode tileMode;

  ui.Shader createShader() {
    return new ui.Gradient.radial(center, radius, colors, stops, tileMode);
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! RadialGradient)
      return false;
    final RadialGradient typedOther = other;
    if (center != typedOther.center ||
        radius != typedOther.radius ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length)
      return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i])
          return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i])
          return false;
      }
    }
    return true;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + center.hashCode;
    value = 37 * value + radius.hashCode;
    value = 37 * value + tileMode.hashCode;
    if (colors != null) {
      for (int i = 0; i < colors.length; i += 1)
        value = 37 * value + colors[i].hashCode;
    } else {
      value = 37 * value + null.hashCode;
    }
    if (stops != null) {
      for (int i = 0; i < stops.length; i += 1)
        value = 37 * value + stops[i].hashCode;
    } else {
      value = 37 * value + null.hashCode;
    }
    return value;
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

Iterable<Rect> _generateImageTileRects(Rect outputRect, Rect fundamentalRect, ImageRepeat repeat) sync* {
  if (repeat == ImageRepeat.noRepeat) {
    yield fundamentalRect;
    return;
  }

  int startX = 0;
  int startY = 0;
  int stopX = 0;
  int stopY = 0;
  double strideX = fundamentalRect.width;
  double strideY = fundamentalRect.height;

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
    startX = ((outputRect.left - fundamentalRect.left) / strideX).floor();
    stopX = ((outputRect.right - fundamentalRect.right) / strideX).ceil();
  }

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
    startY = ((outputRect.top - fundamentalRect.top) / strideY).floor();
    stopY = ((outputRect.bottom - fundamentalRect.bottom) / strideY).ceil();
  }

  for (int i = startX; i <= stopX; ++i) {
    for (int j = startY; j <= stopY; ++j)
      yield fundamentalRect.shift(new Offset(i * strideX, j * strideY));
  }
}

/// Paint an image into the given rectangle in the canvas.
void paintImage({
  Canvas canvas,
  Rect rect,
  ui.Image image,
  ColorFilter colorFilter,
  ImageFit fit,
  ImageRepeat repeat: ImageRepeat.noRepeat,
  Rect centerSlice,
  double alignX,
  double alignY
}) {
  Size outputSize = rect.size;
  Size inputSize = new Size(image.width.toDouble(), image.height.toDouble());
  Offset sliceBorder;
  if (centerSlice != null) {
    sliceBorder = new Offset(
      centerSlice.left + inputSize.width - centerSlice.right,
      centerSlice.top + inputSize.height - centerSlice.bottom
    );
    outputSize -= sliceBorder;
    inputSize -= sliceBorder;
  }
  Size sourceSize;
  Size destinationSize;
  fit ??= centerSlice == null ? ImageFit.scaleDown : ImageFit.fill;
  assert(centerSlice == null || (fit != ImageFit.none && fit != ImageFit.cover));
  switch (fit) {
    case ImageFit.fill:
      sourceSize = inputSize;
      destinationSize = outputSize;
      break;
    case ImageFit.contain:
      sourceSize = inputSize;
      if (outputSize.width / outputSize.height > sourceSize.width / sourceSize.height)
        destinationSize = new Size(sourceSize.width * outputSize.height / sourceSize.height, outputSize.height);
      else
        destinationSize = new Size(outputSize.width, sourceSize.height * outputSize.width / sourceSize.width);
      break;
    case ImageFit.cover:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height)
        sourceSize = new Size(inputSize.width, inputSize.width * outputSize.height / outputSize.width);
      else
        sourceSize = new Size(inputSize.height * outputSize.width / outputSize.height, inputSize.height);
      destinationSize = outputSize;
      break;
    case ImageFit.none:
      sourceSize = new Size(math.min(inputSize.width, outputSize.width),
                            math.min(inputSize.height, outputSize.height));
      destinationSize = sourceSize;
      break;
    case ImageFit.scaleDown:
      sourceSize = inputSize;
      destinationSize = outputSize;
      if (sourceSize.height > destinationSize.height)
        destinationSize = new Size(sourceSize.width * destinationSize.height / sourceSize.height, sourceSize.height);
      if (sourceSize.width > destinationSize.width)
        destinationSize = new Size(destinationSize.width, sourceSize.height * destinationSize.width / sourceSize.width);
      break;
  }
  if (centerSlice != null) {
    outputSize += sliceBorder;
    destinationSize += sliceBorder;
    // We don't have the ability to draw a subset of the image at the same time
    // as we apply a nine-patch stretch.
    assert(sourceSize == inputSize);
  }
  if (repeat != ImageRepeat.noRepeat && destinationSize == outputSize) {
    // There's no need to repeat the image because we're exactly filling the
    // output rect with the image.
    repeat = ImageRepeat.noRepeat;
  }
  Paint paint = new Paint()..isAntiAlias = false;
  if (colorFilter != null)
    paint.colorFilter = colorFilter;
  double dx = (outputSize.width - destinationSize.width) * (alignX ?? 0.5);
  double dy = (outputSize.height - destinationSize.height) * (alignY ?? 0.5);
  Point destinationPosition = rect.topLeft + new Offset(dx, dy);
  Rect destinationRect = destinationPosition & destinationSize;
  if (repeat != ImageRepeat.noRepeat) {
    canvas.save();
    canvas.clipRect(rect);
  }
  if (centerSlice == null) {
    Rect sourceRect = Point.origin & sourceSize;
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageRect(image, sourceRect, tileRect, paint);
  } else {
    for (Rect tileRect in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageNine(image, centerSlice, tileRect, paint);
  }
  if (repeat != ImageRepeat.noRepeat)
    canvas.restore();
}

/// An offset that's expressed as a fraction of a Size.
///
/// FractionalOffset(1.0, 0.0) represents the top right of the Size,
/// FractionalOffset(0.0, 1.0) represents the bottom left of the Size,
class FractionalOffset {
  const FractionalOffset(this.x, this.y);
  final double x;
  final double y;
  FractionalOffset operator -(FractionalOffset other) {
    return new FractionalOffset(x - other.x, y - other.y);
  }
  FractionalOffset operator +(FractionalOffset other) {
    return new FractionalOffset(x + other.x, y + other.y);
  }
  FractionalOffset operator *(double other) {
    return new FractionalOffset(x * other, y * other);
  }
  bool operator ==(dynamic other) {
    if (other is! FractionalOffset)
      return false;
    final FractionalOffset typedOther = other;
    return x == typedOther.x &&
           y == typedOther.y;
  }
  int get hashCode {
    int value = 373;
    value = 37 * value + x.hashCode;
    value = 37 * value + y.hashCode;
    return value;
  }
  static FractionalOffset lerp(FractionalOffset a, FractionalOffset b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new FractionalOffset(b.x * t, b.y * t);
    if (b == null)
      return new FractionalOffset(b.x * (1.0 - t), b.y * (1.0 - t));
    return new FractionalOffset(ui.lerpDouble(a.x, b.x, t), ui.lerpDouble(a.y, b.y, t));
  }
  String toString() => '$runtimeType($x, $y)';
}

/// A background image for a box.
class BackgroundImage {
  BackgroundImage({
    ImageResource image,
    this.fit,
    this.repeat: ImageRepeat.noRepeat,
    this.centerSlice,
    this.colorFilter,
    this.alignment
  }) : _imageResource = image;

  /// How the background image should be inscribed into the box.
  final ImageFit fit;

  /// How to paint any portions of the box not covered by the background image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// A color filter to apply to the background image before painting it.
  final ColorFilter colorFilter;

  /// How to align the image within its bounds.
  final FractionalOffset alignment;

  /// The image to be painted into the background.
  ui.Image get image => _image;
  ui.Image _image;

  final ImageResource _imageResource;

  final List<VoidCallback> _listeners = <VoidCallback>[];

  /// Call listener when the background images changes (e.g., arrives from the network).
  void _addChangeListener(VoidCallback listener) {
    // We add the listener to the _imageResource first so that the first change
    // listener doesn't get callback synchronously if the image resource is
    // already resolved.
    if (_listeners.isEmpty)
      _imageResource.addListener(_handleImageChanged);
    _listeners.add(listener);
  }

  /// No longer call listener when the background image changes.
  void _removeChangeListener(VoidCallback listener) {
    _listeners.remove(listener);
    // We need to remove ourselves as listeners from the _imageResource so that
    // we're not kept alive by the image_cache.
    if (_listeners.isEmpty)
      _imageResource.removeListener(_handleImageChanged);
  }

  void _handleImageChanged(ui.Image resolvedImage) {
    if (resolvedImage == null)
      return;
    _image = resolvedImage;
    final List<VoidCallback> localListeners =
      new List<VoidCallback>.from(_listeners);
    for (VoidCallback listener in localListeners)
      listener();
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BackgroundImage)
      return false;
    final BackgroundImage typedOther = other;
    return fit == typedOther.fit &&
           repeat == typedOther.repeat &&
           centerSlice == typedOther.centerSlice &&
           colorFilter == typedOther.colorFilter &&
           alignment == typedOther.alignment &&
           _imageResource == typedOther._imageResource;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + fit.hashCode;
    value = 37 * value + repeat.hashCode;
    value = 37 * value + centerSlice.hashCode;
    value = 37 * value + colorFilter.hashCode;
    value = 37 * value + alignment.hashCode;
    value = 37 * value + _imageResource.hashCode;
    return value;
  }

  String toString() => 'BackgroundImage($fit, $repeat)';
}

/// The shape to use when rendering a BoxDecoration.
enum BoxShape {
  /// An axis-aligned, 2D rectangle. May have rounded corners. The edges of the
  /// rectangle will match the edges of the box into which the BoxDecoration is
  /// painted.
  rectangle,

  /// A circle centered in the middle of the box into which the BoxDecoration is
  /// painted. The diameter of the circle is the shortest dimension of the box,
  /// either the width of the height, such that the circle touches the edges of
  /// the box.
  circle
}

/// An immutable description of how to paint a box
class BoxDecoration extends Decoration {
  const BoxDecoration({
    this.backgroundColor, // null = don't draw background color
    this.backgroundImage, // null = don't draw background image
    this.border, // null = don't draw border
    this.borderRadius, // null = use more efficient background drawing; note that this must be null for circles
    this.boxShadow, // null = don't draw shadows
    this.gradient, // null = don't allocate gradient objects
    this.shape: BoxShape.rectangle
  });

  bool debugAssertValid() {
    assert(shape != BoxShape.circle ||
           borderRadius == null); // can't have a border radius if you're a circle
    return super.debugAssertValid();
  }

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
  final BoxShape shape;

  /// Returns a new box decoration that is scaled by the given factor
  BoxDecoration scale(double factor) {
    // TODO(abarth): Scale ALL the things.
    return new BoxDecoration(
      backgroundColor: Color.lerp(null, backgroundColor, factor),
      backgroundImage: backgroundImage,
      border: border,
      borderRadius: ui.lerpDouble(null, borderRadius, factor),
      boxShadow: BoxShadow.lerpList(null, boxShadow, factor),
      gradient: gradient,
      shape: shape
    );
  }

  double getEffectiveBorderRadius(Rect rect) {
    double shortestSide = rect.shortestSide;
    // In principle, we should use shortestSide / 2.0, but we don't want to
    // run into floating point rounding errors. Instead, we just use
    // shortestSide and let ui.Canvas do any remaining clamping.
    return borderRadius > shortestSide ? shortestSide : borderRadius;
  }

  bool hitTest(Size size, Point position) {
    assert(shape != null);
    assert((Point.origin & size).contains(position));
    switch (shape) {
      case BoxShape.rectangle:
        if (borderRadius != null) {
          ui.RRect bounds = new ui.RRect.fromRectXY(Point.origin & size, borderRadius, borderRadius);
          return bounds.contains(position);
        }
        return true;
      case BoxShape.circle:
        // Circles are inscribed into our smallest dimension.
        Point center = size.center(Point.origin);
        double distance = (position - center).distance;
        return distance <= math.min(size.width, size.height) / 2.0;
    }
  }

  /// Linearly interpolate between two box decorations.
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
      borderRadius: ui.lerpDouble(a.borderRadius, b.borderRadius, t),
      boxShadow: BoxShadow.lerpList(a.boxShadow, b.boxShadow, t),
      gradient: b.gradient,
      shape: b.shape
    );
  }

  BoxDecoration lerpFrom(Decoration a, double t) {
    if (a is! BoxDecoration)
      return BoxDecoration.lerp(null, this, t);
    return BoxDecoration.lerp(a, this, t);
  }

  BoxDecoration lerpTo(Decoration b, double t) {
    if (b is! BoxDecoration)
      return BoxDecoration.lerp(this, null, t);
    return BoxDecoration.lerp(this, b, t);
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! BoxDecoration)
      return false;
    final BoxDecoration typedOther = other;
    return backgroundColor == typedOther.backgroundColor &&
           backgroundImage == typedOther.backgroundImage &&
           border == typedOther.border &&
           borderRadius == typedOther.borderRadius &&
           boxShadow == typedOther.boxShadow &&
           gradient == typedOther.gradient &&
           shape == typedOther.shape;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value + backgroundColor.hashCode;
    value = 37 * value + backgroundImage.hashCode;
    value = 37 * value + border.hashCode;
    value = 37 * value + borderRadius.hashCode;
    value = 37 * value + boxShadow.hashCode;
    value = 37 * value + gradient.hashCode;
    value = 37 * value + shape.hashCode;
    return value;
  }

  String toString([String prefix = '']) {
    List<String> result = <String>[];
    if (backgroundColor != null)
      result.add('${prefix}backgroundColor: $backgroundColor');
    if (backgroundImage != null)
      result.add('${prefix}backgroundImage: $backgroundImage');
    if (border != null)
      result.add('${prefix}border: $border');
    if (borderRadius != null)
      result.add('${prefix}borderRadius: $borderRadius');
    if (boxShadow != null)
      result.add('${prefix}boxShadow: ${boxShadow.map((BoxShadow shadow) => shadow.toString())}');
    if (gradient != null)
      result.add('${prefix}gradient: $gradient');
    if (shape != BoxShape.rectangle)
      result.add('${prefix}shape: $shape');
    if (result.isEmpty)
      return '$prefix<no decorations specified>';
    return result.join('\n');
  }

  bool get needsListeners => backgroundImage != null;

  void addChangeListener(VoidCallback listener) {
    backgroundImage?._addChangeListener(listener);
  }
  void removeChangeListener(VoidCallback listener) {
    backgroundImage?._removeChangeListener(listener);
  }

  _BoxDecorationPainter createBoxPainter() => new _BoxDecorationPainter(this);
}

/// An object that paints a [BoxDecoration] into a canvas
class _BoxDecorationPainter extends BoxPainter {
  _BoxDecorationPainter(this._decoration) {
    assert(_decoration != null);
  }

  final BoxDecoration _decoration;

  Paint _cachedBackgroundPaint;
  Paint get _backgroundPaint {
    if (_cachedBackgroundPaint == null) {
      Paint paint = new Paint();

      if (_decoration.backgroundColor != null)
        paint.color = _decoration.backgroundColor;

      if (_decoration.gradient != null)
        paint.shader = _decoration.gradient.createShader();

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

  void _paintBox(ui.Canvas canvas, Rect rect, Paint paint) {
    switch (_decoration.shape) {
      case BoxShape.circle:
        assert(_decoration.borderRadius == null);
        Point center = rect.center;
        double radius = rect.shortestSide / 2.0;
        canvas.drawCircle(center, radius, paint);
        break;
      case BoxShape.rectangle:
        if (_decoration.borderRadius == null) {
          canvas.drawRect(rect, paint);
        } else {
          double radius = _decoration.getEffectiveBorderRadius(rect);
          canvas.drawRRect(new ui.RRect.fromRectXY(rect, radius, radius), paint);
        }
        break;
    }
  }

  void _paintShadows(ui.Canvas canvas, Rect rect) {
    if (_decoration.boxShadow == null)
      return;
    for (BoxShadow boxShadow in _decoration.boxShadow) {
      final Paint paint = new Paint()
        ..color = boxShadow.color
        ..maskFilter = new ui.MaskFilter.blur(ui.BlurStyle.normal, boxShadow._blurSigma);
      final Rect bounds = rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
      _paintBox(canvas, bounds, paint);
    }
  }

  void _paintBackgroundColor(ui.Canvas canvas, Rect rect) {
    if (_decoration.backgroundColor != null || _decoration.gradient != null)
      _paintBox(canvas, rect, _backgroundPaint);
  }

  void _paintBackgroundImage(ui.Canvas canvas, Rect rect) {
    final BackgroundImage backgroundImage = _decoration.backgroundImage;
    if (backgroundImage == null)
      return;
    ui.Image image = backgroundImage.image;
    if (image == null)
      return;
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      colorFilter: backgroundImage.colorFilter,
      alignX: backgroundImage.alignment?.x,
      alignY: backgroundImage.alignment?.y,
      fit:  backgroundImage.fit,
      repeat: backgroundImage.repeat
    );
  }

  void _paintBorder(ui.Canvas canvas, Rect rect) {
    if (_decoration.border == null)
      return;

    if (_hasUniformBorder) {
      if (_decoration.borderRadius != null) {
        _paintBorderWithRadius(canvas, rect);
        return;
      }
      if (_decoration.shape == BoxShape.circle) {
        _paintBorderWithCircle(canvas, rect);
        return;
      }
    }

    assert(_decoration.borderRadius == null); // TODO(abarth): Support non-uniform rounded borders.
    assert(_decoration.shape == BoxShape.rectangle); // TODO(ianh): Support non-uniform borders on circles.

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

  void _paintBorderWithRadius(ui.Canvas canvas, Rect rect) {
    assert(_hasUniformBorder);
    assert(_decoration.shape == BoxShape.rectangle);
    Color color = _decoration.border.top.color;
    double width = _decoration.border.top.width;
    double radius = _decoration.getEffectiveBorderRadius(rect);

    ui.RRect outer = new ui.RRect.fromRectXY(rect, radius, radius);
    ui.RRect inner = new ui.RRect.fromRectXY(rect.deflate(width), radius - width, radius - width);
    canvas.drawDRRect(outer, inner, new Paint()..color = color);
  }

  void _paintBorderWithCircle(ui.Canvas canvas, Rect rect) {
    assert(_hasUniformBorder);
    assert(_decoration.shape == BoxShape.circle);
    assert(_decoration.borderRadius == null);
    double width = _decoration.border.top.width;
    if (width <= 0.0)
      return;
    Paint paint = new Paint()
      ..color = _decoration.border.top.color
      ..strokeWidth = width
      ..style = ui.PaintingStyle.stroke;
    Point center = rect.center;
    double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(center, radius, paint);
  }

  /// Paint the box decoration into the given location on the given canvas
  void paint(ui.Canvas canvas, Rect rect) {
    _paintShadows(canvas, rect);
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect);
    _paintBorder(canvas, rect);
  }
}
