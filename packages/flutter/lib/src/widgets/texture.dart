// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'framework.dart';

/// A [Widget] backed by a texture.
class Texture extends LeafRenderObjectWidget {
  /// Creates a widget backed by the texture identified by [textureId].
  const Texture({ Key key, @required this.textureId }): super(key: key);

  /// The identity of the texture backing this widget.
  final int textureId;

  @override
  TextureBox createRenderObject(BuildContext context) => new TextureBox(textureId: textureId);

  @override
  void updateRenderObject(BuildContext context, TextureBox renderObject) {
    renderObject.textureId = textureId;
  }
}
