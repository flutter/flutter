// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A layer to be composed into a scene.
///
/// A layer is the lowest-level rendering primitive. It represents an atomic
/// painting command.
abstract class Layer implements ui.EngineLayer {
  /// An estimated rectangle that this layer will draw into.
  ui.Rect paintBounds = ui.Rect.zero;

  /// Whether or not this layer actually needs to be painted in the scene.
  bool get needsPainting => !paintBounds.isEmpty;

  /// Implement layer visitor.
  R accept<R>(LayerVisitor<R> visitor);

  @override
  void dispose() {}
}

/// A layer that contains child layers.
abstract class ContainerLayer extends Layer {
  ContainerLayer({bool isEngineLayer = false}) {
    if (isEngineLayer) {
      retain();
    }
  }

  int _refCount = 0;
  bool _isDisposed = false;
  bool _isHandleDisposed = false;

  void retain() {
    assert(!_isDisposed, 'Cannot retain a disposed ContainerLayer');
    _refCount++;
  }

  void release() {
    assert(_refCount > 0, 'Cannot release a ContainerLayer with refCount == 0');
    _refCount--;
    if (_refCount == 0) {
      _isDisposed = true;
      for (final Layer child in children) {
        if (child is ContainerLayer) {
          child.release();
        } else if (child is PictureLayer) {
          child.dispose();
        }
      }
    }
  }

  final List<Layer> children = <Layer>[];

  /// The list of child layers.
  ///
  /// Useful in tests.
  List<Layer> get debugLayers => children;

  /// Register [child] as a child of this layer.
  void add(Layer child) {
    if (child is ContainerLayer) {
      child.retain();
    }
    children.add(child);
  }

  @override
  void dispose() {
    if (!_isHandleDisposed) {
      _isHandleDisposed = true;
      release();
    }
  }
}

/// The top-most layer in the layer tree.
///
/// This layer does not draw anything. It's only used so we can add leaf layers
/// to [LayerSceneBuilder] without requiring a [ContainerLayer].
class RootLayer extends ContainerLayer {
  RootLayer() : super(isEngineLayer: false);

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitRoot(this);
  }
}

class BackdropFilterEngineLayer extends ContainerLayer implements ui.BackdropFilterEngineLayer {
  BackdropFilterEngineLayer(this.filter, this.blendMode) : super(isEngineLayer: true);

  final ui.ImageFilter filter;
  final ui.BlendMode blendMode;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitBackdropFilter(this);
  }

  // TODO(dnfield): dispose of the _filter
  // https://github.com/flutter/flutter/issues/82832
}

/// A layer that clips its child layers by a given [Path].
class ClipPathEngineLayer extends ContainerLayer implements ui.ClipPathEngineLayer {
  ClipPathEngineLayer(this.clipPath, this.clipBehavior)
    : assert(clipBehavior != ui.Clip.none),
      super(isEngineLayer: true);

  /// The path used to clip child layers.
  final EnginePath clipPath;
  final ui.Clip clipBehavior;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitClipPath(this);
  }
}

/// A layer that clips its child layers by a given [Rect].
class ClipRectEngineLayer extends ContainerLayer implements ui.ClipRectEngineLayer {
  ClipRectEngineLayer(this.clipRect, this.clipBehavior)
    : assert(clipBehavior != ui.Clip.none),
      super(isEngineLayer: true);

  /// The rectangle used to clip child layers.
  final ui.Rect clipRect;
  final ui.Clip clipBehavior;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitClipRect(this);
  }
}

/// A layer that clips its child layers by a given [RRect].
class ClipRRectEngineLayer extends ContainerLayer implements ui.ClipRRectEngineLayer {
  ClipRRectEngineLayer(this.clipRRect, this.clipBehavior)
    : assert(clipBehavior != ui.Clip.none),
      super(isEngineLayer: true);

  /// The rounded rectangle used to clip child layers.
  final ui.RRect clipRRect;
  final ui.Clip? clipBehavior;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitClipRRect(this);
  }
}

