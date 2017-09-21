// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show Image, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'border.dart';
import 'border_radius.dart';
import 'decoration.dart';
import 'edge_insets.dart';
import 'gradient.dart';
import 'image.dart';

/// A shadow cast by a box.
///
/// BoxShadow can cast non-rectangular shadows if the box is non-rectangular
/// (e.g., has a border radius or a circular shape).
///
/// This class is similar to CSS box-shadow.
@immutable
class BoxShadow {
  /// Creates a box shadow.
  ///
  /// By default, the shadow is solid black with zero [offset], [blurRadius],
  /// and [spreadRadius].
  const BoxShadow({
    this.color: const Color(0xFF000000),
    this.offset: Offset.zero,
    this.blurRadius: 0.0,
    this.spreadRadius: 0.0
  });

  /// The color of the shadow.
  final Color color;

  /// The displacement of the shadow from the box.
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the box's shape.
  final double blurRadius;

  /// The amount the box should be inflated prior to applying the blur.
  final double spreadRadius;

  /// Converts a blur radius in pixels to sigmas.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  //
  // See SkBlurMask::ConvertRadiusToSigma().
  // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  /// The [blurRadius] in sigmas instead of logical pixels.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  double get blurSigma => convertRadiusToSigma(blurRadius);

  /// Returns a new box shadow with its offset, blurRadius, and spreadRadius scaled by the given factor.
  BoxShadow scale(double factor) {
    return new BoxShadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor
    );
  }

  /// Linearly interpolate between two box shadows.
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

  /// Linearly interpolate between two lists of box shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  static List<BoxShadow> lerpList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    if (a == null && b == null)
      return null;
    a ??= <BoxShadow>[];
    b ??= <BoxShadow>[];
    final List<BoxShadow> result = <BoxShadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; ++i)
      result.add(BoxShadow.lerp(a[i], b[i], t));
    for (int i = commonLength; i < a.length; ++i)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; ++i)
      result.add(b[i].scale(t));
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final BoxShadow typedOther = other;
    return color == typedOther.color &&
           offset == typedOther.offset &&
           blurRadius == typedOther.blurRadius &&
           spreadRadius == typedOther.spreadRadius;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius, spreadRadius);

  @override
  String toString() => 'BoxShadow($color, $offset, $blurRadius, $spreadRadius)';
}

/// An immutable description of how to paint a box.
///
/// The [BoxDecoration] class provides a variety of ways to draw a box.
///
/// The box has a [border], a body, and may cast a [boxShadow].
///
/// The [shape] of the box can be a circle or a rectangle. If it is a rectangle,
/// then the [borderRadius] property controls the roundness of the corners.
///
/// The body of the box is painted in layers. The bottom-most layer is the
/// [color], which fills the box. Above that is the [gradient], which also fills
/// the box. Finally there is the [image], the precise alignment of which is
/// controlled by the [DecorationImage] class.
///
/// The [border] paints over the body; the [boxShadow], naturally, paints below it.
///
/// ## Sample code
///
/// The following example uses the [Container] widget from the widgets layer to
/// draw an image with a border:
///
/// ```dart
/// new Container(
///   decoration: new BoxDecoration(
///     color: const Color(0xff7c94b6),
///     image: new DecorationImage(
///       image: new ExactAssetImage('images/flowers.jpeg'),
///       fit: BoxFit.cover,
///     ),
///     border: new Border.all(
///       color: Colors.black,
///       width: 8.0,
///     ),
///   ),
/// )
/// ```
///
/// See also:
///
///  * [DecoratedBox] and [Container], widgets that can be configured with
///    [BoxDecoration] objects.
///  * [CustomPaint], a widget that lets you draw arbitrary graphics.
///  * [Decoration], the base class which lets you define other decorations.
class BoxDecoration extends Decoration {
  /// Creates a box decoration.
  ///
  /// * If [color] is null, this decoration does not paint a background color.
  /// * If [image] is null, this decoration does not paint a background image.
  /// * If [border] is null, this decoration does not paint a border.
  /// * If [borderRadius] is null, this decoration uses more efficient background
  ///   painting commands. The [borderRadius] argument must be be null if [shape] is
  ///   [BoxShape.circle].
  /// * If [boxShadow] is null, this decoration does not paint a shadow.
  /// * If [gradient] is null, this decoration does not paint gradients.
  const BoxDecoration({
    this.color,
    this.image,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
    this.shape: BoxShape.rectangle,
  });

