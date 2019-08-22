// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  Vertices(
    VertexMode mode,
    List<Offset> positions, {
    List<Offset> textureCoordinates,
    List<Color> colors,
    List<int> indices,
  })  : assert(mode != null),
        assert(positions != null);

  Vertices.raw(
    VertexMode mode,
    Float32List positions, {
    Float32List textureCoordinates,
    Int32List colors,
    Uint16List indices,
  })  : assert(mode != null),
        assert(positions != null);
}

/// Records a [Picture] containing a sequence of graphical operations.
///
/// To begin recording, construct a [Canvas] to record the commands.
/// To end recording, use the [PictureRecorder.endRecording] method.
class PictureRecorder {
  /// Creates a new idle PictureRecorder. To associate it with a
  /// [Canvas] and begin recording, pass this [PictureRecorder] to the
  /// [Canvas] constructor.
  factory PictureRecorder() {
    if (engine.experimentalUseSkia) {
      return engine.SkPictureRecorder();
    } else {
      return PictureRecorder._();
    }
  }

  PictureRecorder._();

  engine.RecordingCanvas _canvas;
  Rect cullRect;
  bool _isRecording = false;

  engine.RecordingCanvas beginRecording(Rect bounds) {
    assert(!_isRecording);
    cullRect = bounds;
    _isRecording = true;
    _canvas = engine.RecordingCanvas(cullRect);
    return _canvas;
  }

  /// Whether this object is currently recording commands.
  ///
  /// Specifically, this returns true if a [Canvas] object has been
  /// created to record commands and recording has not yet ended via a
  /// call to [endRecording], and false if either this
  /// [PictureRecorder] has not yet been associated with a [Canvas],
  /// or the [endRecording] method has already been called.
  bool get isRecording => _isRecording;

  /// Finishes recording graphical operations.
  ///
  /// Returns a picture containing the graphical operations that have been
  /// recorded thus far. After calling this function, both the picture recorder
  /// and the canvas objects are invalid and cannot be used further.
  ///
  /// Returns null if the PictureRecorder is not associated with a canvas.
  Picture endRecording() {
    // Returning null is what the flutter engine does:
    // lib/ui/painting/picture_recorder.cc
    if (!_isRecording) {
      return null;
    }
    _isRecording = false;
    return Picture._(_canvas, cullRect);
  }
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
  Canvas(PictureRecorder recorder, [Rect cullRect]) : assert(recorder != null) {
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
    _transform(matrix4);
  }

  void _transform(Float64List matrix4) {
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
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    assert(vertices != null); // vertices is checked on the engine side
    assert(paint != null);
    assert(blendMode != null);
    throw UnimplementedError();
  }

  //
  // See also:
  //
  //  * [drawRawAtlas], which takes its arguments as typed data lists rather
  //    than objects.
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

  //
  // The `rstTransforms` argument is interpreted as a list of four-tuples, with
  // each tuple being ([RSTransform.scos], [RSTransform.ssin],
  // [RSTransform.tx], [RSTransform.ty]).
  //
  // The `rects` argument is interpreted as a list of four-tuples, with each
  // tuple being ([Rect.left], [Rect.top], [Rect.right], [Rect.bottom]).
  //
  // The `colors` argument, which can be null, is interpreted as a list of
  // 32-bit colors, with the same packing as [Color.value].
  //
  // See also:
  //
  //  * [drawAtlas], which takes its arguments as objects rather than typed
  //    data lists.
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
class Picture {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [Picture], use a [PictureRecorder].
  Picture._(this.recordingCanvas, this.cullRect);

  /// Creates an image from this picture.
  ///
  /// The picture is rasterized using the number of pixels specified by the
  /// given width and height.
  ///
  /// Although the image is returned synchronously, the picture is actually
  /// rasterized the first time the image is drawn and then cached.
  Future<Image> toImage(int width, int height) => null;

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  void dispose() {}

  /// Returns the approximate number of bytes allocated for this object.
  ///
  /// The actual size of this picture may be larger, particularly if it contains
  /// references to image or other large objects.
  int get approximateBytesUsed => 0;

  final engine.RecordingCanvas recordingCanvas;
  final Rect cullRect;
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

/// A complex, one-dimensional subset of a plane.
///
/// A path consists of a number of subpaths, and a _current point_.
///
/// Subpaths consist of segments of various types, such as lines,
/// arcs, or beziers. Subpaths can be open or closed, and can
/// self-intersect.
///
/// Closed subpaths enclose a (possibly discontiguous) region of the
/// plane based on the current [fillType].
///
/// The _current point_ is initially at the origin. After each
/// operation adding a segment to a subpath, the current point is
/// updated to the end of that segment.
///
/// Paths can be drawn on canvases using [Canvas.drawPath], and can
/// used to create clip regions using [Canvas.clipPath].
class Path {
  final List<engine.Subpath> subpaths;
  PathFillType _fillType = PathFillType.nonZero;

  engine.Subpath get _currentSubpath => subpaths.isEmpty ? null : subpaths.last;

  List<engine.PathCommand> get _commands => _currentSubpath?.commands;

  /// The current x-coordinate for this path.
  double get _currentX => _currentSubpath?.currentX ?? 0.0;

  /// The current y-coordinate for this path.
  double get _currentY => _currentSubpath?.currentY ?? 0.0;

  /// Recorder used for hit testing paths.
  static RawRecordingCanvas _rawRecorder;

  /// Create a new empty [Path] object.
  factory Path() {
    if (engine.experimentalUseSkia) {
      return engine.SkPath();
    } else {
      return Path._();
    }
  }

  Path._() : subpaths = <engine.Subpath>[];

  /// Creates a copy of another [Path].
  ///
  /// This copy is fast and does not require additional memory unless either
  /// the `source` path or the path returned by this constructor are modified.
  Path.from(Path source)
      : subpaths = List<engine.Subpath>.from(source.subpaths);

  Path._clone(this.subpaths, this._fillType);

  /// Determines how the interior of this path is calculated.
  ///
  /// Defaults to the non-zero winding rule, [PathFillType.nonZero].
  PathFillType get fillType => _fillType;
  set fillType(PathFillType value) {
    _fillType = value;
  }

