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

namespace flutter {

class SceneBuilder : public RefCountedDartWrappable<SceneBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneBuilder);

 public:
  static void Create(Dart_Handle wrapper) {
    UIDartState::ThrowIfUIOperationsProhibited();
    auto res = fml::MakeRefCounted<SceneBuilder>();
    res->AssociateWithDartWrapper(wrapper);
  }

  ~SceneBuilder() override;

  void pushTransformHandle(Dart_Handle layer_handle,
                           Dart_Handle matrix4_handle,
                           fml::RefPtr<EngineLayer> oldLayer) {
    tonic::Float64List matrix4(matrix4_handle);
    pushTransform(layer_handle, matrix4, oldLayer);
  }
  void pushTransform(Dart_Handle layer_handle,
                     tonic::Float64List& matrix4,
                     const fml::RefPtr<EngineLayer>& oldLayer);
  void pushOffset(Dart_Handle layer_handle,
                  double dx,
                  double dy,
                  const fml::RefPtr<EngineLayer>& oldLayer);
  void pushClipRect(Dart_Handle layer_handle,
                    double left,
                    double right,
                    double top,
                    double bottom,
                    int clipBehavior,
                    const fml::RefPtr<EngineLayer>& oldLayer);
  void pushClipRRect(Dart_Handle layer_handle,
                     const RRect& rrect,
                     int clipBehavior,
                     const fml::RefPtr<EngineLayer>& oldLayer);
  void pushClipPath(Dart_Handle layer_handle,
                    const CanvasPath* path,
                    int clipBehavior,
                    const fml::RefPtr<EngineLayer>& oldLayer);
  void pushOpacity(Dart_Handle layer_handle,
                   int alpha,
                   double dx,
                   double dy,
                   const fml::RefPtr<EngineLayer>& oldLayer);
  void pushColorFilter(Dart_Handle layer_handle,
                       const ColorFilter* color_filter,
                       const fml::RefPtr<EngineLayer>& oldLayer);
  void pushImageFilter(Dart_Handle layer_handle,
                       const ImageFilter* image_filter,
                       double dx,
                       double dy,
                       const fml::RefPtr<EngineLayer>& oldLayer);
  void pushBackdropFilter(Dart_Handle layer_handle,
                          ImageFilter* filter,
                          int blendMode,
                          const fml::RefPtr<EngineLayer>& oldLayer);
  void pushShaderMask(Dart_Handle layer_handle,
                      Shader* shader,
                      double maskRectLeft,
                      double maskRectRight,
                      double maskRectTop,
                      double maskRectBottom,
                      int blendMode,
                      int filterQualityIndex,
                      const fml::RefPtr<EngineLayer>& oldLayer);

  void addRetained(const fml::RefPtr<EngineLayer>& retainedLayer);

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

  void setRasterizerTracingThreshold(uint32_t frameInterval);
  void setCheckerboardRasterCacheImages(bool checkerboard);
  void setCheckerboardOffscreenLayers(bool checkerboard);

  void build(Dart_Handle scene_handle);

  const std::vector<std::shared_ptr<ContainerLayer>>& layer_stack() {
    return layer_stack_;
  }

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
