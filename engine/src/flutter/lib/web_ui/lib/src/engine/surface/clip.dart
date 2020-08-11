// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Mixin used by surfaces that clip their contents using an overflowing DOM
/// element.
mixin _DomClip on PersistedContainerSurface {
  /// The dedicated child container element that's separate from the
  /// [rootElement] is used to compensate for the coordinate system shift
  /// introduced by the [rootElement] translation.
  @override
  html.Element? get childContainer => _childContainer;
  html.Element? _childContainer;

  @override
  void adoptElements(_DomClip oldSurface) {
    super.adoptElements(oldSurface);
    _childContainer = oldSurface._childContainer;
    oldSurface._childContainer = null;
  }

  @override
  html.Element createElement() {
    final html.Element element = defaultCreateElement('flt-clip');
    if (!debugShowClipLayers) {
      // Hide overflow in production mode. When debugging we want to see the
      // clipped picture in full.
      element.style
        ..overflow = 'hidden'
        ..zIndex = '0';
    } else {
      // Display the outline of the clipping region. When debugShowClipLayers is
      // `true` we don't hide clip overflow (see above). This outline helps
      // visualizing clip areas.
      element.style.boxShadow = 'inset 0 0 10px green';
    }
    _childContainer = html.Element.tag('flt-clip-interior');
    if (_debugExplainSurfaceStats) {
      // This creates an additional interior element. Count it too.
      _surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    _childContainer!.style.position = 'absolute';

    element.append(_childContainer!);
    return element;
  }

  @override
  void discard() {
    super.discard();

    // Do not detach the child container from the root. It is permanently
    // attached. The elements are reused together and are detached from the DOM
    // together.
    _childContainer = null;
  }
}

/// A surface that creates a rectangular clip.
class PersistedClipRect extends PersistedContainerSurface
    with _DomClip
    implements ui.ClipRectEngineLayer {
  PersistedClipRect(PersistedClipRect? oldLayer, this.rect) : super(oldLayer);

  final ui.Rect rect;

  @override
  void recomputeTransformAndClip() {
    _transform = parent!._transform;
    _localClipBounds = rect;
    _localTransformInverse = null;
    _projectedClip = null;
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'rect');
  }

  @override
  void apply() {
    rootElement!.style
      ..left = '${rect.left}px'
      ..top = '${rect.top}px'
      ..width = '${rect.right - rect.left}px'
      ..height = '${rect.bottom - rect.top}px';

    // Translate the child container in the opposite direction to compensate for
    // the shift in the coordinate system introduced by the translation of the
    // rootElement. Clipping in Flutter has no effect on the coordinate system.
    childContainer!.style
      ..left = '${-rect.left}px'
      ..top = '${-rect.top}px';
  }

  @override
  void update(PersistedClipRect oldSurface) {
    super.update(oldSurface);
    if (rect != oldSurface.rect) {
      apply();
    }
  }

  @override
  bool get isClipping => true;
}

/// A surface that creates a rounded rectangular clip.
class PersistedClipRRect extends PersistedContainerSurface
    with _DomClip
    implements ui.ClipRRectEngineLayer {
  PersistedClipRRect(ui.EngineLayer? oldLayer, this.rrect, this.clipBehavior)
      : super(oldLayer as PersistedSurface?);

  final ui.RRect rrect;
  // TODO(yjbanov): can this be controlled in the browser?
  final ui.Clip? clipBehavior;

  @override
  void recomputeTransformAndClip() {
    _transform = parent!._transform;
    _localClipBounds = rrect.outerRect;
    _localTransformInverse = null;
    _projectedClip = null;
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'rrect');
  }

  @override
  void apply() {
    rootElement!.style
      ..left = '${rrect.left}px'
      ..top = '${rrect.top}px'
      ..width = '${rrect.width}px'
      ..height = '${rrect.height}px'
      ..borderTopLeftRadius = '${rrect.tlRadiusX}px'
      ..borderTopRightRadius = '${rrect.trRadiusX}px'
      ..borderBottomRightRadius = '${rrect.brRadiusX}px'
      ..borderBottomLeftRadius = '${rrect.blRadiusX}px';

    // Translate the child container in the opposite direction to compensate for
    // the shift in the coordinate system introduced by the translation of the
    // rootElement. Clipping in Flutter has no effect on the coordinate system.
    childContainer!.style
      ..left = '${-rrect.left}px'
      ..top = '${-rrect.top}px';
  }

  @override
  void update(PersistedClipRRect oldSurface) {
    super.update(oldSurface);
    if (rrect != oldSurface.rrect) {
      apply();
    }
  }

  @override
  bool get isClipping => true;
}