  /// Opens a new subpath with starting point (x, y).
  void _openNewSubpath(double x, double y) {
    subpaths.add(engine.Subpath(x, y));
    _setCurrentPoint(x, y);
  }

  /// Sets the current point to (x, y).
  void _setCurrentPoint(double x, double y) {
    _currentSubpath.currentX = x;
    _currentSubpath.currentY = y;
  }

  /// Starts a new subpath at the given coordinate.
  void moveTo(double x, double y) {
    _openNewSubpath(x, y);
    _commands.add(engine.MoveTo(x, y));
  }

  /// Starts a new subpath at the given offset from the current point.
  void relativeMoveTo(double dx, double dy) {
    final double newX = _currentX + dx;
    final double newY = _currentY + dy;
    _openNewSubpath(newX, newY);
    _commands.add(engine.MoveTo(newX, newY));
  }

  /// Adds a straight line segment from the current point to the given
  /// point.
  void lineTo(double x, double y) {
    if (subpaths.isEmpty) {
      moveTo(0.0, 0.0);
    }
    _commands.add(engine.LineTo(x, y));
    _setCurrentPoint(x, y);
  }

  /// Adds a straight line segment from the current point to the point
  /// at the given offset from the current point.
  void relativeLineTo(double dx, double dy) {
    final double newX = _currentX + dx;
    final double newY = _currentY + dy;
    if (subpaths.isEmpty) {
      moveTo(0.0, 0.0);
    }
    _commands.add(engine.LineTo(newX, newY));
    _setCurrentPoint(newX, newY);
  }

  void _ensurePathStarted() {
    if (subpaths.isEmpty) {
      subpaths.add(engine.Subpath(0.0, 0.0));
    }
  }

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the given point (x2,y2), using the control point
  /// (x1,y1).
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _ensurePathStarted();
    _commands.add(engine.QuadraticCurveTo(x1, y1, x2, y2));
    _setCurrentPoint(x2, y2);
  }

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the point at the offset (x2,y2) from the current point,
  /// using the control point at the offset (x1,y1) from the current
  /// point.
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _ensurePathStarted();
    _commands.add(engine.QuadraticCurveTo(
        x1 + _currentX, y1 + _currentY, x2 + _currentX, y2 + _currentY));
    _setCurrentPoint(x2 + _currentX, y2 + _currentY);
  }

