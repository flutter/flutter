// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A surface that translates its children using CSS transform and translate.
class PersistedOffset extends PersistedContainerSurface
    implements ui.OffsetEngineLayer {
  PersistedOffset(PersistedOffset? oldLayer, this.dx, this.dy) : super(oldLayer);

  /// Horizontal displacement.
  final double dx;

  /// Vertical displacement.
  final double dy;

  @override
  void recomputeTransformAndClip() {
    _transform = parent!._transform;
    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform!.clone();
      _transform!.translate(dx, dy);
    }
    _projectedClip = null;
    _localTransformInverse = null;
  }

  @override
  Matrix4 get localTransformInverse =>
      _localTransformInverse ??= Matrix4.translationValues(-dx, -dy, 0);

  @override
  html.Element createElement() {
    html.Element element = html.document.createElement('flt-offset');
    DomRenderer.setElementStyle(element, 'position', 'absolute');
    DomRenderer.setElementStyle(element, 'transform-origin', '0 0 0');
    return element;
  }

  @override
  void apply() {
    DomRenderer.setElementTransform(rootElement!, 'translate(${dx}px, ${dy}px)');
  }

  @override
  void update(PersistedOffset oldSurface) {
    super.update(oldSurface);

    if (oldSurface.dx != dx || oldSurface.dy != dy) {
      apply();
    }
  }
}