/// A layer that clips its child layers by a given [RSuperellipse].
class ClipRSuperellipseEngineLayer extends ContainerLayer
    implements ui.ClipRSuperellipseEngineLayer {
  ClipRSuperellipseEngineLayer(this.clipRSuperellipse, this.clipBehavior)
    : assert(clipBehavior != ui.Clip.none),
      super(isEngineLayer: true);

  /// The rounded superellipse used to clip child layers.
  final ui.RSuperellipse clipRSuperellipse;
  final ui.Clip? clipBehavior;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitClipRSuperellipse(this);
  }
}

/// A layer that paints its children with the given opacity.
class OpacityEngineLayer extends ContainerLayer implements ui.OpacityEngineLayer {
  OpacityEngineLayer(this.alpha, this.offset) : super(isEngineLayer: true);

  final int alpha;
  final ui.Offset offset;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitOpacity(this);
  }
}

/// A layer that transforms its child layers by the given transform matrix.
class TransformEngineLayer extends ContainerLayer implements ui.TransformEngineLayer {
  TransformEngineLayer(this.transform) : super(isEngineLayer: true);

  /// The matrix with which to transform the child layers.
  final Matrix4 transform;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitTransform(this);
  }
}

/// Translates its children along x and y coordinates.
///
/// This is a thin wrapper over [TransformEngineLayer] just so the framework
/// gets the "OffsetEngineLayer" when calling `runtimeType.toString()`. This is
/// better for debugging.
class OffsetEngineLayer extends TransformEngineLayer implements ui.OffsetEngineLayer {
  OffsetEngineLayer(double dx, double dy) : super(Matrix4.translationValues(dx, dy, 0.0));

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitOffset(this);
  }
}

/// A layer that applies an [ui.ImageFilter] to its children.
class ImageFilterEngineLayer extends ContainerLayer implements ui.ImageFilterEngineLayer {
  ImageFilterEngineLayer(this.filter, this.offset) : super(isEngineLayer: true);

  final ui.Offset offset;
  final ui.ImageFilter filter;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitImageFilter(this);
  }

  // TODO(dnfield): dispose of the _filter
  // https://github.com/flutter/flutter/issues/82832
}

class ShaderMaskEngineLayer extends ContainerLayer implements ui.ShaderMaskEngineLayer {
  ShaderMaskEngineLayer(this.shader, this.maskRect, this.blendMode, this.filterQuality)
    : super(isEngineLayer: true);

  final ui.Shader shader;
  final ui.Rect maskRect;
  final ui.BlendMode blendMode;
  final ui.FilterQuality filterQuality;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitShaderMask(this);
  }
}

/// A layer containing a [Picture].
class PictureLayer extends Layer {
  PictureLayer(this.picture, this.offset, this.isComplex, this.willChange);

  /// The picture to paint into the canvas.
  final LayerPicture picture;

  /// The offset at which to paint the picture.
  final ui.Offset offset;

  /// A hint to the compositor about whether this picture is complex.
  final bool isComplex;

  /// A hint to the compositor that this picture is likely to change.
  final bool willChange;

  /// The bounds measured in the measure step.
  ui.Rect? sceneBounds;

  /// Whether or not this picture is culled in the final scene. We compute this
  /// when we optimize the scene.
  bool isCulled = false;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitPicture(this);
  }

  @override
  bool get needsPainting => super.needsPainting && !isCulled;

  @override
  void dispose() {
    if (!picture.isDisposed) {
      picture.dispose();
    }
    super.dispose();
  }
}

/// A layer which contains a [ui.ColorFilter].
class ColorFilterEngineLayer extends ContainerLayer implements ui.ColorFilterEngineLayer {
  ColorFilterEngineLayer(this.filter) : super(isEngineLayer: true);

  final ui.ColorFilter filter;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitColorFilter(this);
  }
}

/// A layer which renders a platform view (an HTML element in this case).
class PlatformViewLayer extends Layer {
  PlatformViewLayer(this.viewId, this.offset, this.width, this.height);

  final int viewId;
  final ui.Offset offset;
  final double width;
  final double height;

  @override
  R accept<R>(LayerVisitor<R> visitor) {
    return visitor.visitPlatformView(this);
  }
}
