// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'framework.dart';

/// A rectangle upon which a backend texture is mapped.
///
/// Backend textures are images that can be applied (mapped) to an area of the
/// Flutter view. They are created, managed, and updated using a
/// platform-specific texture registry. This is typically done by a plugin
/// that integrates with host platform video player, camera, or OpenGL APIs,
/// or similar image sources.
///
/// A texture widget refers to its backend texture using an integer ID. Texture
/// IDs are obtained from the texture registry and are scoped to the Flutter
/// view. Texture IDs may be reused after deregistration, at the discretion
/// of the registry. The use of texture IDs currently unknown to the registry
/// will silently result in a blank rectangle.
///
/// Texture widgets are repainted autonomously as dictated by the backend (e.g.
/// on arrival of a video frame). Such repainting generally does not involve
/// executing Dart code.
///
/// The size of the rectangle is determined by its parent widget, and the
/// texture is automatically scaled to fit.
///
/// See also:
///
/// * <https://docs.flutter.io/javadoc/io/flutter/view/TextureRegistry.html>
///   for how to create and manage backend textures on Android.
/// * <https://docs.flutter.io/objcdoc/Protocols/FlutterTextureRegistry.html>
///   for how to create and manage backend textures on iOS.
class Texture extends LeafRenderObjectWidget {
  /// Creates a widget backed by the texture identified by [textureId].
  const Texture({ Key key, @required this.textureId }): assert(textureId != null), super(key: key);

  /// The identity of the backend texture.
  final int textureId;

  @override
  TextureBox createRenderObject(BuildContext context) => TextureBox(textureId: textureId);

  @override
  void updateRenderObject(BuildContext context, TextureBox renderObject) {
    renderObject.textureId = textureId;
  }
}
