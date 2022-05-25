// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../dom.dart';
import '../engine_canvas.dart';
import '../svg.dart';
import '../text/canvas_paragraph.dart';
import '../util.dart';
import '../vector_math.dart';
import 'painting.dart';
import 'path/path.dart';
import 'path/path_to_svg.dart';
import 'shaders/image_shader.dart';
import 'shaders/shader.dart';

/// A canvas that renders to DOM elements and CSS properties.
class DomCanvas extends EngineCanvas with SaveElementStackTracking {
  @override
  final DomElement rootElement;

  DomCanvas(this.rootElement);

  /// Prepare to reuse this canvas by clearing it's current contents.
  @override
  void clear() {
    super.clear();
    removeAllChildren(rootElement);
  }

  @override
  void clipRect(ui.Rect rect, ui.ClipOp clipOp) {
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
    final DomElement box = createDomElement('draw-color');
    box.style
      ..position = 'absolute'
      ..top = '0'
      ..right = '0'
      ..bottom = '0'
      ..left = '0'
      ..backgroundColor = colorToCssString(color)!;
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
    currentElement.append(
        buildDrawRectElement(rect, paint, 'draw-rect', currentTransform));
  }

  @override
  void drawRRect(ui.RRect rrect, SurfacePaintData paint) {
    final DomElement element = buildDrawRectElement(
        rrect.outerRect, paint, 'draw-rrect', currentTransform);
    applyRRectBorderRadius(element.style, rrect);
    currentElement.append(element);
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
    final DomElement paragraphElement = drawParagraphElement(
        paragraph as CanvasParagraph, offset,
        transform: currentTransform);
    currentElement.append(paragraphElement);
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void drawPoints(
      ui.PointMode pointMode, Float32List points, SurfacePaintData paint) {
    throw UnimplementedError();
  }

  @override
  void endOfPaint() {
    // No reuse of elements yet to handle here. Noop.
  }
}

/// Converts a shadow color specified by the framework to the color that should
/// actually be applied when rendering the element.
///
/// Returns a color for box-shadow based on blur filter at sigma.
ui.Color blurColor(ui.Color color, double sigma) {
  final double strength = math.min(math.sqrt(sigma) / (math.pi * 2.0), 1.0);
  final int reducedAlpha = ((1.0 - strength) * color.alpha).round();
  return ui.Color((reducedAlpha & 0xff) << 24 | (color.value & 0x00ffffff));
}

DomHTMLElement buildDrawRectElement(
    ui.Rect rect, SurfacePaintData paint, String tagName, Matrix4 transform) {
  final DomHTMLElement rectangle = domDocument.createElement(tagName) as
      DomHTMLElement;
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
  if (transform.isIdentity()) {
    if (isStroke) {
      effectiveTransform =
          'translate(${left - (strokeWidth / 2.0)}px, ${top - (strokeWidth / 2.0)}px)';
    } else {
      effectiveTransform = 'translate(${left}px, ${top}px)';
    }
  } else {
    // Clone to avoid mutating _transform.
    final Matrix4 translated = transform.clone();
    if (isStroke) {
      translated.translate(
          left - (strokeWidth / 2.0), top - (strokeWidth / 2.0));
    } else {
      translated.translate(left, top);
    }
    effectiveTransform = matrix4ToCssTransform(translated);
  }
  final DomCSSStyleDeclaration style = rectangle.style;
  style
    ..position = 'absolute'
    ..transformOrigin = '0 0 0'
    ..transform = effectiveTransform;

  String cssColor =
      paint.color == null ? '#000000' : colorToCssString(paint.color)!;

  if (paint.maskFilter != null) {
    final double sigma = paint.maskFilter!.webOnlySigma;
    if (browserEngine == BrowserEngine.webkit && !isStroke) {
      // A bug in webkit leaves artifacts when this element is animated
      // with filter: blur, we use boxShadow instead.
      style.boxShadow = '0px 0px ${sigma * 2.0}px $cssColor';
      cssColor = colorToCssString(
          blurColor(paint.color ?? const ui.Color(0xFF000000), sigma))!;
    } else {
      style.filter = 'blur(${sigma}px)';
    }
  }

  if (isStroke) {
    style
      ..width = '${right - left - strokeWidth}px'
      ..height = '${bottom - top - strokeWidth}px'
      ..border = '${_borderStrokeToCssUnit(strokeWidth)} solid $cssColor';
  } else {
    style
      ..width = '${right - left}px'
      ..height = '${bottom - top}px'
      ..backgroundColor = cssColor
      ..backgroundImage = _getBackgroundImageCssValue(paint.shader, rect);
  }
  return rectangle;
}

String _getBackgroundImageCssValue(ui.Shader? shader, ui.Rect bounds) {
  final String url = _getBackgroundImageUrl(shader, bounds);
  return (url != '') ? "url('$url'": '';
}

String _getBackgroundImageUrl(ui.Shader? shader, ui.Rect bounds) {
  if(shader != null) {
    if(shader is EngineImageShader) {
      return shader.image.imgElement.src ?? '';
    }

    if(shader is EngineGradient) {
      return shader.createImageBitmap(bounds, 1, true) as String;
    }
  }
  return '';
}

void applyRRectBorderRadius(DomCSSStyleDeclaration style, ui.RRect rrect) {
  if (rrect.tlRadiusX == rrect.trRadiusX &&
      rrect.tlRadiusX == rrect.blRadiusX &&
      rrect.tlRadiusX == rrect.brRadiusX &&
      rrect.tlRadiusX == rrect.tlRadiusY &&
      rrect.trRadiusX == rrect.trRadiusY &&
      rrect.blRadiusX == rrect.blRadiusY &&
      rrect.brRadiusX == rrect.brRadiusY) {
    style.borderRadius = _borderStrokeToCssUnit(rrect.blRadiusX);
    return;
  }
  // Non-uniform. Apply each corner radius.
  style.borderTopLeftRadius = '${_borderStrokeToCssUnit(rrect.tlRadiusX)} '
      '${_borderStrokeToCssUnit(rrect.tlRadiusY)}';
  style.borderTopRightRadius = '${_borderStrokeToCssUnit(rrect.trRadiusX)} '
      '${_borderStrokeToCssUnit(rrect.trRadiusY)}';
  style.borderBottomLeftRadius = '${_borderStrokeToCssUnit(rrect.blRadiusX)} '
      '${_borderStrokeToCssUnit(rrect.blRadiusY)}';
  style.borderBottomRightRadius = '${_borderStrokeToCssUnit(rrect.brRadiusX)} '
      '${_borderStrokeToCssUnit(rrect.brRadiusY)}';
}

String _borderStrokeToCssUnit(double value) {
  if (value == 0) {
    // TODO(ferhat): hairline nees to take into account both dpi and density.
    value = 1.0;
  }
  return '${value.toStringAsFixed(3)}px';
}

SVGSVGElement pathToSvgElement(
    SurfacePath path, SurfacePaintData paint, String width, String height) {
  // In Firefox some SVG typed attributes are returned as null without a
  // setter. So we use strings here.
  final SVGSVGElement root = createSVGSVGElement()
    ..setAttribute('width', '${width}px')
    ..setAttribute('height', '${height}px')
    ..setAttribute('viewBox', '0 0 $width $height');

  final SVGPathElement svgPath = createSVGPathElement();
  root.append(svgPath);
  final ui.Color color = paint.color ?? const ui.Color(0xFF000000);
  if (paint.style == ui.PaintingStyle.stroke ||
      (paint.style != ui.PaintingStyle.fill &&
          paint.strokeWidth != 0 &&
          paint.strokeWidth != null)) {
    svgPath.setAttribute('stroke', colorToCssString(color)!);
    svgPath.setAttribute('stroke-width', '${paint.strokeWidth ?? 1.0}');
    svgPath.setAttribute('fill', 'none');
  } else if (paint.color != null) {
    svgPath.setAttribute('fill', colorToCssString(color)!);
  } else {
    svgPath.setAttribute('fill', '#000000');
  }
  if (path.fillType == ui.PathFillType.evenOdd) {
    svgPath.setAttribute('fill-rule', 'evenodd');
  }
  svgPath.setAttribute('d', pathToSvg(path.pathRef));
  return root;
}
