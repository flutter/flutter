// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// A canvas that renders to DOM elements and CSS properties.
class DomCanvas extends EngineCanvas with SaveElementStackTracking {
  @override
  final html.Element rootElement = html.Element.tag('flt-dom-canvas');

  DomCanvas() {
    rootElement.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0';
  }

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    super.clear();
    // TODO(yjbanov): we should measure if reusing old elements is beneficial.
    domRenderer.clearDom(rootElement);
  }

  @override
  void clipRect(ui.Rect rect) {
    throw UnimplementedError();
  }

  @override
  void clipRRect(ui.RRect rrect) {
    throw UnimplementedError();
  }

  @override
  void clipPath(ui.Path path) {
    throw UnimplementedError();
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    // TODO(yjbanov): implement blendMode
    final html.Element box = html.Element.tag('draw-color');
    box.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0'
      ..backgroundColor = colorToCssString(color);
    currentElement.append(box);
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawPaint(SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawRect(ui.Rect rect, SurfacePaintData paint) {
    _drawRect(rect, paint, 'draw-rect');
  }

  html.Element _drawRect(ui.Rect rect, SurfacePaintData paint, String tagName) {
    assert(paint.shader == null);
    final html.Element rectangle = html.Element.tag(tagName);
    assert(() {
      rectangle.setAttribute('flt-rect', '$rect');
      rectangle.setAttribute('flt-paint', '$paint');
      return true;
    }());
    String effectiveTransform;
    final bool isStroke = paint.style == ui.PaintingStyle.stroke;
    final double strokeWidth = paint.strokeWidth ?? 0.0;
    final double left = math.min(rect.left, rect.right);
    final double right = math.max(rect.left, rect.right);
    final double top = math.min(rect.top, rect.bottom);
    final double bottom = math.max(rect.top, rect.bottom);
    if (currentTransform.isIdentity()) {
      if (isStroke) {
        effectiveTransform =
            'translate(${left - (strokeWidth / 2.0)}px, ${top - (strokeWidth / 2.0)}px)';
      } else {
        effectiveTransform = 'translate(${left}px, ${top}px)';
      }
    } else {
      // Clone to avoid mutating _transform.
      final Matrix4 translated = currentTransform.clone();
      if (isStroke) {
        translated.translate(
            left - (strokeWidth / 2.0), top - (strokeWidth / 2.0));
      } else {
        translated.translate(left, top);
      }
      effectiveTransform = matrix4ToCssTransform(translated);
    }
    final html.CssStyleDeclaration style = rectangle.style;
    style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0'
      ..transform = effectiveTransform;

    final String cssColor =
        paint.color == null ? '#000000' : colorToCssString(paint.color)!;

    if (paint.maskFilter != null) {
      style.filter = 'blur(${paint.maskFilter!.webOnlySigma}px)';
    }

    if (isStroke) {
      style
        ..width = '${right - left - strokeWidth}px'
        ..height = '${bottom - top - strokeWidth}px'
        ..border = '${strokeWidth}px solid $cssColor';
    } else {
      style
        ..width = '${right - left}px'
        ..height = '${bottom - top}px'
        ..backgroundColor = cssColor;
    }

    currentElement.append(rectangle);
    return rectangle;
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    html.Element element = _drawRect(rrect.outerRect, paint, 'draw-rrect');
    element.style.borderRadius = '${rrect.blRadiusX.toStringAsFixed(3)}px';
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawOval(ui.Rect rect, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawCircle(ui.Offset c, double radius, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawPath(ui.Path path, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    throw UnimplementedError();
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    final html.Element paragraphElement =
        _drawParagraphElement(paragraph as EngineParagraph, offset, transform: currentTransform);
    currentElement.append(paragraphElement);
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void endOfPaint() {
    // No reuse of elements yet to handle here. Noop.
  }
}
