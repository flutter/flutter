// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class LayerScene implements ui.Scene {
  final LayerTree layerTree;

  LayerScene(Layer rootLayer) : layerTree = LayerTree() {
    layerTree.rootLayer = rootLayer;
  }

  @override
  void dispose() {}

  @override
  Future<ui.Image> toImage(int width, int height) => null;

  html.Element get webOnlyRootElement => null;
}

class LayerSceneBuilder implements ui.SceneBuilder {
  Layer rootLayer;
  ContainerLayer currentLayer;

  @override
  void addChildScene({
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    ui.SceneHost sceneHost,
    bool hitTestable = true,
  }) {
    throw UnimplementedError();
  }

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
    bool willChangeHint = false,
  }) {
    currentLayer.add(PictureLayer(picture, offset, isComplexHint, willChangeHint));
  }

  @override
  void addRetained(ui.EngineLayer retainedLayer) {
    if (currentLayer == null) {
      return;
    }
    currentLayer.add(retainedLayer);
  }

  @override
  void addTexture(
    int textureId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    bool freeze = false,
  }) {
    // TODO(b/128315641): implement addTexture.
  }

  @override
  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    Object webOnlyPaintedBy,
  }) {
    currentLayer.add(PlatformViewLayer(viewId, offset, width, height));
  }

  @override
  ui.Scene build() {
    return LayerScene(rootLayer);
  }

  @override
  void pop() {
    if (currentLayer == null) {
      return;
    }
    currentLayer = currentLayer.parent;
  }

  @override
  ui.BackdropFilterEngineLayer pushBackdropFilter(
    ui.ImageFilter filter, {
    ui.EngineLayer oldLayer,
  }) {
    pushLayer(BackdropFilterLayer(filter));
    return null;
  }

  @override
  ui.ClipPathEngineLayer pushClipPath(
    ui.Path path, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.EngineLayer oldLayer,
  }) {
    pushLayer(ClipPathLayer(path, clipBehavior));
    return null;
  }

  @override
  ui.ClipRRectEngineLayer pushClipRRect(
    ui.RRect rrect, {
    ui.Clip clipBehavior,
    ui.EngineLayer oldLayer,
  }) {
    pushLayer(ClipRRectLayer(rrect, clipBehavior));
    return null;
  }

  @override
  ui.ClipRectEngineLayer pushClipRect(
    ui.Rect rect, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.EngineLayer oldLayer,
  }) {
    pushLayer(ClipRectLayer(rect, clipBehavior));
    return null;
  }

  @override
  ui.ColorFilterEngineLayer pushColorFilter(
    ui.ColorFilter filter, {
    ui.ColorFilterEngineLayer oldLayer,
  }) {
    assert(filter != null);
    throw UnimplementedError();
  }

  ui.ImageFilterEngineLayer pushImageFilter(
    ui.ImageFilter filter, {
    ui.ImageFilterEngineLayer oldLayer,
  }) {
    assert(filter != null);
    pushLayer(ImageFilterLayer(filter));
    return null;
  }

  @override
  ui.OffsetEngineLayer pushOffset(
    double dx,
    double dy, {
    ui.EngineLayer oldLayer,
  }) {
    final Matrix4 matrix = Matrix4.translationValues(dx, dy, 0.0);
    final TransformLayer layer = TransformLayer(matrix);
    pushLayer(layer);
    return layer;
  }

  @override
  ui.OpacityEngineLayer pushOpacity(
    int alpha, {
    ui.EngineLayer oldLayer,
    ui.Offset offset = ui.Offset.zero,
  }) {
    final OpacityLayer layer = OpacityLayer(alpha, offset);
    pushLayer(layer);
    return layer;
  }

  @override
  ui.PhysicalShapeEngineLayer pushPhysicalShape({
    ui.Path path,
    double elevation,
    ui.Color color,
    ui.Color shadowColor,
    ui.Clip clipBehavior = ui.Clip.none,
    ui.EngineLayer oldLayer,
  }) {
    final PhysicalShapeLayer layer =
        PhysicalShapeLayer(elevation, color, shadowColor, path, clipBehavior);
    pushLayer(layer);
    return layer;
  }

  @override
  ui.ShaderMaskEngineLayer pushShaderMask(
    ui.Shader shader,
    ui.Rect maskRect,
    ui.BlendMode blendMode, {
    ui.EngineLayer oldLayer,
  }) {
    throw UnimplementedError();
  }

  @override
  ui.TransformEngineLayer pushTransform(
    Float64List matrix4, {
    ui.EngineLayer oldLayer,
  }) {
    final Matrix4 matrix = Matrix4.fromFloat32List(toMatrix32(matrix4));
    pushLayer(TransformLayer(matrix));
    return null;
  }

  @override
  void setCheckerboardOffscreenLayers(bool checkerboard) {
    // TODO: implement setCheckerboardOffscreenLayers
  }

  @override
  void setCheckerboardRasterCacheImages(bool checkerboard) {
    // TODO: implement setCheckerboardRasterCacheImages
  }

  @override
  void setRasterizerTracingThreshold(int frameInterval) {
    // TODO: implement setRasterizerTracingThreshold
  }

  void pushLayer(ContainerLayer layer) {
    if (rootLayer == null) {
      rootLayer = currentLayer = layer;
      return;
    }

    if (currentLayer == null) {
      return;
    }

    currentLayer.add(layer);
    currentLayer = layer;
  }

  @override
  void setProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable,
  ) {
    throw UnimplementedError();
  }
}
