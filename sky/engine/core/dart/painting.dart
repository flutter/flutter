// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Opaque handle to raw decoded image data (pixels).
///
/// To obtain an Image object, use the [decodeImageFromDataPipe] or
/// [decodeImageFromList] functions.
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

  String toString() => '[$width\u00D7$height]';
}

/// Callback signature for [decodeImageFromDataPipe] and [decodeImageFromList].
typedef void ImageDecoderCallback(Image result);

/// Convert an image file from a mojo pipe into an [Image] object.
void decodeImageFromDataPipe(int handle, ImageDecoderCallback callback)
    native "decodeImageFromDataPipe";

/// Convert an image file from a byte array into an [Image] object.
void decodeImageFromList(Uint8List list, ImageDecoderCallback callback)
    native "decodeImageFromList";

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
  void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) native "Path_arcTo";

  /// Adds a new subpath that consists of four lines that outline the
  /// given rectangle.
  void addRect(Rect rect) native "Path_addRect";

  /// Adds a new subpath that consists of a curve that forms the
  /// ellipse that fills the given rectangle.
  void addOval(Rect oval) native "Path_addOval";

  /// Adds a new subpath with one arc segment that consists of the arc
  /// that follows the edge of the oval bounded by the given
  /// rectangle, from startAngle radians around the oval up to
  /// startAngle + sweepAngle radians around the oval, with zero
  /// radians being the point on the right hand side of the oval that
  /// crosses the horizontal line that intersects the center of the
  /// rectangle and with positive angles going clockwise around the
  /// oval.
  void addArc(Rect oval, double startAngle, double sweepAngle) native "Path_addArc";

  /// Adds a new subpath that consists of the straight lines and
  /// curves needed to form the rounded rectangle described by the
  /// argument.
  void addRRect(RRect rrect) native "Path_addRRect";

  /// Closes the last subpath, as if a straight line had been drawn
  /// from the current point to the first point of the subpath.
  void close() native "Path_close";

  /// Clears the [Path] object of all subpaths, returning it to the
  /// same state it had when it was created. The _current point_ is
  /// reset to the origin.
  void reset() native "Path_reset";

  /// Returns a copy of the path with all the segments of every
  /// subpath translated by the given offset.
  Path shift(Offset offset) native "Path_shift";
}

/// Styles to use for blurs in [MaskFilter] objects.
enum BlurStyle {
  // These mirror SkBlurStyle and must be kept in sync.

  /// Fuzzy inside and outside.
  normal,

  /// Solid inside, fuzzy outside.
  solid,

  /// Nothing inside, fuzzy outside.
  outer,

  /// Fuzzy inside, nothing outside.
  inner,
}

class MaskFilter extends NativeFieldWrapperClass2 {
  MaskFilter.blur(BlurStyle style, double sigma, {
    bool ignoreTransform: false,
    bool highQuality: false
  }) {
    _constructor(style.index, sigma, _makeBlurFlags(ignoreTransform, highQuality));
  }
  void _constructor(int style, double sigma, int flags) native "MaskFilter_constructor";

  // Convert constructor parameters to the SkBlurMaskFilter::BlurFlags type.
  static int _makeBlurFlags(bool ignoreTransform, bool highQuality) {
    int flags = 0;
    if (ignoreTransform)
      flags |= 0x01;
    if (highQuality)
      flags |= 0x02;
    return flags;
  }
}

/// A description of a filter to apply when drawing with a particular [Paint].
///
/// See [Paint.colorFilter].
class ColorFilter extends NativeFieldWrapperClass2 {
  ColorFilter.mode(Color color, TransferMode transferMode) {
    _constructor(color, transferMode);
  }
  void _constructor(Color color, TransferMode transferMode) native "ColorFilter_constructor";
}

/// Base class for objects such as [Gradient] and [ImageShader] which
/// correspond to shaders.
abstract class Shader extends NativeFieldWrapperClass2 { }

/// Defines what happens at the edge of the gradient.
enum TileMode {
  /// Edge is clamped to the final color.
  clamp,
  /// Edge is repeated from first color to last.
  repeated,
  /// Edge is mirrored from last color to first.
  mirror
}

class Gradient extends Shader {
  /// Creates a Gradient object that is not initialized.
  ///
  /// Use the [Gradient.linear] or [Gradient.radial] constructors to
  /// obtain a usable [Gradient] object.
  Gradient();
  void _constructor() native "Gradient_constructor";

