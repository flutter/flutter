// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A raw HTML canvas that is directly written to.
class BitmapCanvas extends EngineCanvas with SaveStackTracking {
  /// The rectangle positioned relative to the parent layer's coordinate
  /// system's origin, within which this canvas paints.
  ///
  /// Painting outside these bounds will result in cropping.
  ui.Rect get bounds => _bounds;
  set bounds(ui.Rect newValue) {
    assert(newValue != null);
    _bounds = newValue;
  }

  ui.Rect _bounds;

  /// The amount of padding to add around the edges of this canvas to
  /// ensure that anti-aliased arcs are not clipped.
  static const int paddingPixels = 1;

  @override
  final html.Element rootElement = html.Element.tag('flt-canvas');

  html.CanvasElement _canvas;
  html.CanvasRenderingContext2D _ctx;

  /// The size of the paint [bounds].
  ui.Size get size => _bounds.size;

  /// The last paragraph style is cached to optimize the case where the style
  /// hasn't changed.
  ParagraphGeometricStyle _cachedLastStyle;

  /// List of extra sibling elements created for paragraphs and clipping.
  final List<html.Element> _children = <html.Element>[];

  /// The number of pixels along the width of the bitmap that the canvas element
  /// renders into.
  ///
  /// These pixels are different from the logical CSS pixels. Here a pixel
  /// literally means 1 point with a RGBA color.
  int get widthInBitmapPixels => _widthInBitmapPixels;
  int _widthInBitmapPixels;

  /// The number of pixels along the width of the bitmap that the canvas element
  /// renders into.
  ///
  /// These pixels are different from the logical CSS pixels. Here a pixel
  /// literally means 1 point with a RGBA color.
  int get heightInBitmapPixels => _heightInBitmapPixels;
  int _heightInBitmapPixels;

  /// The number of pixels in the bitmap that the canvas element renders into.
  ///
  /// These pixels are different from the logical CSS pixels. Here a pixel
  /// literally means 1 point with a RGBA color.
  int get bitmapPixelCount => widthInBitmapPixels * heightInBitmapPixels;

  int _saveCount = 0;

  /// Keeps track of what device pixel ratio was used when this [BitmapCanvas]
  /// was created.
  final double _devicePixelRatio = html.window.devicePixelRatio;

  // Cached current filter, fill and stroke style to reduce updates to
  // CanvasRenderingContext2D that are slow even when resetting to null.
  String _prevFilter = 'none';
  Object _prevFillStyle;
  Object _prevStrokeStyle;

  /// Allocates a canvas with enough memory to paint a picture within the given
  /// [bounds].
  ///
  /// This canvas can be reused by pictures with different paint bounds as long
  /// as the [Rect.size] of the bounds fully fit within the size used to
  /// initialize this canvas.
  BitmapCanvas(this._bounds) : assert(_bounds != null) {
    rootElement.style.position = 'absolute';

    // Adds one extra pixel to the requested size. This is to compensate for
    // _initializeViewport() snapping canvas position to 1 pixel, causing
    // painting to overflow by at most 1 pixel.
    final double boundsWidth = size.width + 1 + 2 * paddingPixels;
    final double boundsHeight = size.height + 1 + 2 * paddingPixels;
    _widthInBitmapPixels = (boundsWidth * html.window.devicePixelRatio).ceil();
    _heightInBitmapPixels =
        (boundsHeight * html.window.devicePixelRatio).ceil();

    // Compute the final CSS canvas size given the actual pixel count we
    // allocated. This is done for the following reasons:
    //
    // * To satisfy the invariant: pixel size = css size * device pixel ratio.
    // * To make sure that when we scale the canvas by devicePixelRatio (see
    //   _initializeViewport below) the pixels line up.
    final double cssWidth = _widthInBitmapPixels / html.window.devicePixelRatio;
    final double cssHeight =
        _heightInBitmapPixels / html.window.devicePixelRatio;

    _canvas = html.CanvasElement(
      width: _widthInBitmapPixels,
      height: _heightInBitmapPixels,
    );
    _canvas.style
      ..position = 'absolute'
      ..width = '${cssWidth}px'
      ..height = '${cssHeight}px';
    _ctx = _canvas.context2D;
    rootElement.append(_canvas);
    _initializeViewport();
  }

