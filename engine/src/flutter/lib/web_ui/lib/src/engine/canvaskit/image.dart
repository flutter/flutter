// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

/// A [BackendImage] backed by an `SkImage` from Skia.
class CkImageDelegate implements BackendImage {
  CkImageDelegate(this.skImage);

  /// The underlying CanvasKit Skia image object.
  final SkImage skImage;

  /// Returns the width of the image in pixels.
  @override
  int get width => skImage.width().toInt();

  /// Returns the height of the image in pixels.
  @override
  int get height => skImage.height().toInt();

  /// Releases the native memory allocated for the Skia image.
  @override
  void dispose() {
    skImage.delete();
  }

  /// Checks if this image delegate wraps a Skia image that is an alias (clone) of another.
  @override
  bool isCloneOf(BackendImage other) {
    return other is CkImageDelegate && other.skImage.isAliasOf(skImage);
  }
}
