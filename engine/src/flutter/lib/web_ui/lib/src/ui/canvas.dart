// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of ui;

/// Defines how a list of points is interpreted when drawing a set of points.
///
/// Used by [Canvas.drawPoints].
enum PointMode {
  /// Draw each point separately.
  ///
  /// If the [Paint.strokeCap] is [StrokeCap.round], then each point is drawn
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

/// Defines how a new clip region should be merged with the existing clip
/// region.
///
/// Used by [Canvas.clipRect].
enum ClipOp {
  /// Subtract the new region from the existing region.
  difference,

  /// Intersect the new region from the existing region.
  intersect,
}

enum VertexMode {
  /// Draw each sequence of three points as the vertices of a triangle.
  triangles,

  /// Draw each sliding window of three points as the vertices of a triangle.
  triangleStrip,

  /// Draw the first point and each sliding window of two points as the vertices of a triangle.
  triangleFan,
}

/// A set of vertex data used by [Canvas.drawVertices].
class Vertices {
  final VertexMode _mode;
  final Float32List _positions;
  final Float32List _textureCoordinates;
  final Int32List _colors;
  final Uint16List _indices; // ignore: unused_field

  Vertices._(
    VertexMode mode,
    List<Offset> positions, {
    List<Offset> textureCoordinates,
    List<Color> colors,
    List<int> indices,
  })  : assert(mode != null),
        assert(positions != null),
        _mode = mode,
        _colors = _int32ListFromColors(colors),
        _indices = indices != null ? Uint16List.fromList(indices) : null,
        _positions = engine.offsetListToFloat32List(positions),
        _textureCoordinates =
            engine.offsetListToFloat32List(textureCoordinates) {
    engine.initWebGl();
  }

  /// Creates a set of vertex data for use with [Canvas.drawVertices].
  ///
  /// The [mode] and [positions] parameters must not be null.
  ///
  /// If the [textureCoordinates] or [colors] parameters are provided, they must
  /// be the same length as [positions].
  ///
  /// If the [indices] parameter is provided, all values in the list must be
  /// valid index values for [positions].
  factory Vertices(
    VertexMode mode,
    List<Offset> positions, {
    List<Offset> textureCoordinates,
    List<Color> colors,
    List<int> indices,
  }) {
    if (engine.experimentalUseSkia) {
      return engine.SkVertices(mode, positions,
          textureCoordinates: textureCoordinates,
          colors: colors,
          indices: indices);
    }
    return Vertices._(mode, positions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices);
  }

  Vertices._raw(
    VertexMode mode,
    Float32List positions, {
    Float32List textureCoordinates,
    Int32List colors,
    Uint16List indices,
  })  : assert(mode != null),
        assert(positions != null),
        _mode = mode,
        _positions = positions,
        _textureCoordinates = textureCoordinates,
        _colors = colors,
        _indices = indices {
    engine.initWebGl();
  }

  static Int32List _int32ListFromColors(List<Color> colors) {
    Int32List list = Int32List(colors.length);
    for (int i = 0, len = colors.length; i < len; i++) {
      list[i] = colors[i].value;
    }
    return list;
  }

  /// Creates a set of vertex data for use with [Canvas.drawVertices], directly
  /// using the encoding methods of [new Vertices].
  ///
  /// The [mode] parameter must not be null.
  ///
  /// The [positions] list is interpreted as a list of repeated pairs of x,y
  /// coordinates. It must not be null.
  ///
  /// The [textureCoordinates] list is interpreted as a list of repeated pairs
  /// of x,y coordinates, and must be the same length of [positions] if it
  /// is not null.
  ///
  /// The [colors] list is interpreted as a list of RGBA encoded colors, similar
  /// to [Color.value]. It must be half length of [positions] if it is not
  /// null.
  ///
  /// If the [indices] list is provided, all values in the list must be
  /// valid index values for [positions].
  factory Vertices.raw(
    VertexMode mode,
    Float32List positions, {
    Float32List textureCoordinates,
    Int32List colors,
    Uint16List indices,
  }) {
    if (engine.experimentalUseSkia) {
      return engine.SkVertices.raw(mode, positions,
          textureCoordinates: textureCoordinates,
          colors: colors,
          indices: indices);
    }
    return Vertices._raw(mode, positions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices);
  }

  VertexMode get mode => _mode;
  Int32List get colors => _colors;
  Float32List get positions => _positions;
  Float32List get textureCoordinates => _textureCoordinates;
  Uint16List get indices => _indices;
}

/// Records a [Picture] containing a sequence of graphical operations.
///
/// To begin recording, construct a [Canvas] to record the commands.
/// To end recording, use the [PictureRecorder.endRecording] method.
abstract class PictureRecorder {
  /// Creates a new idle PictureRecorder. To associate it with a
  /// [Canvas] and begin recording, pass this [PictureRecorder] to the
  /// [Canvas] constructor.
  factory PictureRecorder() {
    if (engine.experimentalUseSkia) {
      return engine.SkPictureRecorder();
    } else {
      return engine.EnginePictureRecorder();
    }
  }

