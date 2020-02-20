// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A surface that makes its children transparent.
class PersistedOpacity extends PersistedContainerSurface
    implements ui.OpacityEngineLayer {
  PersistedOpacity(PersistedOpacity oldLayer, this.alpha, this.offset)
      : super(oldLayer);

  final int alpha;
  final ui.Offset offset;

  @override
  void recomputeTransformAndClip() {
    _transform = parent._transform;

    final double dx = offset.dx;
    final double dy = offset.dy;

    if (dx != 0.0 || dy != 0.0) {
      _transform = _transform.clone();
      _transform.translate(dx, dy);
    }
    _localTransformInverse = null;
    _projectedClip = null;
  }

  @override
  Matrix4 get localTransformInverse => _localTransformInverse ??=
      Matrix4.translationValues(-offset.dx, -offset.dy, 0);

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-opacity')..style.transformOrigin = '0 0 0';
  }

  @override
  void apply() {
    // TODO(yjbanov): evaluate using `filter: opacity(X)`. It is a longer string
    //                but it reportedly has better hardware acceleration, so may
    //                be worth the trade-off.
    rootElement.style.opacity = '${alpha / 255}';
    rootElement.style.transform = 'translate(${offset.dx}px, ${offset.dy}px)';
  }

  @override
  void update(PersistedOpacity oldSurface) {
    super.update(oldSurface);
    if (alpha != oldSurface.alpha || offset != oldSurface.offset) {
      apply();
    }
  }
}