class PersistedPhysicalShape extends PersistedContainerSurface
    with _DomClip
    implements ui.PhysicalShapeEngineLayer {
  PersistedPhysicalShape(PersistedPhysicalShape? oldLayer, this.path,
      this.elevation, int color, int shadowColor, this.clipBehavior)
      : color = ui.Color(color),
        shadowColor = ui.Color(shadowColor),
        pathBounds = path.getBounds(),
        super(oldLayer);

  final SurfacePath path;
  final ui.Rect pathBounds;
  final double elevation;
  final ui.Color color;
  final ui.Color shadowColor;
  final ui.Clip clipBehavior;
  html.Element? _clipElement;

  @override
  void recomputeTransformAndClip() {
    _transform = parent!._transform;

    final ui.RRect? roundRect = path.webOnlyPathAsRoundedRect;
    if (roundRect != null) {
      _localClipBounds = roundRect.outerRect;
    } else {
      final ui.Rect? rect = path.webOnlyPathAsRect;
      if (rect != null) {
        _localClipBounds = rect;
      } else {
        _localClipBounds = null;
      }
    }
    _localTransformInverse = null;
    _projectedClip = null;
  }

  void _applyColor() {
    rootElement!.style.backgroundColor = colorToCssString(color);
  }

  void _applyShadow() {
    applyCssShadow(rootElement, pathBounds, elevation, shadowColor);
  }

  @override
  html.Element createElement() {
    return super.createElement()..setAttribute('clip-type', 'physical-shape');
  }

  @override
  void apply() {
    _applyColor();
    _applyShadow();
    _applyShape();
  }

  void _applyShape() {
    // Handle special case of round rect physical shape mapping to
    // rounded div.
    final ui.RRect? roundRect = path.webOnlyPathAsRoundedRect;
    if (roundRect != null) {
      final String borderRadius =
          '${roundRect.tlRadiusX}px ${roundRect.trRadiusX}px '
          '${roundRect.brRadiusX}px ${roundRect.blRadiusX}px';
      final html.CssStyleDeclaration style = rootElement!.style;
      style
        ..left = '${roundRect.left}px'
        ..top = '${roundRect.top}px'
        ..width = '${roundRect.width}px'
        ..height = '${roundRect.height}px'
        ..borderRadius = borderRadius;
      childContainer!.style
        ..left = '${-roundRect.left}px'
        ..top = '${-roundRect.top}px';
      if (clipBehavior != ui.Clip.none) {
        style.overflow = 'hidden';
      }
      return;
    } else {
      final ui.Rect? rect = path.webOnlyPathAsRect;
      if (rect != null) {
        final html.CssStyleDeclaration style = rootElement!.style;
        style
          ..left = '${rect.left}px'
          ..top = '${rect.top}px'
          ..width = '${rect.width}px'
          ..height = '${rect.height}px'
          ..borderRadius = '';
        childContainer!.style
          ..left = '${-rect.left}px'
          ..top = '${-rect.top}px';
        if (clipBehavior != ui.Clip.none) {
          style.overflow = 'hidden';
        }
        return;
      } else {
        final ui.Rect? ovalRect = path.webOnlyPathAsCircle;
        if (ovalRect != null) {
          final double rx = ovalRect.width / 2.0;
          final double ry = ovalRect.height / 2.0;
          final String borderRadius =
              rx == ry ? '${rx}px ' : '${rx}px ${ry}px ';
          final html.CssStyleDeclaration style = rootElement!.style;
          final double left = ovalRect.left;
          final double top = ovalRect.top;
          style
            ..left = '${left}px'
            ..top = '${top}px'
            ..width = '${rx * 2}px'
            ..height = '${ry * 2}px'
            ..borderRadius = borderRadius;
          childContainer!.style
            ..left = '${-left}px'
            ..top = '${-top}px';
          if (clipBehavior != ui.Clip.none) {
            style.overflow = 'hidden';
          }
          return;
        }
      }
    }

    final String svgClipPath = _pathToSvgClipPath(path,
        offsetX: -pathBounds.left,
        offsetY: -pathBounds.top,
        scaleX: 1.0 / pathBounds.width,
        scaleY: 1.0 / pathBounds.height);
    assert(_clipElement == null);
    _clipElement =
        html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
    domRenderer.append(rootElement!, _clipElement!);
    domRenderer.setElementStyle(
        rootElement!, 'clip-path', 'url(#svgClip$_clipIdCounter)');
    domRenderer.setElementStyle(
        rootElement!, '-webkit-clip-path', 'url(#svgClip$_clipIdCounter)');
    final html.CssStyleDeclaration rootElementStyle = rootElement!.style;
    rootElementStyle
      ..overflow = ''
      ..left = '${pathBounds.left}px'
      ..top = '${pathBounds.top}px'
      ..width = '${pathBounds.width}px'
      ..height = '${pathBounds.height}px'
      ..borderRadius = '';
    childContainer!.style
      ..left = '-${pathBounds.left}px'
      ..top = '-${pathBounds.top}px';
  }

  @override
  void update(PersistedPhysicalShape oldSurface) {
    super.update(oldSurface);
    if (oldSurface.color != color) {
      _applyColor();
    }
    if (oldSurface.elevation != elevation ||
        oldSurface.shadowColor != shadowColor) {
      _applyShadow();
    }
    if (oldSurface.path != path) {
      oldSurface._clipElement?.remove();
      // Reset style on prior element since we may have switched between
      // rect/rrect and arbitrary path.
      domRenderer.setElementStyle(rootElement!, 'clip-path', '');
      domRenderer.setElementStyle(rootElement!, '-webkit-clip-path', '');
      _applyShape();
    } else {
      _clipElement = oldSurface._clipElement;
    }
    oldSurface._clipElement = null;
  }
}