  /// Whether this object is currently recording commands.
  ///
  /// Specifically, this returns true if a [Canvas] object has been
  /// created to record commands and recording has not yet ended via a
  /// call to [endRecording], and false if either this
  /// [PictureRecorder] has not yet been associated with a [Canvas],
  /// or the [endRecording] method has already been called.
  bool get isRecording;

  /// Finishes recording graphical operations.
  ///
  /// Returns a picture containing the graphical operations that have been
  /// recorded thus far. After calling this function, both the picture recorder
  /// and the canvas objects are invalid and cannot be used further.
  ///
  /// Returns null if the PictureRecorder is not associated with a canvas.
  Picture endRecording();
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
class Canvas {
  engine.RecordingCanvas _canvas;

  factory Canvas(PictureRecorder recorder, [Rect cullRect]) {
    if (engine.experimentalUseSkia) {
      return engine.CanvasKitCanvas(recorder, cullRect);
    } else {
      return Canvas._(recorder, cullRect);
    }
  }

  /// Creates a canvas for recording graphical operations into the
  /// given picture recorder.
  ///
  /// Graphical operations that affect pixels entirely outside the given
  /// `cullRect` might be discarded by the implementation. However, the
  /// implementation might draw outside these bounds if, for example, a command
  /// draws partially inside and outside the `cullRect`. To ensure that pixels
  /// outside a given region are discarded, consider using a [clipRect]. The
  /// `cullRect` is optional; by default, all operations are kept.
  ///
  /// To end the recording, call [PictureRecorder.endRecording] on the
  /// given recorder.
  Canvas._(engine.EnginePictureRecorder recorder, [Rect cullRect])
      : assert(recorder != null) {
    if (recorder.isRecording) {
      throw ArgumentError(
          '"recorder" must not already be associated with another Canvas.');
    }
    cullRect ??= Rect.largest;
    _canvas = recorder.beginRecording(cullRect);
  }

  /// Saves a copy of the current transform and clip on the save stack.
  ///
  /// Call [restore] to pop the save stack.
  ///
  /// See also:
  ///
  ///  * [saveLayer], which does the same thing but additionally also groups the
  ///    commands done until the matching [restore].
  void save() {
    _canvas.save();
  }

