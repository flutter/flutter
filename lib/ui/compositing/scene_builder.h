// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_

#include <stdint.h>
#include <memory>
#include <stack>

#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/compositing/scene_host.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/engine_layer.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/tonic/typed_data/float64_list.h"

namespace blink {

class SceneBuilder : public RefCountedDartWrappable<SceneBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneBuilder);

 public:
  static fml::RefPtr<SceneBuilder> create() {
    return fml::MakeRefCounted<SceneBuilder>();
  }

  ~SceneBuilder() override;

  void pushTransform(const tonic::Float64List& matrix4);
  fml::RefPtr<EngineLayer> pushOffset(double dx, double dy);
  void pushClipRect(double left,
                    double right,
                    double top,
                    double bottom,
                    int clipBehavior);
  void pushClipRRect(const RRect& rrect, int clipBehavior);
  void pushClipPath(const CanvasPath* path, int clipBehavior);
  void pushOpacity(int alpha, double dx = 0, double dy = 0);
  void pushColorFilter(int color, int blendMode);
  void pushBackdropFilter(ImageFilter* filter);
  void pushShaderMask(Shader* shader,
                      double maskRectLeft,
                      double maskRectRight,
                      double maskRectTop,
                      double maskRectBottom,
                      int blendMode);
  fml::RefPtr<EngineLayer> pushPhysicalShape(const CanvasPath* path,
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
                  bool freeze);

  void addPlatformView(double dx,
                       double dy,
                       double width,
                       double height,
                       int64_t viewId);

  void addChildScene(double dx,
                     double dy,
                     double width,
                     double height,
                     SceneHost* sceneHost,
                     bool hitTestable);

  void setRasterizerTracingThreshold(uint32_t frameInterval);

  void setCheckerboardRasterCacheImages(bool checkerboard);
  void setCheckerboardOffscreenLayers(bool checkerboard);

  fml::RefPtr<Scene> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  SceneBuilder();

  std::shared_ptr<flow::ContainerLayer> root_layer_;
  flow::ContainerLayer* current_layer_ = nullptr;

  int rasterizer_tracing_threshold_ = 0;
  bool checkerboard_raster_cache_images_ = false;
  bool checkerboard_offscreen_layers_ = false;

  void PushLayer(std::shared_ptr<flow::ContainerLayer> layer);

  FML_DISALLOW_COPY_AND_ASSIGN(SceneBuilder);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
