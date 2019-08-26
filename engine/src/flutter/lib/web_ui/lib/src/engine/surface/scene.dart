// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A surface that creates a DOM element for whole app.
class PersistedScene extends PersistedContainerSurface {
  PersistedScene(PersistedScene oldLayer) : super(oldLayer) {
    _transform = Matrix4.identity();
  }

  @override
  void recomputeTransformAndClip() {
    // The scene clip is the size of the entire window.
    // TODO(yjbanov): in the add2app scenario where we might be hosted inside
    //                a custom element, this will be different. We will need to
    //                update this code when we add add2app support.
    final double screenWidth = html.window.innerWidth.toDouble();
    final double screenHeight = html.window.innerHeight.toDouble();
    _localClipBounds = ui.Rect.fromLTRB(0, 0, screenWidth, screenHeight);
    _localTransformInverse = Matrix4.identity();
    _projectedClip = null;
  }

  @override
  Matrix4 get localTransformInverse => _localTransformInverse;

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-scene');
  }

  @override
  void apply() {}
}