  @override
  void dispose() {
    super.dispose();
    // Webkit has a threshold for the amount of canvas pixels an app can
    // allocate. Even though our canvases are being garbage-collected as
    // expected when we don't need them, Webkit keeps track of their sizes
    // towards the threshold. Setting width and height to zero tricks Webkit
    // into thinking that this canvas has a zero size so it doesn't count it
    // towards the threshold.
    if (browserEngine == BrowserEngine.webkit) {
      _canvas.width = _canvas.height = 0;
    }
  }

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    super.clear();
    final int len = _children.length;
    for (int i = 0; i < len; i++) {
      _children[i].remove();
    }
    _children.clear();
    _cachedLastStyle = null;
    // Restore to the state where we have only applied the scaling.
    if (_ctx != null) {
      _ctx.restore();
      _ctx.clearRect(0, 0, _widthInBitmapPixels, _heightInBitmapPixels);
      try {
        _ctx.font = '';
      } catch (e) {
        // Firefox may explode here:
        // https://bugzilla.mozilla.org/show_bug.cgi?id=941146
        if (!_isNsErrorFailureException(e)) {
          rethrow;
        }
      }
      _initializeViewport();
    }
    if (_canvas != null) {
      _canvas.style.transformOrigin = '';
      _canvas.style.transform = '';
    }
  }

  /// Checks whether this [BitmapCanvas] can still be recycled and reused.
  ///
  /// See also:
  ///
  /// * [PersistedStandardPicture._applyBitmapPaint] which uses this method to
  ///   decide whether to reuse this canvas or not.
  /// * [PersistedStandardPicture._recycleCanvas] which also uses this method
  ///   for the same reason.
  bool isReusable() {
    return _devicePixelRatio == html.window.devicePixelRatio;
  }

  /// Configures the canvas such that its coordinate system follows the scene's
  /// coordinate system, and the pixel ratio is applied such that CSS pixels are
  /// translated to bitmap pixels.
  void _initializeViewport() {
    // Save the canvas state with top-level transforms so we can undo
    // any clips later when we reuse the canvas.
    _ctx.save();

    // We always start with identity transform because the surrounding transform
    // is applied on the DOM elements.
    _ctx.setTransform(1, 0, 0, 1, 0, 0);

    // This scale makes sure that 1 CSS pixel is translated to the correct
    // number of bitmap pixels.
    _ctx.scale(html.window.devicePixelRatio, html.window.devicePixelRatio);

    // Flutter emits paint operations positioned relative to the parent layer's
    // coordinate system. However, canvas' coordinate system's origin is always
    // in the top-left corner of the canvas. We therefore need to inject an
    // initial translation so the paint operations are positioned as expected.

    // The flooring of the value is to ensure that canvas' top-left corner
    // lands on the physical pixel.
    final int canvasPositionX = _bounds.left.floor() - paddingPixels;
    final int canvasPositionY = _bounds.top.floor() - paddingPixels;
    final double canvasPositionCorrectionX =
        _bounds.left - paddingPixels - canvasPositionX.toDouble();
    final double canvasPositionCorrectionY =
        _bounds.top - paddingPixels - canvasPositionY.toDouble();

    rootElement.style.transform =
        'translate(${canvasPositionX}px, ${canvasPositionY}px)';

    // This compensates for the translate on the `rootElement`.
    translate(
      -_bounds.left + canvasPositionCorrectionX + paddingPixels,
      -_bounds.top + canvasPositionCorrectionY + paddingPixels,
    );
  }

  /// The `<canvas>` element used by this bitmap canvas.
  html.CanvasElement get canvas => _canvas;

  /// The 2D context of the `<canvas>` element used by this bitmap canvas.
  html.CanvasRenderingContext2D get ctx => _ctx;

  /// Sets the global paint styles to correspond to [paint].
  void _applyPaint(ui.PaintData paint) {
    ctx.globalCompositeOperation =
        _stringForBlendMode(paint.blendMode) ?? 'source-over';
    ctx.lineWidth = paint.strokeWidth ?? 1.0;
    final ui.StrokeCap cap = paint.strokeCap;
    if (cap != null) {
      ctx.lineCap = _stringForStrokeCap(cap);
    } else {
      ctx.lineCap = 'butt';
    }
    final ui.StrokeJoin join = paint.strokeJoin;
    if (join != null) {
      ctx.lineJoin = _stringForStrokeJoin(join);
    } else {
      ctx.lineJoin = 'miter';
    }
    if (paint.shader != null) {
      final EngineGradient engineShader = paint.shader;
      final Object paintStyle = engineShader.createPaintStyle(ctx);
      _setFillAndStrokeStyle(paintStyle, paintStyle);
    } else if (paint.color != null) {
      final String colorString = paint.color.toCssString();
      _setFillAndStrokeStyle(colorString, colorString);
    }
    if (paint.maskFilter != null) {
      _setFilter('blur(${paint.maskFilter.webOnlySigma}px)');
    }
  }

  void _strokeOrFill(ui.PaintData paint, {bool resetPaint = true}) {
    switch (paint.style) {
      case ui.PaintingStyle.stroke:
        ctx.stroke();
        break;
      case ui.PaintingStyle.fill:
      default:
        ctx.fill();
        break;
    }
    if (resetPaint) {
      _resetPaint();
    }
  }

  /// Resets the paint styles that were set due to a previous paint command.
  ///
  /// For example, if a previous paint commands has a blur filter, we need to
  /// undo that filter here.
  ///
  /// This needs to be called after [_applyPaint].
  void _resetPaint() {
    _setFilter('none');
    _setFillAndStrokeStyle(null, null);
  }

  void _setFilter(String value) {
    if (_prevFilter != value) {
      _prevFilter = ctx.filter = value;
    }
  }

  void _setFillAndStrokeStyle(Object fillStyle, Object strokeStyle) {
    final html.CanvasRenderingContext2D _ctx = ctx;
    if (!identical(_prevFillStyle, fillStyle)) {
      _prevFillStyle = _ctx.fillStyle = fillStyle;
    }
    if (!identical(_prevStrokeStyle, strokeStyle)) {
      _prevStrokeStyle = _ctx.strokeStyle = strokeStyle;
    }
  }

  @override
  int save() {
    super.save();
    ctx.save();
    return _saveCount++;
  }

  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    save();
  }

  @override
  void restore() {
    super.restore();
    ctx.restore();
    _saveCount--;
    _cachedLastStyle = null;
  }

  // TODO(yjbanov): not sure what this is attempting to do, but it is probably
  //                wrong because some clips and transforms are expressed using
  //                HTML DOM elements.
  void restoreToCount(int count) {
    assert(_saveCount >= count);
    final int restores = _saveCount - count;
    for (int i = 0; i < restores; i++) {
      ctx.restore();
    }
    _saveCount = count;
  }

  @override
  void translate(double dx, double dy) {
    super.translate(dx, dy);
    ctx.translate(dx, dy);
  }

  @override
  void scale(double sx, double sy) {
    super.scale(sx, sy);
    ctx.scale(sx, sy);
  }

  @override
  void rotate(double radians) {
    super.rotate(radians);
    ctx.rotate(radians);
  }

  @override
  void skew(double sx, double sy) {
    super.skew(sx, sy);
    ctx.transform(1, sy, sx, 1, 0, 0);
    //            |  |   |   |  |  |
    //            |  |   |   |  |  f - vertical translation
    //            |  |   |   |  e - horizontal translation
    //            |  |   |   d - vertical scaling
    //            |  |   c - horizontal skewing
    //            |  b - vertical skewing
    //            a - horizontal scaling
    //
    // Source: https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform
  }

  @override
  void transform(Float64List matrix4) {
    super.transform(matrix4);

    // Canvas2D transform API:
    //
    // ctx.transform(a, b, c, d, e, f);
    //
    // In 3x3 matrix form assuming vector representation of (x, y, 1):
    //
    // a c e
    // b d f
    // 0 0 1
    //
    // This translates to 4x4 matrix with vector representation of (x, y, z, 1)
    // as:
    //
    // a c 0 e
    // b d 0 f
    // 0 0 1 0
    // 0 0 0 1
    //
    // This matrix is sufficient to represent 2D rotates, translates, scales,
    // and skews.
    _ctx.transform(
      matrix4[0],
      matrix4[1],
      matrix4[4],
      matrix4[5],
      matrix4[12],
      matrix4[13],
    );
  }

  @override
  void clipRect(ui.Rect rect) {
    super.clipRect(rect);
    ctx.beginPath();
    ctx.rect(rect.left, rect.top, rect.width, rect.height);
    ctx.clip();
  }

  @override
  void clipRRect(ui.RRect rrect) {
    super.clipRRect(rrect);
    final ui.Path path = ui.Path()..addRRect(rrect);
    _runPath(path);
    ctx.clip();
  }

  @override
  void clipPath(ui.Path path) {
    super.clipPath(path);
    _runPath(path);
    ctx.clip();
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    ctx.globalCompositeOperation = _stringForBlendMode(blendMode);

    // Fill a virtually infinite rect with the color.
    //
    // We can't use (0, 0, width, height) because the current transform can
    // cause it to not fill the entire clip.
    ctx.fillRect(-10000, -10000, 20000, 20000);
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.PaintData paint) {
    _applyPaint(paint);
    ctx.beginPath();
    ctx.moveTo(p1.dx, p1.dy);
    ctx.lineTo(p2.dx, p2.dy);
    ctx.stroke();
    _resetPaint();
  }

  @override
  void drawPaint(ui.PaintData paint) {
    _applyPaint(paint);
    ctx.beginPath();

    // Fill a virtually infinite rect with the color.
    //
    // We can't use (0, 0, width, height) because the current transform can
    // cause it to not fill the entire clip.
    ctx.fillRect(-10000, -10000, 20000, 20000);
    _resetPaint();
  }

  @override
  void drawRect(ui.Rect rect, ui.PaintData paint) {
    _applyPaint(paint);
    ctx.beginPath();
    ctx.rect(rect.left, rect.top, rect.width, rect.height);
    _strokeOrFill(paint);
  }

  @override
  void drawRRect(ui.RRect rrect, ui.PaintData paint) {
    _applyPaint(paint);
    _RRectToCanvasRenderer(ctx).render(rrect);
    _strokeOrFill(paint);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.PaintData paint) {
    _applyPaint(paint);
    _RRectRenderer renderer = _RRectToCanvasRenderer(ctx);
    renderer.render(outer);
    renderer.render(inner, startNewPath: false, reverse: true);
    _strokeOrFill(paint);
  }

  @override
  void drawOval(ui.Rect rect, ui.PaintData paint) {
    _applyPaint(paint);
    ctx.beginPath();
    ctx.ellipse(rect.center.dx, rect.center.dy, rect.width / 2, rect.height / 2,
        0, 0, 2.0 * math.pi, false);
    _strokeOrFill(paint);
  }

  @override
  void drawCircle(ui.Offset c, double radius, ui.PaintData paint) {
    _applyPaint(paint);
    ctx.beginPath();
    ctx.ellipse(c.dx, c.dy, radius, radius, 0, 0, 2.0 * math.pi, false);
    _strokeOrFill(paint);
  }

  @override
  void drawPath(ui.Path path, ui.PaintData paint) {
    _applyPaint(paint);
    _runPath(path);
    _strokeOrFill(paint);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    final List<CanvasShadow> shadows =
        ElevationShadow.computeCanvasShadows(elevation, color);
    if (shadows.isNotEmpty) {
      for (final CanvasShadow shadow in shadows) {
        // TODO(het): Shadows with transparent occluders are not supported
        // on webkit since filter is unsupported.
        if (transparentOccluder && browserEngine != BrowserEngine.webkit) {
          // We paint shadows using a path and a mask filter instead of the
          // built-in shadow* properties. This is because the color alpha of the
          // paint is added to the shadow. The effect we're looking for is to just
          // paint the shadow without the path itself, but if we use a non-zero
          // alpha for the paint the path is painted in addition to the shadow,
          // which is undesirable.
          final ui.Paint paint = ui.Paint()
            ..color = shadow.color
            ..style = ui.PaintingStyle.fill
            ..strokeWidth = 0.0
            ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadow.blur);
          _ctx.save();
          _ctx.translate(shadow.offsetX, shadow.offsetY);
          final ui.PaintData paintData = paint.webOnlyPaintData;
          _applyPaint(paintData);
          _runPath(path);
          _strokeOrFill(paintData, resetPaint: false);
          _ctx.restore();
        } else {
          // TODO(het): We fill the path with this paint, then later we clip
          // by the same path and fill it with a fully opaque color (we know
          // the color is fully opaque because `transparentOccluder` is false.
          // However, due to anti-aliasing of the clip, a few pixels of the
          // path we are about to paint may still be visible after we fill with
          // the opaque occluder. For that reason, we fill with the shadow color,
          // and set the shadow color to fully opaque. This way, the visible
          // pixels are less opaque and less noticeable.
          final ui.Paint paint = ui.Paint()
            ..color = shadow.color
            ..style = ui.PaintingStyle.fill
            ..strokeWidth = 0.0;
          _ctx.save();
          final ui.PaintData paintData = paint.webOnlyPaintData;
          _applyPaint(paintData);
          _ctx.shadowBlur = shadow.blur;
          _ctx.shadowColor = shadow.color.withAlpha(0xff).toCssString();
          _ctx.shadowOffsetX = shadow.offsetX;
          _ctx.shadowOffsetY = shadow.offsetY;
          _runPath(path);
          _strokeOrFill(paintData, resetPaint: false);
          _ctx.restore();
        }
      }
      _resetPaint();
    }
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, ui.PaintData paint) {
    _applyPaint(paint);
    final HtmlImage htmlImage = image;
    final html.Element imgElement = htmlImage.imgElement.clone(true);
    imgElement.style
      ..position = 'absolute'
      ..transform = 'translate(${p.dx}px, ${p.dy}px)';
    rootElement.append(imgElement);
  }

  @override
  void drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, ui.PaintData paint) {
    // TODO(het): Check if the src rect is the entire image, and if so just
    // append the imgElement and set it's height and width.
    final HtmlImage htmlImage = image;
    ctx.drawImageScaledFromSource(
      htmlImage.imgElement,
      src.left,
      src.top,
      src.width,
      src.height,
      dst.left,
      dst.top,
      dst.width,
      dst.height,
    );
  }

  void _drawTextLine(
      ParagraphGeometricStyle style, String line, double x, double y) {
    final double letterSpacing = style.letterSpacing;
    if (letterSpacing == null || letterSpacing == 0.0) {
      ctx.fillText(line, x, y);
    } else {
      // When letter-spacing is set, we go through a more expensive code path
      // that renders each character separately with the correct spacing
      // between them.
      //
      // We are drawing letter spacing like the web does it, by adding the
      // spacing after each letter. This is different from Flutter which puts
      // the spacing around each letter i.e. for a 10px letter spacing, Flutter
      // would put 5px before each letter and 5px after it, but on the web, we
      // put no spacing before the letter and 10px after it. This is how the DOM
      // does it.
      final int len = line.length;
      for (int i = 0; i < len; i++) {
        final String char = line[i];
        ctx.fillText(char, x, y);
        x += letterSpacing + ctx.measureText(char).width;
      }
    }
  }

  @override
  void drawParagraph(EngineParagraph paragraph, ui.Offset offset) {
    assert(paragraph._isLaidOut);

    final ParagraphGeometricStyle style = paragraph._geometricStyle;

    if (paragraph._drawOnCanvas) {
      final List<String> lines =
          paragraph._lines ?? <String>[paragraph._plainText];

      final ui.PaintData backgroundPaint =
          paragraph._background?.webOnlyPaintData;
      if (backgroundPaint != null) {
        final ui.Rect rect = ui.Rect.fromLTWH(
            offset.dx, offset.dy, paragraph.width, paragraph.height);
        drawRect(rect, backgroundPaint);
      }

      if (style != _cachedLastStyle) {
        ctx.font = style.cssFontString;
        _cachedLastStyle = style;
      }
      _applyPaint(paragraph._paint.webOnlyPaintData);

      final double x = offset.dx + paragraph._alignOffset;
      double y = offset.dy + paragraph.alphabeticBaseline;
      final int len = lines.length;
      for (int i = 0; i < len; i++) {
        _drawTextLine(style, lines[i], x, y);
        y += paragraph._lineHeight;
      }
      _resetPaint();
      return;
    }

    final html.Element paragraphElement =
        _drawParagraphElement(paragraph, offset);

    if (isClipped) {
      final List<html.Element> clipElements =
          _clipContent(_clipStack, paragraphElement, offset, currentTransform);
      for (html.Element clipElement in clipElements) {
        rootElement.append(clipElement);
        _children.add(clipElement);
      }
    } else {
      final String cssTransform =
          matrix4ToCssTransform(transformWithOffset(currentTransform, offset));
      paragraphElement.style
        ..transformOrigin = '0 0 0'
        ..transform = cssTransform;
      rootElement.append(paragraphElement);
    }
    _children.add(paragraphElement);
  }

  /// Paints the [picture] into this canvas.
  void drawPicture(ui.Picture picture) {
    picture.recordingCanvas.apply(this);
  }

  // Vertex shader transforms pixel space [Vertices.positions] to
  // final clipSpace -1..1 coordinates with inverted Y Axis.
  static const _vertexShaderTriangle = '''
      #version 300 es
      layout (location=0) in vec4 position;
      layout (location=1) in vec4 color;
      uniform vec4 u_scale;
      uniform vec4 u_shift;
      out vec4 vColor;
      void main() {
        gl_Position = (position * u_scale) + u_shift;
        vColor = color.zyxw;
      }''';
  // This fragment shader enables Int32List of colors to be passed directly
  // to gl context buffer for rendering by decoding RGBA8888.
  static const _fragmentShaderTriangle = '''
      #version 300 es
      precision highp float;
      in vec4 vColor;
      out vec4 fragColor;
      void main() {
        fragColor = vColor;
      }''';

  // WebGL 1 version of shaders above for compatibility with Safari.
  static const _vertexShaderTriangleEs1 = '''
      attribute vec4 position;
      attribute vec4 color;
      uniform vec4 u_scale;
      uniform vec4 u_shift;
      varying vec4 vColor;
      void main() {
        gl_Position = (position * u_scale) + u_shift;
        vColor = color.zyxw;
      }''';
  // WebGL 1 version of shaders above for compatibility with Safari.
  static const _fragmentShaderTriangleEs1 = '''
      precision highp float;
      varying vec4 vColor;
      void main() {
        gl_FragColor = vColor;
      }''';

  /// Draws vertices on a gl context.
  ///
  /// If both colors and textures is specified in paint data,
  /// for [BlendMode.source] we skip colors and use textures,
  /// for [BlendMode.dst] we only use colors and ignore textures.
  /// We also skip paint shader when no texture is specified.
  ///
  /// If no colors or textures are specified, stroke hairlines with
  /// [Paint.color].
  ///
  /// If colors is specified, convert colors to premultiplied (alpha) colors
  /// and use a SkTriColorShader to render.
  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, ui.PaintData paint) {
    // TODO(flutter_web): Implement shaders for [Paint.shader] and
    // blendMode. https://github.com/flutter/flutter/issues/40096
    // Move rendering to OffscreenCanvas so that transform is preserved
    // as well.
    assert(paint.shader == null,
        'Linear/Radial/SweepGradient and ImageShader not supported yet');
    assert(blendMode == ui.BlendMode.srcOver);
    final Int32List colors = vertices.colors;
    final ui.VertexMode mode = vertices.mode;
    if (colors == null) {
      final Float32List positions = mode == ui.VertexMode.triangles
          ? vertices.positions
          : _convertVertexPositions(mode, vertices.positions);
      // Draw hairline for vertices if no vertex colors are specified.
      _drawHairline(positions, paint.color ?? ui.Color(0xFF000000));
      return;
    }

    final html.CanvasElement glCanvas = html.CanvasElement(
      width: _widthInBitmapPixels,
      height: _heightInBitmapPixels,
    );

    glCanvas.style
      ..position = 'absolute'
      ..width = _canvas.style.width
      ..height = _canvas.style.height;
    glCanvas.className = 'gl-canvas';

    _children.add(glCanvas);
    rootElement.append(glCanvas);

    final bool isWebKit = (browserEngine == BrowserEngine.webkit);
    _GlContext gl = _GlContext(glCanvas, isWebKit);
    // Create and compile shaders.
    Object vertexShader = gl.compileShader('VERTEX_SHADER',
        isWebKit ? _vertexShaderTriangleEs1 : _vertexShaderTriangle);
    Object fragmentShader = gl.compileShader('FRAGMENT_SHADER',
        isWebKit ? _fragmentShaderTriangleEs1 : _fragmentShaderTriangle);
    // Create a gl program and link shaders.
    Object program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    gl.useProgram(program);

    // Set uniform to scale 0..width/height pixels coordinates to -1..1
    // clipspace range and flip the Y axis.
    Object resolution = gl.getUniformLocation(program, 'u_scale');
    gl.setUniform4f(resolution, 2.0 / _widthInBitmapPixels.toDouble(),
        -2.0 / _heightInBitmapPixels.toDouble(), 1, 1);
    Object shift = gl.getUniformLocation(program, 'u_shift');
    gl.setUniform4f(shift, -1, 1, 0, 0);

    // Setup geometry.
    Object positionsBuffer = gl.createBuffer();
    assert(positionsBuffer != null);
    gl.bindArrayBuffer(positionsBuffer);
    final Float32List positions = vertices.positions;
    gl.bufferData(positions, gl.kStaticDraw);
    js_util.callMethod(
        gl.glContext, 'vertexAttribPointer', [0, 2, gl.kFloat, false, 0, 0]);
    gl.enableVertexAttribArray(0);

    // Setup color buffer.
    Object colorsBuffer = gl.createBuffer();
    gl.bindArrayBuffer(colorsBuffer);
    // Buffer kBGRA_8888.
    gl.bufferData(colors, gl.kStaticDraw);

    js_util.callMethod(gl.glContext, 'vertexAttribPointer',
        [1, 4, gl.kUnsignedByte, true, 0, 0]);
    gl.enableVertexAttribArray(1);
    gl.clear();
    final int vertexCount = positions.length ~/ 2;
    gl.drawTriangles(vertexCount, mode);
  }

  void _drawHairline(Float32List positions, ui.Color color) {
    assert(positions != null);
    html.CanvasRenderingContext2D _ctx = ctx;
    save();
    final int pointCount = positions.length ~/ 2;
    _setFillAndStrokeStyle('', color.toCssString());
    _ctx.lineWidth = 1.0;
    _ctx.beginPath();
    for (int i = 0, len = pointCount * 2; i < len;) {
      for (int triangleVertexIndex = 0;
          triangleVertexIndex < 3;
          triangleVertexIndex++, i += 2) {
        final double dx = positions[i];
        final double dy = positions[i + 1];
        switch (triangleVertexIndex) {
          case 0:
            _ctx.moveTo(dx, dy);
            break;
          case 1:
            _ctx.lineTo(dx, dy);
            break;
          case 2:
            _ctx.lineTo(dx, dy);
            _ctx.closePath();
            _ctx.stroke();
        }
      }
    }
    restore();
  }

  // Converts from [VertexMode] triangleFan and triangleStrip to triangles.
  Float32List _convertVertexPositions(
      ui.VertexMode mode, Float32List positions) {
    assert(mode != ui.VertexMode.triangles);
    if (mode == ui.VertexMode.triangleFan) {
      final int coordinateCount = positions.length ~/ 2;
      final int triangleCount = coordinateCount - 2;
      final Float32List triangleList = Float32List(triangleCount * 3 * 2);
      double centerX = positions[0];
      double centerY = positions[1];
      int destIndex = 0;
      int positionIndex = 2;
      for (int triangleIndex = 0;
          triangleIndex < triangleCount;
          triangleIndex++, positionIndex += 2) {
        triangleList[destIndex++] = centerX;
        triangleList[destIndex++] = centerY;
        triangleList[destIndex++] = positions[positionIndex];
        triangleList[destIndex++] = positions[positionIndex + 1];
        triangleList[destIndex++] = positions[positionIndex + 2];
        triangleList[destIndex++] = positions[positionIndex + 3];
      }
      return triangleList;
    } else {
      assert(mode == ui.VertexMode.triangleStrip);
      // Set of connected triangles. Each triangle shares 2 last vertices.
      final int vertexCount = positions.length ~/ 2;
      int triangleCount = vertexCount - 2;
      double x0 = positions[0];
      double y0 = positions[1];
      double x1 = positions[2];
      double y1 = positions[3];
      final Float32List triangleList = Float32List(triangleCount * 3 * 2);
      int destIndex = 0;
      for (int i = 0, positionIndex = 4; i < triangleCount; i++) {
        final double x2 = positions[positionIndex++];
        final double y2 = positions[positionIndex++];
        triangleList[destIndex++] = x0;
        triangleList[destIndex++] = y0;
        triangleList[destIndex++] = x1;
        triangleList[destIndex++] = y1;
        triangleList[destIndex++] = x2;
        triangleList[destIndex++] = y2;
        x0 = x1;
        y0 = y1;
        x1 = x2;
        y1 = y2;
      }
      return triangleList;
    }
  }

  /// 'Runs' the given [path] by applying all of its commands to the canvas.
  void _runPath(ui.Path path) {
    ctx.beginPath();
    for (Subpath subpath in path.subpaths) {
      for (PathCommand command in subpath.commands) {
        switch (command.type) {
          case PathCommandTypes.bezierCurveTo:
            final BezierCurveTo curve = command;
            ctx.bezierCurveTo(
                curve.x1, curve.y1, curve.x2, curve.y2, curve.x3, curve.y3);
            break;
          case PathCommandTypes.close:
            ctx.closePath();
            break;
          case PathCommandTypes.ellipse:
            final Ellipse ellipse = command;
            ctx.ellipse(
                ellipse.x,
                ellipse.y,
                ellipse.radiusX,
                ellipse.radiusY,
                ellipse.rotation,
                ellipse.startAngle,
                ellipse.endAngle,
                ellipse.anticlockwise);
            break;
          case PathCommandTypes.lineTo:
            final LineTo lineTo = command;
            ctx.lineTo(lineTo.x, lineTo.y);
            break;
          case PathCommandTypes.moveTo:
            final MoveTo moveTo = command;
            ctx.moveTo(moveTo.x, moveTo.y);
            break;
          case PathCommandTypes.rRect:
            final RRectCommand rrectCommand = command;
            _RRectToCanvasRenderer(ctx)
                .render(rrectCommand.rrect, startNewPath: false);
            break;
          case PathCommandTypes.rect:
            final RectCommand rectCommand = command;
            ctx.rect(rectCommand.x, rectCommand.y, rectCommand.width,
                rectCommand.height);
            break;
          case PathCommandTypes.quadraticCurveTo:
            final QuadraticCurveTo quadraticCurveTo = command;
            ctx.quadraticCurveTo(quadraticCurveTo.x1, quadraticCurveTo.y1,
                quadraticCurveTo.x2, quadraticCurveTo.y2);
            break;
          default:
            throw UnimplementedError('Unknown path command $command');
        }
      }
    }
  }
}

