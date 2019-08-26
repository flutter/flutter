// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Enable this to print every command applied by a canvas.
const bool _debugDumpPaintCommands = false;

/// Records canvas commands to be applied to a [EngineCanvas].
///
/// See [Canvas] for docs for these methods.
class RecordingCanvas {
  /// Maximum paintable bounds for this canvas.
  final _PaintBounds _paintBounds;
  final List<PaintCommand> _commands = <PaintCommand>[];

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

  /// Computes paint bounds based on estimated [bounds] and transforms.
  ui.Rect computePaintBounds() {
    return _paintBounds.computeBounds();
  }

  /// Applies the recorded commands onto an [engineCanvas].
  void apply(EngineCanvas engineCanvas) {
    if (_debugDumpPaintCommands) {
      final StringBuffer debugBuf = StringBuffer();
      debugBuf.writeln(
          '--- Applying RecordingCanvas to ${engineCanvas.runtimeType} '
          'with bounds $_paintBounds');
      for (int i = 0; i < _commands.length; i++) {
        final PaintCommand command = _commands[i];
        debugBuf.writeln('ctx.$command;');
        command.apply(engineCanvas);
      }
      debugBuf.writeln('--- End of command stream');
      print(debugBuf);
    } else {
      try {
        for (int i = 0; i < _commands.length; i++) {
          _commands[i].apply(engineCanvas);
        }
      } catch (e) {
        // commands should never fail, but...
        // https://bugzilla.mozilla.org/show_bug.cgi?id=941146
        if (!_isNsErrorFailureException(e)) {
          rethrow;
        }
      }
    }
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
    _paintBounds.saveTransformsAndClip();
    _commands.add(const PaintSave());
    saveCount++;
  }

