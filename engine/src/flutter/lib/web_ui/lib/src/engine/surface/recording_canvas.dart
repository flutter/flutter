// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// Enable this to print every command applied by a canvas.
const bool _debugDumpPaintCommands = false;

// Returns the squared length of the x, y (of a border radius)
// It normalizes x, y values before working with them, by
// assuming anything < 0 to be 0, because flutter may pass
// negative radii (which Skia assumes to be 0), see:
// https://skia.org/user/api/SkRRect_Reference#SkRRect_inset
double _measureBorderRadius(double x, double y) {
  double clampedX = x < 0 ? 0 : x;
  double clampedY = y < 0 ? 0 : y;
  return clampedX * clampedX + clampedY * clampedY;
}

/// Records canvas commands to be applied to a [EngineCanvas].
///
/// See [Canvas] for docs for these methods.
class RecordingCanvas {
  /// Computes [_pictureBounds].
  final _PaintBounds _paintBounds;

  /// Maximum paintable bounds for the picture painted by this recording.
  ///
  /// The bounds contain the full picture. The commands recorded for the picture
  /// are later pruned based on the clip applied to the picture. See the [apply]
  /// method for more details.
  ui.Rect get pictureBounds {
    assert(
      _debugRecordingEnded,
      'Picture bounds not available yet. Call [endRecording] before accessing picture bounds.',
    );
    return _pictureBounds;
  }
  ui.Rect _pictureBounds;

  final List<PaintCommand> _commands = <PaintCommand>[];

  /// In debug mode returns the list of recorded paint commands for testing.
  List<PaintCommand> get debugPaintCommands {
    if (assertionsEnabled) {
      return _commands;
    }
    throw UnsupportedError('For debugging only.');
  }

  RecordingCanvas(ui.Rect bounds) : _paintBounds = _PaintBounds(bounds);

  /// Whether this canvas is doing arbitrary paint operations not expressible
  /// via DOM elements.
  bool get hasArbitraryPaint => _hasArbitraryPaint;
  bool _hasArbitraryPaint = false;

  /// Forces arbitrary paint even for simple pictures.
  ///
  /// This is useful for testing bitmap canvas when otherwise the compositor
  /// would prefer a DOM canvas.
  void debugEnforceArbitraryPaint() {
    _hasArbitraryPaint = true;
  }

  /// Whether this canvas contain drawing operations.
  ///
  /// Some pictures are created but only contain operations that do not result
  /// in any pixels on the screen. For example, they will only contain saves,
  /// restores, and translates. This happens when a parent [RenderObject]
  /// prepares the canvas for its children to paint to, but the child ends up
  /// not painting anything, such as when an empty [SizedBox] is used to add a
  /// margin between two widgets.
  bool get didDraw => _didDraw;
  bool _didDraw = false;

  /// When assertions are enabled used to ensure that [endRecording] is called
  /// before calling [apply] or [pictureBounds].
  bool _debugRecordingEnded = false;

  /// Stops recording drawing commands and computes paint bounds.
  ///
  /// This must be called prior to passing the picture to the [SceneBuilder]
  /// for rendering. In a production app, this is done automatically by
  /// [PictureRecorder] when the framework calls [PictureRecorder.endRecording].
  /// However, if you are writing a unit-test and using [RecordingCanvas]
  /// directly it is up to you to call this method explicitly.
  void endRecording() {
    _pictureBounds = _paintBounds.computeBounds();
    if (assertionsEnabled) {
      _debugRecordingEnded = true;
    }
  }

  /// Applies the recorded commands onto an [engineCanvas].
  ///
  /// The [clipRect] specifies the clip applied to the picture (screen clip at
  /// a minimum). The commands that fall outside the clip are skipped and are
  /// not applied to the [engineCanvas]. A command must have a non-zero
  /// intersection with the clip in order to be applied.
  void apply(EngineCanvas engineCanvas, ui.Rect clipRect) {
    assert(_debugRecordingEnded);
    if (_debugDumpPaintCommands) {
      final StringBuffer debugBuf = StringBuffer();
      int skips = 0;
      debugBuf.writeln(
          '--- Applying RecordingCanvas to ${engineCanvas.runtimeType} '
          'with bounds $_paintBounds and clip $clipRect (w = ${clipRect.width},'
          ' h = ${clipRect.height})');
      for (int i = 0; i < _commands.length; i++) {
        final PaintCommand command = _commands[i];
        if (command is DrawCommand) {
          if (command.isInvisible(clipRect)) {
            // The drawing command is outside the clip region. No need to apply.
            debugBuf.writeln('SKIPPED: ctx.$command;');
            skips += 1;
            continue;
          }
        }
        debugBuf.writeln('ctx.$command;');
        command.apply(engineCanvas);
      }
      if (skips > 0) {
        debugBuf.writeln('Total commands skipped: $skips');
      }
      debugBuf.writeln('--- End of command stream');
      print(debugBuf);
    } else {
      try {
        if (rectContainsOther(clipRect, _pictureBounds)) {
          // No need to check if commands fit in the clip rect if we already
          // know that the entire picture fits it.
          for (int i = 0, len = _commands.length; i < len; i++) {
            _commands[i].apply(engineCanvas);
          }
        } else {
          // The picture doesn't fit the clip rect. Check that drawing commands
          // fit before applying them.
          for (int i = 0, len = _commands.length; i < len; i++) {
            final PaintCommand command = _commands[i];
            if (command is DrawCommand) {
              if (command.isInvisible(clipRect)) {
                // The drawing command is outside the clip region. No need to apply.
                continue;
              }
            }
            command.apply(engineCanvas);
          }
        }
      } catch (e) {
        // commands should never fail, but...
        // https://bugzilla.mozilla.org/show_bug.cgi?id=941146
        if (!_isNsErrorFailureException(e)) {
          rethrow;
        }
      }
    }
    engineCanvas.endOfPaint();
  }

  /// Prints recorded commands.
  String debugPrintCommands() {
    if (assertionsEnabled) {
      final StringBuffer debugBuf = StringBuffer();
      for (int i = 0; i < _commands.length; i++) {
        final PaintCommand command = _commands[i];
        debugBuf.writeln('ctx.$command;');
      }
      return debugBuf.toString();
    }
    return null;
  }

  void save() {
    assert(!_debugRecordingEnded);
    _paintBounds.saveTransformsAndClip();
    _commands.add(const PaintSave());
    _saveCount++;
  }

  void saveLayerWithoutBounds(SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    // TODO(het): Implement this correctly using another canvas.
    _commands.add(const PaintSave());
    _paintBounds.saveTransformsAndClip();
    _saveCount++;
  }

  void saveLayer(ui.Rect bounds, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    // TODO(het): Implement this correctly using another canvas.
    _commands.add(const PaintSave());
    _paintBounds.saveTransformsAndClip();
    _saveCount++;
  }

