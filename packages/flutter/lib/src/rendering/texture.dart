// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'box.dart';
import 'layer.dart';
import 'object.dart';

/// A rectangle upon which a backend texture is mapped. Backend textures are
/// created, managed, and updated through platform-specific means. This is
/// typically handled by a plugin written using the host platform video player,
/// camera, or OpenGL APIs.
///
/// Texture boxes are repainted autonomously as dictated by the backend (e.g.
/// on arrival of a video frame). Such repainting generally does not involve
/// executing Dart code.
///
/// The size of the rectangle is determined by the parent, and the texture is
/// automatically scaled to fit.
class TextureBox extends RenderBox {
  /// Creates a box backed by the texture identified by [textureId].
  TextureBox({ int textureId }) : _textureId = textureId;

  int _textureId;

  /// Sets the identity of the backend texture to map.
  set textureId(int value) {
    if (value != _textureId) {
      _textureId = value;
      markNeedsPaint();
    }
  }

  /// The identity of the backend texture.
  int get textureId => _textureId;

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_textureId == null) {
      return;
    }
    context.addLayer(new TextureLayer(
      rect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      textureId: _textureId,
    ));
  }
}
