// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// These are additional APIs that are not part of the `dart:ui` interface that
/// are needed internally to properly implement a `SceneBuilder` on top of the
/// generic Canvas/Picture api.
library scene_painting;

import 'package:ui/ui.dart' as ui;

import '../vector_math.dart';

/// A [ui.Canvas] with the additional method [saveLayerWithFilter] which allows
/// the caller to pass an explicit [ui.ImageFilter] which is applied to the
/// layer when [restore] is called.
abstract class LayerCanvas implements ui.Canvas {
  /// This is the same as a normal `saveLayer` call, but we can pass a backdrop image filter.
  void saveLayerWithFilter(ui.Rect? bounds, ui.Paint paint, ui.ImageFilter backdropFilter);

  /// Clears the canvas and replaces it with the given [color].
  void clear(ui.Color color);

  /// Returns [true] if [rect] can quickly be determined to be clipped out of
  /// canvas. May give false negatives, but never false positives.
  bool quickReject(ui.Rect rect);
}

/// A [ui.Picture] that provides approximate bounds for the drawings contained
/// within it.
abstract class LayerPicture implements ui.Picture {
  // This is a conservative bounding box of all the drawing primitives in this picture.
  ui.Rect get cullRect;

  /// Creates a copy of this picture.
  ///
  /// The copy points to the same underlying Skia picture as this picture.
  LayerPicture clone();

  /// Returns `true` if the picture has been disposed.
  bool get isDisposed;
}

/// A [ui.PictureRecorder] which allows callers to know if it has been disposed.
abstract class LayerPictureRecorder implements ui.PictureRecorder {
  /// Whether this reference to the underlying picture recorder is [dispose]d.
  ///
  /// This only returns a valid value if asserts are enabled, and must not be
  /// used otherwise.
  bool get debugDisposed;
}

/// A [ui.ImageFilter] with helper methods for picture measurement and layout.
abstract class LayerImageFilter implements ui.ImageFilter {
  // Since some image filters affect the actual drawing bounds of a given picture, this
  // gives the maximum draw boundary for a picture with the given input bounds after it
  // has been processed by the filter.
  ui.Rect filterBounds(ui.Rect inputBounds);

  // The matrix image filter changes the position of the content, so when positioning
  // platform views and calculating occlusion we need to take its transform into account.
  Matrix4? get transform;

  @override
  String get debugShortDescription => toString();
}

/// A [ui.Path] with a helper method to convert it to an SVG string.
abstract class LayerPath implements ui.Path {
  // In order to properly clip platform views with paths, we need to be able to get a
  // string representation of them.
  String toSvgString();
}
