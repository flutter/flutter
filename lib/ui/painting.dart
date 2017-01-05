// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

Color _scaleAlpha(Color a, double factor) {
  return a.withAlpha((a.alpha * factor).round());
}

/// An immutable 32 bit color value in ARGB format.
///
/// Consider the light teal of the Flutter logo. It is fully opaque, with a red
/// channel value of 0x42 (66), a green channel value of 0xA5 (165), and a blue
/// channel value of 0xF5 (245). In the common "hash syntax" for colour values,
/// it would be described as `#42A5F5`.
///
/// Here are some ways it could be constructed:
///
/// ```dart
/// Color c = const Color(0xFF42A5F5);
/// Color c = const Color.fromARGB(0xFF, 0x42, 0xA5, 0xF5);
/// Color c = const Color.fromARGB(255, 66, 165, 245);
/// Color c = const Color.fromRGBO(66, 165, 245, 1.0);
/// ```
///
/// If you are having a problem with `Color` wherein it seems your color is just
/// not painting, check to make sure you are specifying the full 8 hexadecimal
/// digits. If you only specify six, then the leading two digits are assumed to
/// be zero, which means fully-transparent:
///
/// ```dart
/// Color c1 = const Color(0xFFFFFF); // fully transparent white (invisible)
/// Color c2 = const Color(0xFFFFFFFF); // fully opaque white (visible)
/// ```
class Color {
  /// Construct a color from the lower 32 bits of an [int].
  ///
  /// The bits are interpreted as follows:
  ///
  /// * Bits 24-31 are the alpha value.
  /// * Bits 16-23 are the red value.
  /// * Bits 8-15 are the green value.
  /// * Bits 0-7 are the blue value.
  ///
  /// In other words, if AA is the alpha value in hex, RR the red value in hex,
  /// GG the green value in hex, and BB the blue value in hex, a color can be
  /// expressed as `const Color(0xAARRGGBB)`.
  ///
  /// For example, to get a fully opaque orange, you would use `const
  /// Color(0xFFFF9000)` (`FF` for the alpha, `FF` for the red, `90` for the
  /// green, and `00` for the blue).
  const Color(int value) : value = value & 0xFFFFFFFF;

