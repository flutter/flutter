// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_

#include <cstdint>
#include <memory>
#include <vector>

#include "flutter/flow/layers/container_layer.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/color_filter.h"
#include "flutter/lib/ui/painting/engine_layer.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/tonic/typed_data/typed_list.h"

#if defined(LEGACY_FUCHSIA_EMBEDDER)
#include "flutter/lib/ui/compositing/scene_host.h"  // nogncheck
#endif

namespace flutter {

class SceneBuilder : public RefCountedDartWrappable<SceneBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneBuilder);

 public:
  static fml::RefPtr<SceneBuilder> create() {
    return fml::MakeRefCounted<SceneBuilder>();
  }
  ~SceneBuilder() override;

  void pushTransform(Dart_Handle layer_handle, tonic::Float64List& matrix4);
  void pushOffset(Dart_Handle layer_handle, double dx, double dy);
  void pushClipRect(Dart_Handle layer_handle,
                    double left,
                    double right,
                    double top,
                    double bottom,
                    int clipBehavior);
  void pushClipRRect(Dart_Handle layer_handle,
                     const RRect& rrect,
                     int clipBehavior);
  void pushClipPath(Dart_Handle layer_handle,
                    const CanvasPath* path,
                    int clipBehavior);
  void pushOpacity(Dart_Handle layer_handle,
                   int alpha,
                   double dx = 0,
                   double dy = 0);
  void pushColorFilter(Dart_Handle layer_handle,
                       const ColorFilter* color_filter);
  void pushImageFilter(Dart_Handle layer_handle,
                       const ImageFilter* image_filter);
  void pushBackdropFilter(Dart_Handle layer_handle, ImageFilter* filter);
  void pushShaderMask(Dart_Handle layer_handle,
                      Shader* shader,
                      double maskRectLeft,
                      double maskRectRight,
                      double maskRectTop,
                      double maskRectBottom,
                      int blendMode);
  void pushPhysicalShape(Dart_Handle layer_handle,
                         const CanvasPath* path,
                         double elevation,
                         int color,
                         int shadowColor,
                         int clipBehavior);

  void addRetained(fml::RefPtr<EngineLayer> retainedLayer);

  void pop();

  void addPerformanceOverlay(uint64_t enabledOptions,
                             double left,
                             double right,
                             double top,
                             double bottom);

  void addPicture(double dx, double dy, Picture* picture, int hints);

  void addTexture(double dx,
                  double dy,
                  double width,
                  double height,
                  int64_t textureId,
                  bool freeze,
                  int filterQuality);

  void addPlatformView(double dx,
                       double dy,
                       double width,
                       double height,
                       int64_t viewId);

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  void addChildScene(double dx,
                     double dy,
                     double width,
                     double height,
                     SceneHost* sceneHost,
                     bool hitTestable);
#endif

  void setRasterizerTracingThreshold(uint32_t frameInterval);
  void setCheckerboardRasterCacheImages(bool checkerboard);
  void setCheckerboardOffscreenLayers(bool checkerboard);

  void build(Dart_Handle scene_handle);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  SceneBuilder();

  void AddLayer(std::shared_ptr<Layer> layer);
  void PushLayer(std::shared_ptr<ContainerLayer> layer);
  void PopLayer();

  std::vector<std::shared_ptr<ContainerLayer>> layer_stack_;
  int rasterizer_tracing_threshold_ = 0;
  bool checkerboard_raster_cache_images_ = false;
  bool checkerboard_offscreen_layers_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneBuilder);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