String _stringForBlendMode(ui.BlendMode blendMode) {
  if (blendMode == null) {
    return null;
  }
  switch (blendMode) {
    case ui.BlendMode.srcOver:
      return 'source-over';
    case ui.BlendMode.srcIn:
      return 'source-in';
    case ui.BlendMode.srcOut:
      return 'source-out';
    case ui.BlendMode.srcATop:
      return 'source-atop';
    case ui.BlendMode.dstOver:
      return 'destination-over';
    case ui.BlendMode.dstIn:
      return 'destination-in';
    case ui.BlendMode.dstOut:
      return 'destination-out';
    case ui.BlendMode.dstATop:
      return 'destination-atop';
    case ui.BlendMode.plus:
      return 'lighten';
    case ui.BlendMode.src:
      return 'copy';
    case ui.BlendMode.xor:
      return 'xor';
    case ui.BlendMode.multiply:
    // Falling back to multiply, ignoring alpha channel.
    // TODO(flutter_web): only used for debug, find better fallback for web.
    case ui.BlendMode.modulate:
      return 'multiply';
    case ui.BlendMode.screen:
      return 'screen';
    case ui.BlendMode.overlay:
      return 'overlay';
    case ui.BlendMode.darken:
      return 'darken';
    case ui.BlendMode.lighten:
      return 'lighten';
    case ui.BlendMode.colorDodge:
      return 'color-dodge';
    case ui.BlendMode.colorBurn:
      return 'color-burn';
    case ui.BlendMode.hardLight:
      return 'hard-light';
    case ui.BlendMode.softLight:
      return 'soft-light';
    case ui.BlendMode.difference:
      return 'difference';
    case ui.BlendMode.exclusion:
      return 'exclusion';
    case ui.BlendMode.hue:
      return 'hue';
    case ui.BlendMode.saturation:
      return 'saturation';
    case ui.BlendMode.color:
      return 'color';
    case ui.BlendMode.luminosity:
      return 'luminosity';
    default:
      throw UnimplementedError(
          'Flutter Web does not support the blend mode: $blendMode');
  }
}