  /// Construct a color from the lower 8 bits of four integers.
  ///
  /// * `a` is the alpha value, with 0 being transparent and 255 being fully
  ///   opaque.
  /// * `r` is [red], from 0 to 255.
  /// * `g` is [red], from 0 to 255.
  /// * `b` is [red], from 0 to 255.
  ///
  /// Out of range values are brought into range using modulo 255.
  ///
  /// See also [fromARGB], which takes the alpha value as a floating point
  /// value.
  const Color.fromARGB(int a, int r, int g, int b) :
    value = ((((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) & 0xFFFFFFFF);

  /// Create a color from red, green, blue, and opacity, similar to `rgba()` in CSS.
  ///
  /// * `r` is [red], from 0 to 255.
  /// * `g` is [red], from 0 to 255.
  /// * `b` is [red], from 0 to 255.
  /// * `opacity` is alpha channel of this color as a double, with 0.0 being
  ///   transparent and 1.0 being fully opaque.
  ///
  /// Out of range values are brought into range using modulo 255.
  ///
  /// See also [fromARGB], which takes the opacity as an integer value.
  const Color.fromRGBO(int r, int g, int b, double opacity) :
    value = (((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) & 0xFFFFFFFF);

  /// A 32 bit value representing this color.
  ///
  /// The bits are assigned as follows:
  ///
  /// * Bits 24-31 are the alpha value.
  /// * Bits 16-23 are the red value.
  /// * Bits 8-15 are the green value.
  /// * Bits 0-7 are the blue value.
  final int value;

  /// The alpha channel of this color in an 8 bit value.
  ///
  /// A value of 0 means this color is fully transparent. A value of 255 means
  /// this color is fully opaque.
  int get alpha => (0xff000000 & value) >> 24;

  /// The alpha channel of this color as a double.
  ///
  /// A value of 0.0 means this color is fully transparent. A value of 1.0 means
  /// this color is fully opaque.
  double get opacity => alpha / 0xFF;

  /// The red channel of this color in an 8 bit value.
  int get red => (0x00ff0000 & value) >> 16;

  /// The green channel of this color in an 8 bit value.
  int get green => (0x0000ff00 & value) >> 8;

  /// The blue channel of this color in an 8 bit value.
  int get blue => (0x000000ff & value) >> 0;

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with `a` (which ranges from 0 to 255).
  Color withAlpha(int a) {
    return new Color.fromARGB(a, red, green, blue);
  }

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with the given `opacity` (which ranges from 0.0 to 1.0).
  Color withOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  /// Returns a new color that matches this color with the red channel replaced
  /// with `r`.
  Color withRed(int r) {
    return new Color.fromARGB(alpha, r, green, blue);
  }

  /// Returns a new color that matches this color with the green channel
  /// replaced with `g`.
  Color withGreen(int g) {
    return new Color.fromARGB(alpha, red, g, blue);
  }

  /// Returns a new color that matches this color with the blue channel replaced
  /// with `b`.
  Color withBlue(int b) {
    return new Color.fromARGB(alpha, red, green, b);
  }

  /// Linearly interpolate between two colors.
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color.
  static Color lerp(Color a, Color b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return _scaleAlpha(b, t);
    if (b == null)
      return _scaleAlpha(a, 1.0 - t);
    return new Color.fromARGB(
      lerpDouble(a.alpha, b.alpha, t).toInt(),
      lerpDouble(a.red, b.red, t).toInt(),
      lerpDouble(a.green, b.green, t).toInt(),
      lerpDouble(a.blue, b.blue, t).toInt()
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Color)
      return false;
    final Color typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => "Color(0x${value.toRadixString(16).padLeft(8, '0')})";
}

/// Algorithms to use when painting on the canvas.
///
/// When drawing a shape or image onto a canvas, different algorithms
/// can be used to blend the pixels. The image below shows the effects
/// of these modes.
///
/// [![Open Skia fiddle to view image.](https://flutter.io/images/transfer_mode.png)](https://fiddle.skia.org/c/864acd0659c7a866ea7296a3184b8bdd)
///
/// See [Paint.transferMode].
enum TransferMode {
  // This list comes from Skia's SkXfermode.h and the values (order) should be
  // kept in sync.
  // See: https://skia.org/user/api/skpaint#SkXfermode

  clear,
  src,
  dst,
  srcOver,
  dstOver,
  srcIn,
  dstIn,
  srcOut,
  dstOut,
  srcATop,
  dstATop,
  xor,
  plus,
  modulate,

  // Following blend modes are defined in the CSS Compositing standard.

  screen,  // The last coeff mode.

  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  multiply,  // The last separable mode.

  hue,
  saturation,
  color,
  luminosity,
}

/// Quality levels for image filters.
///
/// See [Paint.filterQuality].
enum FilterQuality {
  // This list comes from Skia's SkFilterQuality.h and the values (order) should
  // be kept in sync.

  /// Fastest possible filtering, albeit also the lowest quality.
  ///
  /// Typically this implies nearest-neighbour filtering.
  none,

  /// Better quality than [none], faster than [medium].
  ///
  /// Typically this implies bilinear interpolation.
  low,

  /// Better quality than [low], faster than [high].
  ///
  /// Typically this implies a combination of bilinear interpolation and
  /// pyramidal parametric prefiltering (mipmaps).
  medium,

  /// Best possible quality filtering, albeit also the slowest.
  ///
  /// Typically this implies bicubic interpolation or better.
  high,
}

/// Styles to use for line endings.
///
/// See [Paint.strokeCap].
enum StrokeCap {
  /// Begin and end contours with a flat edge and no extension.
  butt,

  /// Begin and end contours with a semi-circle extension.
  round,

  /// Begin and end contours with a half square extension. This is
  /// similar to extending each contour by half the stroke width (as
  /// given by [Paint.strokeWidth]).
  square,
}

/// Strategies for painting shapes and paths on a canvas.
///
/// See [Paint.style].
enum PaintingStyle {
  // This list comes from Skia's SkPaint.h and the values (order) should be kept
  // in sync.

  /// Apply the [Paint] to the inside of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results in a disc
  /// of the given size being painted.
  fill,

  /// Apply the [Paint] to the edge of the shape. For example, when
  /// applied to the [Paint.drawCircle] call, this results is a hoop
  /// of the given size being painted. The line drawn on the edge will
  /// be the width given by the [Paint.strokeWidth] property.
  stroke,
}

// If we actually run on big endian machines, we'll need to do something smarter
// here. We don't use [Endianness.HOST_ENDIAN] because it's not a compile-time
// constant and can't propagate into the set/get calls.
const Endianness _kFakeHostEndian = Endianness.LITTLE_ENDIAN;

/// A description of the style to use when drawing on a [Canvas].
///
/// Most APIs on [Canvas] take a [Paint] object to describe the style
/// to use for that operation.
class Paint {
  // Paint objects are encoded in two buffers:
  //
  // * _data is binary data in four-byte fields, each of which is either a
  //   uint32_t or a float. The default value for each field is encoded as
  //   zero to make initialization trivial. Most values already have a default
  //   value of zero, but some, such a color, have a non-zero default value.
  //   To encode or decode these values, XOR the value with the default value.
  //
  // * _objects is a list of unencodable objects, typically wrappers for native
  //   objects. The objects are simply stored in the list without any additional
  //   encoding.
  //
  // The binary format must match the deserialization code in paint.cc.

  final ByteData _data = new ByteData(_kDataByteCount);
  static const int _kIsAntiAliasIndex = 0;
  static const int _kColorIndex = 1;
  static const int _kTransferModeIndex = 2;
  static const int _kStyleIndex = 3;
  static const int _kStrokeWidthIndex = 4;
  static const int _kStrokeCapIndex = 5;
  static const int _kFilterQualityIndex = 6;
  static const int _kColorFilterIndex = 7;
  static const int _kColorFilterColorIndex = 8;
  static const int _kColorFilterTransferModeIndex = 9;

  static const int _kIsAntiAliasOffset = _kIsAntiAliasIndex << 2;
  static const int _kColorOffset = _kColorIndex << 2;
  static const int _kTransferModeOffset = _kTransferModeIndex << 2;
  static const int _kStyleOffset = _kStyleIndex << 2;
  static const int _kStrokeWidthOffset = _kStrokeWidthIndex << 2;
  static const int _kStrokeCapOffset = _kStrokeCapIndex << 2;
  static const int _kFilterQualityOffset = _kFilterQualityIndex << 2;
  static const int _kColorFilterOffset = _kColorFilterIndex << 2;
  static const int _kColorFilterColorOffset = _kColorFilterColorIndex << 2;
  static const int _kColorFilterTransferModeOffset = _kColorFilterTransferModeIndex << 2;
  // If you add more fields, remember to update _kDataByteCount.
  static const int _kDataByteCount = 40;

  // Binary format must match the deserialization code in paint.cc.
  List<dynamic> _objects;
  static const int _kMaskFilterIndex = 0;
  static const int _kShaderIndex = 1;
  static const int _kObjectCount = 2;  // Must be one larger than the largest index

  /// Whether to apply anti-aliasing to lines and images drawn on the
  /// canvas.
  ///
  /// Defaults to true.
  bool get isAntiAlias {
    return _data.getInt32(_kIsAntiAliasOffset, _kFakeHostEndian) == 0;
  }
  set isAntiAlias(bool value) {
    // We encode true as zero and false as one because the default value, which
    // we always encode as zero, is true.
    final int encoded = value ? 0 : 1;
    _data.setInt32(_kIsAntiAliasOffset, encoded, _kFakeHostEndian);
  }

  static const int _kColorDefault = 0xFF000000;

  /// The color to use when stroking or filling a shape.
  ///
  /// Defaults to opaque black.
  ///
  /// See also:
  ///
  ///  * [style], which controls whether to stroke or fill (or both).
  ///  * [colorFilter], which overrides [color].
  ///  * [shader], which overrides [color] with more elaborate effects.
  ///
  /// This color is not used when compositing. To colorize a layer, use
  /// [colorFilter].
  Color get color {
    final int encoded = _data.getInt32(_kColorOffset, _kFakeHostEndian);
    return new Color(encoded ^ _kColorDefault);
  }
  set color(Color value) {
    assert(value != null);
    final int encoded = value.value ^ _kColorDefault;
    _data.setInt32(_kColorOffset, encoded, _kFakeHostEndian);
  }

  static final int _kTransferModeDefault = TransferMode.srcOver.index;

  /// A transfer mode to apply when a shape is drawn or a layer is composited.
  ///
  /// The source colors are from the shape being drawn (e.g. from
  /// [Canvas.drawPath]) or layer being composited (the graphics that were drawn
  /// between the [Canvas.saveLayer] and [Canvas.restore] calls), after applying
  /// the [colorFilter], if any.
  ///
  /// The destination colors are from the background onto which the shape or
  /// layer is being composited.
  ///
  /// Defaults to [TransferMode.srcOver].
  TransferMode get transferMode {
    final int encoded = _data.getInt32(_kTransferModeOffset, _kFakeHostEndian);
    return TransferMode.values[encoded ^ _kTransferModeDefault];
  }
  set transferMode(TransferMode value) {
    assert(value != null);
    final int encoded = value.index ^ _kTransferModeDefault;
    _data.setInt32(_kTransferModeOffset, encoded, _kFakeHostEndian);
  }

  /// Whether to paint inside shapes, the edges of shapes, or both.
  ///
  /// Defaults to [PaintingStyle.fill].
  PaintingStyle get style {
    return PaintingStyle.values[_data.getInt32(_kStyleOffset, _kFakeHostEndian)];
  }
  set style(PaintingStyle value) {
    assert(value != null);
    final int encoded = value.index;
    _data.setInt32(_kStyleOffset, encoded, _kFakeHostEndian);
  }

  /// How wide to make edges drawn when [style] is set to
  /// [PaintingStyle.stroke]. The width is given in logical pixels measured in
  /// the direction orthogonal to the direction of the path.
  ///
  /// Defaults to 0.0, which correspond to a hairline width.
  double get strokeWidth {
    return _data.getFloat32(_kStrokeWidthOffset, _kFakeHostEndian);
  }
  set strokeWidth(double value) {
    assert(value != null);
    final double encoded = value;
    _data.setFloat32(_kStrokeWidthOffset, encoded, _kFakeHostEndian);
  }

  /// The kind of finish to place on the end of lines drawn when
  /// [style] is set to [PaintingStyle.stroke].
  ///
  /// Defaults to [StrokeCap.butt], i.e. no caps.
  StrokeCap get strokeCap {
    return StrokeCap.values[_data.getInt32(_kStrokeCapOffset, _kFakeHostEndian)];
  }
  set strokeCap(StrokeCap value) {
    assert(value != null);
    final int encoded = value.index;
    _data.setInt32(_kStrokeCapOffset, encoded, _kFakeHostEndian);
  }

  /// A mask filter (for example, a blur) to apply to a shape after it has been
  /// drawn but before it has been composited into the image.
  ///
  /// See [MaskFilter] for details.
  MaskFilter get maskFilter {
    if (_objects == null)
      return null;
    return _objects[_kMaskFilterIndex];
  }
  set maskFilter(MaskFilter value) {
    _objects ??= new List<dynamic>(_kObjectCount);
    _objects[_kMaskFilterIndex] = value;
  }

  /// Controls the performance vs quality trade-off to use when applying
  /// filters, such as [maskFilter], or when drawing images, as with
  /// [Canvas.drawImageRect] or [Canvas.drawImageNine].
  ///
  /// Defaults to [FilterQuality.none].
  // TODO(ianh): verify that the image drawing methods actually respect this
  FilterQuality get filterQuality {
    return FilterQuality.values[_data.getInt32(_kFilterQualityOffset, _kFakeHostEndian)];
  }
  set filterQuality(FilterQuality value) {
    assert(value != null);
    final int encoded = value.index;
    _data.setInt32(_kFilterQualityOffset, encoded, _kFakeHostEndian);
  }

  /// The shader to use when stroking or filling a shape.
  ///
  /// When this is null, the [color] is used instead.
  ///
  /// See also:
  ///
  ///  * [Gradient], a shader that paints a color gradient.
  ///  * [ImageShader], a shader that tiles an [Image].
  ///  * [colorFilter], which overrides [shader].
  ///  * [color], which is used if [shader] and [colorFilter] are null.
  Shader get shader {
    if (_objects == null)
      return null;
    return _objects[_kShaderIndex];
  }
  set shader(Shader value) {
    _objects ??= new List<dynamic>(_kObjectCount);
    _objects[_kShaderIndex] = value;
  }

  /// A color filter to apply when a shape is drawn or when a layer is
  /// composited.
  ///
  /// See [ColorFilter] for details.
  ///
  /// When a shape is being drawn, [colorFilter] overrides [color] and [shader].
  ColorFilter get colorFilter {
    final bool isNull = _data.getInt32(_kColorFilterOffset, _kFakeHostEndian) == 0;
    if (isNull)
      return null;
    return new ColorFilter.mode(
      new Color(_data.getInt32(_kColorFilterColorOffset, _kFakeHostEndian)),
      TransferMode.values[_data.getInt32(_kColorFilterTransferModeOffset, _kFakeHostEndian)]
    );
  }
  set colorFilter(ColorFilter value) {
    if (value == null) {
      _data.setInt32(_kColorFilterOffset, 0, _kFakeHostEndian);
      _data.setInt32(_kColorFilterColorOffset, 0, _kFakeHostEndian);
      _data.setInt32(_kColorFilterTransferModeOffset, 0, _kFakeHostEndian);
    } else {
      assert(value._color != null);
      assert(value._transferMode != null);
      _data.setInt32(_kColorFilterOffset, 1, _kFakeHostEndian);
      _data.setInt32(_kColorFilterColorOffset, value._color.value, _kFakeHostEndian);
      _data.setInt32(_kColorFilterTransferModeOffset, value._transferMode.index, _kFakeHostEndian);
    }
  }

  @override
  String toString() {
    StringBuffer result = new StringBuffer();
    String semicolon = '';
    result.write('Paint(');
    if (style == PaintingStyle.stroke) {
      result.write('$style');
      if (strokeWidth != 0.0)
        result.write(' $strokeWidth');
      else
        result.write(' hairline');
      if (strokeCap != StrokeCap.butt)
        result.write(' $strokeCap');
      semicolon = '; ';
    }
    if (isAntiAlias != true) {
      result.write('${semicolon}antialias off');
      semicolon = '; ';
    }
    if (color != const Color(0xFF000000)) {
      if (color != null)
        result.write('$semicolon$color');
      else
        result.write('${semicolon}no color');
      semicolon = '; ';
    }
    if (transferMode != TransferMode.srcOver) {
      result.write('$semicolon$transferMode');
      semicolon = '; ';
    }
    if (colorFilter != null) {
      result.write('${semicolon}colorFilter: $colorFilter');
      semicolon = '; ';
    }
    if (maskFilter != null) {
      result.write('${semicolon}maskFilter: $maskFilter');
      semicolon = '; ';
    }
    if (filterQuality != FilterQuality.none) {
      result.write('${semicolon}filterQuality: $filterQuality');
      semicolon = '; ';
    }
    if (shader != null)
      result.write('${semicolon}shader: $shader');
    result.write(')');
    return result.toString();
  }
}

/// Opaque handle to raw decoded image data (pixels).
///
/// To obtain an Image object, use [decodeImageFromList].
///
/// To draw an Image, use one of the methods on the [Canvas] class, such as
/// [drawImage].
abstract class Image extends NativeFieldWrapperClass2 {
  /// The number of image pixels along the image's horizontal axis.
  int get width native "Image_width";

  /// The number of image pixels along the image's vertical axis.
  int get height native "Image_height";

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() native "Image_dispose";

  @override
  String toString() => '[$width\u00D7$height]';
}

/// Callback signature for [decodeImageFromList].
typedef void ImageDecoderCallback(Image result);

/// Convert an image file from a byte array into an [Image] object.
void decodeImageFromList(Uint8List list, ImageDecoderCallback callback)
    native "decodeImageFromList";

/// Determines how the interior of a [Path] is calculated.
enum PathFillType {
  /// The interior is defined by a non-zero sum of signed edge crossings.
  winding,

  /// The interior is defined by an odd number of edge crossings.
  evenOdd,
}

/// A complex, one-dimensional subset of a plane.
///
/// A path consists of a number of subpaths, and a _current point_.
///
/// Subpaths consist of segments of various types, such as lines,
/// arcs, or beziers. Subpaths can be open or closed, and can
/// self-intersect.
///
/// Closed subpaths enclose a (possibly discontiguous) region of the
/// plane based on whether a line from a given point on the plane to a
/// point at infinity intersects the path an even (non-enclosed) or an
/// odd (enclosed) number of times.
///
/// The _current point_ is initially at the origin. After each
/// operation adding a segment to a subpath, the current point is
/// updated to the end of that segment.
///
/// Paths can be drawn on canvases using [Canvas.drawPath], and can
/// used to create clip regions using [Canvas.clipPath].
class Path extends NativeFieldWrapperClass2 {
  /// Create a new empty [Path] object.
  Path() { _constructor(); }
  void _constructor() native "Path_constructor";

  /// Determines how the interior of this path is calculated.
  PathFillType get fillType => PathFillType.values[_getFillType()];
  set fillType (PathFillType value) => _setFillType(value.index);

  int _getFillType() native "Path_getFillType";
  void _setFillType(int fillType) native "Path_setFillType";

  /// Starts a new subpath at the given coordinate.
  void moveTo(double x, double y) native "Path_moveTo";

  /// Starts a new subpath at the given offset from the current point.
  void relativeMoveTo(double dx, double dy) native "Path_relativeMoveTo";

  /// Adds a straight line segment from the current point to the given
  /// point.
  void lineTo(double x, double y) native "Path_lineTo";

  /// Adds a straight line segment from the current point to the point
  /// at the given offset from the current point.
  void relativeLineTo(double dx, double dy) native "Path_relativeLineTo";

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the given point (x2,y2), using the control point
  /// (x1,y1).
  void quadraticBezierTo(double x1, double y1, double x2, double y2) native "Path_quadraticBezierTo";

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the point at the offset (x2,y2) from the current point,
  /// using the control point at the offset (x1,y1) from the current
  /// point.
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) native "Path_relativeQuadraticBezierTo";

  /// Adds a cubic bezier segment that curves from the current point
  /// to the given point (x3,y3), using the control points (x1,y1) and
  /// (x2,y2).
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) native "Path_cubicTo";

  /// Adds a cubcic bezier segment that curves from the current point
  /// to the point at the offset (x3,y3) from the current point, using
  /// the control points at the offsets (x1,y1) and (x2,y2) from the
  /// current point.
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3) native "Path_relativeCubicTo";

  /// Adds a bezier segment that curves from the current point to the
  /// given point (x2,y2), using the control points (x1,y1) and the
  /// weight w. If the weight is greater than 1, then the curve is a
  /// hyperbola; if the weight equals 1, it's a parabola; and if it is
  /// less than 1, it is an ellipse.
  void conicTo(double x1, double y1, double x2, double y2, double w) native "Path_conicTo";

  /// Adds a bezier segment that curves from the current point to the
  /// point at the offset (x2,y2) from the current point, using the
  /// control point at the offset (x1,y1) from the current point and
  /// the weight w. If the weight is greater than 1, then the curve is
  /// a hyperbola; if the weight equals 1, it's a parabola; and if it
  /// is less than 1, it is an ellipse.
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) native "Path_relativeConicTo";