  /// Saves a copy of the current transform and clip on the save stack, and then
  /// creates a new group which subsequent calls will become a part of. When the
  /// save stack is later popped, the group will be flattened into a layer and
  /// have the given `paint`'s [Paint.colorFilter] and [Paint.blendMode]
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
  ///
  /// ## Using saveLayer with clips
  ///
  /// When a rectangular clip operation (from [clipRect]) is not axis-aligned
  /// with the raster buffer, or when the clip operation is not rectalinear (e.g.
  /// because it is a rounded rectangle clip created by [clipRRect] or an
  /// arbitrarily complicated path clip created by [clipPath]), the edge of the
  /// clip needs to be anti-aliased.
  ///
  /// If two draw calls overlap at the edge of such a clipped region, without
  /// using [saveLayer], the first drawing will be anti-aliased with the
  /// background first, and then the second will be anti-aliased with the result
  /// of blending the first drawing and the background. On the other hand, if
  /// [saveLayer] is used immediately after establishing the clip, the second
  /// drawing will cover the first in the layer, and thus the second alone will
  /// be anti-aliased with the background when the layer is clipped and
  /// composited (when [restore] is called).
  ///
  /// For example, this [CustomPainter.paint] method paints a clean white
  /// rounded rectangle:
  ///
  /// ```dart
  /// void paint(Canvas canvas, Size size) {
  ///   Rect rect = Offset.zero & size;
  ///   canvas.save();
  ///   canvas.clipRRect(new RRect.fromRectXY(rect, 100.0, 100.0));
  ///   canvas.saveLayer(rect, new Paint());
  ///   canvas.drawPaint(new Paint()..color = Colors.red);
  ///   canvas.drawPaint(new Paint()..color = Colors.white);
  ///   canvas.restore();
  ///   canvas.restore();
  /// }
  /// ```
  ///
  /// On the other hand, this one renders a red outline, the result of the red
  /// paint being anti-aliased with the background at the clip edge, then the
  /// white paint being similarly anti-aliased with the background _including
  /// the clipped red paint_:
  ///
  /// ```dart
  /// void paint(Canvas canvas, Size size) {
  ///   // (this example renders poorly, prefer the example above)
  ///   Rect rect = Offset.zero & size;
  ///   canvas.save();
  ///   canvas.clipRRect(new RRect.fromRectXY(rect, 100.0, 100.0));
  ///   canvas.drawPaint(new Paint()..color = Colors.red);
  ///   canvas.drawPaint(new Paint()..color = Colors.white);
  ///   canvas.restore();
  /// }
  /// ```
  ///
  /// This point is moot if the clip only clips one draw operation. For example,
  /// the following paint method paints a pair of clean white rounded
  /// rectangles, even though the clips are not done on a separate layer:
  ///
  /// ```dart
  /// void paint(Canvas canvas, Size size) {
  ///   canvas.save();
  ///   canvas.clipRRect(new RRect.fromRectXY(Offset.zero & (size / 2.0), 50.0, 50.0));
  ///   canvas.drawPaint(new Paint()..color = Colors.white);
  ///   canvas.restore();
  ///   canvas.save();
  ///   canvas.clipRRect(new RRect.fromRectXY(size.center(Offset.zero) & (size / 2.0), 50.0, 50.0));
  ///   canvas.drawPaint(new Paint()..color = Colors.white);
  ///   canvas.restore();
  /// }
  /// ```
  ///
  /// (Incidentally, rather than using [clipRRect] and [drawPaint] to draw
  /// rounded rectangles like this, prefer the [drawRRect] method. These
  /// examples are using [drawPaint] as a proxy for "complicated draw operations
  /// that will get clipped", to illustrate the point.)
  ///
  /// ## Performance considerations
  ///
  /// Generally speaking, [saveLayer] is relatively expensive.
  ///
  /// There are a several different hardware architectures for GPUs (graphics
  /// processing units, the hardware that handles graphics), but most of them
  /// involve batching commands and reordering them for performance. When layers
  /// are used, they cause the rendering pipeline to have to switch render
  /// target (from one layer to another). Render target switches can flush the
  /// GPU's command buffer, which typically means that optimizations that one
  /// could get with larger batching are lost. Render target switches also
  /// generate a lot of memory churn because the GPU needs to copy out the
  /// current frame buffer contents from the part of memory that's optimized for
  /// writing, and then needs to copy it back in once the previous render target
  /// (layer) is restored.
  ///
  /// See also:
  ///
  ///  * [save], which saves the current state, but does not create a new layer
  ///    for subsequent commands.
  ///  * [BlendMode], which discusses the use of [Paint.blendMode] with
  ///    [saveLayer].
  void saveLayer(Rect bounds, Paint paint) {
    assert(paint != null);
    if (bounds == null) {
      _saveLayerWithoutBounds(paint);
    } else {
      assert(engine.rectIsValid(bounds));
      _saveLayer(bounds, paint);
    }
  }

  void _saveLayerWithoutBounds(Paint paint) {
    _canvas.saveLayerWithoutBounds(paint);
  }

  void _saveLayer(Rect bounds, Paint paint) {
    _canvas.saveLayer(bounds, paint);
  }

  /// Pops the current save stack, if there is anything to pop.
  /// Otherwise, does nothing.
  ///
  /// Use [save] and [saveLayer] to push state onto the stack.
  ///
  /// If the state was pushed with with [saveLayer], then this call will also
  /// cause the new layer to be composited into the previous layer.
  void restore() {
    _canvas.restore();
  }

  /// Returns the number of items on the save stack, including the
  /// initial state. This means it returns 1 for a clean canvas, and
  /// that each call to [save] and [saveLayer] increments it, and that
  /// each matching call to [restore] decrements it.
  ///
  /// This number cannot go below 1.
  int getSaveCount() => _canvas.saveCount;

  /// Add a translation to the current transform, shifting the coordinate space
  /// horizontally by the first argument and vertically by the second argument.
  void translate(double dx, double dy) {
    _canvas.translate(dx, dy);
  }

  /// Add an axis-aligned scale to the current transform, scaling by the first
  /// argument in the horizontal direction and the second in the vertical
  /// direction.
  ///
  /// If [sy] is unspecified, [sx] will be used for the scale in both
  /// directions.
  void scale(double sx, [double sy]) => _scale(sx, sy ?? sx);

  void _scale(double sx, double sy) {
    _canvas.scale(sx, sy);
  }

  /// Add a rotation to the current transform. The argument is in radians clockwise.
  void rotate(double radians) {
    _canvas.rotate(radians);
  }

  /// Add an axis-aligned skew to the current transform, with the first argument
  /// being the horizontal skew in radians clockwise around the origin, and the
  /// second argument being the vertical skew in radians clockwise around the
  /// origin.
  void skew(double sx, double sy) {
    _canvas.skew(sx, sy);
  }