String _stringForStrokeCap(ui.StrokeCap strokeCap) {
  if (strokeCap == null) {
    return null;
  }
  switch (strokeCap) {
    case ui.StrokeCap.butt:
      return 'butt';
    case ui.StrokeCap.round:
      return 'round';
    case ui.StrokeCap.square:
    default:
      return 'square';
  }
}

String _stringForStrokeJoin(ui.StrokeJoin strokeJoin) {
  assert(strokeJoin != null);
  switch (strokeJoin) {
    case ui.StrokeJoin.round:
      return 'round';
    case ui.StrokeJoin.bevel:
      return 'bevel';
    case ui.StrokeJoin.miter:
    default:
      return 'miter';
  }
}

/// Clips the content element against a stack of clip operations and returns
/// root of a tree that contains content node.
///
/// The stack of clipping rectangles generate an element that either uses
/// overflow:hidden with bounds to clip child or sets a clip-path to clip
/// it's contents. The clipping rectangles are nested and returned together
/// with a list of svg elements that provide clip-paths.
List<html.Element> _clipContent(List<_SaveClipEntry> clipStack,
    html.HtmlElement content, ui.Offset offset, Matrix4 currentTransform) {
  html.Element root, curElement;
  final List<html.Element> clipDefs = <html.Element>[];
  final int len = clipStack.length;
  for (int clipIndex = 0; clipIndex < len; clipIndex++) {
    final _SaveClipEntry entry = clipStack[clipIndex];
    final html.HtmlElement newElement = html.DivElement();
    if (root == null) {
      root = newElement;
    } else {
      domRenderer.append(curElement, newElement);
    }
    curElement = newElement;
    final ui.Rect rect = entry.rect;
    Matrix4 newClipTransform = entry.currentTransform;
    if (rect != null) {
      final double clipOffsetX = rect.left;
      final double clipOffsetY = rect.top;
      newClipTransform = newClipTransform.clone()
        ..translate(clipOffsetX, clipOffsetY);
      curElement.style
        ..overflow = 'hidden'
        ..transform = matrix4ToCssTransform(newClipTransform)
        ..transformOrigin = '0 0 0'
        ..width = '${rect.right - clipOffsetX}px'
        ..height = '${rect.bottom - clipOffsetY}px';
    } else if (entry.rrect != null) {
      final ui.RRect roundRect = entry.rrect;
      final String borderRadius =
          '${roundRect.tlRadiusX}px ${roundRect.trRadiusX}px '
          '${roundRect.brRadiusX}px ${roundRect.blRadiusX}px';
      final double clipOffsetX = roundRect.left;
      final double clipOffsetY = roundRect.top;
      newClipTransform = newClipTransform.clone()
        ..translate(clipOffsetX, clipOffsetY);
      curElement.style
        ..borderRadius = borderRadius
        ..overflow = 'hidden'
        ..transform = matrix4ToCssTransform(newClipTransform)
        ..transformOrigin = '0 0 0'
        ..width = '${roundRect.right - clipOffsetX}px'
        ..height = '${roundRect.bottom - clipOffsetY}px';
    } else if (entry.path != null) {
      curElement.style.transform = matrix4ToCssTransform(newClipTransform);
      final String svgClipPath = _pathToSvgClipPath(entry.path);
      final html.Element clipElement =
          html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
      domRenderer.setElementStyle(
          curElement, 'clip-path', 'url(#svgClip$_clipIdCounter)');
      domRenderer.setElementStyle(
          curElement, '-webkit-clip-path', 'url(#svgClip$_clipIdCounter)');
      clipDefs.add(clipElement);
    }
    // Reverse the transform of the clipping element so children can use
    // effective transform to render.
    // TODO(flutter_web): When we have more than a single clip element,
    // reduce number of div nodes by merging (multiplying transforms).
    final html.Element reverseTransformDiv = html.DivElement();
    reverseTransformDiv.style
      ..transform =
          _cssTransformAtOffset(newClipTransform.clone()..invert(), 0, 0)
      ..transformOrigin = '0 0 0';
    curElement.append(reverseTransformDiv);
    curElement = reverseTransformDiv;
  }

  root.style.position = 'absolute';
  domRenderer.append(curElement, content);
  content.style
    ..transformOrigin = '0 0 0'
    ..transform = _cssTransformAtOffset(currentTransform, offset.dx, offset.dy);
  return <html.Element>[root]..addAll(clipDefs);
}