  /// If the [forceMoveTo] argument is false, adds a straight line
  /// segment and an arc segment.
  ///
  /// If the [forceMoveTo] argument is true, starts a new subpath
  /// consisting of an arc segment.
  ///
  /// In either case, the arc segment consists of the arc that follows
  /// the edge of the oval bounded by the given rectangle, from
  /// startAngle radians around the oval up to startAngle + sweepAngle
  /// radians around the oval, with zero radians being the point on
  /// the right hand side of the oval that crosses the horizontal line
  /// that intersects the center of the rectangle and with positive
  /// angles going clockwise around the oval.
  ///
  /// The line segment added if [forceMoveTo] is false starts at the
  /// current point and ends at the start of the arc.
  void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    _arcTo(rect.left, rect.top, rect.right, rect.bottom, startAngle, sweepAngle, forceMoveTo);
  }
  void _arcTo(double left, double top, double right, double bottom,
              double startAngle, double sweepAngle, bool forceMoveTo) native "Path_arcTo";

  /// Adds a new subpath that consists of four lines that outline the
  /// given rectangle.
  void addRect(Rect rect) {
    _addRect(rect.left, rect.top, rect.right, rect.bottom);
  }
  void _addRect(double left, double top, double right, double bottom) native "Path_addRect";

  /// Adds a new subpath that consists of a curve that forms the
  /// ellipse that fills the given rectangle.
  void addOval(Rect oval) {
    _addOval(oval.left, oval.top, oval.right, oval.bottom);
  }
  void _addOval(double left, double top, double right, double bottom) native "Path_addOval";

  /// Adds a new subpath with one arc segment that consists of the arc
  /// that follows the edge of the oval bounded by the given
  /// rectangle, from startAngle radians around the oval up to
  /// startAngle + sweepAngle radians around the oval, with zero
  /// radians being the point on the right hand side of the oval that
  /// crosses the horizontal line that intersects the center of the
  /// rectangle and with positive angles going clockwise around the
  /// oval.
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    _addArc(oval.left, oval.top, oval.right, oval.bottom, startAngle, sweepAngle);
  }
  void _addArc(double left, double top, double right, double bottom,
               double startAngle, double sweepAngle) native "Path_addArc";

  /// Adds a new subpath with a sequence of line segments that connect the given
  /// points. If `close` is true, a final line segment will be added that
  /// connects the last point to the first point.
  void addPolygon(List<Point> points, bool close) {
    _addPolygon(_encodePointList(points), close);
  }
  void _addPolygon(Float32List points, bool close) native "Path_addPolygon";

  /// Adds a new subpath that consists of the straight lines and
  /// curves needed to form the rounded rectangle described by the
  /// argument.
  void addRRect(RRect rrect) => _addRRect(rrect._value);
  void _addRRect(Float32List rrect) native "Path_addRRect";

  /// Adds a new subpath that consists of the given path offset by the given
  /// offset.
  void addPath(Path path, Offset offset) => _addPath(path, offset.dx, offset.dy);
  void _addPath(Path path, double dx, double dy) native "Path_addPath";

  /// Adds the given path to this path by extending the current segment of this
  /// path with the the first segment of the given path.
  void extendWithPath(Path path, Offset offset) => _extendWithPath(path, offset.dx, offset.dy);
  void _extendWithPath(Path path, double dx, double dy) native "Path_extendWithPath";

  /// Closes the last subpath, as if a straight line had been drawn
  /// from the current point to the first point of the subpath.
  void close() native "Path_close";

  /// Clears the [Path] object of all subpaths, returning it to the
  /// same state it had when it was created. The _current point_ is
  /// reset to the origin.
  void reset() native "Path_reset";

  /// Tests to see if the point is within the path. (That is, whether
  /// the point would be in the visible portion of the path if the
  /// path was used with [Canvas.clipPath].)
  ///
  /// Returns true if the point is in the path, and false otherwise.
  bool contains(Point position) => _contains(position.x, position.y);
  bool _contains(double x, double y) native "Path_contains";

  /// Returns a copy of the path with all the segments of every
  /// subpath translated by the given offset.
  Path shift(Offset offset) => _shift(offset.dx, offset.dy);
  Path _shift(double dx, double dy) native "Path_shift";

  /// Returns a copy of the path with all the segments of every
  /// subpath transformed by the given matrix.
  Path transform(Float64List matrix4) {
    if (matrix4.length != 16)
      throw new ArgumentError("[matrix4] must have 16 entries.");
    return _transform(matrix4);
  }
  Path _transform(Float64List matrix4) native "Path_transform";
}