  /// Multiply the current transform by the specified 4⨉4 transformation matrix
  /// specified as a list of values in column-major order.
  void transform(Float64List matrix4) {
    assert(matrix4 != null);
    if (matrix4.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }
    _transform(engine.toMatrix32(matrix4));
  }

  void _transform(Float32List matrix4) {
    _canvas.transform(matrix4);
  }

  /// Reduces the clip region to the intersection of the current clip and the
  /// given rectangle.
  ///
  /// If [doAntiAlias] is true, then the clip will be anti-aliased.
  ///
  /// If multiple draw commands intersect with the clip boundary, this can result
  /// in incorrect blending at the clip boundary. See [saveLayer] for a
  /// discussion of how to address that.
  ///
  /// Use [ClipOp.difference] to subtract the provided rectangle from the
  /// current clip.
  void clipRect(Rect rect,
      {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    assert(engine.rectIsValid(rect));
    assert(clipOp != null);
    assert(doAntiAlias != null);
    _clipRect(rect, clipOp, doAntiAlias);
  }

  void _clipRect(Rect rect, ClipOp clipOp, bool doAntiAlias) {
    _canvas.clipRect(rect);
  }

  /// Reduces the clip region to the intersection of the current clip and the
  /// given rounded rectangle.
  ///
  /// If [doAntiAlias] is true, then the clip will be anti-aliased.
  ///
  /// If multiple draw commands intersect with the clip boundary, this can result
  /// in incorrect blending at the clip boundary. See [saveLayer] for a
  /// discussion of how to address that and some examples of using [clipRRect].
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    assert(engine.rrectIsValid(rrect));
    assert(doAntiAlias != null);
    _clipRRect(rrect, doAntiAlias);
  }

  void _clipRRect(RRect rrect, bool doAntiAlias) {
    _canvas.clipRRect(rrect);
  }

  /// Reduces the clip region to the intersection of the current clip and the
  /// given [Path].
  ///
  /// If [doAntiAlias] is true, then the clip will be anti-aliased.
  ///
  /// If multiple draw commands intersect with the clip boundary, this can result
  /// multiple draw commands intersect with the clip boundary, this can result
  /// in incorrect blending at the clip boundary. See [saveLayer] for a
  /// discussion of how to address that.
  void clipPath(Path path, {bool doAntiAlias = true}) {
    assert(path != null); // path is checked on the engine side
    assert(doAntiAlias != null);
    _clipPath(path, doAntiAlias);
  }

  void _clipPath(Path path, bool doAntiAlias) {
    _canvas.clipPath(path, doAntiAlias: doAntiAlias);
  }

  /// Paints the given [Color] onto the canvas, applying the given
  /// [BlendMode], with the given color being the source and the background
  /// being the destination.
  void drawColor(Color color, BlendMode blendMode) {
    assert(color != null);
    assert(blendMode != null);
    _drawColor(color, blendMode);
  }

  void _drawColor(Color color, BlendMode blendMode) {
    _canvas.drawColor(color, blendMode);
  }

  /// Draws a line between the given points using the given paint. The line is
  /// stroked, the value of the [Paint.style] is ignored for this call.
  ///
  /// The `p1` and `p2` arguments are interpreted as offsets from the origin.
  void drawLine(Offset p1, Offset p2, Paint paint) {
    assert(engine.offsetIsValid(p1));
    assert(engine.offsetIsValid(p2));
    assert(paint != null);
    _drawLine(p1, p2, paint);
  }

  void _drawLine(Offset p1, Offset p2, Paint paint) {
    _canvas.drawLine(p1, p2, paint);
  }

  /// Fills the canvas with the given [Paint].
  ///
  /// To fill the canvas with a solid color and blend mode, consider
  /// [drawColor] instead.
  void drawPaint(Paint paint) {
    assert(paint != null);
    _drawPaint(paint);
  }

  void _drawPaint(Paint paint) {
    _canvas.drawPaint(paint);
  }

  /// Draws a rectangle with the given [Paint]. Whether the rectangle is filled
  /// or stroked (or both) is controlled by [Paint.style].
  void drawRect(Rect rect, Paint paint) {
    assert(engine.rectIsValid(rect));
    assert(paint != null);
    _drawRect(rect, paint);
  }

  void _drawRect(Rect rect, Paint paint) {
    _canvas.drawRect(rect, paint);
  }

  /// Draws a rounded rectangle with the given [Paint]. Whether the rectangle is
  /// filled or stroked (or both) is controlled by [Paint.style].
  void drawRRect(RRect rrect, Paint paint) {
    assert(engine.rrectIsValid(rrect));
    assert(paint != null);
    _drawRRect(rrect, paint);
  }

  void _drawRRect(RRect rrect, Paint paint) {
    _canvas.drawRRect(rrect, paint);
  }