  void restore() {
    assert(!_debugRecordingEnded);
    _paintBounds.restoreTransformsAndClip();
    if (_commands.isNotEmpty && _commands.last is PaintSave) {
      // A restore followed a save without any drawing operations in between.
      // This means that the save didn't have any effect on drawing operations
      // and can be omitted. This makes our communication with the canvas less
      // chatty.
      _commands.removeLast();
    } else {
      _commands.add(const PaintRestore());
    }
    _saveCount--;
  }

  void translate(double dx, double dy) {
    assert(!_debugRecordingEnded);
    _paintBounds.translate(dx, dy);
    _commands.add(PaintTranslate(dx, dy));
  }

  void scale(double sx, double sy) {
    assert(!_debugRecordingEnded);
    _paintBounds.scale(sx, sy);
    _commands.add(PaintScale(sx, sy));
  }

  void rotate(double radians) {
    assert(!_debugRecordingEnded);
    _paintBounds.rotateZ(radians);
    _commands.add(PaintRotate(radians));
  }

  void transform(Float32List matrix4) {
    assert(!_debugRecordingEnded);
    _paintBounds.transform(matrix4);
    _commands.add(PaintTransform(matrix4));
  }

  void skew(double sx, double sy) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _paintBounds.skew(sx, sy);
    _commands.add(PaintSkew(sx, sy));
  }

  void clipRect(ui.Rect rect) {
    assert(!_debugRecordingEnded);
    final PaintClipRect command = PaintClipRect(rect);
    _paintBounds.clipRect(rect, command);
    _hasArbitraryPaint = true;
    _commands.add(command);
  }

  void clipRRect(ui.RRect rrect) {
    assert(!_debugRecordingEnded);
    final PaintClipRRect command = PaintClipRRect(rrect);
    _paintBounds.clipRect(rrect.outerRect, command);
    _hasArbitraryPaint = true;
    _commands.add(command);
  }

  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    assert(!_debugRecordingEnded);
    final PaintClipPath command = PaintClipPath(path);
    _paintBounds.clipRect(path.getBounds(), command);
    _hasArbitraryPaint = true;
    _commands.add(command);
  }

  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    assert(!_debugRecordingEnded);
    final PaintDrawColor command = PaintDrawColor(color, blendMode);
    _commands.add(command);
    _paintBounds.grow(_paintBounds.maxPaintBounds, command);
  }

  void drawLine(ui.Offset p1, ui.Offset p2, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    final double paintSpread = math.max(_getPaintSpread(paint), 1.0);
    final PaintDrawLine command = PaintDrawLine(p1, p2, paint.paintData);
    // TODO(yjbanov): This can be optimized. Currently we create a box around
    //                the line and then apply the transform on the box to get
    //                the bounding box. If you have a 45-degree line and a
    //                45-degree transform, the bounding box should be the length
    //                of the line long and stroke width wide, but our current
    //                algorithm produces a square with each side of the length
    //                matching the length of the line.
    _paintBounds.growLTRB(
      math.min(p1.dx, p2.dx) - paintSpread,
      math.min(p1.dy, p2.dy) - paintSpread,
      math.max(p1.dx, p2.dx) + paintSpread,
      math.max(p1.dy, p2.dy) + paintSpread,
      command,
    );
    _hasArbitraryPaint = true;
    _didDraw = true;
    _commands.add(command);
  }

  void drawPaint(SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final PaintDrawPaint command = PaintDrawPaint(paint.paintData);
    _paintBounds.grow(_paintBounds.maxPaintBounds, command);
    _commands.add(command);
  }

  void drawRect(ui.Rect rect, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    if (paint.shader != null) {
      _hasArbitraryPaint = true;
    }
    _didDraw = true;
    final double paintSpread = _getPaintSpread(paint);
    final PaintDrawRect command = PaintDrawRect(rect, paint.paintData);
    if (paintSpread != 0.0) {
      _paintBounds.grow(rect.inflate(paintSpread), command);
    } else {
      _paintBounds.grow(rect, command);
    }
    _commands.add(command);
  }

  void drawRRect(ui.RRect rrect, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    if (paint.shader != null || !rrect.webOnlyUniformRadii) {
      _hasArbitraryPaint = true;
    }
    _didDraw = true;
    final double paintSpread = _getPaintSpread(paint);
    final double left = math.min(rrect.left, rrect.right) - paintSpread;
    final double top = math.min(rrect.top, rrect.bottom) - paintSpread;
    final double right = math.max(rrect.left, rrect.right) + paintSpread;
    final double bottom = math.max(rrect.top, rrect.bottom) + paintSpread;
    final PaintDrawRRect command = PaintDrawRRect(rrect, paint.paintData);
    _paintBounds.growLTRB(left, top, right, bottom, command);
    _commands.add(command);
  }

  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    // Check the inner bounds are contained within the outer bounds
    // see: https://cs.chromium.org/chromium/src/third_party/skia/src/core/SkCanvas.cpp?l=1787-1789
    ui.Rect innerRect = inner.outerRect;
    ui.Rect outerRect = outer.outerRect;
    if (outerRect == innerRect || outerRect.intersect(innerRect) != innerRect) {
      return; // inner is not fully contained within outer
    }

    // Compare radius "length" of the rectangles that are going to be actually drawn
    final ui.RRect scaledOuter = outer.scaleRadii();
    final ui.RRect scaledInner = inner.scaleRadii();

    final double outerTl =
        _measureBorderRadius(scaledOuter.tlRadiusX, scaledOuter.tlRadiusY);
    final double outerTr =
        _measureBorderRadius(scaledOuter.trRadiusX, scaledOuter.trRadiusY);
    final double outerBl =
        _measureBorderRadius(scaledOuter.blRadiusX, scaledOuter.blRadiusY);
    final double outerBr =
        _measureBorderRadius(scaledOuter.brRadiusX, scaledOuter.brRadiusY);

    final double innerTl =
        _measureBorderRadius(scaledInner.tlRadiusX, scaledInner.tlRadiusY);
    final double innerTr =
        _measureBorderRadius(scaledInner.trRadiusX, scaledInner.trRadiusY);
    final double innerBl =
        _measureBorderRadius(scaledInner.blRadiusX, scaledInner.blRadiusY);
    final double innerBr =
        _measureBorderRadius(scaledInner.brRadiusX, scaledInner.brRadiusY);

    if (innerTl > outerTl ||
        innerTr > outerTr ||
        innerBl > outerBl ||
        innerBr > outerBr) {
      return; // Some inner radius is overlapping some outer radius
    }

    _hasArbitraryPaint = true;
    _didDraw = true;
    final double paintSpread = _getPaintSpread(paint);
    final PaintDrawDRRect command = PaintDrawDRRect(outer, inner, paint.paintData);
    _paintBounds.growLTRB(
      outer.left - paintSpread,
      outer.top - paintSpread,
      outer.right + paintSpread,
      outer.bottom + paintSpread,
      command,
    );
    _commands.add(command);
  }

  void drawOval(ui.Rect rect, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double paintSpread = _getPaintSpread(paint);
    final PaintDrawOval command = PaintDrawOval(rect, paint.paintData);
    if (paintSpread != 0.0) {
      _paintBounds.grow(rect.inflate(paintSpread), command);
    } else {
      _paintBounds.grow(rect, command);
    }
    _commands.add(command);
  }

  void drawCircle(ui.Offset c, double radius, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double paintSpread = _getPaintSpread(paint);
    final PaintDrawCircle command = PaintDrawCircle(c, radius, paint.paintData);
    final double distance = radius + paintSpread;
    _paintBounds.growLTRB(
      c.dx - distance,
      c.dy - distance,
      c.dx + distance,
      c.dy + distance,
      command,
    );
    _commands.add(command);
  }

  void drawPath(ui.Path path, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    if (paint.shader == null) {
      // For Rect/RoundedRect paths use drawRect/drawRRect code paths for
      // DomCanvas optimization.
      SurfacePath sPath = path;
      final ui.Rect rect = sPath.webOnlyPathAsRect;
      if (rect != null) {
        drawRect(rect, paint);
        return;
      }
      final ui.RRect rrect = sPath.webOnlyPathAsRoundedRect;
      if (rrect != null) {
        drawRRect(rrect, paint);
        return;
      }
    }
    _hasArbitraryPaint = true;
    _didDraw = true;
    ui.Rect pathBounds = path.getBounds();
    final double paintSpread = _getPaintSpread(paint);
    if (paintSpread != 0.0) {
      pathBounds = pathBounds.inflate(paintSpread);
    }
    // Clone path so it can be reused for subsequent draw calls.
    final ui.Path clone = SurfacePath._shallowCopy(path);
    final PaintDrawPath command = PaintDrawPath(clone, paint.paintData);
    _paintBounds.grow(pathBounds, command);
    clone.fillType = path.fillType;
    _commands.add(command);
  }

  void drawImage(ui.Image image, ui.Offset offset, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double left = offset.dx;
    final double top = offset.dy;
    final command = PaintDrawImage(image, offset, paint.paintData);
    _paintBounds.growLTRB(left, top, left + image.width, top + image.height, command);
    _commands.add(command);
  }

  void drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final PaintDrawImageRect command = PaintDrawImageRect(image, src, dst, paint.paintData);
    _paintBounds.grow(dst, command);
    _commands.add(command);
  }

  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    assert(!_debugRecordingEnded);
    final EngineParagraph engineParagraph = paragraph;
    if (!engineParagraph._isLaidOut) {
      // Ignore non-laid out paragraphs. This matches Flutter's behavior.
      return;
    }

    _didDraw = true;
    if (engineParagraph._geometricStyle.ellipsis != null) {
      _hasArbitraryPaint = true;
    }
    final double left = offset.dx;
    final double top = offset.dy;
    final PaintDrawParagraph command = PaintDrawParagraph(engineParagraph, offset);
    _paintBounds.growLTRB(
      left,
      top,
      left + engineParagraph.width,
      top + engineParagraph.height,
      command,
    );
    _commands.add(command);
  }

  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final ui.Rect shadowRect =
        computePenumbraBounds(path.getBounds(), elevation);
    final PaintDrawShadow command = PaintDrawShadow(path, color, elevation, transparentOccluder);
    _paintBounds.grow(shadowRect, command);
    _commands.add(command);
  }

  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    _hasArbitraryPaint = true;
    _didDraw = true;
    final PaintDrawVertices command = PaintDrawVertices(vertices, blendMode, paint.paintData);
    _growPaintBoundsByPoints(vertices.positions, 0, paint, command);
    _commands.add(command);
  }

  void drawRawPoints(
      ui.PointMode pointMode, Float32List points, SurfacePaint paint) {
    assert(!_debugRecordingEnded);
    if (paint.strokeWidth == null) {
      return;
    }
    _hasArbitraryPaint = true;
    _didDraw = true;
    final PaintDrawPoints command = PaintDrawPoints(pointMode, points, paint.strokeWidth, paint.color);
    _growPaintBoundsByPoints(points, paint.strokeWidth, paint, command);
    _commands.add(command);
  }

  void _growPaintBoundsByPoints(Float32List points, double thickness, SurfacePaint paint, DrawCommand command) {
    double minValueX, maxValueX, minValueY, maxValueY;
    minValueX = maxValueX = points[0];
    minValueY = maxValueY = points[1];
    for (int i = 2, len = points.length; i < len; i += 2) {
      final double x = points[i];
      final double y = points[i + 1];
      if (x.isNaN || y.isNaN) {
        // Follows skia implementation that sets bounds to empty
        // and aborts.
        return;
      }
      minValueX = math.min(minValueX, x);
      maxValueX = math.max(maxValueX, x);
      minValueY = math.min(minValueY, y);
      maxValueY = math.max(maxValueY, y);
    }
    final double distance = thickness / 2.0;
    final double paintSpread = _getPaintSpread(paint);
    _paintBounds.growLTRB(
      minValueX - distance - paintSpread,
      minValueY - distance - paintSpread,
      maxValueX + distance + paintSpread,
      maxValueY + distance + paintSpread,
      command,
    );
  }

  int _saveCount = 1;
  int get saveCount => _saveCount;

  /// Prints the commands recorded by this canvas to the console.
  void debugDumpCommands() {
    print('/' * 40 + ' CANVAS COMMANDS ' + '/' * 40);
    _commands.forEach(print);
    print('/' * 37 + ' END OF CANVAS COMMANDS ' + '/' * 36);
  }
}