/// Styles to use for blurs in [MaskFilter] objects.
enum BlurStyle {
  // These mirror SkBlurStyle and must be kept in sync.

  /// Fuzzy inside and outside. This is useful for painting shadows that are
  /// offset from the shape that ostensibly is casting the shadow.
  normal,

  /// Solid inside, fuzzy outside. This corresponds to drawing the shape, and
  /// additionally drawing the blur. This can make objects appear brighter,
  /// maybe even as if they were fluorescent.
  solid,

  /// Nothing inside, fuzzy outside. This is useful for painting shadows for
  /// partially transparent shapes, when they are painted separately but without
  /// an offset, so that the shadow doesn't paint below the shape.
  outer,

  /// Fuzzy inside, nothing outside. This can make shapes appear to be lit from
  /// within.
  inner,
}

/// A mask filter to apply to shapes as they are painted. A mask filter is a
/// function that takes a bitmap of color pixels, and returns another bitmap of
/// color pixels.
///
/// Instances of this class are used with [Paint.maskFilter] on [Paint] objects.
class MaskFilter extends NativeFieldWrapperClass2 {
  /// Creates a mask filter that takes the shape being drawn and blurs it.
  ///
  /// This is commonly used to approximate shadows.
  ///
  /// The `style` argument controls the kind of effect to draw; see [BlurStyle].
  ///
  /// The `sigma` argument controls the size of the effect. It is the standard
  /// deviation of the Gaussian blur to apply. The value must be greater than
  /// zero. The sigma corresponds to very roughly half the radius of the effect
  /// in pixels.
  ///
  /// A blur is an expensive operation and should therefore be used sparingly.
  MaskFilter.blur(BlurStyle style, double sigma) {
    _constructor(style.index, sigma);
  }
  void _constructor(int style, double sigma) native "MaskFilter_constructor";
}