  @override
  bool debugAssertIsValid() {
    assert(shape != BoxShape.circle ||
           borderRadius == null); // Can't have a border radius if you're a circle.
    return super.debugAssertIsValid();
  }

  /// The color to fill in the background of the box.
  ///
  /// The color is filled into the shape of the box (e.g., either a rectangle,
  /// potentially with a border radius, or a circle).
  final Color color;

  /// An image to paint above the background color. If [shape] is [BoxShape.circle]
  /// then the image is clipped to the circle's boundary.
  final DecorationImage image;

  /// A border to draw above the background [color] or [image].
  final Border border;

  /// If non-null, the corners of this box are rounded by this [BorderRadius].
  ///
  /// Applies only to boxes with rectangular shapes.
  final BorderRadius borderRadius;

  /// A list of shadows cast by this box behind the box.
  ///
  /// The shadow follows the [shape] of the box.
  final List<BoxShadow> boxShadow;

  /// A gradient to use when filling the box.
  final Gradient gradient;

  /// The shape to fill the background [color] into and to cast as the [boxShadow].
  final BoxShape shape;

  /// The inset space occupied by the border.
  @override
  EdgeInsets get padding => border?.dimensions;

  /// Returns a new box decoration that is scaled by the given factor.
  BoxDecoration scale(double factor) {
    // TODO(abarth): Scale ALL the things.
    return new BoxDecoration(
      color: Color.lerp(null, color, factor),
      image: image,
      border: Border.lerp(null, border, factor),
      borderRadius: BorderRadius.lerp(null, borderRadius, factor),
      boxShadow: BoxShadow.lerpList(null, boxShadow, factor),
      gradient: gradient,
      shape: shape,
    );
  }

  @override
  bool get isComplex => boxShadow != null;

  /// Linearly interpolate between two box decorations.
  ///
  /// Interpolates each parameter of the box decoration separately.
  ///
  /// See also [Decoration.lerp].
  static BoxDecoration lerp(BoxDecoration a, BoxDecoration b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    // TODO(abarth): lerp ALL the fields.
    return new BoxDecoration(
      color: Color.lerp(a.color, b.color, t),
      image: b.image,
      border: Border.lerp(a.border, b.border, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      boxShadow: BoxShadow.lerpList(a.boxShadow, b.boxShadow, t),
      gradient: b.gradient,
      shape: b.shape,
    );
  }

  @override
  BoxDecoration lerpFrom(Decoration a, double t) {
    if (a is! BoxDecoration)
      return BoxDecoration.lerp(null, this, t);
    return BoxDecoration.lerp(a, this, t);
  }

  @override
  BoxDecoration lerpTo(Decoration b, double t) {
    if (b is! BoxDecoration)
      return BoxDecoration.lerp(this, null, t);
    return BoxDecoration.lerp(this, b, t);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final BoxDecoration typedOther = other;
    return color == typedOther.color &&
           image == typedOther.image &&
           border == typedOther.border &&
           borderRadius == typedOther.borderRadius &&
           boxShadow == typedOther.boxShadow &&
           gradient == typedOther.gradient &&
           shape == typedOther.shape;
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      image,
      border,
      borderRadius,
      boxShadow,
      gradient,
      shape,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace
      ..emptyBodyDescription = '<no decorations specified>';

    properties.add(new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(new DiagnosticsProperty<DecorationImage>('image', image, defaultValue: null));
    properties.add(new DiagnosticsProperty<Border>('border', border, defaultValue: null));
    properties.add(new DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius, defaultValue: null));
    properties.add(new IterableProperty<BoxShadow>('boxShadow', boxShadow, defaultValue: null, style: DiagnosticsTreeStyle.whitespace));
    properties.add(new DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null));
    properties.add(new EnumProperty<BoxShape>('shape', shape, defaultValue: BoxShape.rectangle));
  }

  @override
  bool hitTest(Size size, Offset position) {
    assert(shape != null);
    assert((Offset.zero & size).contains(position));
    switch (shape) {
      case BoxShape.rectangle:
        if (borderRadius != null) {
          final RRect bounds = borderRadius.toRRect(Offset.zero & size);
          return bounds.contains(position);
        }
        return true;
      case BoxShape.circle:
        // Circles are inscribed into our smallest dimension.
        final Offset center = size.center(Offset.zero);
        final double distance = (position - center).distance;
        return distance <= math.min(size.width, size.height) / 2.0;
    }
    assert(shape != null);
    return null;
  }

