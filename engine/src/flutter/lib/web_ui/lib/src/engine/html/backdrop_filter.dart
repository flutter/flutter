// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A surface that applies an image filter to background.
class PersistedBackdropFilter extends PersistedContainerSurface
    implements ui.BackdropFilterEngineLayer {
  PersistedBackdropFilter(PersistedBackdropFilter? oldLayer, this.filter)
      : super(oldLayer);

  final EngineImageFilter filter;

  /// The dedicated child container element that's separate from the
  /// [rootElement] is used to host child in front of [filterElement] that
  /// is transformed to cover background.
  @override
  html.Element? get childContainer => _childContainer;
  html.Element? _childContainer;
  html.Element? _filterElement;
  ui.Rect? _activeClipBounds;
  // Cached inverted transform for _transform.
  late Matrix4 _invertedTransform;
  // Reference to transform last used to cache [_invertedTransform].
  Matrix4? _previousTransform;

  @override
  void adoptElements(PersistedBackdropFilter oldSurface) {
    super.adoptElements(oldSurface);
    _childContainer = oldSurface._childContainer;
    _filterElement = oldSurface._filterElement;
    oldSurface._childContainer = null;
  }

  @override
  html.Element createElement() {
    final html.Element element = defaultCreateElement('flt-backdrop')
      ..style.transformOrigin = '0 0 0';
    _childContainer = html.Element.tag('flt-backdrop-interior');
    _childContainer!.style.position = 'absolute';
    if (_debugExplainSurfaceStats) {
      // This creates an additional interior element. Count it too.
      _surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    _filterElement = defaultCreateElement('flt-backdrop-filter');
    _filterElement!.style.transformOrigin = '0 0 0';
    element..append(_filterElement!)..append(_childContainer!);
    return element;
  }

  @override
  void discard() {
    super.discard();
    // Do not detach the child container from the root. It is permanently
    // attached. The elements are reused together and are detached from the DOM
    // together.
    _childContainer = null;
    _filterElement = null;
  }

  @override
  void apply() {
    if (_previousTransform != _transform) {
      _invertedTransform = Matrix4.inverted(_transform!);
      _previousTransform = _transform;
    }
    // https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html
    // Defines the effective area as the parent/ancestor clip or if not
    // available, the whole screen.
    //
    // The CSS backdrop-filter will use isolation boundary defined in
    // https://drafts.fxtf.org/filter-effects-2/#BackdropFilterProperty
    // Therefore we need to use parent clip element bounds for
    // backdrop boundary.
    final double dpr = ui.window.devicePixelRatio;
    ui.Rect rect = transformRect(_invertedTransform, ui.Rect.fromLTRB(0, 0,
        ui.window.physicalSize.width * dpr,
        ui.window.physicalSize.height * dpr));
    double left = rect.left;
    double top = rect.top;
    double width = rect.width;
    double height = rect.height;
    PersistedContainerSurface? parentSurface = parent;
    while (parentSurface != null) {
      if (parentSurface.isClipping) {
        final ui.Rect activeClipBounds = (_activeClipBounds = parentSurface._localClipBounds)!;
        left = activeClipBounds.left;
        top = activeClipBounds.top;
        width = activeClipBounds.width;
        height = activeClipBounds.height;
        break;
      }
      parentSurface = parentSurface.parent;
    }
    final html.CssStyleDeclaration filterElementStyle = _filterElement!.style;
    filterElementStyle
      ..position = 'absolute'
      ..left = '${left}px'
      ..top = '${top}px'
      ..width = '${width}px'
      ..height = '${height}px';
    if (browserEngine == BrowserEngine.firefox) {
      // For FireFox for now render transparent black background.
      // TODO(flutter_web): Switch code to use filter when
      // See https://caniuse.com/#feat=css-backdrop-filter.
      filterElementStyle
        ..backgroundColor = '#000'
        ..opacity = '0.2';
    } else {
      // CSS uses pixel radius for blur. Flutter & SVG use sigma parameters. For
      // Gaussian blur with standard deviation (normal distribution),
      // the blur will fall within 2 * sigma pixels.
      if (browserEngine == BrowserEngine.webkit) {
        DomRenderer.setElementStyle(_filterElement!, '-webkit-backdrop-filter',
            _imageFilterToCss(filter));
      }
      DomRenderer.setElementStyle(_filterElement!, 'backdrop-filter', _imageFilterToCss(filter));
    }
  }

  @override
  void update(PersistedBackdropFilter oldSurface) {
    super.update(oldSurface);
    if (filter != oldSurface.filter) {
      apply();
    } else {
      _checkForUpdatedAncestorClipElement();
    }
  }

  void _checkForUpdatedAncestorClipElement() {
    // If parent clip element has moved, adjust bounds.
    PersistedContainerSurface? parentSurface = parent;
    while (parentSurface != null) {
      if (parentSurface.isClipping) {
        if (parentSurface._localClipBounds != _activeClipBounds) {
          apply();
        }
        break;
      }
      parentSurface = parentSurface.parent;
    }
  }

  @override
  void retain() {
    super.retain();
    _checkForUpdatedAncestorClipElement();
  }
}