  /// Draws a shape consisting of the difference between two rounded rectangles
  /// with the given [Paint]. Whether this shape is filled or stroked (or both)
  /// is controlled by [Paint.style].
  ///
  /// This shape is almost but not quite entirely unlike an annulus.
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    assert(engine.rrectIsValid(outer));
    assert(engine.rrectIsValid(inner));
    assert(paint != null);
    _drawDRRect(outer, inner, paint);
  }

  void _drawDRRect(RRect outer, RRect inner, Paint paint) {
    _canvas.drawDRRect(outer, inner, paint);
  }

  /// Draws an axis-aligned oval that fills the given axis-aligned rectangle
  /// with the given [Paint]. Whether the oval is filled or stroked (or both) is
  /// controlled by [Paint.style].
  void drawOval(Rect rect, Paint paint) {
    assert(engine.rectIsValid(rect));
    assert(paint != null);
    _drawOval(rect, paint);
  }

  void _drawOval(Rect rect, Paint paint) {
    _canvas.drawOval(rect, paint);
  }

  /// Draws a circle centered at the point given by the first argument and
  /// that has the radius given by the second argument, with the [Paint] given in
  /// the third argument. Whether the circle is filled or stroked (or both) is
  /// controlled by [Paint.style].
  void drawCircle(Offset c, double radius, Paint paint) {
    assert(engine.offsetIsValid(c));
    assert(paint != null);
    _drawCircle(c, radius, paint);
  }

  void _drawCircle(Offset c, double radius, Paint paint) {
    _canvas.drawCircle(c, radius, paint);
  }

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
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {
    assert(engine.rectIsValid(rect));
    assert(paint != null);
    const double pi = math.pi;
    const double pi2 = 2.0 * pi;

    final Path path = Path();
    if (useCenter) {
      path.moveTo(
          (rect.left + rect.right) / 2.0, (rect.top + rect.bottom) / 2.0);
    }
    bool forceMoveTo = !useCenter;
    if (sweepAngle <= -pi2) {
      path.arcTo(rect, startAngle, -pi, forceMoveTo);
      startAngle -= pi;
      path.arcTo(rect, startAngle, -pi, false);
      startAngle -= pi;
      forceMoveTo = false;
      sweepAngle += pi2;
    }
    while (sweepAngle >= pi2) {
      path.arcTo(rect, startAngle, pi, forceMoveTo);
      startAngle += pi;
      path.arcTo(rect, startAngle, pi, false);
      startAngle += pi;
      forceMoveTo = false;
      sweepAngle -= pi2;
    }
    path.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
    if (useCenter) {
      path.close();
    }
    _canvas.drawPath(path, paint);
  }

  /// Draws the given [Path] with the given [Paint]. Whether this shape is
  /// filled or stroked (or both) is controlled by [Paint.style]. If the path is
  /// filled, then subpaths within it are implicitly closed (see [Path.close]).
  void drawPath(Path path, Paint paint) {
    assert(path != null); // path is checked on the engine side
    assert(paint != null);
    _drawPath(path, paint);
  }

  void _drawPath(Path path, Paint paint) {
    _canvas.drawPath(path, paint);
  }

  /// Draws the given [Image] into the canvas with its top-left corner at the
  /// given [Offset]. The image is composited into the canvas using the given [Paint].
  void drawImage(Image image, Offset p, Paint paint) {
    assert(image != null); // image is checked on the engine side
    assert(engine.offsetIsValid(p));
    assert(paint != null);
    _drawImage(image, p, paint);
  }

  void _drawImage(Image image, Offset p, Paint paint) {
    _canvas.drawImage(image, p, paint);
  }

  /// Draws the subset of the given image described by the `src` argument into
  /// the canvas in the axis-aligned rectangle given by the `dst` argument.
  ///
  /// This might sample from outside the `src` rect by up to half the width of
  /// an applied filter.
  ///
  /// Multiple calls to this method with different arguments (from the same
  /// image) can be batched into a single call to [drawAtlas] to improve
  /// performance.
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {
    assert(image != null); // image is checked on the engine side
    assert(engine.rectIsValid(src));
    assert(engine.rectIsValid(dst));
    assert(paint != null);
    _drawImageRect(image, src, dst, paint);
  }

  void _drawImageRect(Image image, Rect src, Rect dst, Paint paint) {
    _canvas.drawImageRect(image, src, dst, paint);
  }

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
    assert(image != null); // image is checked on the engine side
    assert(engine.rectIsValid(center));
    assert(engine.rectIsValid(dst));
    assert(paint != null);

    // Assert you can fit the scaled image into dst.
    assert(image.width - center.width >= dst.width);
    assert(image.height - center.height >= dst.height);

