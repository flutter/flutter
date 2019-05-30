// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A surface that creates a DOM element for whole app.
class PersistedScene extends PersistedContainerSurface {
  PersistedScene() : super(const Object()) {
    _transform = Matrix4.identity();
  }

  @override
  bool isTotalMatchFor(PersistedSurface other) {
    // The scene is a special-case kind of surface in that it is the only root
    // layer in the tree. Therefore it can always be updated from a previous
    // scene. There's no ambiguity about whether you can accidentally pick a
    // false match.
    assert(other is PersistedScene);
    return true;
  }

  @override
  void recomputeTransformAndClip() {
    // The scene clip is the size of the entire window.
    // TODO(yjbanov): in the add2app scenario where we might be hosted inside
    //                a custom element, this will be different. We will need to
    //                update this code when we add add2app support.
    final double screenWidth = html.window.innerWidth.toDouble();
    final double screenHeight = html.window.innerHeight.toDouble();
    _globalClip = ui.Rect.fromLTRB(0, 0, screenWidth, screenHeight);
  }

  @override
  html.Element createElement() {
    return defaultCreateElement('flt-scene');
  }

  @override
  void apply() {}
}
