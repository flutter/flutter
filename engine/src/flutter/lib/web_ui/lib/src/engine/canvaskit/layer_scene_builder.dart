// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

class LayerScene implements ui.Scene {
  final LayerTree layerTree;

  LayerScene(Layer? rootLayer) : layerTree = LayerTree() {
    layerTree.rootLayer = rootLayer;
  }

  @override
  void dispose() {}

  @override
  Future<ui.Image> toImage(int width, int height) {
    ui.Picture picture = layerTree.flatten();
    return picture.toImage(width, height);
  }
}

class LayerSceneBuilder implements ui.SceneBuilder {
  Layer? rootLayer;
  ContainerLayer? currentLayer;

  @override
  void addChildScene({
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    ui.SceneHost? sceneHost,
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
    currentLayer!.add(PictureLayer(
        picture as CkPicture, offset, isComplexHint, willChangeHint));
  }

  @override
  void addRetained(ui.EngineLayer retainedLayer) {
    if (currentLayer == null) {
      return;
    }
    currentLayer!.add(retainedLayer as Layer);
  }

  @override
  void addTexture(
    int textureId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    bool freeze = false,
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) {
    // TODO(b/128315641): implement addTexture.
  }

  @override
  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0,
    Object? webOnlyPaintedBy,
  }) {
    currentLayer!.add(PlatformViewLayer(viewId, offset, width, height));
  }

  @override
  LayerScene build() {
    return LayerScene(rootLayer);
  }

  @override
  void pop() {
    if (currentLayer == null) {
      return;
    }
    currentLayer = currentLayer!.parent;
  }

  @override
  BackdropFilterEngineLayer? pushBackdropFilter(
    ui.ImageFilter filter, {
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<BackdropFilterEngineLayer>(BackdropFilterEngineLayer(filter));
  }

  @override
  ClipPathEngineLayer? pushClipPath(
    ui.Path path, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<ClipPathEngineLayer>(ClipPathEngineLayer(path as CkPath, clipBehavior));
  }

  @override
  ClipRRectEngineLayer? pushClipRRect(
    ui.RRect rrect, {
    ui.Clip? clipBehavior,
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<ClipRRectEngineLayer>(ClipRRectEngineLayer(rrect, clipBehavior));
  }

  @override
  ClipRectEngineLayer? pushClipRect(
    ui.Rect rect, {
    ui.Clip clipBehavior = ui.Clip.antiAlias,
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<ClipRectEngineLayer>(ClipRectEngineLayer(rect, clipBehavior));
  }

  @override
  ColorFilterEngineLayer? pushColorFilter(
    ui.ColorFilter filter, {
    ui.ColorFilterEngineLayer? oldLayer,
  }) {
    assert(filter != null); // ignore: unnecessary_null_comparison
    return pushLayer<ColorFilterEngineLayer>(ColorFilterEngineLayer(filter));
  }

  ImageFilterEngineLayer? pushImageFilter(
    ui.ImageFilter filter, {
    ui.ImageFilterEngineLayer? oldLayer,
  }) {
    assert(filter != null); // ignore: unnecessary_null_comparison
    return pushLayer<ImageFilterEngineLayer>(ImageFilterEngineLayer(filter));
  }

  @override
  OffsetEngineLayer pushOffset(
    double dx,
    double dy, {
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<OffsetEngineLayer>(OffsetEngineLayer(dx, dy));
  }

  @override
  OpacityEngineLayer pushOpacity(
    int alpha, {
    ui.EngineLayer? oldLayer,
    ui.Offset offset = ui.Offset.zero,
  }) {
    return pushLayer<OpacityEngineLayer>(OpacityEngineLayer(alpha, offset));
  }

  @override
  PhysicalShapeEngineLayer pushPhysicalShape({
    required ui.Path path,
    required double elevation,
    required ui.Color color,
    ui.Color? shadowColor,
    ui.Clip clipBehavior = ui.Clip.none,
    ui.EngineLayer? oldLayer,
  }) {
    return pushLayer<PhysicalShapeEngineLayer>(PhysicalShapeEngineLayer(
      elevation,
      color,
      shadowColor,
      path as CkPath,
      clipBehavior,
    ));
  }

  @override
  ShaderMaskEngineLayer pushShaderMask(
    ui.Shader shader,
    ui.Rect maskRect,
    ui.BlendMode blendMode, {
    ui.EngineLayer? oldLayer,
  }) {
    throw UnimplementedError();
  }

  @override
  TransformEngineLayer? pushTransform(
    Float64List matrix4, {
    ui.EngineLayer? oldLayer,
  }) {
    final Matrix4 matrix = Matrix4.fromFloat32List(toMatrix32(matrix4));
    return pushLayer<TransformEngineLayer>(TransformEngineLayer(matrix));
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

  T pushLayer<T extends ContainerLayer>(T layer) {
    if (rootLayer == null) {
      rootLayer = currentLayer = layer;
      return layer;
    }

    if (currentLayer == null) {
      return layer;
    }

    currentLayer!.add(layer);
    currentLayer = layer;
    return layer;
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