  /// Creates a linear gradient from [endPoint[0]] to [endPoint[1]]. If
  /// [colorStops] is provided, [colorStops[i]] is a number from 0 to 1 that
  /// specifies where [color[i]] begins in the gradient.
  // TODO(mpcomplete): Maybe pass a list of (color, colorStop) pairs instead?
  Gradient.linear(List<Point> endPoints,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    _constructor();
    if (endPoints == null || endPoints.length != 2)
      throw new ArgumentError("Expected exactly 2 [endPoints].");
    _validateColorStops(colors, colorStops);
    _initLinear(endPoints, colors, colorStops, tileMode.index);
  }
  void _initLinear(List<Point> endPoints, List<Color> colors, List<double> colorStops, int tileMode) native "Gradient_initLinear";

  /// Creates a radial gradient centered at [center] that ends at [radius]
  /// distance from the center. If [colorStops] is provided, [colorStops[i]] is
  /// a number from 0 to 1 that specifies where [color[i]] begins in the
  /// gradient.
  Gradient.radial(Point center,
                  double radius,
                  List<Color> colors,
                  [List<double> colorStops = null,
                  TileMode tileMode = TileMode.clamp]) {
    _constructor();
    _validateColorStops(colors, colorStops);
    _initRadial(center, radius, colors, colorStops, tileMode.index);
  }
  void _initRadial(Point center, double radius, List<Color> colors, List<double> colorStops, int tileMode) native "Gradient_initRadial";

  static void _validateColorStops(List<Color> colors, List<double> colorStops) {
    if (colorStops != null && (colors == null || colors.length != colorStops.length))
      throw new ArgumentError("[colors] and [colorStops] parameters must be equal length.");
  }
}

class ImageShader extends Shader {
  ImageShader(Image image, TileMode tmx, TileMode tmy, Float64List matrix4) {
    if (image == null)
      throw new ArgumentError("[image] argument cannot be null");
    if (tmx == null)
      throw new ArgumentError("[tmx] argument cannot be null");
    if (tmy == null)
      throw new ArgumentError("[tmy] argument cannot be null");
    if (matrix4 == null)
      throw new ArgumentError("[matrix4] argument cannot be null");
    _constructor();
    _initWithImage(image, tmx.index, tmy.index, matrix4);
  }
  void _constructor() native "ImageShader_constructor";
  void _initWithImage(Image image, int tmx, int tmy, Float64List matrix4) native "ImageShader_initWithImage";
}

/// Defines how a list of points is interpreted when drawing a set of triangles.
/// See Skia or OpenGL documentation for more details.
enum VertexMode {
  triangles,
  triangleStrip,
  triangleFan,
}