/// A description of a color filter to apply when drawing a shape or compositing
/// a layer with a particular [Paint]. A color filter is a function that takes
/// two colors, and outputs one color. When applied during compositing, it is
/// independently applied to each pixel of the layer being drawn before the
/// entire layer is merged with the destination.
///
/// Instances of this class are used with [Paint.colorFilter] on [Paint]
/// objects.
class ColorFilter {
  /// Creates a color filter that applies the transfer mode given as the second
  /// argument. The source color is the one given as the first argument, and the
  /// destination color is the one from the layer being composited.
  ///
  /// The output of this filter is then composited into the background according
  /// to the [Paint.transferMode], using the output of this filter as the source
  /// and the background as the destination.
  ColorFilter.mode(Color color, TransferMode transferMode)
    : _color = color, _transferMode = transferMode;

  final Color _color;
  final TransferMode _transferMode;

  @override
  bool operator ==(dynamic other) {
    if (other is! ColorFilter)
      return false;
    final ColorFilter typedOther = other;
    return _color == typedOther._color &&
           _transferMode == typedOther._transferMode;
  }

  @override
  int get hashCode => hashValues(_color, _transferMode);

  @override
  String toString() => "ColorFilter($_color, $TransferMode)";
}

/// A filter operation to apply to a raster image.
///
/// See [SceneBuilder.pushBackdropFilter].
class ImageFilter extends NativeFieldWrapperClass2 {
  void _constructor() native "ImageFilter_constructor";

  /// A source filter containing an image.
  // ImageFilter.image({ Image image }) {
  //   _constructor();
  //   _initImage(image);
  // }
  // void _initImage(Image image) native "ImageFilter_initImage";

  /// A source filter containing a picture.
  // ImageFilter.picture({ Picture picture }) {
  //   _constructor();
  //   _initPicture(picture);
  // }
  // void _initPicture(Picture picture) native "ImageFilter_initPicture";

  /// Creates an image filter that applies a Gaussian blur.
  ImageFilter.blur({ double sigmaX: 0.0, double sigmaY: 0.0 }) {
    _constructor();
    _initBlur(sigmaX, sigmaY);
  }
  void _initBlur(double sigmaX, double sigmaY) native "ImageFilter_initBlur";
}

/// Base class for objects such as [Gradient] and [ImageShader] which
/// correspond to shaders as used by [Paint.shader].
abstract class Shader extends NativeFieldWrapperClass2 { }

/// Defines what happens at the edge of the gradient.
enum TileMode {
  /// Edge is clamped to the final color.
  clamp,

  /// Edge is repeated from first color to last.
  repeated,

  /// Edge is mirrored from last color to first.
  mirror,
}

Int32List _encodeColorList(List<Color> colors) {
  final int colorCount = colors.length;
  final Int32List result = new Int32List(colorCount);
  for (int i = 0; i < colorCount; ++i)
    result[i] = colors[i].value;
  return result;
}

Float32List _encodePointList(List<Point> points) {
  final int pointCount = points.length;
  final Float32List result = new Float32List(pointCount * 2);
  for (int i = 0; i < pointCount; ++i) {
    final int xIndex = i * 2;
    final int yIndex = xIndex + 1;
    final Point point = points[i];
    result[xIndex] = point.x;
    result[yIndex] = point.y;
  }
  return result;
}

/// A shader (as used by [Paint.shader]) that renders a color gradient.
///
/// There are two useful types of gradients, created by [new Gradient.linear]
/// and [new Griadent.radial].
class Gradient extends Shader {
  /// Creates a Gradient object that is not initialized.
  ///
  /// Use the [Gradient.linear] or [Gradient.radial] constructors to
  /// obtain a usable [Gradient] object.
  Gradient();
  void _constructor() native "Gradient_constructor";

  /// Creates a linear gradient from `endPoint[0]` to `endPoint[1]`. If
  /// `colorStops` is provided, `colorStops[i]` is a number from 0 to 1 that
  /// specifies where `color[i]` begins in the gradient. If `colorStops` is not
  /// provided, then two stops at 0.0 and 1.0 are implied. The behavior before
  /// and after the radius is described by the `tileMode` argument.
  // TODO(mpcomplete): Consider passing a list of (color, colorStop) pairs
  // instead.
  Gradient.linear(List<Point> endPoints,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    if (endPoints == null || endPoints.length != 2)
      throw new ArgumentError("Expected exactly 2 [endPoints].");
    _validateColorStops(colors, colorStops);
    final Float32List endPointsBuffer = _encodePointList(endPoints);
    final Int32List colorsBuffer = _encodeColorList(colors);
    final Float32List colorStopsBuffer = colorStops == null ? null : new Float32List.fromList(colorStops);
    _constructor();
    _initLinear(endPointsBuffer, colorsBuffer, colorStopsBuffer, tileMode.index);
  }
  void _initLinear(Float32List endPoints, Int32List colors, Float32List colorStops, int tileMode) native "Gradient_initLinear";

  /// Creates a radial gradient centered at `center` that ends at `radius`
  /// distance from the center. If `colorStops` is provided, `colorStops[i]` is
  /// a number from 0 to 1 that specifies where `color[i]` begins in the
  /// gradient. If `colorStops` is not provided, then two stops at 0.0 and 1.0
  /// are implied. The behavior before and after the radius is described by the
  /// `tileMode` argument.
  Gradient.radial(Point center,
                  double radius,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    _validateColorStops(colors, colorStops);
    final Int32List colorsBuffer = _encodeColorList(colors);
    final Float32List colorStopsBuffer = colorStops == null ? null : new Float32List.fromList(colorStops);
    _constructor();
    _initRadial(center.x, center.y, radius, colorsBuffer, colorStopsBuffer, tileMode.index);
  }
  void _initRadial(double centerX, double centerY, double radius, Int32List colors, Float32List colorStops, int tileMode) native "Gradient_initRadial";

  static void _validateColorStops(List<Color> colors, List<double> colorStops) {
    if (colorStops != null && colors.length != colorStops.length)
      throw new ArgumentError("[colors] and [colorStops] parameters must be equal length.");
  }
}

