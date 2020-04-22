// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A raw HTML canvas that is directly written to.
class BitmapCanvas extends EngineCanvas {
  /// The rectangle positioned relative to the parent layer's coordinate
  /// system's origin, within which this canvas paints.
  ///
  /// Painting outside these bounds will result in cropping.
  ui.Rect get bounds => _bounds;
  set bounds(ui.Rect newValue) {
    assert(newValue != null);
    _bounds = newValue;
    final int newCanvasPositionX = _bounds.left.floor() - kPaddingPixels;
    final int newCanvasPositionY = _bounds.top.floor() - kPaddingPixels;
    if (_canvasPositionX != newCanvasPositionX ||
        _canvasPositionY != newCanvasPositionY) {
      _canvasPositionX = newCanvasPositionX;
      _canvasPositionY = newCanvasPositionY;
      _updateRootElementTransform();
    }
  }

  ui.Rect _bounds;

  /// The amount of padding to add around the edges of this canvas to
  /// ensure that anti-aliased arcs are not clipped.
  static const int kPaddingPixels = 1;

  @override
  final html.Element rootElement = html.Element.tag('flt-canvas');

  final _CanvasPool _canvasPool;

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
  final int _widthInBitmapPixels;

  /// The number of pixels along the width of the bitmap that the canvas element
  /// renders into.
  ///
  /// These pixels are different from the logical CSS pixels. Here a pixel
  /// literally means 1 point with a RGBA color.
  final int _heightInBitmapPixels;

  /// The number of pixels in the bitmap that the canvas element renders into.
  ///
  /// These pixels are different from the logical CSS pixels. Here a pixel
  /// literally means 1 point with a RGBA color.
  int get bitmapPixelCount => _widthInBitmapPixels * _heightInBitmapPixels;

  int _saveCount = 0;

  /// Keeps track of what device pixel ratio was used when this [BitmapCanvas]
  /// was created.
  final double _devicePixelRatio = EngineWindow.browserDevicePixelRatio;

  // Compensation for [_initializeViewport] snapping canvas position to 1 pixel.
  int _canvasPositionX, _canvasPositionY;

  // Indicates the instructions following drawImage or drawParagraph that
  // a child element was created to paint.
  // TODO(flutter_web): When childElements are created by
  // drawImage/drawParagraph commands, compositing order is not correctly
  // handled when we interleave these with other paint commands.
  // To solve this, recording canvas will have to check the paint queue
  // and send a hint to EngineCanvas that additional canvas layers need
  // to be used to composite correctly. In practice this is very rare
  // with Widgets but CustomPainter(s) can hit this code path.
  bool _childOverdraw = false;

  /// Forces text to be drawn using HTML rather than bitmap.
  ///
  /// Use this for tests only.
  set debugChildOverdraw(bool value) {
    _childOverdraw = value;
  }

  /// Allocates a canvas with enough memory to paint a picture within the given
  /// [bounds].
  ///
  /// This canvas can be reused by pictures with different paint bounds as long
  /// as the [Rect.size] of the bounds fully fit within the size used to
  /// initialize this canvas.
  BitmapCanvas(this._bounds)
      : assert(_bounds != null),
        _widthInBitmapPixels = _widthToPhysical(_bounds.width),
        _heightInBitmapPixels = _heightToPhysical(_bounds.height),
        _canvasPool = _CanvasPool(_widthToPhysical(_bounds.width),
            _heightToPhysical(_bounds.height)) {
    rootElement.style.position = 'absolute';
    // Adds one extra pixel to the requested size. This is to compensate for
    // _initializeViewport() snapping canvas position to 1 pixel, causing
    // painting to overflow by at most 1 pixel.
    _canvasPositionX = _bounds.left.floor() - kPaddingPixels;
    _canvasPositionY = _bounds.top.floor() - kPaddingPixels;
    _updateRootElementTransform();
    _canvasPool.allocateCanvas(rootElement);
    _setupInitialTransform();
  }

  void _updateRootElementTransform() {
    // Flutter emits paint operations positioned relative to the parent layer's
    // coordinate system. However, canvas' coordinate system's origin is always
    // in the top-left corner of the canvas. We therefore need to inject an
    // initial translation so the paint operations are positioned as expected.
    //
    // The flooring of the value is to ensure that canvas' top-left corner
    // lands on the physical pixel. TODO: !This is not accurate if there are
    // transforms higher up in the stack.
    rootElement.style.transform =
        'translate(${_canvasPositionX}px, ${_canvasPositionY}px)';
  }