  /// Adds a cubic bezier segment that curves from the current point
  /// to the given point (x3,y3), using the control points (x1,y1) and
  /// (x2,y2).
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _ensurePathStarted();
    _commands.add(engine.BezierCurveTo(x1, y1, x2, y2, x3, y3));
    _setCurrentPoint(x3, y3);
  }

  /// Adds a cubic bezier segment that curves from the current point
  /// to the point at the offset (x3,y3) from the current point, using
  /// the control points at the offsets (x1,y1) and (x2,y2) from the
  /// current point.
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _ensurePathStarted();
    _commands.add(engine.BezierCurveTo(x1 + _currentX, y1 + _currentY,
        x2 + _currentX, y2 + _currentY, x3 + _currentX, y3 + _currentY));
    _setCurrentPoint(x3 + _currentX, y3 + _currentY);
  }

  /// Adds a bezier segment that curves from the current point to the
  /// given point (x2,y2), using the control points (x1,y1) and the
  /// weight w. If the weight is greater than 1, then the curve is a
  /// hyperbola; if the weight equals 1, it's a parabola; and if it is
  /// less than 1, it is an ellipse.
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    final List<Offset> quads =
        engine.Conic(_currentX, _currentY, x1, y1, x2, y2, w).toQuads();
    final int len = quads.length;
    for (int i = 1; i < len; i += 2) {
      quadraticBezierTo(
          quads[i].dx, quads[i].dy, quads[i + 1].dx, quads[i + 1].dy);
    }
  }

  /// Adds a bezier segment that curves from the current point to the
  /// point at the offset (x2,y2) from the current point, using the
  /// control point at the offset (x1,y1) from the current point and
  /// the weight w. If the weight is greater than 1, then the curve is
  /// a hyperbola; if the weight equals 1, it's a parabola; and if it
  /// is less than 1, it is an ellipse.
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    conicTo(_currentX + x1, _currentY + y1, _currentX + x2, _currentY + y2, w);
  }

  /// If the `forceMoveTo` argument is false, adds a straight line
  /// segment and an arc segment.
  ///
  /// If the `forceMoveTo` argument is true, starts a new subpath
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
  /// The line segment added if `forceMoveTo` is false starts at the
  /// current point and ends at the start of the arc.
  void arcTo(
      Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    assert(engine.rectIsValid(rect));
    final Offset center = rect.center;
    final double radiusX = rect.width / 2;
    final double radiusY = rect.height / 2;
    final double startX = radiusX * math.cos(startAngle) + center.dx;
    final double startY = radiusY * math.sin(startAngle) + center.dy;
    if (forceMoveTo) {
      _openNewSubpath(startX, startY);
    } else {
      lineTo(startX, startY);
    }
    _commands.add(engine.Ellipse(center.dx, center.dy, radiusX, radiusY, 0.0,
        startAngle, startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(radiusX * math.cos(startAngle + sweepAngle) + center.dx,
        radiusY * math.sin(startAngle + sweepAngle) + center.dy);
  }

  /// Appends up to four conic curves weighted to describe an oval of `radius`
  /// and rotated by `rotation`.
  ///
  /// The first curve begins from the last point in the path and the last ends
  /// at `arcEnd`. The curves follow a path in a direction determined by
  /// `clockwise` and `largeArc` in such a way that the sweep angle
  /// is always less than 360 degrees.
  ///
  /// A simple line is appended if either either radii are zero or the last
  /// point in the path is `arcEnd`. The radii are scaled to fit the last path
  /// point if both are greater than zero but too small to describe an arc.
  ///
  /// See Conversion from endpoint to center parametrization described in
  /// https://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter
  /// as reference for implementation.
  void arcToPoint(
    Offset arcEnd, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    assert(engine.offsetIsValid(arcEnd));
    assert(engine.radiusIsValid(radius));
    // _currentX, _currentY are the coordinates of start point on path,
    // arcEnd is final point of arc.
    // rx,ry are the radii of the eclipse (semi-major/semi-minor axis)
    // largeArc is false if arc is spanning less than or equal to 180 degrees.
    // clockwise is false if arc sweeps through decreasing angles or true
    // if sweeping through increasing angles.
    // rotation is the angle from the x-axis of the current coordinate
    // system to the x-axis of the eclipse.

    double rx = radius.x.abs();
    double ry = radius.y.abs();

    // If the current point and target point for the arc are identical, it
    // should be treated as a zero length path. This ensures continuity in
    // animations.
    final bool isSamePoint = _currentX == arcEnd.dx && _currentY == arcEnd.dy;

    // If rx = 0 or ry = 0 then this arc is treated as a straight line segment
    // (a "lineto") joining the endpoints.
    // http://www.w3.org/TR/SVG/implnote.html#ArcOutOfRangeParameters
    if (isSamePoint || rx.toInt() == 0 || ry.toInt() == 0) {
      _commands.add(engine.LineTo(arcEnd.dx, arcEnd.dy));
      _setCurrentPoint(arcEnd.dx, arcEnd.dy);
      return;
    }

    // As an intermediate point to finding center parametrization, place the
    // origin on the midpoint between start/end points and rotate to align
    // coordinate axis with axes of the ellipse.
    final double midPointX = (_currentX - arcEnd.dx) / 2.0;
    final double midPointY = (_currentY - arcEnd.dy) / 2.0;

    // Convert rotation or radians.
    final double xAxisRotation = math.pi * rotation / 180.0;

    // Cache cos/sin value.
    final double cosXAxisRotation = math.cos(xAxisRotation);
    final double sinXAxisRotation = math.sin(xAxisRotation);

    // Calculate rotate midpoint as x/yPrime.
    final double xPrime =
        (cosXAxisRotation * midPointX) + (sinXAxisRotation * midPointY);
    final double yPrime =
        (-sinXAxisRotation * midPointX) + (cosXAxisRotation * midPointY);

    // Check if the radii are big enough to draw the arc, scale radii if not.
    // http://www.w3.org/TR/SVG/implnote.html#ArcCorrectionOutOfRangeRadii
    double rxSquare = rx * rx;
    double rySquare = ry * ry;
    final double xPrimeSquare = xPrime * xPrime;
    final double yPrimeSquare = yPrime * yPrime;

    double radiiScale = (xPrimeSquare / rxSquare) + (yPrimeSquare / rySquare);
    if (radiiScale > 1) {
      radiiScale = math.sqrt(radiiScale);
      rx *= radiiScale;
      ry *= radiiScale;
      rxSquare = rx * rx;
      rySquare = ry * ry;
    }

    // Compute transformed center. eq. 5.2
    final double distanceSquare =
        (rxSquare * yPrimeSquare) + rySquare * xPrimeSquare;
    final double cNumerator = (rxSquare * rySquare) - distanceSquare;
    double scaleFactor = math.sqrt(math.max(cNumerator / distanceSquare, 0.0));
    if (largeArc == clockwise) {
      scaleFactor = -scaleFactor;
    }
    // Ready to compute transformed center.
    final double cxPrime = scaleFactor * ((rx * yPrime) / ry);
    final double cyPrime = scaleFactor * (-(ry * xPrime) / rx);

    // Rotate to find actual center.
    final double cx = cosXAxisRotation * cxPrime -
        sinXAxisRotation * cyPrime +
        ((_currentX + arcEnd.dx) / 2.0);
    final double cy = sinXAxisRotation * cxPrime +
        cosXAxisRotation * cyPrime +
        ((_currentY + arcEnd.dy) / 2.0);

    // Calculate start angle and sweep.
    // Start vector is from midpoint of start/end points to transformed center.
    final double startVectorX = (xPrime - cxPrime) / rx;
    final double startVectorY = (yPrime - cyPrime) / ry;

    final double startAngle = math.atan2(startVectorY, startVectorX);
    final double endVectorX = (-xPrime - cxPrime) / rx;
    final double endVectorY = (-yPrime - cyPrime) / ry;
    double sweepAngle = math.atan2(endVectorY, endVectorX) - startAngle;

    if (clockwise && sweepAngle < 0) {
      sweepAngle += math.pi * 2.0;
    } else if (!clockwise && sweepAngle > 0) {
      sweepAngle -= math.pi * 2.0;
    }

    _commands.add(engine.Ellipse(cx, cy, rx, ry, xAxisRotation, startAngle,
        startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(arcEnd.dx, arcEnd.dy);
  }

  /// Appends up to four conic curves weighted to describe an oval of `radius`
  /// and rotated by `rotation`.
  ///
  /// The last path point is described by (px, py).
  ///
  /// The first curve begins from the last point in the path and the last ends
  /// at `arcEndDelta.dx + px` and `arcEndDelta.dy + py`. The curves follow a
  /// path in a direction determined by `clockwise` and `largeArc`
  /// in such a way that the sweep angle is always less than 360 degrees.
  ///
  /// A simple line is appended if either either radii are zero, or, both
  /// `arcEndDelta.dx` and `arcEndDelta.dy` are zero. The radii are scaled to
  /// fit the last path point if both are greater than zero but too small to
  /// describe an arc.
  void relativeArcToPoint(
    Offset arcEndDelta, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    assert(engine.offsetIsValid(arcEndDelta));
    assert(engine.radiusIsValid(radius));
    arcToPoint(Offset(_currentX + arcEndDelta.dx, _currentY + arcEndDelta.dy),
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise);
  }

  /// Adds a new subpath that consists of four lines that outline the
  /// given rectangle.
  void addRect(Rect rect) {
    assert(engine.rectIsValid(rect));
    _openNewSubpath(rect.left, rect.top);
    _commands
        .add(engine.RectCommand(rect.left, rect.top, rect.width, rect.height));
  }

  /// Adds a new subpath that consists of a curve that forms the
  /// ellipse that fills the given rectangle.
  ///
  /// To add a circle, pass an appropriate rectangle as `oval`.
  /// [Rect.fromCircle] can be used to easily describe the circle's center
  /// [Offset] and radius.
  void addOval(Rect oval) {
    assert(engine.rectIsValid(oval));
    final Offset center = oval.center;
    final double radiusX = oval.width / 2;
    final double radiusY = oval.height / 2;

    /// At startAngle = 0, the path will begin at center + cos(0) * radius.
    _openNewSubpath(center.dx + radiusX, center.dy);
    _commands.add(engine.Ellipse(
        center.dx, center.dy, radiusX, radiusY, 0.0, 0.0, 2 * math.pi, false));
  }

  /// Adds a new subpath with one arc segment that consists of the arc
  /// that follows the edge of the oval bounded by the given
  /// rectangle, from startAngle radians around the oval up to
  /// startAngle + sweepAngle radians around the oval, with zero
  /// radians being the point on the right hand side of the oval that
  /// crosses the horizontal line that intersects the center of the
  /// rectangle and with positive angles going clockwise around the
  /// oval.
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    assert(engine.rectIsValid(oval));
    final Offset center = oval.center;
    final double radiusX = oval.width / 2;
    final double radiusY = oval.height / 2;
    _openNewSubpath(radiusX * math.cos(startAngle) + center.dx,
        radiusY * math.sin(startAngle) + center.dy);
    _commands.add(engine.Ellipse(center.dx, center.dy, radiusX, radiusY, 0.0,
        startAngle, startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(radiusX * math.cos(startAngle + sweepAngle) + center.dx,
        radiusY * math.sin(startAngle + sweepAngle) + center.dy);
  }

  /// Adds a new subpath with a sequence of line segments that connect the given
  /// points.
  ///
  /// If `close` is true, a final line segment will be added that connects the
  /// last point to the first point.
  ///
  /// The `points` argument is interpreted as offsets from the origin.
  void addPolygon(List<Offset> points, bool close) {
    assert(points != null);
    if (points.isEmpty) {
      return;
    }

    moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset point = points[i];
      lineTo(point.dx, point.dy);
    }
    if (close) {
      this.close();
    } else {
      _setCurrentPoint(points.last.dx, points.last.dy);
    }
  }

  /// Adds a new subpath that consists of the straight lines and
  /// curves needed to form the rounded rectangle described by the
  /// argument.
  void addRRect(RRect rrect) {
    assert(engine.rrectIsValid(rrect));

    // Set the current point to the top left corner of the rectangle (the
    // point on the top of the rectangle farthest to the left that isn't in
    // the rounded corner).
    // TODO(het): Is this the current point in Flutter?
    _openNewSubpath(rrect.tallMiddleRect.left, rrect.top);
    _commands.add(engine.RRectCommand(rrect));
  }

  /// Adds a new subpath that consists of the given `path` offset by the given
  /// `offset`.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given offset. The matrix is a 4x4
  /// matrix stored in column major order.
  void addPath(Path path, Offset offset, {Float64List matrix4}) {
    assert(path != null); // path is checked on the engine side
    assert(engine.offsetIsValid(offset));
    if (matrix4 != null) {
      assert(engine.matrix4IsValid(matrix4));
      _addPathWithMatrix(path, offset.dx, offset.dy, matrix4);
    } else {
      _addPath(path, offset.dx, offset.dy);
    }
  }

  void _addPath(Path path, double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) {
      subpaths.addAll(path.subpaths);
    } else {
      throw UnimplementedError('Cannot add path with non-zero offset');
    }
  }

  void _addPathWithMatrix(Path path, double dx, double dy, Float64List matrix) {
    throw UnimplementedError('Cannot add path with transform matrix');
  }

  /// Adds the given path to this path by extending the current segment of this
  /// path with the the first segment of the given path.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given `offset`.  The matrix is a 4x4
  /// matrix stored in column major order.
  void extendWithPath(Path path, Offset offset, {Float64List matrix4}) {
    assert(path != null); // path is checked on the engine side
    assert(engine.offsetIsValid(offset));
    if (matrix4 != null) {
      assert(engine.matrix4IsValid(matrix4));
      _extendWithPathAndMatrix(path, offset.dx, offset.dy, matrix4);
    } else {
      _extendWithPath(path, offset.dx, offset.dy);
    }
  }

  void _extendWithPath(Path path, double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) {
      assert(path.subpaths.length == 1);
      _ensurePathStarted();
      _commands.addAll(path.subpaths.single.commands);
      _setCurrentPoint(
          path.subpaths.single.currentX, path.subpaths.single.currentY);
    } else {
      throw UnimplementedError('Cannot extend path with non-zero offset');
    }
  }

  void _extendWithPathAndMatrix(
      Path path, double dx, double dy, Float64List matrix) {
    throw UnimplementedError('Cannot extend path with transform matrix');
  }

  /// Closes the last subpath, as if a straight line had been drawn
  /// from the current point to the first point of the subpath.
  void close() {
    _ensurePathStarted();
    _commands.add(const engine.CloseCommand());
    _setCurrentPoint(_currentSubpath.startX, _currentSubpath.startY);
  }

  /// Clears the [Path] object of all subpaths, returning it to the
  /// same state it had when it was created. The _current point_ is
  /// reset to the origin.
  void reset() {
    subpaths.clear();
  }

  /// Tests to see if the given point is within the path. (That is, whether the
  /// point would be in the visible portion of the path if the path was used
  /// with [Canvas.clipPath].)
  ///
  /// The `point` argument is interpreted as an offset from the origin.
  ///
  /// Returns true if the point is in the path, and false otherwise.
  ///
  /// Note: Not very efficient, it creates a canvas, plays path and calls
  /// Context2D isPointInPath. If performance becomes issue, retaining
  /// RawRecordingCanvas can remove create/remove rootElement cost.
  bool contains(Offset point) {
    assert(engine.offsetIsValid(point));
    final int subPathCount = subpaths.length;
    if (subPathCount == 0) {
      return false;
    }
    final double pointX = point.dx;
    final double pointY = point.dy;
    if (subPathCount == 1) {
      // Optimize for rect/roundrect checks.
      final engine.Subpath subPath = subpaths[0];
      if (subPath.commands.length == 1) {
        final engine.PathCommand cmd = subPath.commands[0];
        if (cmd is engine.RectCommand) {
          if (pointY < cmd.y || pointY > (cmd.y + cmd.height)) {
            return false;
          }
          if (pointX < cmd.x || pointX > (cmd.x + cmd.width)) {
            return false;
          }
          return true;
        } else if (cmd is engine.RRectCommand) {
          final RRect rRect = cmd.rrect;
          if (pointY < rRect.top || pointY > rRect.bottom) {
            return false;
          }
          if (pointX < rRect.left || pointX > rRect.right) {
            return false;
          }
          if (pointX < (rRect.left + rRect.tlRadiusX) &&
              pointY < (rRect.top + rRect.tlRadiusY)) {
            // Top left corner
            return _ellipseContains(
                pointX,
                pointY,
                rRect.left + rRect.tlRadiusX,
                rRect.top + rRect.tlRadiusY,
                rRect.tlRadiusX,
                rRect.tlRadiusY);
          } else if (pointX >= (rRect.right - rRect.trRadiusX) &&
              pointY < (rRect.top + rRect.trRadiusY)) {
            // Top right corner
            return _ellipseContains(
                pointX,
                pointY,
                rRect.right - rRect.trRadiusX,
                rRect.top + rRect.trRadiusY,
                rRect.trRadiusX,
                rRect.trRadiusY);
          } else if (pointX >= (rRect.right - rRect.brRadiusX) &&
              pointY >= (rRect.bottom - rRect.brRadiusY)) {
            // Bottom right corner
            return _ellipseContains(
                pointX,
                pointY,
                rRect.right - rRect.brRadiusX,
                rRect.bottom - rRect.brRadiusY,
                rRect.trRadiusX,
                rRect.trRadiusY);
          } else if (pointX < (rRect.left + rRect.blRadiusX) &&
              pointY >= (rRect.bottom - rRect.blRadiusY)) {
            // Bottom left corner
            return _ellipseContains(
                pointX,
                pointY,
                rRect.left + rRect.blRadiusX,
                rRect.bottom - rRect.blRadiusY,
                rRect.trRadiusX,
                rRect.trRadiusY);
          }
          return true;
        }
      }
    }
    final Size size = window.physicalSize / window.devicePixelRatio;
    _rawRecorder ??= RawRecordingCanvas(size);
    // Account for the shift due to padding.
    _rawRecorder.translate(-engine.BitmapCanvas.paddingPixels.toDouble(),
        -engine.BitmapCanvas.paddingPixels.toDouble());
    _rawRecorder.drawPath(
        this, (Paint()..color = const Color(0xFF000000)).webOnlyPaintData);
    final bool result = _rawRecorder.ctx.isPointInPath(pointX, pointY);
    _rawRecorder.dispose();
    return result;
  }

  /// Returns a copy of the path with all the segments of every
  /// subpath translated by the given offset.
  Path shift(Offset offset) {
    assert(engine.offsetIsValid(offset));
    final List<engine.Subpath> shiftedSubpaths = <engine.Subpath>[];
    for (final engine.Subpath subpath in subpaths) {
      shiftedSubpaths.add(subpath.shift(offset));
    }
    return Path._clone(shiftedSubpaths, fillType);
  }

  /// Returns a copy of the path with all the segments of every
  /// subpath transformed by the given matrix.
  Path transform(Float64List matrix4) {
    assert(engine.matrix4IsValid(matrix4));
    throw UnimplementedError();
  }

  /// Computes the bounding rectangle for this path.
  ///
  /// A path containing only axis-aligned points on the same straight line will
  /// have no area, and therefore `Rect.isEmpty` will return true for such a
  /// path. Consider checking `rect.width + rect.height > 0.0` instead, or
  /// using the [computeMetrics] API to check the path length.
  ///
  /// For many more elaborate paths, the bounds may be inaccurate.  For example,
  /// when a path contains a circle, the points used to compute the bounds are
  /// the circle's implied control points, which form a square around the
  /// circle; if the circle has a transformation applied using [transform] then
  /// that square is rotated, and the (axis-aligned, non-rotated) bounding box
  /// therefore ends up grossly overestimating the actual area covered by the
  /// circle.
  // see https://skia.org/user/api/SkPath_Reference#SkPath_getBounds
  Rect getBounds() {
    // Sufficiently small number for curve eq.
    const double epsilon = 0.000000001;
    bool ltrbInitialized = false;
    double left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
    double curX = 0.0;
    double curY = 0.0;
    double minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0;
    for (engine.Subpath subpath in subpaths) {
      for (engine.PathCommand op in subpath.commands) {
        bool skipBounds = false;
        switch (op.type) {
          case engine.PathCommandTypes.moveTo:
            final engine.MoveTo cmd = op;
            curX = minX = maxX = cmd.x;
            curY = minY = maxY = cmd.y;
            break;
          case engine.PathCommandTypes.lineTo:
            final engine.LineTo cmd = op;
            curX = minX = maxX = cmd.x;
            curY = minY = maxY = cmd.y;
            break;
          case engine.PathCommandTypes.ellipse:
            final engine.Ellipse cmd = op;
            // Rotate 4 corners of bounding box.
            final double rx = cmd.radiusX;
            final double ry = cmd.radiusY;
            final double cosVal = math.cos(cmd.rotation);
            final double sinVal = math.sin(cmd.rotation);
            final double rxCos = rx * cosVal;
            final double ryCos = ry * cosVal;
            final double rxSin = rx * sinVal;
            final double rySin = ry * sinVal;

            final double leftDeltaX = rxCos - rySin;
            final double rightDeltaX = -rxCos - rySin;
            final double topDeltaY = ryCos + rxSin;
            final double bottomDeltaY = ryCos - rxSin;

            final double centerX = cmd.x;
            final double centerY = cmd.y;

            double rotatedX = centerX + leftDeltaX;
            double rotatedY = centerY + topDeltaY;
            minX = maxX = rotatedX;
            minY = maxY = rotatedY;

            rotatedX = centerX + rightDeltaX;
            rotatedY = centerY + bottomDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            rotatedX = centerX - leftDeltaX;
            rotatedY = centerY - topDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            rotatedX = centerX - rightDeltaX;
            rotatedY = centerY - bottomDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            curX = centerX + cmd.radiusX;
            curY = centerY;
            break;
          case engine.PathCommandTypes.quadraticCurveTo:
            final engine.QuadraticCurveTo cmd = op;
            final double x1 = curX;
            final double y1 = curY;
            final double cpX = cmd.x1;
            final double cpY = cmd.y1;
            final double x2 = cmd.x2;
            final double y2 = cmd.y2;

            minX = math.min(x1, x2);
            minY = math.min(y1, y2);
            maxX = math.max(x1, x2);
            maxY = math.max(y1, y2);

            // Curve equation : (1-t)(1-t)P1 + 2t(1-t)CP + t*t*P2.
            // At extrema's derivative = 0.
            // Solve for
            // -2x1+2tx1 + 2cpX + 4tcpX + 2tx2 = 0
            // -2x1 + 2cpX +2t(x1 + 2cpX + x2) = 0
            // t = (x1 - cpX) / (x1 - 2cpX + x2)

            double denom = x1 - (2 * cpX) + x2;
            if (denom.abs() > epsilon) {
              final num t1 = (x1 - cpX) / denom;
              if ((t1 >= 0) && (t1 <= 1.0)) {
                // Solve (x,y) for curve at t = tx to find extrema
                final num tprime = 1.0 - t1;
                final num extremaX = (tprime * tprime * x1) +
                    (2 * t1 * tprime * cpX) +
                    (t1 * t1 * x2);
                final num extremaY = (tprime * tprime * y1) +
                    (2 * t1 * tprime * cpY) +
                    (t1 * t1 * y2);
                // Expand bounds.
                minX = math.min(minX, extremaX);
                maxX = math.max(maxX, extremaX);
                minY = math.min(minY, extremaY);
                maxY = math.max(maxY, extremaY);
              }
            }
            // Now calculate dy/dt = 0
            denom = y1 - (2 * cpY) + y2;
            if (denom.abs() > epsilon) {
              final num t2 = (y1 - cpY) / denom;
              if ((t2 >= 0) && (t2 <= 1.0)) {
                final num tprime2 = 1.0 - t2;
                final num extrema2X = (tprime2 * tprime2 * x1) +
                    (2 * t2 * tprime2 * cpX) +
                    (t2 * t2 * x2);
                final num extrema2Y = (tprime2 * tprime2 * y1) +
                    (2 * t2 * tprime2 * cpY) +
                    (t2 * t2 * y2);
                // Expand bounds.
                minX = math.min(minX, extrema2X);
                maxX = math.max(maxX, extrema2X);
                minY = math.min(minY, extrema2Y);
                maxY = math.max(maxY, extrema2Y);
              }
            }
            curX = x2;
            curY = y2;
            break;
          case engine.PathCommandTypes.bezierCurveTo:
            final engine.BezierCurveTo cmd = op;
            final double startX = curX;
            final double startY = curY;
            final double cpX1 = cmd.x1;
            final double cpY1 = cmd.y1;
            final double cpX2 = cmd.x2;
            final double cpY2 = cmd.y2;
            final double endX = cmd.x3;
            final double endY = cmd.y3;
            // Bounding box is defined by all points on the curve where
            // monotonicity changes.
            minX = math.min(startX, endX);
            minY = math.min(startY, endY);
            maxX = math.max(startX, endX);
            maxY = math.max(startY, endY);

            double extremaX;
            double extremaY;
            double a, b, c;

            // Check for simple case of strong ordering before calculating
            // extrema
            if (!(((startX < cpX1) && (cpX1 < cpX2) && (cpX2 < endX)) ||
                ((startX > cpX1) && (cpX1 > cpX2) && (cpX2 > endX)))) {
              // The extrema point is dx/dt B(t) = 0
              // The derivative of B(t) for cubic bezier is a quadratic equation
              // with multiple roots
              // B'(t) = a*t*t + b*t + c*t
              a = -startX + (3 * (cpX1 - cpX2)) + endX;
              b = 2 * (startX - (2 * cpX1) + cpX2);
              c = -startX + cpX1;

              // Now find roots for quadratic equation with known coefficients
              // a,b,c
              // The roots are (-b+-sqrt(b*b-4*a*c)) / 2a
              num s = (b * b) - (4 * a * c);
              // If s is negative, we have no real roots
              if ((s >= 0.0) && (a.abs() > epsilon)) {
                if (s == 0.0) {
                  // we have only 1 root
                  final num t = -b / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);
                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                } else {
                  // we have 2 roots
                  s = math.sqrt(s);
                  num t = (-b - s) / (2 * a);
                  num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);
                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                  // check 2nd root
                  t = (-b + s) / (2 * a);
                  tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);

                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                }
              }
            }

            // Now calc extremes for dy/dt = 0 just like above
            if (!(((startY < cpY1) && (cpY1 < cpY2) && (cpY2 < endY)) ||
                ((startY > cpY1) && (cpY1 > cpY2) && (cpY2 > endY)))) {
              // The extrema point is dy/dt B(t) = 0
              // The derivative of B(t) for cubic bezier is a quadratic equation
              // with multiple roots
              // B'(t) = a*t*t + b*t + c*t
              a = -startY + (3 * (cpY1 - cpY2)) + endY;
              b = 2 * (startY - (2 * cpY1) + cpY2);
              c = -startY + cpY1;

              // Now find roots for quadratic equation with known coefficients
              // a,b,c
              // The roots are (-b+-sqrt(b*b-4*a*c)) / 2a
              num s = (b * b) - (4 * a * c);
              // If s is negative, we have no real roots
              if ((s >= 0.0) && (a.abs() > epsilon)) {
                if (s == 0.0) {
                  // we have only 1 root
                  final num t = -b / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaY = ((tprime * tprime * tprime) * startY) +
                        ((3 * tprime * tprime * t) * cpY1) +
                        ((3 * tprime * t * t) * cpY2) +
                        (t * t * t * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                } else {
                  // we have 2 roots
                  s = math.sqrt(s);
                  final num t = (-b - s) / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaY = ((tprime * tprime * tprime) * startY) +
                        ((3 * tprime * tprime * t) * cpY1) +
                        ((3 * tprime * t * t) * cpY2) +
                        (t * t * t * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                  // check 2nd root
                  final num t2 = (-b + s) / (2 * a);
                  final num tprime2 = 1.0 - t2;
                  if ((t2 >= 0.0) && (t2 <= 1.0)) {
                    extremaY = ((tprime2 * tprime2 * tprime2) * startY) +
                        ((3 * tprime2 * tprime2 * t2) * cpY1) +
                        ((3 * tprime2 * t2 * t2) * cpY2) +
                        (t2 * t2 * t2 * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                }
              }
            }
            break;
          case engine.PathCommandTypes.rect:
            final engine.RectCommand cmd = op;
            left = cmd.x;
            double width = cmd.width;
            if (cmd.width < 0) {
              left -= width;
              width = -width;
            }
            double top = cmd.y;
            double height = cmd.height;
            if (cmd.height < 0) {
              top -= height;
              height = -height;
            }
            curX = minX = left;
            maxX = left + width;
            curY = minY = top;
            maxY = top + height;
            break;
          case engine.PathCommandTypes.rRect:
            final engine.RRectCommand cmd = op;
            final RRect rRect = cmd.rrect;
            curX = minX = rRect.left;
            maxX = rRect.left + rRect.width;
            curY = minY = rRect.top;
            maxY = rRect.top + rRect.height;
            break;
          case engine.PathCommandTypes.close:
          default:
            skipBounds = false;
            break;
        }
        if (!skipBounds) {
          if (!ltrbInitialized) {
            left = minX;
            right = maxX;
            top = minY;
            bottom = maxY;
            ltrbInitialized = true;
          } else {
            left = math.min(left, minX);
            right = math.max(right, maxX);
            top = math.min(top, minY);
            bottom = math.max(bottom, maxY);
          }
        }
      }
    }
    return ltrbInitialized
        ? Rect.fromLTRB(left, top, right, bottom)
        : Rect.zero;
  }

  /// Combines the two paths according to the manner specified by the given
  /// `operation`.
  ///
  /// The resulting path will be constructed from non-overlapping contours. The
  /// curve order is reduced where possible so that cubics may be turned into
  /// quadratics, and quadratics maybe turned into lines.
  static Path combine(PathOperation operation, Path path1, Path path2) {
    assert(path1 != null);
    assert(path2 != null);
    throw UnimplementedError();
  }

  /// Creates a [PathMetrics] object for this path.
  ///
  /// If `forceClosed` is set to true, the contours of the path will be measured
  /// as if they had been closed, even if they were not explicitly closed.
  PathMetrics computeMetrics({bool forceClosed = false}) {
    return PathMetrics._(this, forceClosed);
  }

  /// Detects if path is rounded rectangle and returns rounded rectangle or
  /// null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  RRect get webOnlyPathAsRoundedRect {
    if (subpaths.length != 1) {
      return null;
    }
    final engine.Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final engine.PathCommand command = subPath.commands[0];
    return (command is engine.RRectCommand) ? command.rrect : null;
  }

  /// Detects if path is simple rectangle and returns rectangle or null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  Rect get webOnlyPathAsRect {
    if (subpaths.length != 1) {
      return null;
    }
    final engine.Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final engine.PathCommand command = subPath.commands[0];
    return (command is engine.RectCommand)
        ? Rect.fromLTWH(command.x, command.y, command.width, command.height)
        : null;
  }

  /// Detects if path is simple oval and returns [engine.Ellipse] or null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  engine.Ellipse get webOnlyPathAsCircle {
    if (subpaths.length != 1) {
      return null;
    }
    final engine.Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final engine.PathCommand command = subPath.commands[0];
    if (command is engine.Ellipse) {
      final engine.Ellipse ellipse = command;
      if ((ellipse.endAngle - ellipse.startAngle) % (2 * math.pi) == 0.0) {
        return ellipse;
      }
    }
    return null;
  }

  /// Serializes this path to a value that's sent to a CSS custom painter for
  /// painting.
  List<dynamic> webOnlySerializeToCssPaint() {
    final List<dynamic> serializedSubpaths = <dynamic>[];
    for (int i = 0; i < subpaths.length; i++) {
      serializedSubpaths.add(subpaths[i].serializeToCssPaint());
    }
    return serializedSubpaths;
  }

  @override
  String toString() {
    if (engine.assertionsEnabled) {
      return 'Path(${subpaths.join(', ')})';
    } else {
      return super.toString();
    }
  }
}