abstract class PaintCommand {
  const PaintCommand();

  void apply(EngineCanvas canvas);

  void serializeToCssPaint(List<List<dynamic>> serializedCommands);
}

/// A [PaintCommand] that affect pixels on the screen (unlike, for example, the
/// [SaveCommand]).
abstract class DrawCommand extends PaintCommand {
  /// Whether the command is completely clipped out of the picture.
  bool isClippedOut = false;

  /// The left bound of the graphic produced by this command in picture-global
  /// coordinates.
  double leftBound = double.negativeInfinity;

  /// The top bound of the graphic produced by this command in picture-global
  /// coordinates.
  double topBound = double.negativeInfinity;

  /// The right bound of the graphic produced by this command in picture-global
  /// coordinates.
  double rightBound = double.infinity;

  /// The bottom bound of the graphic produced by this command in
  /// picture-global coordinates.
  double bottomBound = double.infinity;

  /// Whether this command intersects with the [clipRect].
  bool isInvisible(ui.Rect clipRect) {
    if (isClippedOut) {
      return true;
    }

    // Check top and bottom first because vertical scrolling is more common
    // than horizontal scrolling.
    return bottomBound < clipRect.top ||
      topBound > clipRect.bottom ||
      rightBound < clipRect.left ||
      leftBound > clipRect.right;
  }
}