/// A shader (as used by [Paint.shader]) that tiles an image.
class ImageShader extends Shader {
  /// Creates an image-tiling shader. The first argument specifies the image to
  /// tile. The second and third arguments specify the [TileMode] for the x
  /// direction and y direction respectively. The fourth argument gives the
  /// matrix to apply to the effect. All the arguments are required and must not
  /// be null.
  ImageShader(Image image, TileMode tmx, TileMode tmy, Float64List matrix4) {
    if (image == null)
      throw new ArgumentError("[image] argument cannot be null");
    if (tmx == null)
      throw new ArgumentError("[tmx] argument cannot be null");
    if (tmy == null)
      throw new ArgumentError("[tmy] argument cannot be null");
    if (matrix4 == null)
      throw new ArgumentError("[matrix4] argument cannot be null");
    if (matrix4.length != 16)
      throw new ArgumentError("[matrix4] must have 16 entries.");
    _constructor();
    _initWithImage(image, tmx.index, tmy.index, matrix4);
  }
  void _constructor() native "ImageShader_constructor";
  void _initWithImage(Image image, int tmx, int tmy, Float64List matrix4) native "ImageShader_initWithImage";
}

/// Defines how a list of points is interpreted when drawing a set of triangles.
///
/// Used by [Canvas.drawVertices].
enum VertexMode {
  /// Draw each sequence of three points as the vertices of a triangle.
  triangles,

  /// Draw each sliding window of three points as the vertices of a triangle.
  triangleStrip,

  /// Draw the first point and each sliding window of two points as the vertices of a triangle.
  triangleFan,
}

/// Defines how a list of points is interpreted when drawing a set of points.
///
/// Used by [Canvas.drawPoints].
enum PointMode {
  /// Draw each point separately.
  ///
  /// If the [Paint.strokeCap] is [StrokeCat.round], then each point is drawn
  /// as a circle with the diameter of the [Paint.strokeWidth], filled as
  /// described by the [Paint] (ignoring [Paint.style]).
  ///
  /// Otherwise, each point is drawn as an axis-aligned square with sides of
  /// length [Paint.strokeWidth], filled as described by the [Paint] (ignoring
  /// [Paint.style]).
  points,

  /// Draw each sequence of two points as a line segment.
  ///
  /// If the number of points is odd, then the last point is ignored.
  ///
  /// The lines are stroked as described by the [Paint] (ignoring
  /// [Paint.style]).
  lines,

  /// Draw the entire sequence of point as one line.
  ///
  /// The lines are stroked as described by the [Paint] (ignoring
  /// [Paint.style]).
  polygon,
}

/// An interface for recording graphical operations.
///
/// [Canvas] objects are used in creating [Picture] objects, which can
/// themselves be used with a [SceneBuilder] to build a [Scene]. In
/// normal usage, however, this is all handled by the framework.
///
/// A canvas has a current transformation matrix which is applied to all
/// operations. Initially, the transformation matrix is the identity transform.
/// It can be modified using the [translate], [scale], [rotate], [skew],
/// and [transform] methods.
///
/// A canvas also has a current clip region which is applied to all operations.
/// Initially, the clip region is infinite. It can be modified using the
/// [clipRect], [clipRRect], and [clipPath] methods.
///
/// The current transform and clip can be saved and restored using the stack
/// managed by the [save], [saveLayer], and [restore] methods.
class Canvas extends NativeFieldWrapperClass2 {
  /// Creates a canvas for recording graphical operations into the
  /// given picture recorder.
  ///
  /// Graphical operations that affect pixels entirely outside the given
  /// cullRect might be discarded by the implementation. However, the
  /// implementation might draw outside these bounds if, for example, a command
  /// draws partially inside and outside the cullRect. To ensure that pixels
  /// outside a given region are discarded, consider using a [clipRect].
  ///
  /// To end the recording, call [PictureRecorder.endRecording] on the
  /// given recorder.
  Canvas(PictureRecorder recorder, Rect cullRect) {
    if (recorder == null)
      throw new ArgumentError('The given PictureRecorder was null.');
    if (recorder.isRecording)
      throw new ArgumentError('The given PictureRecorder is already associated with another Canvas.');
    // TODO(ianh): throw if recorder is defunct (https://github.com/flutter/flutter/issues/2531)
    _constructor(recorder, cullRect.left, cullRect.top, cullRect.right, cullRect.bottom);
  }
  void _constructor(PictureRecorder recorder,
                    double left,
                    double top,
                    double right,
                    double bottom) native "Canvas_constructor";

  /// Saves a copy of the current transform and clip on the save stack.
  ///
  /// Call [restore] to pop the save stack.
  void save() native "Canvas_save";

  /// Saves a copy of the current transform and clip on the save stack, and then
  /// creates a new group which subsequent calls will become a part of. When the
  /// save stack is later popped, the group will be flattened into a layer and
  /// have the given `paint`'s [Paint.colorFilter] and [Paint.transferMode]
  /// applied.
  ///
  /// This lets you create composite effects, for example making a group of
  /// drawing commands semi-transparent. Without using [saveLayer], each part of
  /// the group would be painted individually, so where they overlap would be
  /// darker than where they do not. By using [saveLayer] to group them
  /// together, they can be drawn with an opaque color at first, and then the
  /// entire group can be made transparent using the [saveLayer]'s paint.
  ///
  /// Call [restore] to pop the save stack and apply the paint to the group.
  void saveLayer(Rect bounds, Paint paint) {
    if (bounds == null) {
      _saveLayerWithoutBounds(paint._objects, paint._data);
    } else {
      _saveLayer(bounds.left, bounds.top, bounds.right, bounds.bottom,
                 paint._objects, paint._data);
    }
  }
  void _saveLayerWithoutBounds(List<dynamic> paintObjects, ByteData paintData)
      native "Canvas_saveLayerWithoutBounds";
  // TODO(jackson): Paint should be optional, but making it optional causes crash
  void _saveLayer(double left,
                  double top,
                  double right,
                  double bottom,
                  List<dynamic> paintObjects,
                  ByteData paintData) native "Canvas_saveLayer";

  /// Pops the current save stack, if there is anything to pop.
  /// Otherwise, does nothing.
  ///
  /// Use [save] and [saveLayer] to push state onto the stack.
  ///
  /// If the state was pushed with with [saveLayer], then this call will also
  /// cause the new layer to be composited into the previous layer.
  void restore() native "Canvas_restore";

  /// Returns the number of items on the save stack, including the
  /// initial state. This means it returns 1 for a clean canvas, and
  /// that each call to [save] and [saveLayer] increments it, and that
  /// each matching call to [restore] decrements it.
  ///
  /// This number cannot go below 1.
  int getSaveCount() native "Canvas_getSaveCount";

  /// Add a translation to the current transform, shifting the coordinate space
  /// horizontally by the first argument and vertically by the second argument.
  void translate(double dx, double dy) native "Canvas_translate";

  /// Add an axis-aligned scale to the current transform, scaling by the first
  /// argument in the horizontal direction and the second in the vertical
  /// direction.
  void scale(double sx, double sy) native "Canvas_scale";

  /// Add a rotation to the current transform. The argument is in radians clockwise.
  void rotate(double radians) native "Canvas_rotate";

  /// Add an axis-aligned skew to the current transform, with the first argument
  /// being the horizontal skew in radians clockwise around the origin, and the
  /// second argument being the vertical skew in radians clockwise around the
  /// origin.
  void skew(double sx, double sy) native "Canvas_skew";