/// An iterable collection of [PathMetric] objects describing a [Path].
///
/// A [PathMetrics] object is created by using the [Path.computeMetrics] method,
/// and represents the path as it stood at the time of the call. Subsequent
/// modifications of the path do not affect the [PathMetrics] object.
///
/// Each path metric corresponds to a segment, or contour, of a path.
///
/// For example, a path consisting of a [Path.lineTo], a [Path.moveTo], and
/// another [Path.lineTo] will contain two contours and thus be represented by
/// two [PathMetric] objects.
///
/// When iterating across a [PathMetrics]' contours, the [PathMetric] objects
/// are only valid until the next one is obtained.
class PathMetrics extends IterableBase<PathMetric> {
  PathMetrics._(Path path, bool forceClosed)
      : _iterator = PathMetricIterator._(PathMetric._(path, forceClosed));

  final Iterator<PathMetric> _iterator;

  @override
  Iterator<PathMetric> get iterator => _iterator;
}

/// Tracks iteration from one segment of a path to the next for measurement.
class PathMetricIterator implements Iterator<PathMetric> {
  PathMetricIterator._(this._pathMetric);

  PathMetric _pathMetric;
  bool _firstTime = true;

  @override
  PathMetric get current => _firstTime ? null : _pathMetric;

  @override
  bool moveNext() {
    // PathMetric isn't a normal iterable - it's already initialized to its
    // first Path.  Should only call _moveNext when done with the first one.
    if (_firstTime == true) {
      _firstTime = false;
      return true;
    } else if (_pathMetric?._moveNext() == true) {
      return true;
    }
    _pathMetric = null;
    return false;
  }
}