class PaintSave extends PaintCommand {
  const PaintSave();

  @override
  void apply(EngineCanvas canvas) {
    canvas.save();
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'save()';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(const <int>[1]);
  }
}

class PaintRestore extends PaintCommand {
  const PaintRestore();

  @override
  void apply(EngineCanvas canvas) {
    canvas.restore();
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'restore()';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(const <int>[2]);
  }
}

class PaintTranslate extends PaintCommand {
  final double dx;
  final double dy;

  PaintTranslate(this.dx, this.dy);

  @override
  void apply(EngineCanvas canvas) {
    canvas.translate(dx, dy);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'translate($dx, $dy)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<num>[3, dx, dy]);
  }
}

class PaintScale extends PaintCommand {
  final double sx;
  final double sy;

  PaintScale(this.sx, this.sy);

  @override
  void apply(EngineCanvas canvas) {
    canvas.scale(sx, sy);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'scale($sx, $sy)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<num>[4, sx, sy]);
  }
}

class PaintRotate extends PaintCommand {
  final double radians;

  PaintRotate(this.radians);

  @override
  void apply(EngineCanvas canvas) {
    canvas.rotate(radians);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'rotate($radians)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<num>[5, radians]);
  }
}

class PaintTransform extends PaintCommand {
  final Float32List matrix4;

  PaintTransform(this.matrix4);

  @override
  void apply(EngineCanvas canvas) {
    canvas.transform(matrix4);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'transform(Matrix4.fromFloat32List(Float32List.fromList(<double>[${matrix4.join(', ')}])))';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[6]..addAll(matrix4));
  }
}

class PaintSkew extends PaintCommand {
  final double sx;
  final double sy;

  PaintSkew(this.sx, this.sy);

  @override
  void apply(EngineCanvas canvas) {
    canvas.skew(sx, sy);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'skew($sx, $sy)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<num>[7, sx, sy]);
  }
}

class PaintClipRect extends DrawCommand {
  final ui.Rect rect;

  PaintClipRect(this.rect);

  @override
  void apply(EngineCanvas canvas) {
    canvas.clipRect(rect);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'clipRect($rect)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[8, _serializeRectToCssPaint(rect)]);
  }
}

class PaintClipRRect extends DrawCommand {
  final ui.RRect rrect;

  PaintClipRRect(this.rrect);

  @override
  void apply(EngineCanvas canvas) {
    canvas.clipRRect(rrect);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'clipRRect($rrect)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      9,
      _serializeRRectToCssPaint(rrect),
    ]);
  }
}

class PaintClipPath extends DrawCommand {
  final SurfacePath path;

  PaintClipPath(this.path);

  @override
  void apply(EngineCanvas canvas) {
    canvas.clipPath(path);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'clipPath($path)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[10, path.webOnlySerializeToCssPaint()]);
  }
}

class PaintDrawColor extends DrawCommand {
  final ui.Color color;
  final ui.BlendMode blendMode;

  PaintDrawColor(this.color, this.blendMode);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawColor(color, blendMode);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawColor($color, $blendMode)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands
        .add(<dynamic>[11, colorToCssString(color), blendMode.index]);
  }
}

class PaintDrawLine extends DrawCommand {
  final ui.Offset p1;
  final ui.Offset p2;
  final SurfacePaintData paint;

  PaintDrawLine(this.p1, this.p2, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawLine(p1, p2, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawLine($p1, $p2, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      12,
      p1.dx,
      p1.dy,
      p2.dx,
      p2.dy,
      _serializePaintToCssPaint(paint)
    ]);
  }
}

class PaintDrawPaint extends DrawCommand {
  final SurfacePaintData paint;

  PaintDrawPaint(this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawPaint(paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawPaint($paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[13, _serializePaintToCssPaint(paint)]);
  }
}

class PaintDrawVertices extends DrawCommand {
  final ui.Vertices vertices;
  final ui.BlendMode blendMode;
  final SurfacePaintData paint;
  PaintDrawVertices(this.vertices, this.blendMode, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawVertices(vertices, blendMode, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawVertices($vertices, $blendMode, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    throw UnimplementedError();
  }
}

class PaintDrawPoints extends DrawCommand {
  final Float32List points;
  final ui.PointMode pointMode;
  final double strokeWidth;
  final ui.Color color;
  PaintDrawPoints(this.pointMode, this.points, this.strokeWidth, this.color);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawPoints(pointMode, points, strokeWidth, color);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawPoints($pointMode, $points, $strokeWidth, $color)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    throw UnimplementedError();
  }
}

class PaintDrawRect extends DrawCommand {
  final ui.Rect rect;
  final SurfacePaintData paint;

  PaintDrawRect(this.rect, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawRect(rect, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawRect($rect, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      14,
      _serializeRectToCssPaint(rect),
      _serializePaintToCssPaint(paint)
    ]);
  }
}

class PaintDrawRRect extends DrawCommand {
  final ui.RRect rrect;
  final SurfacePaintData paint;

  PaintDrawRRect(this.rrect, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawRRect(rrect, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawRRect($rrect, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      15,
      _serializeRRectToCssPaint(rrect),
      _serializePaintToCssPaint(paint),
    ]);
  }
}

class PaintDrawDRRect extends DrawCommand {
  final ui.RRect outer;
  final ui.RRect inner;
  final SurfacePaintData paint;

  PaintDrawDRRect(this.outer, this.inner, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawDRRect(outer, inner, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawDRRect($outer, $inner, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      16,
      _serializeRRectToCssPaint(outer),
      _serializeRRectToCssPaint(inner),
      _serializePaintToCssPaint(paint),
    ]);
  }
}

class PaintDrawOval extends DrawCommand {
  final ui.Rect rect;
  final SurfacePaintData paint;

  PaintDrawOval(this.rect, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawOval(rect, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawOval($rect, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      17,
      _serializeRectToCssPaint(rect),
      _serializePaintToCssPaint(paint),
    ]);
  }
}

class PaintDrawCircle extends DrawCommand {
  final ui.Offset c;
  final double radius;
  final SurfacePaintData paint;

  PaintDrawCircle(this.c, this.radius, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawCircle(c, radius, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawCircle($c, $radius, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      18,
      c.dx,
      c.dy,
      radius,
      _serializePaintToCssPaint(paint),
    ]);
  }
}

class PaintDrawPath extends DrawCommand {
  final SurfacePath path;
  final SurfacePaintData paint;

