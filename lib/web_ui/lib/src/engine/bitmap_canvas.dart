// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// A raw HTML canvas that is directly written to.
class BitmapCanvas extends EngineCanvas {
  /// The rectangle positioned relative to the parent layer's coordinate
  /// system's origin, within which this canvas paints.
  ///
  /// Painting outside these bounds will result in cropping.
  ui.Rect get bounds => _bounds;
  set bounds(ui.Rect newValue) {
    assert(newValue != null); // ignore: unnecessary_null_comparison
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
  CrossFrameCache<html.HtmlElement>? _elementCache;

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
  ParagraphGeometricStyle? _cachedLastStyle;

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
  int? _canvasPositionX, _canvasPositionY;

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
      : assert(_bounds != null), // ignore: unnecessary_null_comparison
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
    _canvasPool.allocateCanvas(rootElement as html.HtmlElement);
    _setupInitialTransform();
  }

  /// Setup cache for reusing DOM elements across frames.
  void setElementCache(CrossFrameCache<html.HtmlElement> cache) {
    _elementCache = cache;
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
        _canvasPositionX!.toDouble();
    final double canvasPositionCorrectionY =
        _bounds.top - BitmapCanvas.kPaddingPixels - _canvasPositionY!.toDouble();
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
    assert(newBounds != null); // ignore: unnecessary_null_comparison
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
      html.Element child = _children[i];
      // Don't remove children that have been reused by CrossFrameCache.
      if (child.parent == rootElement) {
        child.remove();
      }
    }
    _children.clear();
    _cachedLastStyle = null;
    _setupInitialTransform();
  }

  /// Checks whether this [BitmapCanvas] can still be recycled and reused.
  ///
  /// See also:
  ///
  /// * [PersistedPicture._applyBitmapPaint] which uses this method to
  ///   decide whether to reuse this canvas or not.
  /// * [PersistedPicture._recycleCanvas] which also uses this method
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
  void _setUpPaint(SurfacePaintData paint) {
    _canvasPool.contextHandle.setUpPaint(paint);
  }

  void _tearDownPaint() {
    _canvasPool.contextHandle.tearDownPaint();
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
    _setUpPaint(paint);
    _canvasPool.strokeLine(p1, p2);
    _tearDownPaint();
  }

  @override
  void drawPaint(SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.fill();
    _tearDownPaint();
  }

  @override
  void drawRect(ui.Rect rect, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawRect(rect, paint.style);
    _tearDownPaint();
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawRRect(rrect, paint.style);
    _tearDownPaint();
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawDRRect(outer, inner, paint.style);
    _tearDownPaint();
  }

  @override
  void drawOval(ui.Rect rect, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawOval(rect, paint.style);
    _tearDownPaint();
  }

  @override
  void drawCircle(ui.Offset c, double radius, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawCircle(c, radius, paint.style);
    _tearDownPaint();
  }

  @override
  void drawPath(ui.Path path, SurfacePaintData paint) {
    _setUpPaint(paint);
    _canvasPool.drawPath(path, paint.style);
    _tearDownPaint();
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    _canvasPool.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, SurfacePaintData paint) {
    final html.HtmlElement imageElement = _drawImage(image, p, paint);
    if (paint.colorFilter != null) {
      _applyTargetSize(imageElement, image.width.toDouble(),
          image.height.toDouble());
    }
    _childOverdraw = true;
    _canvasPool.closeCurrentCanvas();
    _cachedLastStyle = null;
  }

  html.ImageElement _reuseOrCreateImage(HtmlImage htmlImage) {
    final String cacheKey = htmlImage.imgElement.src!;
    if (_elementCache != null) {
      html.ImageElement? imageElement = _elementCache!.reuse(cacheKey) as html.ImageElement?;
      if (imageElement != null) {
        return imageElement;
      }
    }
    // Can't reuse, create new instance.
    html.ImageElement newImageElement = htmlImage.cloneImageElement();
    if (_elementCache != null) {
      _elementCache!.cache(cacheKey, newImageElement, _onEvictElement);
    }
    return newImageElement;
  }

  static void _onEvictElement(html.HtmlElement element) {
    element.remove();
  }

  html.HtmlElement _drawImage(
      ui.Image image, ui.Offset p, SurfacePaintData paint) {
    final HtmlImage htmlImage = image as HtmlImage;
    final ui.BlendMode? blendMode = paint.blendMode;
    final EngineColorFilter? colorFilter = paint.colorFilter as EngineColorFilter?;
    final ui.BlendMode? colorFilterBlendMode = colorFilter?._blendMode;
    html.HtmlElement imgElement;
    if (colorFilterBlendMode == null) {
      // No Blending, create an image by cloning original loaded image.
      imgElement = _reuseOrCreateImage(htmlImage);
    } else {
      switch (colorFilterBlendMode) {
        case ui.BlendMode.colorBurn:
        case ui.BlendMode.colorDodge:
        case ui.BlendMode.hue:
        case ui.BlendMode.modulate:
        case ui.BlendMode.overlay:
        case ui.BlendMode.plus:
        case ui.BlendMode.srcIn:
        case ui.BlendMode.srcATop:
        case ui.BlendMode.srcOut:
        case ui.BlendMode.saturation:
        case ui.BlendMode.color:
        case ui.BlendMode.luminosity:
        case ui.BlendMode.xor:
          imgElement = _createImageElementWithSvgFilter(image,
              colorFilter!._color, colorFilterBlendMode, paint);
          break;
        default:
          imgElement = _createBackgroundImageWithBlend(image,
              colorFilter!._color, colorFilterBlendMode, paint);
          break;
      }
    }
    imgElement.style.mixBlendMode = _stringForBlendMode(blendMode) ?? '';
    if (_canvasPool.isClipped) {
      // Reset width/height since they may have been previously set.
      imgElement.style
        ..removeProperty('width')
        ..removeProperty('height');
      final List<html.Element> clipElements = _clipContent(
          _canvasPool._clipStack!, imgElement, p, _canvasPool.currentTransform);
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
    // If source and destination sizes are identical, we can skip the longer
    // code path that sets the size of the element and clips.
    //
    // If there is a color filter set however, we maybe using background-image
    // to render therefore we have to explicitely set width/height of the
    // element for blending to work with background-color.
    if (dst.width == image.width &&
        dst.height == image.height &&
        !requiresClipping &&
        paint.colorFilter == null) {
      _drawImage(image, dst.topLeft, paint);
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

      final html.Element imgElement =
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
      _applyTargetSize(imgElement as html.HtmlElement, targetWidth, targetHeight);
      if (requiresClipping) {
        restore();
      }
    }
    _closeCurrentCanvas();
  }

  void _applyTargetSize(html.HtmlElement imageElement, double targetWidth,
      double targetHeight) {
    final html.CssStyleDeclaration imageStyle = imageElement.style;
    final String widthPx = '${targetWidth.toStringAsFixed(2)}px';
    final String heightPx = '${targetHeight.toStringAsFixed(2)}px';
    imageStyle
      // left,top are set to 0 (although position is absolute) because
      // Chrome will glitch if you leave them out, reproducable with
      // canvas_image_blend_test on row 6,  MacOS / Chrome 81.04.
      ..left = "0px"
      ..top = "0px"
      ..width = widthPx
      ..height = heightPx;
    if (imageElement is! html.ImageElement) {
      imageElement.style.backgroundSize = '$widthPx $heightPx';
    }
  }

  // Creates a Div element to render an image using background-image css
  // attribute to be able to use background blend mode(s) when possible.
  //
  // Example: <div style="
  //               position:absolute;
  //               background-image:url(....);
  //               background-blend-mode:"darken"
  //               background-color: #RRGGBB">
  //
  // Special cases:
  // For clear,dstOut it generates a blank element.
  // For src,srcOver it only sets background-color attribute.
  // For dst,dstIn , it only sets source not background color.
  html.HtmlElement _createBackgroundImageWithBlend(HtmlImage image,
      ui.Color? filterColor, ui.BlendMode colorFilterBlendMode,
      SurfacePaintData paint) {
    // When blending with color we can't use an image element.
    // Instead use a div element with background image, color and
    // background blend mode.
    final html.HtmlElement imgElement = html.DivElement();
    final html.CssStyleDeclaration style = imgElement.style;
    switch (colorFilterBlendMode) {
      case ui.BlendMode.clear:
      case ui.BlendMode.dstOut:
        style.position = 'absolute';
        break;
      case ui.BlendMode.src:
      case ui.BlendMode.srcOver:
        style
            ..position = 'absolute'
            ..backgroundColor = colorToCssString(filterColor);
        break;
      case ui.BlendMode.dst:
      case ui.BlendMode.dstIn:
        style
          ..position = 'absolute'
          ..backgroundImage = "url('${image.imgElement.src}')";
        break;
      default:
        style
          ..position = 'absolute'
          ..backgroundImage = "url('${image.imgElement.src}')"
          ..backgroundBlendMode = _stringForBlendMode(colorFilterBlendMode) ?? ''
          ..backgroundColor = colorToCssString(filterColor);
        break;
    }
    return imgElement;
  }

  // Creates an image element and an svg filter to apply on the element.
  html.HtmlElement _createImageElementWithSvgFilter(HtmlImage image,
      ui.Color? filterColor, ui.BlendMode colorFilterBlendMode,
      SurfacePaintData paint) {
    // For srcIn blendMode, we use an svg filter to apply to image element.
    String? svgFilter;
    switch (colorFilterBlendMode) {
      case ui.BlendMode.srcIn:
      case ui.BlendMode.srcATop:
        svgFilter = _srcInColorFilterToSvg(filterColor);
        break;
      case ui.BlendMode.srcOut:
        svgFilter = _srcOutColorFilterToSvg(filterColor);
        break;
      case ui.BlendMode.xor:
        svgFilter = _xorColorFilterToSvg(filterColor);
        break;
      case ui.BlendMode.plus:
        // Porter duff source + destination.
        svgFilter = _compositeColorFilterToSvg(filterColor, 0, 1, 1, 0);
        break;
      case ui.BlendMode.modulate:
        // Porter duff source * destination but preserves alpha.
        svgFilter = _modulateColorFilterToSvg(filterColor!);
        break;
      case ui.BlendMode.overlay:
        // Since overlay is the same as hard-light by swapping layers,
        // pass hard-light blend function.
        svgFilter = _blendColorFilterToSvg(filterColor, 'hard-light',
            swapLayers: true);
        break;
      // Several of the filters below (although supported) do not render the
      // same (close but not exact) as native flutter when used as blend mode
      // for a background-image with a background color. They only look
      // identical when feBlend is used within an svg filter definition.
      //
      // Saturation filter uses destination when source is transparent.
      // cMax = math.max(r, math.max(b, g));
      // cMin = math.min(r, math.min(b, g));
      // delta = cMax - cMin;
      // lightness = (cMax + cMin) / 2.0;
      // saturation = delta / (1.0 - (2 * lightness - 1.0).abs());
      case ui.BlendMode.saturation:
      case ui.BlendMode.colorDodge:
      case ui.BlendMode.colorBurn:
      case ui.BlendMode.hue:
      case ui.BlendMode.color:
      case ui.BlendMode.luminosity:
        svgFilter = _blendColorFilterToSvg(filterColor,
            _stringForBlendMode(colorFilterBlendMode));
        break;
      default:
        break;
    }
    final html.Element filterElement =
    html.Element.html(svgFilter, treeSanitizer: _NullTreeSanitizer());
    rootElement.append(filterElement);
    _children.add(filterElement);
    final html.HtmlElement imgElement = _reuseOrCreateImage(image);
    imgElement.style.filter = 'url(#_fcf${_filterIdCounter})';
    if (colorFilterBlendMode == ui.BlendMode.saturation) {
      imgElement.style.backgroundColor = colorToCssString(filterColor);
    }
    return imgElement;
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
    html.CanvasRenderingContext2D? ctx = _canvasPool.context;
    x += line.left;
    final double? letterSpacing = style.letterSpacing;
    if (letterSpacing == null || letterSpacing == 0.0) {
      ctx!.fillText(line.displayText!, x, y);
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
      final int len = line.displayText!.length;
      for (int i = 0; i < len; i++) {
        final String char = line.displayText![i];
        ctx!.fillText(char, x, y);
        x += letterSpacing + ctx.measureText(char).width!;
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
      final List<EngineLineMetrics> lines = paragraph._measurementResult!.lines!;

      final SurfacePaintData? backgroundPaint = paragraph._background?.paintData;
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
      _setUpPaint(paragraph._paint!.paintData);
      double y = offset.dy + paragraph.alphabeticBaseline;
      final int len = lines.length;
      for (int i = 0; i < len; i++) {
        _drawTextLine(style, lines[i], offset.dx, y);
        y += paragraph._lineHeight;
      }
      _tearDownPaint();

      return;
    }

    final html.Element paragraphElement =
        _drawParagraphElement(paragraph, offset);
    if (_canvasPool.isClipped) {
      final List<html.Element> clipElements = _clipContent(
          _canvasPool._clipStack!,
          paragraphElement as html.HtmlElement,
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
    // If there is a prior sibling such as img prevent left/top shift.
    paragraphElement.style
      ..left = "0px"
      ..top = "0px";
    _closeCurrentCanvas();
  }

  /// Paints the [picture] into this canvas.
  void drawPicture(ui.Picture picture) {
    final EnginePicture enginePicture = picture as EnginePicture;
    enginePicture.recordingCanvas!.apply(this, bounds);
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
      SurfaceVertices vertices, ui.BlendMode blendMode, SurfacePaintData paint) {
    // TODO(flutter_web): Implement shaders for [Paint.shader] and
    // blendMode. https://github.com/flutter/flutter/issues/40096
    // Move rendering to OffscreenCanvas so that transform is preserved
    // as well.
    assert(paint.shader == null,
        'Linear/Radial/SweepGradient and ImageShader not supported yet');
    final Int32List? colors = vertices._colors;
    final ui.VertexMode mode = vertices._mode;
    html.CanvasRenderingContext2D? ctx = _canvasPool.context;
    if (colors == null) {
      final Float32List positions = mode == ui.VertexMode.triangles
          ? vertices._positions
          : _convertVertexPositions(mode, vertices._positions);
      // Draw hairline for vertices if no vertex colors are specified.
      save();
      final ui.Color color = paint.color ?? ui.Color(0xFF000000);
      _canvasPool.contextHandle
        ..fillStyle = null
        ..strokeStyle = colorToCssString(color);
      _glRenderer!.drawHairline(ctx, positions);
      restore();
      return;
    }
    _glRenderer!.drawVertices(ctx, _widthInBitmapPixels, _heightInBitmapPixels,
        _canvasPool.currentTransform, vertices, blendMode, paint);
  }

  /// Stores paint data used by [drawPoints]. We cannot use the original paint
  /// data object because painting style is determined by [ui.PointMode] and
  /// not by [SurfacePointData.style].
  static SurfacePaintData _drawPointsPaint = SurfacePaintData()
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..blendMode = ui.BlendMode.srcOver;

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points, SurfacePaintData paint) {
    if (pointMode == ui.PointMode.points) {
      _drawPointsPaint.style = ui.PaintingStyle.stroke;
    } else {
      _drawPointsPaint.style = ui.PaintingStyle.fill;
    }
    _drawPointsPaint.color = paint.color;
    _drawPointsPaint.strokeWidth = paint.strokeWidth;
    _drawPointsPaint.maskFilter = paint.maskFilter;

    _setUpPaint(_drawPointsPaint);
    _canvasPool.drawPoints(pointMode, points, paint.strokeWidth! / 2.0);
    _tearDownPaint();
  }

  @override
  void endOfPaint() {
    _canvasPool.endOfPaint();
    _elementCache?.commitFrame();
  }
}

String? _stringForBlendMode(ui.BlendMode? blendMode) {
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

String? _stringForStrokeCap(ui.StrokeCap? strokeCap) {
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
  assert(strokeJoin != null); // ignore: unnecessary_null_comparison
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
  html.Element? root, curElement;
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
      domRenderer.append(curElement!, newElement);
    }
    curElement = newElement;
    final ui.Rect? rect = entry.rect;
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
      final ui.RRect roundRect = entry.rrect!;
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
      curElement.style
        ..transform = matrix4ToCssTransform(newClipTransform)
        ..transformOrigin = '0 0 0';
      String svgClipPath = createSvgClipDef(curElement as html.HtmlElement, entry.path!);
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

  root!.style.position = 'absolute';
  domRenderer.append(curElement!, content);
  setElementTransform(
    content,
    transformWithOffset(currentTransform, offset).storage,
  );
  return <html.Element>[root]..addAll(clipDefs);
}

/// Converts a [maskFilter] to the value to be used on a `<canvas>`.
///
/// Only supported in non-WebKit browsers.
String _maskFilterToCanvasFilter(ui.MaskFilter? maskFilter) {
  assert(
    browserEngine != BrowserEngine.webkit,
    'WebKit (Safari) does not support `filter` canvas property.',
  );
  if (maskFilter != null) {
    // Multiply by device-pixel ratio because the canvas' pixel width and height
    // are larger than its CSS width and height by device-pixel ratio.
    return 'blur(${maskFilter.webOnlySigma * window.devicePixelRatio}px)';
  } else {
    return 'none';
  }
}

int _filterIdCounter = 0;

// The color matrix for feColorMatrix element changes colors based on
// the following:
//
// | R' |     | r1 r2 r3 r4 r5 |   | R |
// | G' |     | g1 g2 g3 g4 g5 |   | G |
// | B' |  =  | b1 b2 b3 b4 b5 | * | B |
// | A' |     | a1 a2 a3 a4 a5 |   | A |
// | 1  |     | 0  0  0  0  1  |   | 1 |
//
// R' = r1*R + r2*G + r3*B + r4*A + r5
// G' = g1*R + g2*G + g3*B + g4*A + g5
// B' = b1*R + b2*G + b3*B + b4*A + b5
// A' = a1*R + a2*G + a3*B + a4*A + a5
String _srcInColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feColorMatrix values="0 0 0 0 1 ' // Ignore input, set it to absolute.
          '0 0 0 0 1 '
          '0 0 0 0 1 '
          '0 0 0 1 0" result="destalpha"/>' // Just take alpha channel of destination
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="destalpha" '
      'operator="arithmetic" k1="1" k2="0" k3="0" k4="0" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

String _srcOutColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" operator="out" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

String _xorColorFilterToSvg(ui.Color? color) {
  _filterIdCounter += 1;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" operator="xor" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// The source image and color are composited using :
// result = k1 *in*in2 + k2*in + k3*in2 + k4.
String _compositeColorFilterToSvg(ui.Color? color, double k1, double k2, double k3 , double k4) {
  _filterIdCounter += 1;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>'
      '<feComposite in="flood" in2="SourceGraphic" '
      'operator="arithmetic" k1="$k1" k2="$k2" k3="$k3" k4="$k4" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// Porter duff source * destination , keep source alpha.
// First apply color filter to source to change it to [color], then
// composite using multiplication.
String _modulateColorFilterToSvg(ui.Color color) {
  _filterIdCounter += 1;
  final double r = color.red / 255.0;
  final double b = color.blue / 255.0;
  final double g = color.green / 255.0;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" '
      'filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%">'
      '<feColorMatrix values="0 0 0 0 $r ' // Ignore input, set it to absolute.
      '0 0 0 0 $g '
      '0 0 0 0 $b '
      '0 0 0 1 0" result="recolor"/>'
      '<feComposite in="recolor" in2="SourceGraphic" '
      'operator="arithmetic" k1="1" k2="0" k3="0" k4="0" result="comp">'
      '</feComposite>'
      '</filter></svg>';
}

// Uses feBlend element to blend source image with a color.
String _blendColorFilterToSvg(ui.Color? color, String? feBlend,
    {bool swapLayers = false}) {
  _filterIdCounter += 1;
  return '<svg width="0" height="0">'
      '<filter id="_fcf$_filterIdCounter" filterUnits="objectBoundingBox" '
      'x="0%" y="0%" width="100%" height="100%">'
      '<feFlood flood-color="${colorToCssString(color)}" flood-opacity="1" result="flood">'
      '</feFlood>' +
      (swapLayers
      ? '<feBlend in="SourceGraphic" in2="flood" mode="$feBlend"/>'
      : '<feBlend in="flood" in2="SourceGraphic" mode="$feBlend"/>') +
      '</filter></svg>';
}
