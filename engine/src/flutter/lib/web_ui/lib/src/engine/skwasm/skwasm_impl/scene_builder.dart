// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmScene implements ui.Scene {
  SkwasmScene(this.picture);

  final ui.Picture picture;

  @override
  void dispose() {
    picture.dispose();
  }

  @override
  Future<ui.Image> toImage(int width, int height) {
    return picture.toImage(width, height);
  }

  @override
  ui.Image toImageSync(int width, int height) {
    return picture.toImageSync(width, height);
  }

}

class SkwasmSceneBuilder implements ui.SceneBuilder {
  LayerBuilder currentBuilder = LayerBuilder.rootLayer();

  @override
  void addPerformanceOverlay(int enabledOptions, ui.Rect bounds) {
    // We don't plan to implement this on the web.
    throw UnimplementedError();
  }

  @override
  void addPicture(
    ui.Offset offset,
    ui.Picture picture, {
    bool isComplexHint = false,
    bool willChangeHint = false
  }) {
    currentBuilder.addPicture(
      offset,
      picture,
      isComplexHint:
      isComplexHint,
      willChangeHint: willChangeHint
    );
  }

  @override
  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0
  }) {
    throw UnimplementedError('Platform view not yet implemented with skwasm renderer.');
  }

  @override
  void addRetained(ui.EngineLayer retainedLayer) {
    final ui.Picture? picture = (retainedLayer as PictureLayer).picture;
    if (picture == null) {
      throw StateError('Adding incomplete retained layer.');
    }
    currentBuilder.addPicture(ui.Offset.zero, picture);
  }

  @override
  void addTexture(
    int textureId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    bool freeze = false,
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) {
    // TODO(jacksongardner): implement addTexture
  }

  @override
  ui.BackdropFilterEngineLayer pushBackdropFilter(
    ui.ImageFilter filter, {
    ui.BlendMode blendMode = ui.BlendMode.srcOver,
    ui.BackdropFilterEngineLayer? oldLayer
  }) {
    return pushLayer<BackdropFilterLayer>(
      BackdropFilterLayer(),
      BackdropFilterOperation()
    );
  }

  @override
  ui.ClipPathEngineLayer pushClipPath(
    ui.Path path, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.ClipPathEngineLayer? oldLayer
  }) {
    return pushLayer<ClipPathLayer>(
      ClipPathLayer(),
      ClipPathOperation(path, clipBehavior),
    );
  }

  @override
  ui.ClipRRectEngineLayer pushClipRRect(
    ui.RRect rrect, {
    required ui.Clip clipBehavior,
    ui.ClipRRectEngineLayer? oldLayer
  }) {
    return pushLayer<ClipRRectLayer>(
      ClipRRectLayer(),
      ClipRRectOperation(rrect, clipBehavior)
    );
  }

  @override
  ui.ClipRectEngineLayer pushClipRect(
    ui.Rect rect, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.ClipRectEngineLayer? oldLayer
  }) {
    return pushLayer<ClipRectLayer>(
      ClipRectLayer(),
      ClipRectOperation(rect, clipBehavior)
    );
  }

  @override
  ui.ColorFilterEngineLayer pushColorFilter(
    ui.ColorFilter filter, {
    ui.ColorFilterEngineLayer? oldLayer
  }) {
    return pushLayer<ColorFilterLayer>(
      ColorFilterLayer(),
      ColorFilterOperation(),
    );
  }

  @override
  ui.ImageFilterEngineLayer pushImageFilter(
    ui.ImageFilter filter, {
    ui.Offset offset = ui.Offset.zero,
    ui.ImageFilterEngineLayer? oldLayer
  }) {
    return pushLayer<ImageFilterLayer>(
      ImageFilterLayer(),
      ImageFilterOperation(),
    );
  }

  @override
  ui.OffsetEngineLayer pushOffset(
    double dx,
    double dy, {
    ui.OffsetEngineLayer? oldLayer
  }) {
    return pushLayer<OffsetLayer>(
      OffsetLayer(),
      OffsetOperation(dx, dy)
    );
  }

  @override
  ui.OpacityEngineLayer pushOpacity(int alpha, {
    ui.Offset offset = ui.Offset.zero,
    ui.OpacityEngineLayer? oldLayer
  }) {
    return pushLayer<OpacityLayer>(
      OpacityLayer(),
      OpacityOperation(alpha, offset),
    );
  }

  @override
  ui.PhysicalShapeEngineLayer pushPhysicalShape({
    required ui.Path path,
    required double elevation,
    required ui.Color color,
    ui.Color? shadowColor,
    ui.Clip clipBehavior = ui.Clip.none,
    ui.PhysicalShapeEngineLayer? oldLayer
  }) {
    // TODO(jacksongardner): implement pushPhysicalShape
    throw UnimplementedError();
  }

  @override
  ui.ShaderMaskEngineLayer pushShaderMask(
    ui.Shader shader,
    ui.Rect maskRect,
    ui.BlendMode blendMode, {
    ui.ShaderMaskEngineLayer? oldLayer,
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) {
    // TODO(jacksongardner): implement pushShaderMask
    throw UnimplementedError();
  }

  @override
  ui.TransformEngineLayer pushTransform(
    Float64List matrix4, {
    ui.TransformEngineLayer? oldLayer
  }) {
    return pushLayer<TransformLayer>(
      TransformLayer(),
      TransformOperation(matrix4),
    );
  }

  @override
  void setCheckerboardOffscreenLayers(bool checkerboard) {
    // TODO(jacksongardner): implement setCheckerboardOffscreenLayers
  }

  @override
  void setCheckerboardRasterCacheImages(bool checkerboard) {
    // TODO(jacksongardner): implement setCheckerboardRasterCacheImages
  }

  @override
  void setProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable
  ) {
    // TODO(jacksongardner): implement setProperties
  }

  @override
  void setRasterizerTracingThreshold(int frameInterval) {
    // TODO(jacksongardner): implement setRasterizerTracingThreshold
  }

  @override
  ui.Scene build() {
    while (currentBuilder.parent != null) {
      pop();
    }
    final ui.Picture finalPicture = currentBuilder.build();
    return SkwasmScene(finalPicture);
  }

  @override
  void pop() {
    final ui.Picture picture = currentBuilder.build();
    final LayerBuilder? parentBuilder = currentBuilder.parent;
    if (parentBuilder == null) {
      throw StateError('Popped too many times.');
    }
    currentBuilder = parentBuilder;
    currentBuilder.addPicture(ui.Offset.zero, picture);
  }

  T pushLayer<T extends PictureLayer>(T layer, LayerOperation operation) {
    currentBuilder = LayerBuilder.childLayer(
      parent: currentBuilder,
      layer: layer,
      operation: operation
    );
    return layer;
  }
}