    // The four unscaled corner rectangles in the from the src.
    final Rect srcTopLeft = Rect.fromLTWH(
      0,
      0,
      center.left,
      center.top,
    );
    final Rect srcTopRight = Rect.fromLTWH(
      center.right,
      0,
      image.width - center.right,
      center.top,
    );
    final Rect srcBottomLeft = Rect.fromLTWH(
      0,
      center.bottom,
      center.left,
      image.height - center.bottom,
    );
    final Rect srcBottomRight = Rect.fromLTWH(
      center.right,
      center.bottom,
      image.width - center.right,
      image.height - center.bottom,
    );

    final Rect dstTopLeft = srcTopLeft.shift(dst.topLeft);

    // The center rectangle in the dst region
    final Rect dstCenter = Rect.fromLTWH(
      dstTopLeft.right,
      dstTopLeft.bottom,
      dst.width - (srcTopLeft.width + srcTopRight.width),
      dst.height - (srcTopLeft.height + srcBottomLeft.height),
    );

    drawImageRect(image, srcTopLeft, dstTopLeft, paint);

    final Rect dstTopRight = Rect.fromLTWH(
      dstCenter.right,
      dst.top,
      srcTopRight.width,
      srcTopRight.height,
    );
    drawImageRect(image, srcTopRight, dstTopRight, paint);

    final Rect dstBottomLeft = Rect.fromLTWH(
      dst.left,
      dstCenter.bottom,
      srcBottomLeft.width,
      srcBottomLeft.height,
    );
    drawImageRect(image, srcBottomLeft, dstBottomLeft, paint);

    final Rect dstBottomRight = Rect.fromLTWH(
      dstCenter.right,
      dstCenter.bottom,
      srcBottomRight.width,
      srcBottomRight.height,
    );
    drawImageRect(image, srcBottomRight, dstBottomRight, paint);

    // Draw the top center rectangle.
    drawImageRect(
      image,
      Rect.fromLTRB(
        srcTopLeft.right,
        srcTopLeft.top,
        srcTopRight.left,
        srcTopRight.bottom,
      ),
      Rect.fromLTRB(
        dstTopLeft.right,
        dstTopLeft.top,
        dstTopRight.left,
        dstTopRight.bottom,
      ),
      paint,
    );

    // Draw the middle left rectangle.
    drawImageRect(
      image,
      Rect.fromLTRB(
        srcTopLeft.left,
        srcTopLeft.bottom,
        srcBottomLeft.right,
        srcBottomLeft.top,
      ),
      Rect.fromLTRB(
        dstTopLeft.left,
        dstTopLeft.bottom,
        dstBottomLeft.right,
        dstBottomLeft.top,
      ),
      paint,
    );

    // Draw the center rectangle.
    drawImageRect(image, center, dstCenter, paint);

    // Draw the middle right rectangle.
    drawImageRect(
      image,
      Rect.fromLTRB(
        srcTopRight.left,
        srcTopRight.bottom,
        srcBottomRight.right,
        srcBottomRight.top,
      ),
      Rect.fromLTRB(
        dstTopRight.left,
        dstTopRight.bottom,
        dstBottomRight.right,
        dstBottomRight.top,
      ),
      paint,
    );

    // Draw the bottom center rectangle.
    drawImageRect(
      image,
      Rect.fromLTRB(
        srcBottomLeft.right,
        srcBottomLeft.top,
        srcBottomRight.left,
        srcBottomRight.bottom,
      ),
      Rect.fromLTRB(
        dstBottomLeft.right,
        dstBottomLeft.top,
        dstBottomRight.left,
        dstBottomRight.bottom,
      ),
      paint,
    );
  }

  /// Draw the given picture onto the canvas. To create a picture, see
  /// [PictureRecorder].
  void drawPicture(Picture picture) {
    assert(picture != null); // picture is checked on the engine side
    // TODO(het): Support this
    throw UnimplementedError();
  }

  /// Draws the text in the given [Paragraph] into this canvas at the given
  /// [Offset].
  ///
  /// The [Paragraph] object must have had [Paragraph.layout] called on it
  /// first.
  ///
  /// To align the text, set the `textAlign` on the [ParagraphStyle] object
  /// passed to the [new ParagraphBuilder] constructor. For more details see
  /// [TextAlign] and the discussion at [new ParagraphStyle].
  ///
  /// If the text is left aligned or justified, the left margin will be at the
  /// position specified by the `offset` argument's [Offset.dx] coordinate.
  ///
  /// If the text is right aligned or justified, the right margin will be at the
  /// position described by adding the [ParagraphConstraints.width] given to
  /// [Paragraph.layout], to the `offset` argument's [Offset.dx] coordinate.
  ///
  /// If the text is centered, the centering axis will be at the position
  /// described by adding half of the [ParagraphConstraints.width] given to
  /// [Paragraph.layout], to the `offset` argument's [Offset.dx] coordinate.
  void drawParagraph(Paragraph paragraph, Offset offset) {
    assert(paragraph != null);
    assert(engine.offsetIsValid(offset));
    _drawParagraph(paragraph, offset);
  }