String _cssTransformAtOffset(
    Matrix4 transform, double offsetX, double offsetY) {
  return matrix4ToCssTransform(
      transformWithOffset(transform, ui.Offset(offsetX, offsetY)));
}

/// JS Interop helper for webgl apis.
class _GlContext {
  final Object glContext;
  dynamic _kCompileStatus;
  dynamic _kArrayBuffer;
  dynamic _kStaticDraw;
  dynamic _kFloat;
  dynamic _kColorBufferBit;
  dynamic _kTriangles;
  dynamic _kLinkStatus;
  dynamic _kUnsignedByte;

  _GlContext(html.CanvasElement canvas, bool useWebGl1)
      : glContext = canvas.getContext(useWebGl1 ? 'webgl' : 'webgl2');

  Object compileShader(String shaderType, String source) {
    Object shader = _createShader(shaderType);
    js_util.callMethod(glContext, 'shaderSource', [shader, source]);
    js_util.callMethod(glContext, 'compileShader', [shader]);
    bool shaderStatus = js_util
        .callMethod(glContext, 'getShaderParameter', [shader, compileStatus]);
    if (!shaderStatus) {
      throw Exception('Shader compilation failed: ${getShaderInfoLog(shader)}');
    }
    return shader;
  }

  Object createProgram() =>
      js_util.callMethod(glContext, 'createProgram', const []);