  PaintDrawPath(this.path, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawPath(path, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawPath($path, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      19,
      path.webOnlySerializeToCssPaint(),
      _serializePaintToCssPaint(paint),
    ]);
  }
}

class PaintDrawShadow extends DrawCommand {
  PaintDrawShadow(
      this.path, this.color, this.elevation, this.transparentOccluder);

  final SurfacePath path;
  final ui.Color color;
  final double elevation;
  final bool transparentOccluder;

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawShadow($path, $color, $elevation, $transparentOccluder)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    serializedCommands.add(<dynamic>[
      20,
      path.webOnlySerializeToCssPaint(),
      <dynamic>[
        color.alpha,
        color.red,
        color.green,
        color.blue,
      ],
      elevation,
      transparentOccluder,
    ]);
  }
}

class PaintDrawImage extends DrawCommand {
  final ui.Image image;
  final ui.Offset offset;
  final SurfacePaintData paint;

  PaintDrawImage(this.image, this.offset, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawImage(image, offset, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawImage($image, $offset, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    if (assertionsEnabled) {
      throw UnsupportedError('drawImage not serializable');
    }
  }
}

class PaintDrawImageRect extends DrawCommand {
  final ui.Image image;
  final ui.Rect src;
  final ui.Rect dst;
  final SurfacePaintData paint;

  PaintDrawImageRect(this.image, this.src, this.dst, this.paint);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'drawImageRect($image, $src, $dst, $paint)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    if (assertionsEnabled) {
      throw UnsupportedError('drawImageRect not serializable');
    }
  }
}

class PaintDrawParagraph extends DrawCommand {
  final EngineParagraph paragraph;
  final ui.Offset offset;

  PaintDrawParagraph(this.paragraph, this.offset);

  @override
  void apply(EngineCanvas canvas) {
    canvas.drawParagraph(paragraph, offset);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'DrawParagraph(${paragraph._plainText}, $offset)';
    } else {
      return super.toString();
    }
  }

  @override
  void serializeToCssPaint(List<List<dynamic>> serializedCommands) {
    if (assertionsEnabled) {
      throw UnsupportedError('drawParagraph not serializable');
    }
  }
}

List<dynamic> _serializePaintToCssPaint(SurfacePaintData paint) {
  final EngineGradient engineShader = paint.shader;
  return <dynamic>[
    paint.blendMode?.index,
    paint.style?.index,
    paint.strokeWidth,
    paint.strokeCap?.index,
    paint.isAntiAlias,
    colorToCssString(paint.color),
    engineShader?.webOnlySerializeToCssPaint(),
    paint.maskFilter?.webOnlySerializeToCssPaint(),
    paint.filterQuality?.index,
    paint.colorFilter?.webOnlySerializeToCssPaint(),
  ];
}

List<dynamic> _serializeRectToCssPaint(ui.Rect rect) {
  return <dynamic>[
    rect.left,
    rect.top,
    rect.right,
    rect.bottom,
  ];
}

List<dynamic> _serializeRRectToCssPaint(ui.RRect rrect) {
  return <dynamic>[
    rrect.left,
    rrect.top,
    rrect.right,
    rrect.bottom,
    rrect.tlRadiusX,
    rrect.tlRadiusY,
    rrect.trRadiusX,
    rrect.trRadiusY,
    rrect.brRadiusX,
    rrect.brRadiusY,
    rrect.blRadiusX,
    rrect.blRadiusY,
  ];
}

class Subpath {
  double startX = 0.0;
  double startY = 0.0;
  double currentX = 0.0;
  double currentY = 0.0;

  final List<PathCommand> commands;

  Subpath(this.startX, this.startY) : commands = <PathCommand>[];

  Subpath shift(ui.Offset offset) {
    final Subpath result = Subpath(startX + offset.dx, startY + offset.dy)
      ..currentX = currentX + offset.dx
      ..currentY = currentY + offset.dy;

    for (final PathCommand command in commands) {
      result.commands.add(command.shifted(offset));
    }

    return result;
  }

  List<dynamic> serializeToCssPaint() {
    final List<dynamic> serialization = <dynamic>[];
    for (int i = 0; i < commands.length; i++) {
      serialization.add(commands[i].serializeToCssPaint());
    }
    return serialization;
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'Subpath(${commands.join(', ')})';
    } else {
      return super.toString();
    }
  }
}

/// ! Houdini implementation relies on indices here. Keep in sync.
class PathCommandTypes {
  static const int moveTo = 0;
  static const int lineTo = 1;
  static const int ellipse = 2;
  static const int close = 3;
  static const int quadraticCurveTo = 4;
  static const int bezierCurveTo = 5;
  static const int rect = 6;
  static const int rRect = 7;
}

abstract class PathCommand {
  final int type;
  const PathCommand(this.type);

  PathCommand shifted(ui.Offset offset);

  List<dynamic> serializeToCssPaint();

  /// Transform the command and add to targetPath.
  void transform(Float32List matrix4, SurfacePath targetPath);

  /// Helper method for implementing transforms.
  static ui.Offset _transformOffset(double x, double y, Float32List matrix4) =>
      ui.Offset((matrix4[0] * x) + (matrix4[4] * y) + matrix4[12],
          (matrix4[1] * x) + (matrix4[5] * y) + matrix4[13]);
}

class MoveTo extends PathCommand {
  final double x;
  final double y;

  const MoveTo(this.x, this.y) : super(PathCommandTypes.moveTo);

  @override
  MoveTo shifted(ui.Offset offset) {
    return MoveTo(x + offset.dx, y + offset.dy);
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[1, x, y];
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    final ui.Offset offset = PathCommand._transformOffset(x, y, matrix4);
    targetPath.moveTo(offset.dx, offset.dy);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'MoveTo($x, $y)';
    } else {
      return super.toString();
    }
  }
}

class LineTo extends PathCommand {
  final double x;
  final double y;

  const LineTo(this.x, this.y) : super(PathCommandTypes.lineTo);

  @override
  LineTo shifted(ui.Offset offset) {
    return LineTo(x + offset.dx, y + offset.dy);
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[2, x, y];
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    final ui.Offset offset = PathCommand._transformOffset(x, y, matrix4);
    targetPath.lineTo(offset.dx, offset.dy);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'LineTo($x, $y)';
    } else {
      return super.toString();
    }
  }
}

class Ellipse extends PathCommand {
  final double x;
  final double y;
  final double radiusX;
  final double radiusY;
  final double rotation;
  final double startAngle;
  final double endAngle;
  final bool anticlockwise;

  const Ellipse(this.x, this.y, this.radiusX, this.radiusY, this.rotation,
      this.startAngle, this.endAngle, this.anticlockwise)
      : super(PathCommandTypes.ellipse);