  void _setupInitialTransform() {
    final double canvasPositionCorrectionX = _bounds.left -
        BitmapCanvas.kPaddingPixels -
        _canvasPositionX.toDouble();
    final double canvasPositionCorrectionY =
        _bounds.top - BitmapCanvas.kPaddingPixels - _canvasPositionY.toDouble();
    // This compensates for the translate on the `rootElement`.
    _canvasPool.initialTransform = ui.Offset(
      -_bounds.left + canvasPositionCorrectionX + BitmapCanvas.kPaddingPixels,
      -_bounds.top + canvasPositionCorrectionY + BitmapCanvas.kPaddingPixels,
    );
  }

  static int _widthToPhysical(double width) {
    final double boundsWidth = width + 1;
    return (boundsWidth * EngineWindow.browserDevicePixelRatio).ceil() +
        2 * kPaddingPixels;
  }

  static int _heightToPhysical(double height) {
    final double boundsHeight = height + 1;
    return (boundsHeight * EngineWindow.browserDevicePixelRatio).ceil() +
        2 * kPaddingPixels;
  }

  // Used by picture to assess if canvas is large enough to reuse as is.
  bool doesFitBounds(ui.Rect newBounds) {
    assert(newBounds != null);
    return _widthInBitmapPixels >= _widthToPhysical(newBounds.width) &&
        _heightInBitmapPixels >= _heightToPhysical(newBounds.height);
  }