/// Utilities for measuring a [Path] and extracting subpaths.
///
/// Iterate over the object returned by [Path.computeMetrics] to obtain
/// [PathMetric] objects.
///
/// Once created, metrics will only be valid while the iterator is at the given
/// contour. When the next contour's [PathMetric] is obtained, this object
/// becomes invalid.
class PathMetric {
  final Path path;
  final bool forceClosed;

  /// Create a new empty [Path] object.
  PathMetric._(this.path, this.forceClosed);

  /// Return the total length of the current contour.
  double get length => throw UnimplementedError();

  /// Computes the position of hte current contour at the given offset, and the
  /// angle of the path at that point.
  ///
  /// For example, calling this method with a distance of 1.41 for a line from
  /// 0.0,0.0 to 2.0,2.0 would give a point 1.0,1.0 and the angle 45 degrees
  /// (but in radians).
  ///
  /// Returns null if the contour has zero [length].
  ///
  /// The distance is clamped to the [length] of the current contour.
  Tangent getTangentForOffset(double distance) {
    final Float32List posTan = _getPosTan(distance);
    // first entry == 0 indicates that Skia returned false
    if (posTan[0] == 0.0) {
      return null;
    } else {
      return Tangent(
          Offset(posTan[1], posTan[2]), Offset(posTan[3], posTan[4]));
    }
  }

