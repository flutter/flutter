// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
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
  final double _devicePixelRatio = EnginePlatformDispatcher.browserDevicePixelRatio;

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

  /// Indicates bitmap canvas contains a 3d transform.
  /// WebKit fails to preserve paint order when this happens and therefore
  /// requires insertion of <div style="transform: translate3d(0,0,0);"> to be
  /// used for each child to force correct rendering order.
  bool _contains3dTransform = false;

  /// Indicates that contents should be rendered into canvas so a dataUrl
  /// can be constructed from contents.
  bool _preserveImageData = false;

  /// Canvas pixel to screen pixel ratio. Similar to dpi but
  /// uses global transform of canvas to compute ratio.
  final double _density;

  /// Allocates a canvas with enough memory to paint a picture within the given
  /// [bounds].
  ///
  /// This canvas can be reused by pictures with different paint bounds as long
  /// as the [Rect.size] of the bounds fully fit within the size used to
  /// initialize this canvas.
  BitmapCanvas(this._bounds, {double density = 1.0})
      : assert(_bounds != null), // ignore: unnecessary_null_comparison
        _density = density,
        _widthInBitmapPixels = _widthToPhysical(_bounds.width),
        _heightInBitmapPixels = _heightToPhysical(_bounds.height),
        _canvasPool = _CanvasPool(_widthToPhysical(_bounds.width),
            _heightToPhysical(_bounds.height), density) {
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

  /// Constructs bitmap canvas to capture image data.
  factory BitmapCanvas.imageData(ui.Rect bounds) {
    BitmapCanvas bitmapCanvas = BitmapCanvas(bounds);
    bitmapCanvas._preserveImageData = true;
    return bitmapCanvas;
  }

  /// Setup cache for reusing DOM elements across frames.
  void setElementCache(CrossFrameCache<html.HtmlElement>? cache) {
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
    final double canvasPositionCorrectionY = _bounds.top -
        BitmapCanvas.kPaddingPixels -
        _canvasPositionY!.toDouble();
    // This compensates for the translate on the `rootElement`.
    _canvasPool.initialTransform = ui.Offset(
      -_bounds.left + canvasPositionCorrectionX + BitmapCanvas.kPaddingPixels,
      -_bounds.top + canvasPositionCorrectionY + BitmapCanvas.kPaddingPixels,
    );
  }

  static int _widthToPhysical(double width) {
    final double boundsWidth = width + 1;
    return (boundsWidth * EnginePlatformDispatcher.browserDevicePixelRatio).ceil() +
        2 * kPaddingPixels;
  }

  static int _heightToPhysical(double height) {
    final double boundsHeight = height + 1;
    return (boundsHeight * EnginePlatformDispatcher.browserDevicePixelRatio).ceil() +
        2 * kPaddingPixels;
  }

  // Used by picture to assess if canvas is large enough to reuse as is.
  bool doesFitBounds(ui.Rect newBounds, double newDensity) {
    assert(newBounds != null); // ignore: unnecessary_null_comparison
    return _widthInBitmapPixels >= _widthToPhysical(newBounds.width) &&
        _heightInBitmapPixels >= _heightToPhysical(newBounds.height) &&
        _density == newDensity;
  }

  @override
  void dispose() {
    _canvasPool.dispose();
  }

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    _contains3dTransform = false;
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
    return _devicePixelRatio == EnginePlatformDispatcher.browserDevicePixelRatio;
  }

  /// Returns a "data://" URI containing a representation of the image in this
  /// canvas in PNG format.
  String toDataUrl() {
    return _canvasPool.toDataUrl();
  }

  /// Sets the global paint styles to correspond to [paint].
  void _setUpPaint(SurfacePaintData paint, ui.Rect? shaderBounds) {
    _canvasPool.contextHandle.setUpPaint(paint, shaderBounds);
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
    TransformKind transformKind = transformKindOf(matrix4);
    if (transformKind == TransformKind.complex) {
      _contains3dTransform = true;
    }
    _canvasPool.transform(matrix4);
  }

  @override
  void clipRect(ui.Rect rect, ui.ClipOp op) {
    if (op == ui.ClipOp.difference) {
      // Create 2 rectangles inside each other that represents
      // clip area difference using even-odd fill rule.
      final SurfacePath path = new SurfacePath();
      path.fillType = ui.PathFillType.evenOdd;
      path.addRect(ui.Rect.fromLTWH(0, 0, _bounds.width, _bounds.height));
      path.addRect(rect);
      _canvasPool.clipPath(path);
    } else {
      _canvasPool.clipRect(rect);
    }
  }

  @override
  void clipRRect(ui.RRect rrect) {
    _canvasPool.clipRRect(rrect);
  }

  @override
  void clipPath(ui.Path path) {
    _canvasPool.clipPath(path);
  }

  /// Whether drawing operation should use DOM node instead of Canvas.
  ///
  /// - Perspective transforms are not supported by canvas and require
  ///   DOM to render correctly.
  /// - Pictures typically have large rect/rounded rectangles as background
  ///   prefer DOM if canvas has not been allocated yet.
  ///
  bool _useDomForRendering(SurfacePaintData paint) =>
      (_preserveImageData == false && _contains3dTransform) ||
      (_childOverdraw && _canvasPool._canvas == null &&
          paint.maskFilter == null &&
          paint.shader == null &&
          paint.style != ui.PaintingStyle.stroke);

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    final SurfacePaintData paintData = SurfacePaintData()
      ..color = color
      ..blendMode = blendMode;
    if (_useDomForRendering(paintData)) {
      drawRect(_computeScreenBounds(_canvasPool._currentTransform), paintData);
    } else {
      _canvasPool.drawColor(color, blendMode);
    }
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, SurfacePaintData paint) {
    if (_useDomForRendering(paint)) {
      final SurfacePath path = SurfacePath()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy);
      drawPath(path, paint);
    } else {
      ui.Rect? shaderBounds = (paint.shader != null) ?
      ui.Rect.fromPoints(p1, p2) : null;
      _setUpPaint(paint, shaderBounds);
      _canvasPool.strokeLine(p1, p2);
      _tearDownPaint();
    }
  }

  @override
  void drawPaint(SurfacePaintData paint) {
    if (_useDomForRendering(paint)) {
      drawRect(_computeScreenBounds(_canvasPool._currentTransform), paint);
    } else {
      ui.Rect? shaderBounds = (paint.shader != null) ?
      _computePictureBounds() : null;
      _setUpPaint(paint, shaderBounds);
      _canvasPool.fill();
      _tearDownPaint();
    }
  }

  @override
  void drawRect(ui.Rect rect, SurfacePaintData paint) {
    if (_useDomForRendering(paint)) {
      html.HtmlElement element = _buildDrawRectElement(
          rect, paint, 'draw-rect', _canvasPool._currentTransform);
      _drawElement(
          element,
          ui.Offset(
              math.min(rect.left, rect.right), math.min(rect.top, rect.bottom)),
          paint);
    } else {
      _setUpPaint(paint, rect);
      _canvasPool.drawRect(rect, paint.style);
      _tearDownPaint();
    }
  }

  /// Inserts a dom element at [offset] creating stack of divs for clipping
  /// if required.
  void _drawElement(
      html.Element element, ui.Offset offset, SurfacePaintData paint) {
    if (_canvasPool.isClipped) {
      final List<html.Element> clipElements = _clipContent(
          _canvasPool._clipStack!,
          element,
          ui.Offset.zero,
          transformWithOffset(_canvasPool._currentTransform, offset));
      for (html.Element clipElement in clipElements) {
        rootElement.append(clipElement);
        _children.add(clipElement);
      }
    } else {
      rootElement.append(element);
      _children.add(element);
    }
    ui.BlendMode? blendMode = paint.blendMode;
    if (blendMode != null) {
      element.style.mixBlendMode = _stringForBlendMode(blendMode) ?? '';
    }
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    final ui.Rect rect = rrect.outerRect;
    if (_useDomForRendering(paint)) {
      html.HtmlElement element = _buildDrawRectElement(
          rect, paint, 'draw-rrect', _canvasPool._currentTransform);
      _applyRRectBorderRadius(element.style, rrect);
      _drawElement(
          element,
          ui.Offset(
              math.min(rect.left, rect.right), math.min(rect.top, rect.bottom)),
          paint);
    } else {
    _setUpPaint(paint, rrect.outerRect);
    _canvasPool.drawRRect(rrect, paint.style);
      _tearDownPaint();
    }
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaintData paint) {
    _setUpPaint(paint, outer.outerRect);
    _canvasPool.drawDRRect(outer, inner, paint.style);
    _tearDownPaint();
  }

  @override
  void drawOval(ui.Rect rect, SurfacePaintData paint) {
    if (_useDomForRendering(paint)) {
      html.HtmlElement element = _buildDrawRectElement(
          rect, paint, 'draw-oval', _canvasPool._currentTransform);
      _drawElement(
          element,
          ui.Offset(
              math.min(rect.left, rect.right), math.min(rect.top, rect.bottom)),
          paint);
      element.style.borderRadius =
          '${(rect.width / 2.0)}px / ${(rect.height / 2.0)}px';
    } else {
      _setUpPaint(paint, rect);
      _canvasPool.drawOval(rect, paint.style);
      _tearDownPaint();
    }
  }

  @override
  void drawCircle(ui.Offset c, double radius, SurfacePaintData paint) {
    ui.Rect rect = ui.Rect.fromCircle(center: c, radius: radius);
    if (_useDomForRendering(paint)) {
      html.HtmlElement element = _buildDrawRectElement(
          rect, paint, 'draw-circle', _canvasPool._currentTransform);
      _drawElement(
          element,
          ui.Offset(
              math.min(rect.left, rect.right), math.min(rect.top, rect.bottom)),
          paint);
      element.style.borderRadius = '50%';
    } else {
      _setUpPaint(paint, paint.shader != null
          ? ui.Rect.fromCircle(center: c, radius: radius) : null);
      _canvasPool.drawCircle(c, radius, paint.style);
      _tearDownPaint();
    }
  }

  @override
  void drawPath(ui.Path path, SurfacePaintData paint) {
    if (_useDomForRendering(paint)) {
      final Matrix4 transform = _canvasPool._currentTransform;
      final SurfacePath surfacePath = path as SurfacePath;
      final ui.Rect? pathAsLine = surfacePath.toStraightLine();
      if (pathAsLine != null) {
        final ui.Rect rect = (pathAsLine.top == pathAsLine.bottom) ?
          ui.Rect.fromLTWH(pathAsLine.left, pathAsLine.top, pathAsLine.width, 1)
          : ui.Rect.fromLTWH(pathAsLine.left, pathAsLine.top, 1, pathAsLine.height);

        html.HtmlElement element = _buildDrawRectElement(
            rect, paint, 'draw-rect', _canvasPool._currentTransform);
        _drawElement(
            element,
            ui.Offset(
                math.min(rect.left, rect.right), math.min(rect.top, rect.bottom)),
            paint);
        return;
      }
      final ui.Rect? pathAsRect = surfacePath.toRect();
      if (pathAsRect != null) {
        drawRect(pathAsRect, paint);
        return;
      }
      final ui.Rect pathBounds = surfacePath.getBounds();
      html.Element svgElm = _pathToSvgElement(
          surfacePath, paint, '${pathBounds.right}', '${pathBounds.bottom}');
      if (!_canvasPool.isClipped) {
        html.CssStyleDeclaration style = svgElm.style;
        style.position = 'absolute';
        if (!transform.isIdentity()) {
          style
            ..transform = matrix4ToCssTransform(transform)
            ..transformOrigin = '0 0 0';
        }
      }
      _drawElement(svgElm, ui.Offset(0, 0), paint);
    } else {
      _setUpPaint(paint, paint.shader != null ? path.getBounds() : null);
      _canvasPool.drawPath(path, paint.style);
      _tearDownPaint();
    }
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
      _applyTargetSize(
          imageElement, image.width.toDouble(), image.height.toDouble());
    }
    _childOverdraw = true;
    _canvasPool.closeCurrentCanvas();
    _cachedLastStyle = null;
  }

  html.ImageElement _reuseOrCreateImage(HtmlImage htmlImage) {
    final String cacheKey = htmlImage.imgElement.src!;
    if (_elementCache != null) {
      html.ImageElement? imageElement =
          _elementCache!.reuse(cacheKey) as html.ImageElement?;
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
    html.HtmlElement imgElement;
    if (colorFilter is _CkBlendModeColorFilter) {
      switch (colorFilter.blendMode) {
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
              colorFilter.color, colorFilter.blendMode, paint);
          break;
        default:
          imgElement = _createBackgroundImageWithBlend(image,
              colorFilter.color, colorFilter.blendMode, paint);
          break;
      }
    } else {
      // No Blending, create an image by cloning original loaded image.
      imgElement = _reuseOrCreateImage(htmlImage);
    }
    imgElement.style.mixBlendMode = _stringForBlendMode(blendMode) ?? '';
    if (_canvasPool.isClipped) {
      // Reset width/height since they may have been previously set.
      imgElement.style..removeProperty('width')..removeProperty('height');
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
        clipRect(dst, ui.ClipOp.intersect);
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
      _applyTargetSize(
          imgElement as html.HtmlElement, targetWidth, targetHeight);
      if (requiresClipping) {
        restore();
      }
    }
    _closeCurrentCanvas();
  }

  void _applyTargetSize(
      html.HtmlElement imageElement, double targetWidth, double targetHeight) {
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
  html.HtmlElement _createBackgroundImageWithBlend(
      HtmlImage image,
      ui.Color? filterColor,
      ui.BlendMode colorFilterBlendMode,
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
          ..backgroundBlendMode =
              _stringForBlendMode(colorFilterBlendMode) ?? ''
          ..backgroundColor = colorToCssString(filterColor);
        break;
    }
    return imgElement;
  }

  // Creates an image element and an svg filter to apply on the element.
  html.HtmlElement _createImageElementWithSvgFilter(
      HtmlImage image,
      ui.Color? filterColor,
      ui.BlendMode colorFilterBlendMode,
      SurfacePaintData paint) {
    // For srcIn blendMode, we use an svg filter to apply to image element.
    String? svgFilter =
        svgFilterFromBlendMode(filterColor, colorFilterBlendMode);
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

  void setFontFromParagraphStyle(ParagraphGeometricStyle style) {
    if (style != _cachedLastStyle) {
      html.CanvasRenderingContext2D ctx = _canvasPool.context;
      ctx.font = style.cssFontString;
      _cachedLastStyle = style;
    }
  }

  /// Measures the given [text] and returns a [html.TextMetrics] object that
  /// contains information about the measurement.
  ///
  /// The text is measured using the font set by the most recent call to
  /// [setFontFromParagraphStyle].
  html.TextMetrics measureText(String text) {
    return _canvasPool.context.measureText(text);
  }

  /// Draws text to the canvas starting at coordinate ([x], [y]).
  ///
  /// The text is drawn starting at coordinates ([x], [y]). It uses the current
  /// font set by the most recent call to [setFontFromParagraphStyle].
  void fillText(String text, double x, double y) {
    _canvasPool.context.fillText(text, x, y);
  }

  @override
  void drawParagraph(EngineParagraph paragraph, ui.Offset offset) {
    assert(paragraph.isLaidOut);

    if (paragraph.drawOnCanvas && _childOverdraw == false) {
      paragraph.paint(this, offset);
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
  void drawVertices(SurfaceVertices vertices, ui.BlendMode blendMode,
      SurfacePaintData paint) {
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
  void drawPoints(
      ui.PointMode pointMode, Float32List points, SurfacePaintData paint) {
    if (pointMode == ui.PointMode.points) {
      _drawPointsPaint.style = ui.PaintingStyle.stroke;
    } else {
      _drawPointsPaint.style = ui.PaintingStyle.fill;
    }
    _drawPointsPaint.color = paint.color;
    _drawPointsPaint.strokeWidth = paint.strokeWidth;
    _drawPointsPaint.maskFilter = paint.maskFilter;

    _setUpPaint(_drawPointsPaint, null);
    _canvasPool.drawPoints(pointMode, points, paint.strokeWidth! / 2.0);
    _tearDownPaint();
  }

  @override
  void endOfPaint() {
    _canvasPool.endOfPaint();
    _elementCache?.commitFrame();
    // Wrap all elements in translate3d (workaround for webkit paint order bug).
    if (_contains3dTransform && browserEngine == BrowserEngine.webkit) {
      for (html.Element element in rootElement.children) {
        html.DivElement paintOrderElement = html.DivElement()
          ..style.transform = 'translate3d(0,0,0)';
        paintOrderElement.append(element);
        rootElement.append(paintOrderElement);
        _children.add(paintOrderElement);
      }
    }
    if (rootElement.firstChild is html.HtmlElement &&
        (rootElement.firstChild as html.HtmlElement).tagName.toLowerCase() ==
            'canvas') {
      (rootElement.firstChild as html.HtmlElement).style.zIndex = '-1';
    }
  }

  /// Computes paint bounds given [targetTransform] to completely cover window
  /// viewport.
  ui.Rect _computeScreenBounds(Matrix4 targetTransform) {
    final Matrix4 inverted = targetTransform.clone()..invert();
    final double dpr = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width * dpr;
    final double height = ui.window.physicalSize.height * dpr;
    Vector3 topLeft = inverted.perspectiveTransform(Vector3(0, 0, 0));
    Vector3 topRight = inverted.perspectiveTransform(Vector3(width, 0, 0));
    Vector3 bottomRight =
        inverted.perspectiveTransform(Vector3(width, height, 0));
    Vector3 bottomLeft = inverted.perspectiveTransform(Vector3(0, height, 0));
    return ui.Rect.fromLTRB(
      math.min(topLeft.x,
              math.min(topRight.x, math.min(bottomRight.x, bottomLeft.x))),
      math.min(topLeft.y,
              math.min(topRight.y, math.min(bottomRight.y, bottomLeft.y))),
      math.max(topLeft.x,
              math.max(topRight.x, math.max(bottomRight.x, bottomLeft.x))),
      math.max(topLeft.y,
              math.max(topRight.y, math.max(bottomRight.y, bottomLeft.y))),
    );
  }

  /// Computes paint bounds to completely cover picture.
  ui.Rect _computePictureBounds() {
    return ui.Rect.fromLTRB(0, 0, _bounds.width, _bounds.height);
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
    html.Element content, ui.Offset offset, Matrix4 currentTransform) {
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
    final TransformKind transformKind =
        transformKindOf(newClipTransform.storage);
    bool requiresTransformStyle = transformKind == TransformKind.complex;
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
      String svgClipPath =
          createSvgClipDef(curElement as html.HtmlElement, entry.path!);
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
    if (requiresTransformStyle) {
      // Instead of flattening matrix3d, preserve so it can be reversed.
      curElement.style.transformStyle = 'preserve-3d';
      reverseTransformDiv.style.transformStyle = 'preserve-3d';
    }
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