  void attachShader(Object program, Object shader) {
    js_util.callMethod(glContext, 'attachShader', [program, shader]);
  }

  void linkProgram(Object program) {
    js_util.callMethod(glContext, 'linkProgram', [program]);
    if (!js_util
        .callMethod(glContext, 'getProgramParameter', [program, kLinkStatus])) {
      throw Exception(getProgramInfoLog(program));
    }
  }

  void useProgram(Object program) {
    js_util.callMethod(glContext, 'useProgram', [program]);
  }

  Object createBuffer() =>
      js_util.callMethod(glContext, 'createBuffer', const []);

  void bindArrayBuffer(Object buffer) {
    js_util.callMethod(glContext, 'bindBuffer', [kArrayBuffer, buffer]);
  }

  void bufferData(TypedData data, dynamic type) {
    js_util.callMethod(glContext, 'bufferData', [kArrayBuffer, data, type]);
  }

  void enableVertexAttribArray(int index) {
    js_util.callMethod(glContext, 'enableVertexAttribArray', [index]);
  }

  /// Clear background.
  void clear() {
    js_util.callMethod(glContext, 'clear', [kColorBufferBit]);
  }

  void drawTriangles(int triangleCount, ui.VertexMode vertexMode) {
    dynamic mode = _triangleTypeFromMode(vertexMode);
    js_util.callMethod(glContext, 'drawArrays', [mode, 0, triangleCount]);
  }