  void saveLayerWithoutBounds(ui.Paint paint) {
    _hasArbitraryPaint = true;
    // TODO(het): Implement this correctly using another canvas.
    _commands.add(const PaintSave());
    _paintBounds.saveTransformsAndClip();
    saveCount++;
  }

  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    _hasArbitraryPaint = true;
    // TODO(het): Implement this correctly using another canvas.
    _commands.add(const PaintSave());
    _paintBounds.saveTransformsAndClip();
    saveCount++;
  }

  void restore() {
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
    saveCount--;
  }

  void translate(double dx, double dy) {
    _paintBounds.translate(dx, dy);
    _commands.add(PaintTranslate(dx, dy));
  }

  void scale(double sx, double sy) {
    _paintBounds.scale(sx, sy);
    _commands.add(PaintScale(sx, sy));
  }

  void rotate(double radians) {
    _paintBounds.rotateZ(radians);
    _commands.add(PaintRotate(radians));
  }

  void transform(Float64List matrix4) {
    _paintBounds.transform(matrix4);
    _commands.add(PaintTransform(matrix4));
  }

  void skew(double sx, double sy) {
    _hasArbitraryPaint = true;
    _paintBounds.skew(sx, sy);
    _commands.add(PaintSkew(sx, sy));
  }

  void clipRect(ui.Rect rect) {
    _paintBounds.clipRect(rect);
    _hasArbitraryPaint = true;
    _commands.add(PaintClipRect(rect));
  }

  void clipRRect(ui.RRect rrect) {
    _paintBounds.clipRect(rrect.outerRect);
    _hasArbitraryPaint = true;
    _commands.add(PaintClipRRect(rrect));
  }

  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    _paintBounds.clipRect(path.getBounds());
    _hasArbitraryPaint = true;
    _commands.add(PaintClipPath(path));
  }

  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    _paintBounds.grow(_paintBounds.maxPaintBounds);
    _commands.add(PaintDrawColor(color, blendMode));
  }

  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    final double strokeWidth = math.max(paint.strokeWidth, 1.0);
    // TODO(yjbanov): This can be optimized. Currently we create a box around
    //                the line and then apply the transform on the box to get
    //                the bounding box. If you have a 45-degree line and a
    //                45-degree transform, the bounding box should be the length
    //                of the line long and stroke width wide, but our current
    //                algorithm produces a square with each side of the length
    //                matching the length of the line.
    _paintBounds.growLTRB(
        math.min(p1.dx, p2.dx) - strokeWidth,
        math.min(p1.dy, p2.dy) - strokeWidth,
        math.max(p1.dx, p2.dx) + strokeWidth,
        math.max(p1.dy, p2.dy) + strokeWidth);
    _hasArbitraryPaint = true;
    _didDraw = true;
    _commands.add(PaintDrawLine(p1, p2, paint.webOnlyPaintData));
  }

  void drawPaint(ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    _paintBounds.grow(_paintBounds.maxPaintBounds);
    _commands.add(PaintDrawPaint(paint.webOnlyPaintData));
  }

  void drawRect(ui.Rect rect, ui.Paint paint) {
    if (paint.shader != null) {
      _hasArbitraryPaint = true;
    }
    _didDraw = true;
    if (paint.strokeWidth != null && paint.strokeWidth != 0) {
      _paintBounds.grow(rect.inflate(paint.strokeWidth / 2.0));
    } else {
      _paintBounds.grow(rect);
    }
    _commands.add(PaintDrawRect(rect, paint.webOnlyPaintData));
  }

  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double strokeWidth =
        paint.strokeWidth == null ? 0 : paint.strokeWidth;
    final double left = math.min(rrect.left, rrect.right) - strokeWidth;
    final double right = math.max(rrect.left, rrect.right) + strokeWidth;
    final double top = math.min(rrect.top, rrect.bottom) - strokeWidth;
    final double bottom = math.max(rrect.top, rrect.bottom) + strokeWidth;
    _paintBounds.growLTRB(left, top, right, bottom);
    _commands.add(PaintDrawRRect(rrect, paint.webOnlyPaintData));
  }

  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    // If inner rect is not contained inside outer, flutter engine skips
    // painting rectangle.
    if (!(outer.contains(ui.Offset(inner.left, inner.top)) &&
        outer.contains(ui.Offset(inner.right, inner.bottom)))) {
      return;
    }
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double strokeWidth =
        paint.strokeWidth == null ? 0 : paint.strokeWidth;
    _paintBounds.growLTRB(outer.left - strokeWidth, outer.top - strokeWidth,
        outer.right + strokeWidth, outer.bottom + strokeWidth);
    _commands.add(PaintDrawDRRect(outer, inner, paint.webOnlyPaintData));
  }

  void drawOval(ui.Rect rect, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    if (paint.strokeWidth != null) {
      _paintBounds.grow(rect.inflate(paint.strokeWidth));
    } else {
      _paintBounds.grow(rect);
    }
    _commands.add(PaintDrawOval(rect, paint.webOnlyPaintData));
  }

  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double strokeWidth =
        paint.strokeWidth == null ? 0 : paint.strokeWidth;
    _paintBounds.growLTRB(
        c.dx - radius - strokeWidth,
        c.dy - radius - strokeWidth,
        c.dx + radius + strokeWidth,
        c.dy + radius + strokeWidth);
    _commands.add(PaintDrawCircle(c, radius, paint.webOnlyPaintData));
  }

  void drawPath(ui.Path path, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    ui.Rect pathBounds = path.getBounds();
    if (paint.strokeWidth != null) {
      pathBounds = pathBounds.inflate(paint.strokeWidth);
    }
    _paintBounds.grow(pathBounds);
    // Clone path so it can be reused for subsequent draw calls.
    final ui.Path clone = ui.Path.from(path);
    clone.fillType = path.fillType;
    _commands.add(PaintDrawPath(clone, paint.webOnlyPaintData));
  }

  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    final double left = offset.dx;
    final double top = offset.dy;
    _paintBounds.growLTRB(left, top, left + image.width, top + image.height);
    _commands.add(PaintDrawImage(image, offset, paint.webOnlyPaintData));
  }

  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    _paintBounds.grow(dst);
    _commands.add(PaintDrawImageRect(image, src, dst, paint.webOnlyPaintData));
  }

  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
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
    _paintBounds.growLTRB(
        left, top, left + engineParagraph.width, top + engineParagraph.height);
    _commands.add(PaintDrawParagraph(engineParagraph, offset));
  }

  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    _hasArbitraryPaint = true;
    _didDraw = true;
    final ui.Rect shadowRect =
        ElevationShadow.computeShadowRect(path.getBounds(), elevation);
    _paintBounds.grow(shadowRect);
    _commands.add(PaintDrawShadow(path, color, elevation, transparentOccluder));
  }

  int saveCount = 1;

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
  final Float64List matrix4;

  PaintTransform(this.matrix4);

  @override
  void apply(EngineCanvas canvas) {
    canvas.transform(matrix4);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'transform(Matrix4.fromFloat64List(Float64List.fromList(<double>[${matrix4.join(', ')}])))';
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

class PaintClipRect extends PaintCommand {
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

class PaintClipRRect extends PaintCommand {
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

class PaintClipPath extends PaintCommand {
  final ui.Path path;

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

class PaintDrawColor extends PaintCommand {
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
    serializedCommands.add(<dynamic>[11, color.toCssString(), blendMode.index]);
  }
}

class PaintDrawLine extends PaintCommand {
  final ui.Offset p1;
  final ui.Offset p2;
  final ui.PaintData paint;

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

class PaintDrawPaint extends PaintCommand {
  final ui.PaintData paint;

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

class PaintDrawRect extends PaintCommand {
  final ui.Rect rect;
  final ui.PaintData paint;

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

class PaintDrawRRect extends PaintCommand {
  final ui.RRect rrect;
  final ui.PaintData paint;

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

class PaintDrawDRRect extends PaintCommand {
  final ui.RRect outer;
  final ui.RRect inner;
  final ui.PaintData paint;

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

class PaintDrawOval extends PaintCommand {
  final ui.Rect rect;
  final ui.PaintData paint;

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

class PaintDrawCircle extends PaintCommand {
  final ui.Offset c;
  final double radius;
  final ui.PaintData paint;

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

class PaintDrawPath extends PaintCommand {
  final ui.Path path;
  final ui.PaintData paint;

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

class PaintDrawShadow extends PaintCommand {
  PaintDrawShadow(
      this.path, this.color, this.elevation, this.transparentOccluder);

  final ui.Path path;
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

class PaintDrawImage extends PaintCommand {
  final ui.Image image;
  final ui.Offset offset;
  final ui.PaintData paint;

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

class PaintDrawImageRect extends PaintCommand {
  final ui.Image image;
  final ui.Rect src;
  final ui.Rect dst;
  final ui.PaintData paint;

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

class PaintDrawParagraph extends PaintCommand {
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

List<dynamic> _serializePaintToCssPaint(ui.PaintData paint) {
  final EngineGradient engineShader = paint.shader;
  return <dynamic>[
    paint.blendMode?.index,
    paint.style?.index,
    paint.strokeWidth,
    paint.strokeCap?.index,
    paint.isAntiAlias,
    paint.color.toCssString(),
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

  void transform(Float64List matrix4) {
    final Matrix4 m4 = Matrix4.fromFloat64List(matrix4);
    _currentMatrix.multiply(m4);
    _currentMatrixIsIdentity = _currentMatrix.isIdentity();
  }

  void skew(double sx, double sy) {
    _currentMatrixIsIdentity = false;

    // DO NOT USE Matrix4.skew(sx, sy)! It treats sx and sy values as radians,
    // but in our case they are transform matrix values.
    final Matrix4 skewMatrix = Matrix4.identity();
    final Float64List storage = skewMatrix.storage;
    storage[1] = sy;
    storage[4] = sx;
    _currentMatrix.multiply(skewMatrix);
  }

  void clipRect(ui.Rect rect) {
    // If we have an active transform, calculate screen relative clipping
    // rectangle and union with current clipping rectangle.
    if (!_currentMatrixIsIdentity) {
      final Vector3 leftTop =
          _currentMatrix.transform3(Vector3(rect.left, rect.top, 0.0));
      final Vector3 rightTop =
          _currentMatrix.transform3(Vector3(rect.right, rect.top, 0.0));
      final Vector3 leftBottom =
          _currentMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0));
      final Vector3 rightBottom =
          _currentMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0));
      rect = ui.Rect.fromLTRB(
          math.min(math.min(math.min(leftTop.x, rightTop.x), leftBottom.x),
              rightBottom.x),
          math.min(math.min(math.min(leftTop.y, rightTop.y), leftBottom.y),
              rightBottom.y),
          math.max(math.max(math.max(leftTop.x, rightTop.x), leftBottom.x),
              rightBottom.x),
          math.max(math.max(math.max(leftTop.y, rightTop.y), leftBottom.y),
              rightBottom.y));
    }
    if (!_clipRectInitialized) {
      _currentClipLeft = rect.left;
      _currentClipTop = rect.top;
      _currentClipRight = rect.right;
      _currentClipBottom = rect.bottom;
      _clipRectInitialized = true;
    } else {
      if (rect.left > _currentClipLeft) {
        _currentClipLeft = rect.left;
      }
      if (rect.top > _currentClipTop) {
        _currentClipTop = rect.top;
      }
      if (rect.right < _currentClipRight) {
        _currentClipRight = rect.right;
      }
      if (rect.bottom < _currentClipBottom) {
        _currentClipBottom = rect.bottom;
      }
    }
  }

  /// Grow painted area to include given rectangle.
  void grow(ui.Rect r) {
    growLTRB(r.left, r.top, r.right, r.bottom);
  }

  /// Grow painted area to include given rectangle.
  void growLTRB(double left, double top, double right, double bottom) {
    if (left == right || top == bottom) {
      return;
    }

    double transformedPointLeft = left;
    double transformedPointTop = top;
    double transformedPointRight = right;
    double transformedPointBottom = bottom;

    if (!_currentMatrixIsIdentity) {
      final ui.Rect transformedRect =
          transformLTRB(_currentMatrix, left, top, right, bottom);
      transformedPointLeft = transformedRect.left;
      transformedPointTop = transformedRect.top;
      transformedPointRight = transformedRect.right;
      transformedPointBottom = transformedRect.bottom;
    }

    if (_clipRectInitialized) {
      if (transformedPointLeft > _currentClipRight) {
        return;
      }
      if (transformedPointRight < _currentClipLeft) {
        return;
      }
      if (transformedPointTop > _currentClipBottom) {
        return;
      }
      if (transformedPointBottom < _currentClipTop) {
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