  @override
  Ellipse shifted(ui.Offset offset) {
    return Ellipse(x + offset.dx, y + offset.dy, radiusX, radiusY, rotation,
        startAngle, endAngle, anticlockwise);
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[
      3,
      x,
      y,
      radiusX,
      radiusY,
      rotation,
      startAngle,
      endAngle,
      anticlockwise,
    ];
  }

  @override
  void transform(Float32List matrix4, SurfacePath targetPath) {
    final ui.Path bezierPath = ui.Path();
    _drawArcWithBezier(
        x,
        y,
        radiusX,
        radiusY,
        rotation,
        startAngle,
        anticlockwise ? startAngle - endAngle : endAngle - startAngle,
        matrix4,
        bezierPath);
    if (matrix4 != null) {
      targetPath._addPathWithMatrix(bezierPath, 0, 0, matrix4);
    } else {
      targetPath._addPath(bezierPath, 0, 0);
    }
  }

  void _drawArcWithBezier(
      double centerX,
      double centerY,
      double radiusX,
      double radiusY,
      double rotation,
      double startAngle,
      double sweep,
      Float32List matrix4,
      ui.Path targetPath) {
    double ratio = sweep.abs() / (math.pi / 2.0);
    if ((1.0 - ratio).abs() < 0.0000001) {
      ratio = 1.0;
    }
    final int segments = math.max(ratio.ceil(), 1);
    final double anglePerSegment = sweep / segments;
    double angle = startAngle;
    for (int segment = 0; segment < segments; segment++) {
      _drawArcSegment(targetPath, centerX, centerY, radiusX, radiusY, rotation,
          angle, anglePerSegment, segment == 0, matrix4);
      angle += anglePerSegment;
    }
  }

  void _drawArcSegment(
      ui.Path path,
      double centerX,
      double centerY,
      double radiusX,
      double radiusY,
      double rotation,
      double startAngle,
      double sweep,
      bool startPath,
      Float32List matrix4) {
    final double s = 4 / 3 * math.tan(sweep / 4);

    // Rotate unit vector to startAngle and endAngle to use for computing start
    // and end points of segment.
    final double x1 = math.cos(startAngle);
    final double y1 = math.sin(startAngle);
    final double endAngle = startAngle + sweep;
    final double x2 = math.cos(endAngle);
    final double y2 = math.sin(endAngle);

    // Compute scaled curve control points.
    final double cpx1 = (x1 - y1 * s) * radiusX;
    final double cpy1 = (y1 + x1 * s) * radiusY;
    final double cpx2 = (x2 + y2 * s) * radiusX;
    final double cpy2 = (y2 - x2 * s) * radiusY;

    final double endPointX = centerX + x2 * radiusX;
    final double endPointY = centerY + y2 * radiusY;

    final double rotationRad = rotation * math.pi / 180.0;
    final double cosR = math.cos(rotationRad);
    final double sinR = math.sin(rotationRad);
    if (startPath) {
      final double scaledX1 = x1 * radiusX;
      final double scaledY1 = y1 * radiusY;
      if (rotation == 0.0) {
        path.moveTo(centerX + scaledX1, centerY + scaledY1);
      } else {
        final double rotatedStartX = (scaledX1 * cosR) + (scaledY1 * sinR);
        final double rotatedStartY = (scaledY1 * cosR) - (scaledX1 * sinR);
        path.moveTo(centerX + rotatedStartX, centerY + rotatedStartY);
      }
    }
    if (rotation == 0.0) {
      path.cubicTo(centerX + cpx1, centerY + cpy1, centerX + cpx2,
          centerY + cpy2, endPointX, endPointY);
    } else {
      final double rotatedCpx1 = centerX + (cpx1 * cosR) + (cpy1 * sinR);
      final double rotatedCpy1 = centerY + (cpy1 * cosR) - (cpx1 * sinR);
      final double rotatedCpx2 = centerX + (cpx2 * cosR) + (cpy2 * sinR);
      final double rotatedCpy2 = centerY + (cpy2 * cosR) - (cpx2 * sinR);
      final double rotatedEndX = centerX +
          ((endPointX - centerX) * cosR) +
          ((endPointY - centerY) * sinR);
      final double rotatedEndY = centerY +
          ((endPointY - centerY) * cosR) -
          ((endPointX - centerX) * sinR);
      path.cubicTo(rotatedCpx1, rotatedCpy1, rotatedCpx2, rotatedCpy2,
          rotatedEndX, rotatedEndY);
    }
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'Ellipse($x, $y, $radiusX, $radiusY)';
    } else {
      return super.toString();
    }
  }
}

class QuadraticCurveTo extends PathCommand {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const QuadraticCurveTo(this.x1, this.y1, this.x2, this.y2)
      : super(PathCommandTypes.quadraticCurveTo);

  @override
  QuadraticCurveTo shifted(ui.Offset offset) {
    return QuadraticCurveTo(
        x1 + offset.dx, y1 + offset.dy, x2 + offset.dx, y2 + offset.dy);
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[4, x1, y1, x2, y2];
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    final double m0 = matrix4[0];
    final double m1 = matrix4[1];
    final double m4 = matrix4[4];
    final double m5 = matrix4[5];
    final double m12 = matrix4[12];
    final double m13 = matrix4[13];
    final double transformedX1 = (m0 * x1) + (m4 * y1) + m12;
    final double transformedY1 = (m1 * x1) + (m5 * y1) + m13;
    final double transformedX2 = (m0 * x2) + (m4 * y2) + m12;
    final double transformedY2 = (m1 * x2) + (m5 * y2) + m13;
    targetPath.quadraticBezierTo(
        transformedX1, transformedY1, transformedX2, transformedY2);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'QuadraticCurveTo($x1, $y1, $x2, $y2)';
    } else {
      return super.toString();
    }
  }
}

class BezierCurveTo extends PathCommand {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;

  const BezierCurveTo(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3)
      : super(PathCommandTypes.bezierCurveTo);

  @override
  BezierCurveTo shifted(ui.Offset offset) {
    return BezierCurveTo(x1 + offset.dx, y1 + offset.dy, x2 + offset.dx,
        y2 + offset.dy, x3 + offset.dx, y3 + offset.dy);
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[5, x1, y1, x2, y2, x3, y3];
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    final double s0 = matrix4[0];
    final double s1 = matrix4[1];
    final double s4 = matrix4[4];
    final double s5 = matrix4[5];
    final double s12 = matrix4[12];
    final double s13 = matrix4[13];
    final double transformedX1 = (s0 * x1) + (s4 * y1) + s12;
    final double transformedY1 = (s1 * x1) + (s5 * y1) + s13;
    final double transformedX2 = (s0 * x2) + (s4 * y2) + s12;
    final double transformedY2 = (s1 * x2) + (s5 * y2) + s13;
    final double transformedX3 = (s0 * x3) + (s4 * y3) + s12;
    final double transformedY3 = (s1 * x3) + (s5 * y3) + s13;
    targetPath.cubicTo(transformedX1, transformedY1, transformedX2,
        transformedY2, transformedX3, transformedY3);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'BezierCurveTo($x1, $y1, $x2, $y2, $x3, $y3)';
    } else {
      return super.toString();
    }
  }
}

