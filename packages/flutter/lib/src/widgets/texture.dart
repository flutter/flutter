// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'framework.dart';

/// A rectangle upon which a backend texture is mapped. Backend textures are
/// created, managed, and updated through platform-specific means. This is
/// typically handled by a plugin written using the host platform video player,
/// camera, or OpenGL APIs.
///
/// Texture widgets are repainted autonomously as dictated by the backend (e.g.
/// on arrival of a video frame). Such repainting generally does not involve
/// executing Dart code.
///
/// The size of the rectangle is determined by its parent widget, and the
/// texture is automatically scaled to fit.
class Texture extends LeafRenderObjectWidget {
  /// Creates a widget backed by the texture identified by [textureId].
  const Texture({ Key key, @required this.textureId }): super(key: key);

  /// The identity of the backend texture.
  final int textureId;

  @override
  TextureBox createRenderObject(BuildContext context) => new TextureBox(textureId: textureId);

  @override
  void updateRenderObject(BuildContext context, TextureBox renderObject) {
    renderObject.textureId = textureId;
  }
}
