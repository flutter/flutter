// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A surface that makes its children transparent.
class PersistedOpacity extends PersistedContainerSurface
    implements ui.OpacityEngineLayer {
  PersistedOpacity(PersistedOpacity? oldLayer, this.alpha, this.offset)
      : super(oldLayer);

  final int alpha;
  final ui.Offset offset;

  @override
  void recomputeTransformAndClip() {
    _transform = parent!._transform;

    final double dx = offset.dx;
    final double dy = offset.dy;

    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform!.clone();
      _transform!.translate(dx, dy);
    }
    _localTransformInverse = null;
    _projectedClip = null;
  }

  @override
  Matrix4 get localTransformInverse => _localTransformInverse ??=
      Matrix4.translationValues(-offset.dx, -offset.dy, 0);

  @override
  html.Element createElement() {
    html.Element element = domRenderer.createElement('flt-opacity');
    DomRenderer.setElementStyle(element, 'position', 'absolute');
    DomRenderer.setElementStyle(element, 'transform-origin', '0 0 0');
    return element;
  }

  @override
  void apply() {
    html.Element element = rootElement!;
    DomRenderer.setElementStyle(element, 'opacity', '${alpha / 255}');
    DomRenderer.setElementTransform(element, 'translate(${offset.dx}px, ${offset.dy}px)');
  }

  @override
  void update(PersistedOpacity oldSurface) {
    super.update(oldSurface);
    if (alpha != oldSurface.alpha || offset != oldSurface.offset) {
      apply();
    }
  }
}