  /// Multiply the current transform by the specified 4⨉4 transformation matrix
  /// specified as a list of values in column-major order.
  void transform(Float64List matrix4) {
    if (matrix4.length != 16)
      throw new ArgumentError("[matrix4] must have 16 entries.");
    _transform(matrix4);
  }
  void _transform(Float64List matrix4) native "Canvas_transform";

  /// Reduces the clip region to the intersection of the current clip and the
  /// given rectangle.
  void clipRect(Rect rect) {
    _clipRect(rect.left, rect.top, rect.right, rect.bottom);
  }
  void _clipRect(double left,
                 double top,
                 double right,
                 double bottom) native "Canvas_clipRect";

  /// Reduces the clip region to the intersection of the current clip and the
  /// given rounded rectangle.
  void clipRRect(RRect rrect) => _clipRRect(rrect._value);
  void _clipRRect(Float32List rrect) native "Canvas_clipRRect";

  /// Reduces the clip region to the intersection of the current clip and the
  /// given [Path].
  void clipPath(Path path) native "Canvas_clipPath";

  /// Paints the given [Color] onto the canvas, applying the given
  /// [TransferMode], with the given color being the source and the background
  /// being the destination.
  void drawColor(Color color, TransferMode transferMode) {
    _drawColor(color.value, transferMode.index);
  }
  void _drawColor(int color, int transferMode) native "Canvas_drawColor";

  /// Draws a line between the given [Point]s using the given paint. The line is
  /// stroked, the value of the [Paint.style] is ignored for this call.
  void drawLine(Point p1, Point p2, Paint paint) {
    _drawLine(p1.x, p1.y, p2.x, p2.y, paint._objects, paint._data);
  }
  void _drawLine(double x1,
                 double y1,
                 double x2,
                 double y2,
                 List<dynamic> paintObjects,
                 ByteData paintData) native "Canvas_drawLine";

  /// Fills the canvas with the given [Paint].
  ///
  /// To fill the canvas with a solid color and transfer mode, consider
  /// [drawColor] instead.
  void drawPaint(Paint paint) => _drawPaint(paint._objects, paint._data);
  void _drawPaint(List<dynamic> paintObjects, ByteData paintData) native "Canvas_drawPaint";

  /// Draws a rectangle with the given [Paint]. Whether the rectangle is filled
  /// or stroked (or both) is controlled by [Paint.style].
  void drawRect(Rect rect, Paint paint) {
    _drawRect(rect.left, rect.top, rect.right, rect.bottom,
              paint._objects, paint._data);
  }
  void _drawRect(double left,
                 double top,
                 double right,
                 double bottom,
                 List<dynamic> paintObjects,
                 ByteData paintData) native "Canvas_drawRect";

  /// Draws a rounded rectangle with the given [Paint]. Whether the rectangle is
  /// filled or stroked (or both) is controlled by [Paint.style].
  void drawRRect(RRect rrect, Paint paint) {
    _drawRRect(rrect._value, paint._objects, paint._data);
  }
  void _drawRRect(Float32List rrect,
                  List<dynamic> paintObjects,
                  ByteData paintData) native "Canvas_drawRRect";

