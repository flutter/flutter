// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../shadow.dart';
import '../svg.dart';
import '../util.dart';
import 'dom_canvas.dart';
import 'painting.dart';
import 'path/path.dart';
import 'path_to_svg_clip.dart';
import 'surface.dart';
import 'surface_stats.dart';

/// Mixin used by surfaces that clip their contents using an overflowing DOM
/// element.
mixin _DomClip on PersistedContainerSurface {
  /// The dedicated child container element that's separate from the
  /// [rootElement] is used to compensate for the coordinate system shift
  /// introduced by the [rootElement] translation.
  @override
  DomElement? get childContainer => _childContainer;
  DomElement? _childContainer;

  @override
  void adoptElements(_DomClip oldSurface) {
    super.adoptElements(oldSurface);
    _childContainer = oldSurface._childContainer;
    oldSurface._childContainer = null;
  }

  @override
  DomElement createElement() {
    final DomElement element = defaultCreateElement('flt-clip');
    _childContainer = createDomElement('flt-clip-interior');
    if (debugExplainSurfaceStats) {
      // This creates an additional interior element. Count it too.
      surfaceStatsFor(this).allocatedDomNodeCount++;
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

  void applyOverflow(DomElement element, ui.Clip? clipBehaviour) {
    if (!debugShowClipLayers) {
      // Hide overflow in production mode. When debugging we want to see the
      // clipped picture in full.
      if (clipBehaviour != ui.Clip.none) {
        element.style
          ..overflow = 'hidden'
          ..zIndex = '0';
      }
    } else {
      // Display the outline of the clipping region. When debugShowClipLayers is
      // `true` we don't hide clip overflow (see above). This outline helps
      // visualizing clip areas.
      element.style.boxShadow = 'inset 0 0 10px green';
    }
  }
}

/// A surface that creates a rectangular clip.
class PersistedClipRect extends PersistedContainerSurface
    with _DomClip
    implements ui.ClipRectEngineLayer {
  PersistedClipRect(PersistedClipRect? oldLayer, this.rect, this.clipBehavior)
      : super(oldLayer);
  final ui.Clip? clipBehavior;
  final ui.Rect rect;

  @override
  void recomputeTransformAndClip() {
    transform = parent!.transform;
    if (clipBehavior != ui.Clip.none) {
      localClipBounds = rect;
    } else {
      localClipBounds = null;
    }
    projectedClip = null;
  }

  @override
  DomElement createElement() {
    return super.createElement()..setAttribute('clip-type', 'rect');
  }

  @override
  void apply() {
    rootElement!.style
      ..left = '${rect.left}px'
      ..top = '${rect.top}px'
      ..width = '${rect.right - rect.left}px'
      ..height = '${rect.bottom - rect.top}px';
    applyOverflow(rootElement!, clipBehavior);

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
    if (rect != oldSurface.rect || clipBehavior != oldSurface.clipBehavior) {
      localClipBounds = null;
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
    transform = parent!.transform;
    if (clipBehavior != ui.Clip.none) {
      localClipBounds = rrect.outerRect;
    } else {
      localClipBounds = null;
    }
    projectedClip = null;
  }

  @override
  DomElement createElement() {
    return super.createElement()..setAttribute('clip-type', 'rrect');
  }

  @override
  void apply() {
    final DomCSSStyleDeclaration style = rootElement!.style;
    style
      ..left = '${rrect.left}px'
      ..top = '${rrect.top}px'
      ..width = '${rrect.width}px'
      ..height = '${rrect.height}px'
      ..borderTopLeftRadius = '${rrect.tlRadiusX}px'
      ..borderTopRightRadius = '${rrect.trRadiusX}px'
      ..borderBottomRightRadius = '${rrect.brRadiusX}px'
      ..borderBottomLeftRadius = '${rrect.blRadiusX}px';
    applyOverflow(rootElement!, clipBehavior);

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
    if (rrect != oldSurface.rrect || clipBehavior != oldSurface.clipBehavior) {
      localClipBounds = null;
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
  DomElement? _clipElement;
  DomElement? _svgElement;

  @override
  void recomputeTransformAndClip() {
    transform = parent!.transform;

    if (clipBehavior != ui.Clip.none) {
      final ui.RRect? roundRect = path.toRoundedRect();
      if (roundRect != null) {
        localClipBounds = roundRect.outerRect;
      } else {
        final ui.Rect? rect = path.toRect();
        if (rect != null) {
          localClipBounds = rect;
        } else {
          localClipBounds = null;
        }
      }
    } else {
      localClipBounds = null;
    }
    projectedClip = null;
  }

  void _applyColor() {
    rootElement!.style.backgroundColor = colorToCssString(color)!;
  }

  @override
  DomElement createElement() {
    return super.createElement()..setAttribute('clip-type', 'physical-shape');
  }

  @override
  void discard() {
    super.discard();
    _clipElement?.remove();
    _clipElement = null;
    _svgElement?.remove();
    _svgElement = null;
  }

  @override
  void apply() {
    _applyShape();
  }

  void _applyShape() {
    _applyColor();
    // Handle special case of round rect physical shape mapping to
    // rounded div.
    final ui.RRect? roundRect = path.toRoundedRect();
    if (roundRect != null) {
      final String borderRadius =
          '${roundRect.tlRadiusX}px ${roundRect.trRadiusX}px '
          '${roundRect.brRadiusX}px ${roundRect.blRadiusX}px';
      final DomCSSStyleDeclaration style = rootElement!.style;
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
      applyCssShadow(rootElement, pathBounds, elevation, shadowColor);
      return;
    } else {
      final ui.Rect? rect = path.toRect();
      if (rect != null) {
        final DomCSSStyleDeclaration style = rootElement!.style;
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
        applyCssShadow(rootElement, pathBounds, elevation, shadowColor);
        return;
      } else {
        final ui.Rect? ovalRect = path.toCircle();
        if (ovalRect != null) {
          final double rx = ovalRect.width / 2.0;
          final double ry = ovalRect.height / 2.0;
          final String borderRadius =
              rx == ry ? '${rx}px ' : '${rx}px ${ry}px ';
          final DomCSSStyleDeclaration style = rootElement!.style;
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
          applyCssShadow(rootElement, pathBounds, elevation, shadowColor);
          return;
        }
      }
    }

    /// If code reaches this point, we have a path we want to clip against and
    /// potentially have a shadow due to material surface elevation.
    ///
    /// When there is no shadow we can simply clip a div with a background
    /// color using a svg clip path.
    ///
    /// Otherwise we need to paint svg element for the path and clip
    /// contents against same path for shadow to work since box-shadow doesn't
    /// take clip-path into account.
    ///
    /// Webkit has a bug when applying clip-path on an element that has
    /// position: absolute and transform
    /// (https://bugs.webkit.org/show_bug.cgi?id=141731).
    /// To place clipping rectangle correctly
    /// we size the inner container to cover full pathBounds instead of sizing
    /// to clipping rect bounds (which is the case for elevation == 0.0 where
    /// we shift outer/inner clip area instead to position clip-path).
    final SVGSVGElement svgClipPath = elevation == 0.0
        ? pathToSvgClipPath(path,
            offsetX: -pathBounds.left,
            offsetY: -pathBounds.top,
            scaleX: 1.0 / pathBounds.width,
            scaleY: 1.0 / pathBounds.height)
        : pathToSvgClipPath(path,
            offsetX: 0.0,
            offsetY: 0.0,
            scaleX: 1.0 / pathBounds.right,
            scaleY: 1.0 / pathBounds.bottom);

    /// If apply is called multiple times (without update), remove prior
    /// svg clip and render elements.
    _clipElement?.remove();
    _svgElement?.remove();
    _clipElement = svgClipPath;
    rootElement!.append(_clipElement!);
    if (elevation == 0.0) {
      setClipPath(rootElement!, createSvgClipUrl());
      final DomCSSStyleDeclaration rootElementStyle = rootElement!.style;
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
      return;
    }

    setClipPath(childContainer!, createSvgClipUrl());
    final DomCSSStyleDeclaration rootElementStyle = rootElement!.style;
    rootElementStyle
      ..overflow = ''
      ..left = '${pathBounds.left}px'
      ..top = '${pathBounds.top}px'
      ..width = '${pathBounds.width}px'
      ..height = '${pathBounds.height}px'
      ..borderRadius = '';
    childContainer!.style
      ..left = '-${pathBounds.left}px'
      ..top = '-${pathBounds.top}px'
      ..width = '${pathBounds.right}px'
      ..height = '${pathBounds.bottom}px';

    final ui.Rect pathBounds2 = path.getBounds();
    _svgElement = pathToSvgElement(
        path,
        SurfacePaintData()
          ..style = ui.PaintingStyle.fill
          ..color = color,
        '${pathBounds2.right}',
        '${pathBounds2.bottom}');

    /// Render element behind the clipped content.
    rootElement!.insertBefore(_svgElement!, childContainer);

    final SurfaceShadowData shadow = computeShadow(pathBounds, elevation)!;
    final ui.Color boxShadowColor = toShadowColor(shadowColor);
    _svgElement!.style
      ..filter = 'drop-shadow(${shadow.offset.dx}px ${shadow.offset.dy}px '
          '${shadow.blurWidth}px '
          'rgba(${boxShadowColor.red}, ${boxShadowColor.green}, '
          '${boxShadowColor.blue}, ${boxShadowColor.alpha / 255}))'
      ..transform = 'translate(-${pathBounds2.left}px, -${pathBounds2.top}px)';

    rootElement!.style.backgroundColor = '';
  }

  @override
  void update(PersistedPhysicalShape oldSurface) {
    super.update(oldSurface);
    final bool pathChanged = oldSurface.path != path;
    if (pathChanged) {
      localClipBounds = null;
    }
    if (pathChanged ||
        oldSurface.elevation != elevation ||
        oldSurface.shadowColor != shadowColor ||
        oldSurface.color != color) {
      oldSurface._clipElement?.remove();
      oldSurface._clipElement = null;
      oldSurface._svgElement?.remove();
      oldSurface._svgElement = null;
      _clipElement?.remove();
      _clipElement = null;
      _svgElement?.remove();
      _svgElement = null;
      // Reset style on prior element since we may have switched between
      // rect/rrect and arbitrary path.
      setClipPath(rootElement!, '');
      _applyShape();
    } else {
      // Reuse clipElement from prior surface.
      _clipElement = oldSurface._clipElement;
      if (_clipElement != null) {
        rootElement!.append(_clipElement!);
      }
      oldSurface._clipElement = null;
      _svgElement = oldSurface._svgElement;
      if (_svgElement != null) {
        rootElement!.insertBefore(_svgElement!, childContainer);
      }
      oldSurface._svgElement = null;
    }
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
  DomElement? _clipElement;

  @override
  DomElement createElement() {
    return defaultCreateElement('flt-clippath');
  }

  @override
  void recomputeTransformAndClip() {
    super.recomputeTransformAndClip();
    if (clipBehavior != ui.Clip.none) {
      localClipBounds ??= clipPath.getBounds();
    } else {
      localClipBounds = null;
    }
  }

  @override
  void apply() {
    _clipElement?.remove();
    _clipElement = createSvgClipDef(childContainer!, clipPath);
    childContainer!.append(_clipElement!);
  }

  @override
  void update(PersistedClipPath oldSurface) {
    super.update(oldSurface);
    if (oldSurface.clipPath != clipPath) {
      localClipBounds = null;
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
SVGSVGElement createSvgClipDef(DomElement element, ui.Path clipPath) {
  final ui.Rect pathBounds = clipPath.getBounds();
  final SVGSVGElement svgClipPath = pathToSvgClipPath(clipPath,
      scaleX: 1.0 / pathBounds.right, scaleY: 1.0 / pathBounds.bottom);
  setClipPath(element, createSvgClipUrl());
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