  Float32List _getPosTan(double distance) => throw UnimplementedError();

  /// Given a start and stop distance, return the intervening segment(s).
  ///
  /// `start` and `end` are pinned to legal values (0..[length])
  /// Returns null if the segment is 0 length or `start` > `stop`.
  /// Begin the segment with a moveTo if `startWithMoveTo` is true.
  Path extractPath(double start, double end, {bool startWithMoveTo = true}) =>
      throw UnimplementedError();

  /// Whether the contour is closed.
  ///
  /// Returns true if the contour ends with a call to [Path.close] (which may
  /// have been implied when using [Path.addRect]) or if `forceClosed` was
  /// specified as true in the call to [Path.computeMetrics].  Returns false
  /// otherwise.
  bool get isClosed => throw UnimplementedError();

  // Move to the next contour in the path.
  //
  // A path can have a next contour if [Path.moveTo] was called after drawing
  // began. Return true if one exists, or false.
  //
  // This is not exactly congruent with a regular [Iterator.moveNext].
  // Typically, [Iterator.moveNext] should be called before accessing the
  // [Iterator.current]. In this case, the [PathMetric] is valid before
  // calling `_moveNext` - `_moveNext` should be called after the first
  // iteration is done instead of before.
  bool _moveNext() => throw UnimplementedError();