  /// Draws a shape consisting of the difference between two rounded rectangles
  /// with the given [Paint]. Whether this shape is filled or stroked (or both)
  /// is controlled by [Paint.style].
  ///
  /// This shape is almost but not quite entirely unlike an annulus.
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    _drawDRRect(outer._value, inner._value, paint._objects, paint._data);
  }
  void _drawDRRect(Float32List outer,
                   Float32List inner,
                   List<dynamic> paintObjects,
                   ByteData paintData) native "Canvas_drawDRRect";

  /// Draws an axis-aligned oval that fills the given axis-aligned rectangle
  /// with the given [Paint]. Whether the oval is filled or stroked (or both) is
  /// controlled by [Paint.style].
  void drawOval(Rect rect, Paint paint) {
    _drawOval(rect.left, rect.top, rect.right, rect.bottom,
              paint._objects, paint._data);
  }
  void _drawOval(double left,
                 double top,
                 double right,
                 double bottom,
                 List<dynamic> paintObjects,
                 ByteData paintData) native "Canvas_drawOval";

  /// Draws a circle centered at the point given by the first two arguments and
  /// that has the radius given by the third argument, with the [Paint] given in
  /// the fourth argument. Whether the circle is filled or stroked (or both) is
  /// controlled by [Paint.style].
  void drawCircle(Point c, double radius, Paint paint) {
    _drawCircle(c.x, c.y, radius, paint._objects, paint._data);
  }
  void _drawCircle(double x,
                   double y,
                   double radius,
                   List<dynamic> paintObjects,
                   ByteData paintData) native "Canvas_drawCircle";

  /// Draw an arc scaled to fit inside the given rectangle. It starts from
  /// startAngle radians around the oval up to startAngle + sweepAngle
  /// radians around the oval, with zero radians being the point on
  /// the right hand side of the oval that crosses the horizontal line
  /// that intersects the center of the rectangle and with positive
  /// angles going clockwise around the oval. If useCenter is true, the arc is
  /// closed back to the center, forming a circle sector. Otherwise, the arc is
  /// not closed, forming a circle segment.
  ///
  /// This method is optimized for drawing arcs and should be faster than [Path.arcTo].
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    _drawArc(rect.left, rect.top, rect.right, rect.bottom, startAngle,
             sweepAngle, useCenter, paint._objects, paint._data);
  }
  void _drawArc(double left,
                double top,
                double right,
                double bottom,
                double startAngle,
                double sweepAngle,
                bool useCenter,
                List<dynamic> paintObjects,
                ByteData paintData) native "Canvas_drawArc";

  /// Draws the given [Path] with the given [Paint]. Whether this shape is
  /// filled or stroked (or both) is controlled by [Paint.style]. If the path is
  /// filled, then subpaths within it are implicitly closed (see [Path.close]).
  void drawPath(Path path, Paint paint) {
    _drawPath(path, paint._objects, paint._data);
  }
  void _drawPath(Path path,
                 List<dynamic> paintObjects,
                 ByteData paintData) native "Canvas_drawPath";

  /// Draws the given [Image] into the canvas with its top-left corner at the
  /// given [Point]. The image is composited into the canvas using the given [Paint].
  void drawImage(Image image, Point p, Paint paint) {
    _drawImage(image, p.x, p.y, paint._objects, paint._data);
  }
  void _drawImage(Image image,
                  double x,
                  double y,
                  List<dynamic> paintObjects,
                  ByteData paintData) native "Canvas_drawImage";

  /// Draws the subset of the given image described by the `src` argument into
  /// the canvas in the axis-aligned rectangle given by the `dst` argument.
  ///
  /// This might sample from outside the `src` rect by up to half the width of
  /// an applied filter.
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {
    _drawImageRect(image,
                   src.left,
                   src.top,
                   src.right,
                   src.bottom,
                   dst.left,
                   dst.top,
                   dst.right,
                   dst.bottom,
                   paint._objects,
                   paint._data);
  }
  void _drawImageRect(Image image,
                      double srcLeft,
                      double srcTop,
                      double srcRight,
                      double srcBottom,
                      double dstLeft,
                      double dstTop,
                      double dstRight,
                      double dstBottom,
                      List<dynamic> paintObjects,
                      ByteData paintData) native "Canvas_drawImageRect";

  /// Draws the given [Image] into the canvas using the given [Paint].
  ///
  /// The image is drawn in nine portions described by splitting the image by
  /// drawing two horizontal lines and two vertical lines, where the `center`
  /// argument describes the rectangle formed by the four points where these
  /// four lines intersect each other. (This forms a 3-by-3 grid of regions,
  /// the center region being described by the `center` argument.)
  ///
  /// The four regions in the corners are drawn, without scaling, in the four
  /// corners of the destination rectangle described by `dst`. The remaining
  /// five regions are drawn by stretching them to fit such that they exactly
  /// cover the destination rectangle while maintaining their relative
  /// positions.
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) {
    _drawImageNine(image,
                   center.left,
                   center.top,
                   center.right,
                   center.bottom,
                   dst.left,
                   dst.top,
                   dst.right,
                   dst.bottom,
                   paint._objects,
                   paint._data);
  }
  void _drawImageNine(Image image,
                      double centerLeft,
                      double centerTop,
                      double centerRight,
                      double centerBottom,
                      double dstLeft,
                      double dstTop,
                      double dstRight,
                      double dstBottom,
                      List<dynamic> paintObjects,
                      ByteData paintData) native "Canvas_drawImageNine";

  /// Draw the given picture onto the canvas. To create a picture, see
  /// [PictureRecorder].
  void drawPicture(Picture picture) native "Canvas_drawPicture";

  /// Draws the text in the given paragraph into this canvas at the given offset.
  ///
  /// Valid only after [Paragraph.layout] has been called on the paragraph.
  void drawParagraph(Paragraph paragraph, Offset offset) {
    paragraph._paint(this, offset.dx, offset.dy);
  }

  /// Draws a sequence of points according to the given [PointMode].
  void drawPoints(PointMode pointMode, List<Point> points, Paint paint) {
    _drawPoints(paint._objects, paint._data, pointMode.index, _encodePointList(points));
  }
  void _drawPoints(List<dynamic> paintObjects,
                   ByteData paintData,
                   int pointMode,
                   Float32List points) native "Canvas_drawPoints";

  void drawVertices(VertexMode vertexMode,
                    List<Point> vertices,
                    List<Point> textureCoordinates,
                    List<Color> colors,
                    TransferMode transferMode,
                    List<int> indicies,
                    Paint paint) {
    final int vertexCount = vertices.length;

    if (textureCoordinates.isNotEmpty && textureCoordinates.length != vertexCount)
      throw new ArgumentError("[vertices] and [textureCoordinates] lengths must match");
    if (colors.isNotEmpty && colors.length != vertexCount)
      throw new ArgumentError("[vertices] and [colors] lengths must match");

    final Float32List vertexBuffer = _encodePointList(vertices);
    final Float32List textureCoordinateBuffer = textureCoordinates.isEmpty ? null : _encodePointList(textureCoordinates);
    final Int32List colorBuffer = colors.isEmpty ? null : _encodeColorList(colors);
    final Int32List indexBuffer = new Int32List.fromList(indicies);

    _drawVertices(
      paint._objects, paint._data, vertexMode.index, vertexBuffer,
      textureCoordinateBuffer, colorBuffer, transferMode.index, indexBuffer
    );
  }
  void _drawVertices(List<dynamic> paintObjects,
                     ByteData paintData,
                     int vertexMode,
                     Float32List vertices,
                     Float32List textureCoordinates,
                     Int32List colors,
                     int transferMode,
                     Int32List indicies) native "Canvas_drawVertices";

  // TODO(eseidel): Paint should be optional, but optional doesn't work.
  void drawAtlas(Image atlas,
                 List<RSTransform> transforms,
                 List<Rect> rects,
                 List<Color> colors,
                 TransferMode transferMode,
                 Rect cullRect,
                 Paint paint) {
    final int rectCount = rects.length;

    if (transforms.length != rectCount)
      throw new ArgumentError("[transforms] and [rects] lengths must match");
    if (colors.isNotEmpty && colors.length != rectCount)
      throw new ArgumentError("if supplied, [colors] length must match that of [transforms] and [rects]");

    final Float32List rstTransformBuffer = new Float32List(rectCount * 4);
    final Float32List rectBuffer = new Float32List(rectCount * 4);

    for (int i = 0; i < rectCount; ++i) {
      final int index0 = i * 4;
      final int index1 = index0 + 1;
      final int index2 = index0 + 2;
      final int index3 = index0 + 3;
      final RSTransform rstTransform = transforms[i];
      final Rect rect = rects[i];
      rstTransformBuffer[index0] = rstTransform.scos;
      rstTransformBuffer[index1] = rstTransform.ssin;
      rstTransformBuffer[index2] = rstTransform.tx;
      rstTransformBuffer[index3] = rstTransform.ty;
      rectBuffer[index0] = rect.left;
      rectBuffer[index1] = rect.top;
      rectBuffer[index2] = rect.right;
      rectBuffer[index3] = rect.bottom;
    }

    final Int32List colorBuffer = colors.isEmpty ? null : _encodeColorList(colors);
    final Float32List cullRectBuffer = cullRect?._value;

    _drawAtlas(
      paint._objects, paint._data, atlas, rstTransformBuffer, rectBuffer,
      colorBuffer, transferMode.index, cullRectBuffer
    );
  }
  void _drawAtlas(List<dynamic> paintObjects,
                  ByteData paintData,
                  Image atlas,
                  Float32List rstTransforms,
                  Float32List rects,
                  Int32List colors,
                  int transferMode,
                  Float32List cullRect) native "Canvas_drawAtlas";
}

/// An object representing a sequence of recorded graphical operations.
///
/// To create a [Picture], use a [PictureRecorder].
///
/// A [Picture] can be placed in a [Scene] using a [SceneBuilder], via
/// the [SceneBuilder.addPicture] method. A [Picture] can also be
/// drawn into a [Canvas], using the [Canvas.drawPicture] method.
abstract class Picture extends NativeFieldWrapperClass2 {
  /// Creates an uninitialized Picture object.
  ///
  /// Calling the Picture constructor directly will not create a useable
  /// object. To create a Picture object, use a [PictureRecorder].
  Picture(); // (this constructor is here just so we can document it)

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() native "Picture_dispose";
}

/// Records a [Picture] containing a sequence of graphical operations.
///
/// To begin recording, construct a [Canvas] to record the commands.
/// To end recording, use the [PictureRecorder.endRecording] method.
class PictureRecorder extends NativeFieldWrapperClass2 {
  /// Creates a new idle PictureRecorder. To associate it with a
  /// [Canvas] and begin recording, pass this [PictureRecorder] to the
  /// [Canvas] constructor.
  PictureRecorder() { _constructor(); }
  void _constructor() native "PictureRecorder_constructor";

  /// Whether this object is currently recording commands.
  ///
  /// Specifically, this returns true if a [Canvas] object has been
  /// created to record commands and recording has not yet ended via a
  /// call to [endRecording], and false if either this
  /// [PictureRecorder] has not yet been associated with a [Canvas],
  /// or the [endRecording] method has already been called.
  bool get isRecording native "PictureRecorder_isRecording";

  /// Finishes recording graphical operations.
  ///
  /// Returns a picture containing the graphical operations that have been
  /// recorded thus far. After calling this function, both the picture recorder
  /// and the canvas objects are invalid and cannot be used further.
  ///
  /// Returns null if the PictureRecorder is not associated with a canvas.
  Picture endRecording() native "PictureRecorder_endRecording";
}