class RectCommand extends PathCommand {
  final double x;
  final double y;
  final double width;
  final double height;

  const RectCommand(this.x, this.y, this.width, this.height)
      : super(PathCommandTypes.rect);

  @override
  RectCommand shifted(ui.Offset offset) {
    return RectCommand(x + offset.dx, y + offset.dy, width, height);
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    final double s0 = matrix4[0];
    final double s1 = matrix4[1];
    final double s4 = matrix4[4];
    final double s5 = matrix4[5];
    final double s12 = matrix4[12];
    final double s13 = matrix4[13];
    final double transformedX1 = (s0 * x) + (s4 * y) + s12;
    final double transformedY1 = (s1 * x) + (s5 * y) + s13;
    final double x2 = x + width;
    final double y2 = y + height;
    final double transformedX2 = (s0 * x2) + (s4 * y) + s12;
    final double transformedY2 = (s1 * x2) + (s5 * y) + s13;
    final double transformedX3 = (s0 * x2) + (s4 * y2) + s12;
    final double transformedY3 = (s1 * x2) + (s5 * y2) + s13;
    final double transformedX4 = (s0 * x) + (s4 * y2) + s12;
    final double transformedY4 = (s1 * x) + (s5 * y2) + s13;
    if (transformedY1 == transformedY2 &&
        transformedY3 == transformedY4 &&
        transformedX1 == transformedX4 &&
        transformedX2 == transformedX3) {
      // It is still a rectangle.
      targetPath.addRect(ui.Rect.fromLTRB(
          transformedX1, transformedY1, transformedX3, transformedY3));
    } else {
      targetPath.moveTo(transformedX1, transformedY1);
      targetPath.lineTo(transformedX2, transformedY2);
      targetPath.lineTo(transformedX3, transformedY3);
      targetPath.lineTo(transformedX4, transformedY4);
      targetPath.close();
    }
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[6, x, y, width, height];
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'Rect($x, $y, $width, $height)';
    } else {
      return super.toString();
    }
  }
}

class RRectCommand extends PathCommand {
  final ui.RRect rrect;

  const RRectCommand(this.rrect) : super(PathCommandTypes.rRect);

  @override
  RRectCommand shifted(ui.Offset offset) {
    return RRectCommand(rrect.shift(offset));
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[7, _serializeRRectToCssPaint(rrect)];
  }

  @override
  void transform(Float32List matrix4, SurfacePath targetPath) {
    final ui.Path roundRectPath = ui.Path();
    _RRectToPathRenderer(roundRectPath).render(rrect);
    if (matrix4 != null) {
      targetPath._addPathWithMatrix(roundRectPath, 0, 0, matrix4);
    } else {
      targetPath._addPath(roundRectPath, 0, 0);
    }
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return '$rrect';
    } else {
      return super.toString();
    }
  }
}

class CloseCommand extends PathCommand {
  const CloseCommand() : super(PathCommandTypes.close);

  @override
  CloseCommand shifted(ui.Offset offset) {
    return this;
  }

  @override
  List<dynamic> serializeToCssPaint() {
    return <dynamic>[8];
  }

  @override
  void transform(Float32List matrix4, ui.Path targetPath) {
    targetPath.close();
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'Close()';
    } else {
      return super.toString();
    }
  }
}

class _PaintBounds {
  // Bounds of maximum area that is paintable by canvas ops.
  final ui.Rect maxPaintBounds;

  bool _didPaintInsideClipArea = false;
  // Bounds of actually painted area. If _left is not set, reported paintBounds
  // should be empty since growLTRB calls were outside active clipping
  // region.
  double _left, _top, _right, _bottom;
  // Stack of transforms.
  List<Matrix4> _transforms;
  // Stack of clip bounds.
  List<ui.Rect> _clipStack;
  bool _currentMatrixIsIdentity = true;
  Matrix4 _currentMatrix = Matrix4.identity();
  bool _clipRectInitialized = false;
  double _currentClipLeft = 0.0,
      _currentClipTop = 0.0,
      _currentClipRight = 0.0,
      _currentClipBottom = 0.0;

  _PaintBounds(this.maxPaintBounds);

  void translate(double dx, double dy) {
    if (dx != 0.0 || dy != 0.0) {
      _currentMatrixIsIdentity = false;
    }
    _currentMatrix.translate(dx, dy);
  }

  void scale(double sx, double sy) {
    if (sx != 1.0 || sy != 1.0) {
      _currentMatrixIsIdentity = false;
    }
    _currentMatrix.scale(sx, sy);
  }

  void rotateZ(double radians) {
    if (radians != 0.0) {
      _currentMatrixIsIdentity = false;
    }
    _currentMatrix.rotateZ(radians);
  }

  void transform(Float32List matrix4) {
    final Matrix4 m4 = Matrix4.fromFloat32List(matrix4);
    _currentMatrix.multiply(m4);
    _currentMatrixIsIdentity = _currentMatrix.isIdentity();
  }

  void skew(double sx, double sy) {
    _currentMatrixIsIdentity = false;

    // DO NOT USE Matrix4.skew(sx, sy)! It treats sx and sy values as radians,
    // but in our case they are transform matrix values.
    final Matrix4 skewMatrix = Matrix4.identity();
    final Float32List storage = skewMatrix.storage;
    storage[1] = sy;
    storage[4] = sx;
    _currentMatrix.multiply(skewMatrix);
  }

  static final Float32List _tempRectData = Float32List(4);

  void clipRect(final ui.Rect rect, DrawCommand command) {
    double left = rect.left;
    double top = rect.top;
    double right = rect.right;
    double bottom = rect.bottom;

    // If we have an active transform, calculate screen relative clipping
    // rectangle and union with current clipping rectangle.
    if (!_currentMatrixIsIdentity) {
      _tempRectData[0] = left;
      _tempRectData[1] = top;
      _tempRectData[2] = right;
      _tempRectData[3] = bottom;

      transformLTRB(_currentMatrix, _tempRectData);
      left = _tempRectData[0];
      top = _tempRectData[1];
      right = _tempRectData[2];
      bottom = _tempRectData[3];
    }

    if (!_clipRectInitialized) {
      _currentClipLeft = left;
      _currentClipTop = top;
      _currentClipRight = right;
      _currentClipBottom = bottom;
      _clipRectInitialized = true;
    } else {
      if (left > _currentClipLeft) {
        _currentClipLeft = left;
      }
      if (top > _currentClipTop) {
        _currentClipTop = top;
      }
      if (right < _currentClipRight) {
        _currentClipRight = right;
      }
      if (bottom < _currentClipBottom) {
        _currentClipBottom = bottom;
      }
    }
    if (_currentClipLeft >= _currentClipRight || _currentClipTop >= _currentClipBottom) {
      command.isClippedOut = true;
    } else {
      command.leftBound = _currentClipLeft;
      command.topBound = _currentClipTop;
      command.rightBound = _currentClipRight;
      command.bottomBound = _currentClipBottom;
    }
  }