  @override
  _BoxDecorationPainter createBoxPainter([VoidCallback onChanged]) {
    assert(onChanged != null || image == null);
    return new _BoxDecorationPainter(this, onChanged);
  }
}

/// An object that paints a [BoxDecoration] into a canvas.
class _BoxDecorationPainter extends BoxPainter {
  _BoxDecorationPainter(this._decoration, VoidCallback onChange)
    : assert(_decoration != null),
      super(onChange);

  final BoxDecoration _decoration;

  Paint _cachedBackgroundPaint;
  Rect _rectForCachedBackgroundPaint;
  Paint _getBackgroundPaint(Rect rect) {
    assert(rect != null);
    if (_cachedBackgroundPaint == null ||
        (_decoration.gradient == null && _rectForCachedBackgroundPaint != null) ||
        (_decoration.gradient != null && _rectForCachedBackgroundPaint != rect)) {
      final Paint paint = new Paint();

      if (_decoration.color != null)
        paint.color = _decoration.color;

      if (_decoration.gradient != null) {
        paint.shader = _decoration.gradient.createShader(rect);
        _rectForCachedBackgroundPaint = rect;
      } else {
        _rectForCachedBackgroundPaint = null;
      }

      _cachedBackgroundPaint = paint;
    }

    return _cachedBackgroundPaint;
  }

  void _paintBox(Canvas canvas, Rect rect, Paint paint) {
    switch (_decoration.shape) {
      case BoxShape.circle:
        assert(_decoration.borderRadius == null);
        final Offset center = rect.center;
        final double radius = rect.shortestSide / 2.0;
        canvas.drawCircle(center, radius, paint);
        break;
      case BoxShape.rectangle:
        if (_decoration.borderRadius == null) {
          canvas.drawRect(rect, paint);
        } else {
          canvas.drawRRect(_decoration.borderRadius.toRRect(rect), paint);
        }
        break;
    }
  }

  void _paintShadows(Canvas canvas, Rect rect) {
    if (_decoration.boxShadow == null)
      return;
    for (BoxShadow boxShadow in _decoration.boxShadow) {
      final Paint paint = new Paint()
        ..color = boxShadow.color
        ..maskFilter = new MaskFilter.blur(BlurStyle.normal, boxShadow.blurSigma);
      final Rect bounds = rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
      _paintBox(canvas, bounds, paint);
    }
  }

  void _paintBackgroundColor(Canvas canvas, Rect rect) {
    if (_decoration.color != null || _decoration.gradient != null)
      _paintBox(canvas, rect, _getBackgroundPaint(rect));
  }

  ImageStream _imageStream;
  ImageInfo _image;

  void _paintBackgroundImage(Canvas canvas, Rect rect, ImageConfiguration configuration) {
    final DecorationImage backgroundImage = _decoration.image;
    if (backgroundImage == null)
      return;
    final ImageStream newImageStream = backgroundImage.image.resolve(configuration);
    if (newImageStream.key != _imageStream?.key) {
      _imageStream?.removeListener(_imageListener);
      _imageStream = newImageStream;
      _imageStream.addListener(_imageListener);
    }
    final ui.Image image = _image?.image;
    if (image == null)
      return;

    Path clipPath;
    if (_decoration.shape == BoxShape.circle)
      clipPath = new Path()..addOval(rect);
    else if (_decoration.borderRadius != null)
      clipPath = new Path()..addRRect(_decoration.borderRadius.toRRect(rect));
    if (clipPath != null) {
      canvas.save();
      canvas.clipPath(clipPath);
    }

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      colorFilter: backgroundImage.colorFilter,
      fit: backgroundImage.fit,
      alignment: backgroundImage.alignment,
      centerSlice: backgroundImage.centerSlice,
      repeat: backgroundImage.repeat,
    );

    if (clipPath != null)
      canvas.restore();
  }

  void _imageListener(ImageInfo value, bool synchronousCall) {
    if (_image == value)
      return;
    _image = value;
    assert(onChanged != null);
    if (!synchronousCall)
      onChanged();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _imageStream = null;
    _image = null;
    super.dispose();
  }

  /// Paint the box decoration into the given location on the given canvas
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    _paintShadows(canvas, rect);
    _paintBackgroundColor(canvas, rect);
    _paintBackgroundImage(canvas, rect, configuration);
    _decoration.border?.paint(
      canvas,
      rect,
      shape: _decoration.shape,
      borderRadius: _decoration.borderRadius
    );
  }
}