  @override
  void dispose() {
    _canvasPool.dispose();
  }

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    _canvasPool.clear();
    final int len = _children.length;
    for (int i = 0; i < len; i++) {
      _children[i].remove();
    }
    _children.clear();
    _cachedLastStyle = null;
    _setupInitialTransform();
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
    return _devicePixelRatio == EngineWindow.browserDevicePixelRatio;
  }

  /// Returns a data URI containing a representation of the image in this
  /// canvas.
  String toDataUrl() {
    return _canvasPool.toDataUrl();
  }

  /// Sets the global paint styles to correspond to [paint].
  void _applyPaint(SurfacePaintData paint) {
    ContextStateHandle contextHandle = _canvasPool.contextHandle;
    contextHandle
      ..lineWidth = paint.strokeWidth ?? 1.0
      ..blendMode = paint.blendMode
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..filter = _maskFilterToCss(paint.maskFilter);

    if (paint.shader != null) {
      final EngineGradient engineShader = paint.shader;
      final Object paintStyle =
          engineShader.createPaintStyle(_canvasPool.context);
      contextHandle.fillStyle = paintStyle;
      contextHandle.strokeStyle = paintStyle;
    } else if (paint.color != null) {
      final String colorString = colorToCssString(paint.color);
      contextHandle.fillStyle = colorString;
      contextHandle.strokeStyle = colorString;
    } else {
      contextHandle.fillStyle = '';
      contextHandle.strokeStyle = '';
    }
  }

  @override
  int save() {
    _canvasPool.save();
    return _saveCount++;
  }

  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    save();
  }

  @override
  void restore() {
    _canvasPool.restore();
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
      _canvasPool.restore();
    }
    _saveCount = count;
  }

  @override
  void translate(double dx, double dy) {
    _canvasPool.translate(dx, dy);
  }

  @override
  void scale(double sx, double sy) {
    _canvasPool.scale(sx, sy);
  }

  @override
  void rotate(double radians) {
    _canvasPool.rotate(radians);
  }

  @override
  void skew(double sx, double sy) {
    _canvasPool.skew(sx, sy);
  }

  @override
  void transform(Float32List matrix4) {
    _canvasPool.transform(matrix4);
  }

  @override
  void clipRect(ui.Rect rect) {
    _canvasPool.clipRect(rect);
  }

  @override
  void clipRRect(ui.RRect rrect) {
    _canvasPool.clipRRect(rrect);
  }

  @override
  void clipPath(ui.Path path) {
    _canvasPool.clipPath(path);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    _canvasPool.drawColor(color, blendMode);
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.strokeLine(p1, p2);
  }

  @override
  void drawPaint(SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.fill();
  }

  @override
  void drawRect(ui.Rect rect, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawRect(rect, paint.style);
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawRRect(rrect, paint.style);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawDRRect(outer, inner, paint.style);
  }

  @override
  void drawOval(ui.Rect rect, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawOval(rect, paint.style);
  }

  @override
  void drawCircle(ui.Offset c, double radius, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawCircle(c, radius, paint.style);
  }

  @override
  void drawPath(ui.Path path, SurfacePaintData paint) {
    _applyPaint(paint);
    _canvasPool.drawPath(path, paint.style);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    _canvasPool.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, SurfacePaintData paint) {
    _drawImage(image, p, paint);
    _childOverdraw = true;
    _canvasPool.closeCurrentCanvas();
  }

  html.ImageElement _drawImage(
      ui.Image image, ui.Offset p, SurfacePaintData paint) {
    final HtmlImage htmlImage = image;
    final html.Element imgElement = htmlImage.cloneImageElement();
    final ui.BlendMode blendMode = paint.blendMode;
    imgElement.style.mixBlendMode = _stringForBlendMode(blendMode);
    if (_canvasPool.isClipped) {
      // Reset width/height since they may have been previously set.
      imgElement.style..removeProperty('width')..removeProperty('height');
      final List<html.Element> clipElements = _clipContent(
          _canvasPool._clipStack, imgElement, p, _canvasPool.currentTransform);
      for (html.Element clipElement in clipElements) {
        rootElement.append(clipElement);
        _children.add(clipElement);
      }
    } else {
      final String cssTransform = float64ListToCssTransform(
          transformWithOffset(_canvasPool.currentTransform, p).storage);
      imgElement.style
        ..transformOrigin = '0 0 0'
        ..transform = cssTransform
        // Reset width/height since they may have been previously set.
        ..removeProperty('width')
        ..removeProperty('height');
      rootElement.append(imgElement);
      _children.add(imgElement);
    }
    return imgElement;
  }

  @override
  void drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, SurfacePaintData paint) {
    final bool requiresClipping = src.left != 0 ||
        src.top != 0 ||
        src.width != image.width ||
        src.height != image.height;
    if (dst.width == image.width &&
        dst.height == image.height &&
        !requiresClipping) {
      drawImage(image, dst.topLeft, paint);
    } else {
      if (requiresClipping) {
        save();
        clipRect(dst);
      }
      double targetLeft = dst.left;
      double targetTop = dst.top;
      if (requiresClipping) {
        if (src.width != image.width) {
          double leftMargin = -src.left * (dst.width / src.width);
          targetLeft += leftMargin;
        }
        if (src.height != image.height) {
          double topMargin = -src.top * (dst.height / src.height);
          targetTop += topMargin;
        }
      }

      final html.ImageElement imgElement =
          _drawImage(image, ui.Offset(targetLeft, targetTop), paint);
      // To scale set width / height on destination image.
      // For clipping we need to scale according to
      // clipped-width/full image width and shift it according to left/top of
      // source rectangle.
      double targetWidth = dst.width;
      double targetHeight = dst.height;
      if (requiresClipping) {
        targetWidth *= image.width / src.width;
        targetHeight *= image.height / src.height;
      }
      final html.CssStyleDeclaration imageStyle = imgElement.style;
      imageStyle
        ..width = '${targetWidth.toStringAsFixed(2)}px'
        ..height = '${targetHeight.toStringAsFixed(2)}px';
      if (requiresClipping) {
        restore();
      }
    }
    _closeCurrentCanvas();
  }

  // Should be called when we add new html elements into rootElement so that
  // paint order is preserved.
  //
  // For example if we draw a path and then a paragraph and image:
  //   - rootElement
  //   |--- <canvas>
  //   |--- <p>
  //   |--- <img>
  // Any drawing operations after these tags should allocate a new canvas,
  // instead of drawing into earlier canvas.
  void _closeCurrentCanvas() {
    _canvasPool.closeCurrentCanvas();
    _childOverdraw = true;
  }

  void _drawTextLine(
    ParagraphGeometricStyle style,
    EngineLineMetrics line,
    double x,
    double y,
  ) {
    html.CanvasRenderingContext2D ctx = _canvasPool.context;
    x += line.left;
    final double letterSpacing = style.letterSpacing;
    if (letterSpacing == null || letterSpacing == 0.0) {
      ctx.fillText(line.displayText, x, y);
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
      final int len = line.displayText.length;
      for (int i = 0; i < len; i++) {
        final String char = line.displayText[i];
        ctx.fillText(char, x, y);
        x += letterSpacing + ctx.measureText(char).width;
      }
    }
  }

  @override
  void drawParagraph(EngineParagraph paragraph, ui.Offset offset) {
    assert(paragraph._isLaidOut);
    final ParagraphGeometricStyle style = paragraph._geometricStyle;

    if (paragraph._drawOnCanvas && _childOverdraw == false) {
      // !Do not move this assignment above this if clause since, accessing
      // context will generate extra <canvas> tags.
      final List<EngineLineMetrics> lines = paragraph._measurementResult.lines;

      final SurfacePaintData backgroundPaint = paragraph._background?.paintData;
      if (backgroundPaint != null) {
        final ui.Rect rect = ui.Rect.fromLTWH(
            offset.dx, offset.dy, paragraph.width, paragraph.height);
        drawRect(rect, backgroundPaint);
      }

      if (style != _cachedLastStyle) {
        html.CanvasRenderingContext2D ctx = _canvasPool.context;
        ctx.font = style.cssFontString;
        _cachedLastStyle = style;
      }
      _applyPaint(paragraph._paint.paintData);

      double y = offset.dy + paragraph.alphabeticBaseline;
      final int len = lines.length;
      for (int i = 0; i < len; i++) {
        _drawTextLine(style, lines[i], offset.dx, y);
        y += paragraph._lineHeight;
      }
      return;
    }

    final html.Element paragraphElement =
        _drawParagraphElement(paragraph, offset);
    if (_canvasPool.isClipped) {
      final List<html.Element> clipElements = _clipContent(
          _canvasPool._clipStack,
          paragraphElement,
          offset,
          _canvasPool.currentTransform);
      for (html.Element clipElement in clipElements) {
        rootElement.append(clipElement);
        _children.add(clipElement);
      }
    } else {
      setElementTransform(
        paragraphElement,
        transformWithOffset(_canvasPool.currentTransform, offset).storage,
      );
      rootElement.append(paragraphElement);
    }
    _children.add(paragraphElement);
    _closeCurrentCanvas();
  }

  /// Paints the [picture] into this canvas.
  void drawPicture(ui.Picture picture) {
    final EnginePicture enginePicture = picture;
    enginePicture.recordingCanvas.apply(this, bounds);
  }

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
      ui.Vertices vertices, ui.BlendMode blendMode, SurfacePaintData paint) {
    // TODO(flutter_web): Implement shaders for [Paint.shader] and
    // blendMode. https://github.com/flutter/flutter/issues/40096
    // Move rendering to OffscreenCanvas so that transform is preserved
    // as well.
    assert(paint.shader == null,
        'Linear/Radial/SweepGradient and ImageShader not supported yet');
    final Int32List colors = vertices.colors;
    final ui.VertexMode mode = vertices.mode;
    html.CanvasRenderingContext2D ctx = _canvasPool.context;
    if (colors == null) {
      final Float32List positions = mode == ui.VertexMode.triangles
          ? vertices.positions
          : _convertVertexPositions(mode, vertices.positions);
      // Draw hairline for vertices if no vertex colors are specified.
      save();
      final ui.Color color = paint.color ?? ui.Color(0xFF000000);
      _canvasPool.contextHandle
        ..fillStyle = null
        ..strokeStyle = colorToCssString(color);
      _glRenderer.drawHairline(ctx, positions);
      restore();
      return;
    }
    _glRenderer.drawVertices(ctx, _widthInBitmapPixels, _heightInBitmapPixels,
        _canvasPool.currentTransform, vertices, blendMode, paint);
  }

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points,
      double strokeWidth, ui.Color color) {
    ContextStateHandle contextHandle = _canvasPool.contextHandle;
    contextHandle
      ..lineWidth = strokeWidth
      ..blendMode = ui.BlendMode.srcOver
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..filter = '';
    final String cssColor = colorToCssString(color);
    if (pointMode == ui.PointMode.points) {
      contextHandle.fillStyle = cssColor;
    } else {
      contextHandle.strokeStyle = cssColor;
    }
    _canvasPool.drawPoints(pointMode, points, strokeWidth / 2.0);
  }

  @override
  void endOfPaint() {
    assert(_saveCount == 0);
    _canvasPool.endOfPaint();
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
    newElement.style.position = 'absolute';
    applyWebkitClipFix(newElement);
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
        ..width = '${rect.right - clipOffsetX}px'
        ..height = '${rect.bottom - clipOffsetY}px';
      setElementTransform(curElement, newClipTransform.storage);
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
        ..width = '${roundRect.right - clipOffsetX}px'
        ..height = '${roundRect.bottom - clipOffsetY}px';
      setElementTransform(curElement, newClipTransform.storage);
    } else if (entry.path != null) {
      curElement.style.transform = matrix4ToCssTransform(newClipTransform);
      String svgClipPath = createSvgClipDef(curElement, entry.path);
      final html.Element clipElement =
          html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
      clipDefs.add(clipElement);
    }
    // Reverse the transform of the clipping element so children can use
    // effective transform to render.
    // TODO(flutter_web): When we have more than a single clip element,
    // reduce number of div nodes by merging (multiplying transforms).
    final html.Element reverseTransformDiv = html.DivElement();
    reverseTransformDiv.style.position = 'absolute';
    setElementTransform(
      reverseTransformDiv,
      (newClipTransform.clone()..invert()).storage,
    );
    curElement.append(reverseTransformDiv);
    curElement = reverseTransformDiv;
  }

  root.style.position = 'absolute';
  domRenderer.append(curElement, content);
  setElementTransform(
    content,
    transformWithOffset(currentTransform, offset).storage,
  );
  return <html.Element>[root]..addAll(clipDefs);
}

String _maskFilterToCss(ui.MaskFilter maskFilter) {
  if (maskFilter == null) {
    return 'none';
  }
  return 'blur(${maskFilter.webOnlySigma}px)';
}