  /// Grow painted area to include given rectangle.
  void grow(ui.Rect r, DrawCommand command) {
    growLTRB(r.left, r.top, r.right, r.bottom, command);
  }

  /// Grow painted area to include given rectangle.
  void growLTRB(double left, double top, double right, double bottom, DrawCommand command) {
    if (left == right || top == bottom) {
      command.isClippedOut = true;
      return;
    }

    double transformedPointLeft = left;
    double transformedPointTop = top;
    double transformedPointRight = right;
    double transformedPointBottom = bottom;

    if (!_currentMatrixIsIdentity) {
      _tempRectData[0] = left;
      _tempRectData[1] = top;
      _tempRectData[2] = right;
      _tempRectData[3] = bottom;

      transformLTRB(_currentMatrix, _tempRectData);
      transformedPointLeft = _tempRectData[0];
      transformedPointTop = _tempRectData[1];
      transformedPointRight = _tempRectData[2];
      transformedPointBottom = _tempRectData[3];
    }

    if (_clipRectInitialized) {
      if (transformedPointLeft > _currentClipRight) {
        command.isClippedOut = true;
        return;
      }
      if (transformedPointRight < _currentClipLeft) {
        command.isClippedOut = true;
        return;
      }
      if (transformedPointTop > _currentClipBottom) {
        command.isClippedOut = true;
        return;
      }
      if (transformedPointBottom < _currentClipTop) {
        command.isClippedOut = true;
        return;
      }
      if (transformedPointLeft < _currentClipLeft) {
        transformedPointLeft = _currentClipLeft;
      }
      if (transformedPointRight > _currentClipRight) {
        transformedPointRight = _currentClipRight;
      }
      if (transformedPointTop < _currentClipTop) {
        transformedPointTop = _currentClipTop;
      }
      if (transformedPointBottom > _currentClipBottom) {
        transformedPointBottom = _currentClipBottom;
      }
    }

    command.leftBound = transformedPointLeft;
    command.topBound = transformedPointTop;
    command.rightBound = transformedPointRight;
    command.bottomBound = transformedPointBottom;

    if (_didPaintInsideClipArea) {
      _left = math.min(
          math.min(_left, transformedPointLeft), transformedPointRight);
      _right = math.max(
          math.max(_right, transformedPointLeft), transformedPointRight);
      _top =
          math.min(math.min(_top, transformedPointTop), transformedPointBottom);
      _bottom = math.max(
          math.max(_bottom, transformedPointTop), transformedPointBottom);
    } else {
      _left = math.min(transformedPointLeft, transformedPointRight);
      _right = math.max(transformedPointLeft, transformedPointRight);
      _top = math.min(transformedPointTop, transformedPointBottom);
      _bottom = math.max(transformedPointTop, transformedPointBottom);
    }
    _didPaintInsideClipArea = true;
  }

  void saveTransformsAndClip() {
    _clipStack ??= <ui.Rect>[];
    _transforms ??= <Matrix4>[];
    _transforms.add(_currentMatrix?.clone());
    _clipStack.add(_clipRectInitialized
        ? ui.Rect.fromLTRB(_currentClipLeft, _currentClipTop, _currentClipRight,
            _currentClipBottom)
        : null);
  }

  void restoreTransformsAndClip() {
    _currentMatrix = _transforms.removeLast();
    final ui.Rect clipRect = _clipStack.removeLast();
    if (clipRect != null) {
      _currentClipLeft = clipRect.left;
      _currentClipTop = clipRect.top;
      _currentClipRight = clipRect.right;
      _currentClipBottom = clipRect.bottom;
      _clipRectInitialized = true;
    } else if (_clipRectInitialized) {
      _clipRectInitialized = false;
    }
  }

  ui.Rect computeBounds() {
    if (!_didPaintInsideClipArea) {
      return ui.Rect.zero;
    }

    // The framework may send us NaNs in the case when it attempts to invert an
    // infinitely size rect.
    final double maxLeft = maxPaintBounds.left.isNaN
        ? double.negativeInfinity
        : maxPaintBounds.left;
    final double maxRight =
        maxPaintBounds.right.isNaN ? double.infinity : maxPaintBounds.right;
    final double maxTop =
        maxPaintBounds.top.isNaN ? double.negativeInfinity : maxPaintBounds.top;
    final double maxBottom =
        maxPaintBounds.bottom.isNaN ? double.infinity : maxPaintBounds.bottom;

    final double left = math.min(_left, _right);
    final double right = math.max(_left, _right);
    final double top = math.min(_top, _bottom);
    final double bottom = math.max(_top, _bottom);

    if (right < maxLeft || bottom < maxTop) {
      // Computed and max bounds do not intersect.
      return ui.Rect.zero;
    }

    return ui.Rect.fromLTRB(
      math.max(left, maxLeft),
      math.max(top, maxTop),
      math.min(right, maxRight),
      math.min(bottom, maxBottom),
    );
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      final ui.Rect bounds = computeBounds();
      return '_PaintBounds($bounds of size ${bounds.size})';
    } else {
      return super.toString();
    }
  }
}

/// Computes the length of the visual effect caused by paint parameters, such
/// as blur and stroke width.
///
/// This paint spread should be taken into accound when estimating bounding
/// boxes for paint operations that apply the paint.
double _getPaintSpread(SurfacePaint paint) {
  double spread = 0.0;
  final ui.MaskFilter maskFilter = paint?.maskFilter;
  if (maskFilter != null) {
    // Multiply by 2 because the sigma is the standard deviation rather than
    // the length of the blur.
    // See also: https://developer.mozilla.org/en-US/docs/Web/CSS/filter-function/blur
    spread += maskFilter.webOnlySigma * 2.0;
  }
  if (paint.strokeWidth != null && paint.strokeWidth != 0) {
    // The multiplication by sqrt(2) is to account for line joints that
    // meet at 90-degree angle. Division by 2 is because only half of the
    // stroke is sticking out of the original shape. The other half is
    // inside the shape.
    const double sqrtOfTwoDivByTwo = 0.70710678118;
    spread += paint.strokeWidth * sqrtOfTwoDivByTwo;
  }
  return spread;
}