  /// Sets affine transformation from normalized device coordinates
  /// to window coordinates
  void viewport(double x, double y, double width, double height) {
    js_util.callMethod(glContext, 'viewport', [x, y, width, height]);
  }

  dynamic _triangleTypeFromMode(ui.VertexMode mode) {
    switch (mode) {
      case ui.VertexMode.triangles:
        return kTriangles;
        break;
      case ui.VertexMode.triangleFan:
        return kTriangleFan;
        break;
      case ui.VertexMode.triangleStrip:
        return kTriangleStrip;
        break;
    }
  }

  Object _createShader(String shaderType) => js_util.callMethod(
      glContext, 'createShader', [js_util.getProperty(glContext, shaderType)]);

  /// Error state of gl context.
  dynamic get error => js_util.callMethod(glContext, 'getError', const []);

  /// Shader compiler error, if this returns [kFalse], to get details use
  /// [getShaderInfoLog].
  dynamic get compileStatus =>
      _kCompileStatus ??= js_util.getProperty(glContext, 'COMPILE_STATUS');

  dynamic get kArrayBuffer =>
      _kArrayBuffer ??= js_util.getProperty(glContext, 'ARRAY_BUFFER');

  dynamic get kLinkStatus =>
      _kLinkStatus ??= js_util.getProperty(glContext, 'LINK_STATUS');