  void _drawParagraph(Paragraph paragraph, Offset offset) {
    _canvas.drawParagraph(paragraph, offset);
  }

  /// Draws a sequence of points according to the given [PointMode].
  ///
  /// The `points` argument is interpreted as offsets from the origin.
  ///
  /// See also:
  ///
  ///  * [drawRawPoints], which takes `points` as a [Float32List] rather than a
  ///    [List<Offset>].
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {
    assert(pointMode != null);
    assert(points != null);
    assert(paint != null);
    final Float32List pointList = engine.offsetListToFloat32List(points);
    drawRawPoints(pointMode, pointList, paint);
  }

  /// Draws a sequence of points according to the given [PointMode].
  ///
  /// The `points` argument is interpreted as a list of pairs of floating point
  /// numbers, where each pair represents an x and y offset from the origin.
  ///
  /// See also:
  ///
  ///  * [drawPoints], which takes `points` as a [List<Offset>] rather than a
  ///    [List<Float32List>].
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    assert(pointMode != null);
    assert(points != null);
    assert(paint != null);
    if (points.length % 2 != 0) {
      throw ArgumentError('"points" must have an even number of values.');
    }
    _canvas.drawRawPoints(pointMode, points, paint);
  }

  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    if (vertices == null) {
      return;
    }
    //assert(vertices != null); // vertices is checked on the engine side
    assert(paint != null);
    assert(blendMode != null);
    _canvas.drawVertices(vertices, blendMode, paint);
  }

  /// Draws part of an image - the [atlas] - onto the canvas.
  ///
  /// This method allows for optimization when you only want to draw part of an
  /// image on the canvas, such as when using sprites or zooming. It is more
  /// efficient than using clips or masks directly.
  ///
  /// All parameters must not be null.
  ///
  /// See also:
  ///
  ///  * [drawRawAtlas], which takes its arguments as typed data lists rather
  ///    than objects.
  void drawAtlas(Image atlas, List<RSTransform> transforms, List<Rect> rects,
      List<Color> colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    assert(atlas != null); // atlas is checked on the engine side
    assert(transforms != null);
    assert(rects != null);
    assert(colors != null);
    assert(blendMode != null);
    assert(paint != null);

    final int rectCount = rects.length;
    if (transforms.length != rectCount) {
      throw ArgumentError('"transforms" and "rects" lengths must match.');
    }
    if (colors.isNotEmpty && colors.length != rectCount) {
      throw ArgumentError(
          'If non-null, "colors" length must match that of "transforms" and "rects".');
    }

    // TODO(het): Do we need to support this?
    throw UnimplementedError();
  }

  /// Draws part of an image - the [atlas] - onto the canvas.
  ///
  /// This method allows for optimization when you only want to draw part of an
  /// image on the canvas, such as when using sprites or zooming. It is more
  /// efficient than using clips or masks directly.
  ///
  /// The [rstTransforms] argument is interpreted as a list of four-tuples, with
  /// each tuple being ([RSTransform.scos], [RSTransform.ssin],
  /// [RSTransform.tx], [RSTransform.ty]).
  ///
  /// The [rects] argument is interpreted as a list of four-tuples, with each
  /// tuple being ([Rect.left], [Rect.top], [Rect.right], [Rect.bottom]).
  ///
  /// The [colors] argument, which can be null, is interpreted as a list of
  /// 32-bit colors, with the same packing as [Color.value].
  ///
  /// See also:
  ///
  ///  * [drawAtlas], which takes its arguments as objects rather than typed
  ///    data lists.
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects,
      Int32List colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    assert(atlas != null); // atlas is checked on the engine side
    assert(rstTransforms != null);
    assert(rects != null);
    assert(colors != null);
    assert(blendMode != null);
    assert(paint != null);

    final int rectCount = rects.length;
    if (rstTransforms.length != rectCount) {
      throw ArgumentError('"rstTransforms" and "rects" lengths must match.');
    }
    if (rectCount % 4 != 0) {
      throw ArgumentError(
          '"rstTransforms" and "rects" lengths must be a multiple of four.');
    }
    if (colors != null && colors.length * 4 != rectCount) {
      throw ArgumentError(
          'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".');
    }

    // TODO(het): Do we need to support this?
    throw UnimplementedError();
  }

  /// Draws a shadow for a [Path] representing the given material elevation.
  ///
  /// The `transparentOccluder` argument should be true if the occluding object
  /// is not opaque.
  ///
  /// The arguments must not be null.
  void drawShadow(
      Path path, Color color, double elevation, bool transparentOccluder) {
    assert(path != null); // path is checked on the engine side
    assert(color != null);
    assert(transparentOccluder != null);
    _canvas.drawShadow(path, color, elevation, transparentOccluder);
  }
}