/// An interface for recording graphical operations.
///
/// [Canvas] objects are used in creating [Picture] objects, which can
/// themselves be used with a [SceneBuilder] to build a [Scene]. In
/// normal usage, however, this is all handled by the framework.
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
    _constructor(recorder, cullRect);
  }
  void _constructor(PictureRecorder recorder, Rect cullRect) native "Canvas_constructor";

  /// Saves a copy of the current transform and clip on the save stack.
  ///
  /// Call [restore] to pop the save stack.
  void save() native "Canvas_save";
 
  /// Saves a copy of the current transform and clip on the save
  /// stack, and then creates a new group which subsequent calls will
  /// become a part of. When the save stack is later popped, the group
  /// will be flattened and have the given paint applied.
  ///
  /// This lets you create composite effects, for example making a
  /// group of drawing commands semi-transparent. Without using
  /// [saveLayer], each part of the group would be painted
  /// individually, so where they overlap would be darker than where
  /// they do not. By using [saveLayer] to group them together, they
  /// can be drawn with an opaque color at first, and then the entire
  /// group can be made transparent using the [saveLayer]'s paint.
  ///
  /// Call [restore] to pop the save stack and apply the paint to the
  /// group.
  void saveLayer(Rect bounds, Paint paint) native "Canvas_saveLayer"; // TODO(jackson): Paint should be optional, but making it optional causes crash

  /// Pops the current save stack, if there is anything to pop.
  /// Otherwise, does nothing.
  ///
  /// Use [save] and [saveLayer] to push state onto the stack.
  void restore() native "Canvas_restore";
  
  /// Returns the number of items on the save stack, including the
  /// initial state. This means it returns 1 for a clean canvas, and
  /// that each call to [save] and [saveLayer] increments it, and that
  /// each matching call to [restore] decrements it.
  ///
  /// This number cannot go below 1.
  int getSaveCount() native "Canvas_getSaveCount";
  
  void translate(double dx, double dy) native "Canvas_translate";
  void scale(double sx, double sy) native "Canvas_scale";
  void rotate(double radians) native "Canvas_rotate";
  void skew(double sx, double sy) native "Canvas_skew";

  void transform(Float64List matrix4) {
    if (matrix4.length != 16)
      throw new ArgumentError("[matrix4] must have 16 entries.");
    _transform(matrix4);
  }
  void _transform(Float64List matrix4) native "Canvas_transform";

  void setMatrix(Float64List matrix4) {
    if (matrix4.length != 16)
      throw new ArgumentError("[matrix4] must have 16 entries.");
    _setMatrix(matrix4);
  }
  void _setMatrix(Float64List matrix4) native "Canvas_setMatrix";

  Float64List getTotalMatrix() native "Canvas_getTotalMatrix";
  void clipRect(Rect rect) native "Canvas_clipRect";
  void clipRRect(RRect rrect) native "Canvas_clipRRect";
  void clipPath(Path path) native "Canvas_clipPath";
  void drawColor(Color color, TransferMode transferMode) native "Canvas_drawColor";
  void drawLine(Point p1, Point p2, Paint paint) native "Canvas_drawLine";
  void drawPaint(Paint paint) native "Canvas_drawPaint";
  void drawRect(Rect rect, Paint paint) native "Canvas_drawRect";
  void drawRRect(RRect rrect, Paint paint) native "Canvas_drawRRect";
  void drawDRRect(RRect outer, RRect inner, Paint paint) native "Canvas_drawDRRect";
  void drawOval(Rect rect, Paint paint) native "Canvas_drawOval";
  void drawCircle(Point c, double radius, Paint paint) native "Canvas_drawCircle";
  void drawPath(Path path, Paint paint) native "Canvas_drawPath";
  void drawImage(Image image, Point p, Paint paint) native "Canvas_drawImage";

  /// Draws the src rect from the image into the canvas as dst rect.
  ///
  /// Might sample from outside the src rect by half the width of an applied
  /// filter.
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) native "Canvas_drawImageRect";

  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) native "Canvas_drawImageNine";

  /// Draw the given picture onto the canvas. To create a picture, see
  /// [PictureRecorder].
  void drawPicture(Picture picture) native "Canvas_drawPicture";

  /// Draws the text in the given paragraph into this canvas at the given offset.
  ///
  /// Valid only after [Paragraph.layout] has been called on the paragraph.
  void drawParagraph(Paragraph paragraph, Offset offset) native "Canvas_drawParagraph";

  void drawVertices(VertexMode vertexMode,
                    List<Point> vertices,
                    List<Point> textureCoordinates,
                    List<Color> colors,
                    TransferMode transferMode,
                    List<int> indicies,
                    Paint paint) {
    int vertexCount = vertices.length;
    if (textureCoordinates.isNotEmpty && textureCoordinates.length != vertexCount)
      throw new ArgumentError("[vertices] and [textureCoordinates] lengths must match");
    if (colors.isNotEmpty && colors.length != vertexCount)
      throw new ArgumentError("[vertices] and [colors] lengths must match");
    for (Point point in vertices) {
      if (point == null)
        throw new ArgumentError("[vertices] cannot contain a null");
    }
    for (Point point in textureCoordinates) {
      if (point == null)
        throw new ArgumentError("[textureCoordinates] cannot contain a null");
    }
    _drawVertices(vertexMode.index, vertices, textureCoordinates, colors, transferMode, indicies, paint);
  }
  void _drawVertices(int vertexMode,
                     List<Point> vertices,
                     List<Point> textureCoordinates,
                     List<Color> colors,
                     TransferMode transferMode,
                     List<int> indicies,
                     Paint paint) native "Canvas_drawVertices";

  void drawAtlas(Image image,
                 List<RSTransform> transforms,
                 List<Rect> rects,
                 List<Color> colors,
                 TransferMode mode,
                 Rect cullRect,
                 Paint paint) {
    if (transforms.length != rects.length)
      throw new ArgumentError("[transforms] and [rects] lengths must match");
    if (colors.isNotEmpty && colors.length != rects.length)
      throw new ArgumentError("if supplied, [colors] length must match that of [transforms] and [rects]");
    for (RSTransform transform in transforms) {
      if (transform == null)
        throw new ArgumentError("[transforms] cannot contain a null");
    }
    for (Rect rect in rects) {
      if (rect == null)
        throw new ArgumentError("[rects] cannot contain a null");
    }
    _drawAtlas(image, transforms, rects, colors, mode, cullRect, paint);
  }
  void _drawAtlas(Image image,
                  List<RSTransform> transforms,
                  List<Rect> rects,
                  List<Color> colors,
                  TransferMode mode,
                  Rect cullRect,
                  // TODO(eseidel): Paint should be optional, but optional doesn't work.
                  Paint paint) native "Canvas_drawAtlas";
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