/// A surface that clips it's children.
class PersistedClipPath extends PersistedContainerSurface
    implements ui.ClipPathEngineLayer {
  PersistedClipPath(
      PersistedClipPath? oldLayer, this.clipPath, this.clipBehavior)
      : super(oldLayer);

  final ui.Path clipPath;
  final ui.Clip clipBehavior;
  html.Element? _clipElement;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-clippath');
  }

  @override
  void recomputeTransformAndClip() {
    super.recomputeTransformAndClip();
    _localClipBounds ??= clipPath.getBounds();
  }

  @override
  void apply() {
    _clipElement?.remove();
    final String svgClipPath = createSvgClipDef(childContainer as html.HtmlElement, clipPath);
    _clipElement =
        html.Element.html(svgClipPath, treeSanitizer: _NullTreeSanitizer());
    domRenderer.append(childContainer!, _clipElement!);
  }

  @override
  void update(PersistedClipPath oldSurface) {
    super.update(oldSurface);
    if (oldSurface.clipPath != clipPath) {
      _localClipBounds = null;
      oldSurface._clipElement?.remove();
      apply();
    } else {
      _clipElement = oldSurface._clipElement;
    }
    oldSurface._clipElement = null;
  }

  @override
  void discard() {
    _clipElement?.remove();
    _clipElement = null;
    super.discard();
  }

  @override
  bool get isClipping => true;
}

/// Creates an svg clipPath and applies it to [element].
String createSvgClipDef(html.HtmlElement element, ui.Path clipPath) {
  final ui.Rect pathBounds = clipPath.getBounds();
  final String svgClipPath = _pathToSvgClipPath(clipPath,
      scaleX: 1.0 / pathBounds.right, scaleY: 1.0 / pathBounds.bottom);
  domRenderer.setElementStyle(
      element, 'clip-path', 'url(#svgClip$_clipIdCounter)');
  domRenderer.setElementStyle(
      element, '-webkit-clip-path', 'url(#svgClip$_clipIdCounter)');
  // We need to set width and height for the clipElement to cover the
  // bounds of the path since browsers such as Safari and Edge
  // seem to incorrectly intersect the element bounding rect with
  // the clip path. Chrome and Firefox don't perform intersect instead they
  // use the path itself as source of truth.
  element.style
    ..width = '${pathBounds.right}px'
    ..height = '${pathBounds.bottom}px';
  return svgClipPath;
}