/// An object representing a sequence of recorded graphical operations.
///
/// To create a [Picture], use a [PictureRecorder].
///
/// A [Picture] can be placed in a [Scene] using a [SceneBuilder], via
/// the [SceneBuilder.addPicture] method. A [Picture] can also be
/// drawn into a [Canvas], using the [Canvas.drawPicture] method.
abstract class Picture {
  /// Creates an image from this picture.
  ///
  /// The returned image will be `width` pixels wide and `height` pixels high.
  /// The picture is rasterized within the 0 (left), 0 (top), `width` (right),
  /// `height` (bottom) bounds. Content outside these bounds is clipped.
  ///
  /// Although the image is returned synchronously, the picture is actually
  /// rasterized the first time the image is drawn and then cached.
  Future<Image> toImage(int width, int height);

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose();

  /// Returns the approximate number of bytes allocated for this object.
  ///
  /// The actual size of this picture may be larger, particularly if it contains
  /// references to image or other large objects.
  int get approximateBytesUsed;
}

/// Determines the winding rule that decides how the interior of a [Path] is
/// calculated.
///
/// This enum is used by the [Path.fillType] property.
enum PathFillType {
  /// The interior is defined by a non-zero sum of signed edge crossings.
  ///
  /// For a given point, the point is considered to be on the inside of the path
  /// if a line drawn from the point to infinity crosses lines going clockwise
  /// around the point a different number of times than it crosses lines going
  /// counter-clockwise around that point.
  ///
  /// See: <https://en.wikipedia.org/wiki/Nonzero-rule>
  nonZero,

  /// The interior is defined by an odd number of edge crossings.
  ///
  /// For a given point, the point is considered to be on the inside of the path
  /// if a line drawn from the point to infinity crosses an odd number of lines.
  ///
  /// See: <https://en.wikipedia.org/wiki/Even-odd_rule>
  evenOdd,
}

/// Strategies for combining paths.
///
/// See also:
///
/// * [Path.combine], which uses this enum to decide how to combine two paths.
// Must be kept in sync with SkPathOp
enum PathOperation {
  /// Subtract the second path from the first path.
  ///
  /// For example, if the two paths are overlapping circles of equal diameter
  /// but differing centers, the result would be a crescent portion of the
  /// first circle that was not overlapped by the second circle.
  ///
  /// See also:
  ///
  ///  * [reverseDifference], which is the same but subtracting the first path
  ///    from the second.
  difference,

  /// Create a new path that is the intersection of the two paths, leaving the
  /// overlapping pieces of the path.
  ///
  /// For example, if the two paths are overlapping circles of equal diameter
  /// but differing centers, the result would be only the overlapping portion
  /// of the two circles.
  ///
  /// See also:
  ///  * [xor], which is the inverse of this operation
  intersect,

  /// Create a new path that is the union (inclusive-or) of the two paths.
  ///
  /// For example, if the two paths are overlapping circles of equal diameter
  /// but differing centers, the result would be a figure-eight like shape
  /// matching the outer boundaries of both circles.
  union,

  /// Create a new path that is the exclusive-or of the two paths, leaving
  /// everything but the overlapping pieces of the path.
  ///
  /// For example, if the two paths are overlapping circles of equal diameter
  /// but differing centers, the figure-eight like shape less the overlapping
  /// parts
  ///
  /// See also:
  ///  * [intersect], which is the inverse of this operation
  xor,

  /// Subtract the first path from the second path.
  ///
  /// For example, if the two paths are overlapping circles of equal diameter
  /// but differing centers, the result would be a crescent portion of the
  /// second circle that was not overlapped by the first circle.
  ///
  /// See also:
  ///
  ///  * [difference], which is the same but subtracting the second path
  ///    from the first.
  reverseDifference,
}

class RawRecordingCanvas extends engine.BitmapCanvas
    implements PictureRecorder {
  RawRecordingCanvas(Size size) : super(Offset.zero & size);

  @override
  void dispose() {
    clear();
  }

  engine.RecordingCanvas beginRecording(Rect bounds) =>
      throw UnsupportedError('');

  @override
  Picture endRecording() => throw UnsupportedError('');

  engine.RecordingCanvas _canvas; // ignore: unused_field

  bool _isRecording = true; // ignore: unused_field

  @override
  bool get isRecording => true;

  Rect cullRect;
}