  @override
  String toString() => 'PathMetric';
}

/// The geometric description of a tangent: the angle at a point.
///
/// See also:
///  * [PathMetric.getTangentForOffset], which returns the tangent of an offset
///    along a path.
class Tangent {
  /// Creates a [Tangent] with the given values.
  ///
  /// The arguments must not be null.
  const Tangent(this.position, this.vector)
      : assert(position != null),
        assert(vector != null);

  /// Creates a [Tangent] based on the angle rather than the vector.
  ///
  /// The [vector] is computed to be the unit vector at the given angle,
  /// interpreted as clockwise radians from the x axis.
  factory Tangent.fromAngle(Offset position, double angle) {
    return Tangent(position, Offset(math.cos(angle), math.sin(angle)));
  }

  /// Position of the tangent.
  ///
  /// When used with [PathMetric.getTangentForOffset], this represents the
  /// precise position that the given offset along the path corresponds to.
  final Offset position;

  /// The vector of the curve at [position].
  ///
  /// When used with [PathMetric.getTangentForOffset], this is the vector of the
  /// curve that is at the given offset along the path (i.e. the direction of
  /// the curve at [position]).
  final Offset vector;

  /// The direction of the curve at [position].
  ///
  /// When used with [PathMetric.getTangentForOffset], this is the angle of the
  /// curve that is the given offset along the path (i.e. the direction of the
  /// curve at [position]).
  ///
  /// This value is in radians, with 0.0 meaning pointing along the x axis in
  /// the positive x-axis direction, positive numbers pointing downward toward
  /// the negative y-axis, i.e. in a clockwise direction, and negative numbers
  /// pointing upward toward the positive y-axis, i.e. in a counter-clockwise
  /// direction.
  // flip the sign to be consistent with [Path.arcTo]'s `sweepAngle`
  double get angle => -math.atan2(vector.dy, vector.dx);
}

class RawRecordingCanvas extends engine.BitmapCanvas
    implements PictureRecorder {
  RawRecordingCanvas(Size size) : super(Offset.zero & size);

  @override
  void dispose() {
    clear();
  }

  @override
  engine.RecordingCanvas beginRecording(Rect bounds) =>
      throw UnsupportedError('');
  @override
  Picture endRecording() => throw UnsupportedError('');

  @override
  engine.RecordingCanvas _canvas;

  @override
  bool _isRecording = true;

  @override
  bool get isRecording => true;

  @override
  Rect cullRect;
}

// Returns true if point is inside ellipse.
bool _ellipseContains(double px, double py, double centerX, double centerY,
    double radiusX, double radiusY) {
  final double dx = px - centerX;
  final double dy = py - centerY;
  return ((dx * dx) / (radiusX * radiusX)) + ((dy * dy) / (radiusY * radiusY)) <
      1.0;
}