  dynamic get kFloat => _kFloat ??= js_util.getProperty(glContext, 'FLOAT');

  dynamic get kUnsignedByte =>
      _kUnsignedByte ??= js_util.getProperty(glContext, 'UNSIGNED_BYTE');

  dynamic get kStaticDraw =>
      _kStaticDraw ??= js_util.getProperty(glContext, 'STATIC_DRAW');

  dynamic get kTriangles =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLES');

  dynamic get kTriangleFan =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLE_FAN');

  dynamic get kTriangleStrip =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLE_STRIP');

  dynamic get kColorBufferBit =>
      _kColorBufferBit ??= js_util.getProperty(glContext, 'COLOR_BUFFER_BIT');

  /// Returns reference to uniform in program.
  Object getUniformLocation(Object program, String uniformName) {
    return js_util
        .callMethod(glContext, 'getUniformLocation', [program, uniformName]);
  }

  /// Sets vec2 uniform values.
  void setUniform2f(Object uniform, double value1, double value2) {
    return js_util
        .callMethod(glContext, 'uniform2f', [uniform, value1, value2]);
  }

  /// Sets vec4 uniform values.
  void setUniform4f(Object uniform, double value1, double value2, double value3,
      double value4) {
    return js_util.callMethod(
        glContext, 'uniform4f', [uniform, value1, value2, value3, value4]);
  }

  /// Shader compile error log.
  dynamic getShaderInfoLog(Object glShader) {
    return js_util.callMethod(glContext, 'getShaderInfoLog', [glShader]);
  }

  ///  Errors that occurred during failed linking or validation of program
  ///  objects. Typically called after [linkProgram].
  String getProgramInfoLog(Object glProgram) {
    return js_util.callMethod(glContext, 'getProgramInfoLog', [glProgram]);
  }
}
