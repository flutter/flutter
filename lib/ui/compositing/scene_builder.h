// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_

#include <stdint.h>
#include <memory>
#include <stack>

#include "flutter/flow/layers/layer_builder.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/compositing/scene_host.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/shader.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float64_list.h"

namespace blink {

class SceneBuilder : public fxl::RefCountedThreadSafe<SceneBuilder>,
                     public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SceneBuilder);

 public:
  static fxl::RefPtr<SceneBuilder> create() {
    return fxl::MakeRefCounted<SceneBuilder>();
  }

  ~SceneBuilder() override;

  void pushTransform(const tonic::Float64List& matrix4);
  void pushClipRect(double left, double right, double top, double bottom);
  void pushClipRRect(const RRect& rrect);
  void pushClipPath(const CanvasPath* path);
  void pushOpacity(int alpha);
  void pushColorFilter(int color, int blendMode);
  void pushBackdropFilter(ImageFilter* filter);
  void pushShaderMask(Shader* shader,
                      double maskRectLeft,
                      double maskRectRight,
                      double maskRectTop,
                      double maskRectBottom,
                      int blendMode);
  void pushPhysicalShape(const CanvasPath* path, double elevation, int color, int shadowColor);

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
                  int64_t textureId);

  void addChildScene(double dx,
                     double dy,
                     double width,
                     double height,
                     SceneHost* sceneHost,
                     bool hitTestable);

  void setRasterizerTracingThreshold(uint32_t frameInterval);

  void setCheckerboardRasterCacheImages(bool checkerboard);
  void setCheckerboardOffscreenLayers(bool checkerboard);

  fxl::RefPtr<Scene> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  SceneBuilder();

  std::unique_ptr<flow::LayerBuilder> layer_builder_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
