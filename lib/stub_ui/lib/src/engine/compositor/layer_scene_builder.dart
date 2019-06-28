// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  @override
  html.Element get webOnlyRootElement => null;
}

class LayerSceneBuilder implements ui.SceneBuilder {
  Layer rootLayer;
  ContainerLayer currentLayer;

  @override
  void addChildScene(
      {ui.Offset offset = ui.Offset.zero,
      double width = 0.0,
      double height = 0.0,
      ui.SceneHost sceneHost,
      bool hitTestable = true}) {
    throw new UnimplementedError();
  }

  @override
  void addPerformanceOverlay(int enabledOptions, ui.Rect bounds,
      {Object webOnlyPaintedBy}) {
    // We don't plan to implement this on the web.
    throw UnimplementedError();
  }

  @override
  void addPicture(ui.Offset offset, ui.Picture picture,
      {bool isComplexHint = false,
      bool willChangeHint = false,
      Object webOnlyPaintedBy}) {
    currentLayer
        .add(PictureLayer(picture, offset, isComplexHint, willChangeHint));
  }

  @override
  void addRetained(ui.EngineLayer retainedLayer) {
    if (currentLayer == null) return;
    currentLayer.add(retainedLayer);
  }

  @override
  void addTexture(int textureId,
      {ui.Offset offset = ui.Offset.zero,
      double width = 0.0,
      double height = 0.0,
      bool freeze = false,
      Object webOnlyPaintedBy}) {
    // TODO(b/128315641): implement addTexture.
  }

  @override
  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
  }) {
    // TODO(b/128317425): implement addPlatformView.
  }

  @override
  ui.Scene build() {
    return LayerScene(rootLayer);
  }

  @override
  void pop() {
    if (currentLayer == null) return;
    currentLayer = currentLayer.parent;
  }

  @override
  ui.BackdropFilterEngineLayer pushBackdropFilter(ui.ImageFilter filter,
      {ui.BackdropFilterEngineLayer oldLayer}) {
    throw new UnimplementedError();
  }

  @override
  ui.ClipPathEngineLayer pushClipPath(ui.Path path,
      {ui.Clip clipBehavior = ui.Clip.antiAlias, ui.ClipPathEngineLayer oldLayer}) {
    pushLayer(ClipPathLayer(path));
    return null;
  }

  @override
  ui.ClipRRectEngineLayer pushClipRRect(ui.RRect rrect,
      {ui.Clip clipBehavior, ui.ClipRRectEngineLayer oldLayer}) {
    pushLayer(ClipRRectLayer(rrect));
    return null;
  }

  @override
  ui.ClipRectEngineLayer pushClipRect(ui.Rect rect,
      {ui.Clip clipBehavior = ui.Clip.antiAlias, ui.ClipRectEngineLayer oldLayer}) {
    pushLayer(ClipRectLayer(rect));
    return null;
  }

  @override
  ui.ColorFilterEngineLayer pushColorFilter(ui.Color color, ui.BlendMode blendMode,
      {ui.ColorFilterEngineLayer oldLayer}) {
    throw new UnimplementedError();
  }

  @override
  ui.OffsetEngineLayer pushOffset(double dx, double dy, {ui.OffsetEngineLayer oldLayer}) {
    final matrix = Matrix4.translationValues(dx, dy, 0.0);
    final layer = TransformLayer(matrix);
    pushLayer(layer);
    return layer;
  }

  @override
  ui.OpacityEngineLayer pushOpacity(int alpha,
      {ui.OpacityEngineLayer oldLayer, ui.Offset offset = ui.Offset.zero}) {
    // TODO(het): Implement opacity
    pushOffset(0.0, 0.0);
    return null;
  }

  @override
  ui.PhysicalShapeEngineLayer pushPhysicalShape(
      {ui.Path path,
      double elevation,
      ui.Color color,
      ui.Color shadowColor,
      ui.Clip clipBehavior = ui.Clip.none,
      ui.PhysicalShapeEngineLayer oldLayer}) {
    final layer =
        PhysicalShapeLayer(elevation, color, shadowColor, path, clipBehavior);
    pushLayer(layer);
    return layer;
  }

  @override
  ui.ShaderMaskEngineLayer pushShaderMask(
      ui.Shader shader, ui.Rect maskRect, ui.BlendMode blendMode,
      {ui.ShaderMaskEngineLayer oldLayer}) {
    throw new UnimplementedError();
  }

  @override
  ui.TransformEngineLayer pushTransform(Float64List matrix4, {ui.TransformEngineLayer oldLayer}) {
    final Matrix4 matrix = Matrix4.fromList(matrix4);
    final TransformLayer layer = TransformLayer(matrix);
    pushLayer(layer);
    return layer;
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

    if (currentLayer == null) return;

    currentLayer.add(layer);
    currentLayer = layer;
  }
}
