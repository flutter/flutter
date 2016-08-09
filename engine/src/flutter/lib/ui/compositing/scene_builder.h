// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_

#include <stdint.h>

#include <memory>

#include "flutter/flow/layers/container_layer.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/shader.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float64_list.h"

namespace blink {

class SceneBuilder : public ftl::RefCountedThreadSafe<SceneBuilder>,
                     public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SceneBuilder);

 public:
  static ftl::RefPtr<SceneBuilder> create() {
    return ftl::MakeRefCounted<SceneBuilder>();
  }

  ~SceneBuilder() override;

  void pushTransform(const tonic::Float64List& matrix4);
  void pushClipRect(double left, double right, double top, double bottom);
  void pushClipRRect(const RRect& rrect);
  void pushClipPath(const CanvasPath* path);
  void pushOpacity(int alpha);
  void pushColorFilter(int color, int transferMode);
  void pushBackdropFilter(ImageFilter* filter);
  void pushShaderMask(Shader* shader,
                      double maskRectLeft,
                      double maskRectRight,
                      double maskRectTop,
                      double maskRectBottom,
                      int transferMode);
  void pop();

  void addPerformanceOverlay(uint64_t enabledOptions,
                             double left,
                             double right,
                             double top,
                             double bottom);
  void addPicture(double dx, double dy, Picture* picture, int hints);
  void addChildScene(double dx,
                     double dy,
                     double devicePixelRatio,
                     int physicalWidth,
                     int physicalHeight,
                     uint32_t sceneToken);

  void setRasterizerTracingThreshold(uint32_t frameInterval);

  ftl::RefPtr<Scene> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit SceneBuilder();

  void addLayer(std::unique_ptr<flow::ContainerLayer> layer);

  std::unique_ptr<flow::ContainerLayer> m_rootLayer;
  flow::ContainerLayer* m_currentLayer;
  int32_t m_currentRasterizerTracingThreshold;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_BUILDER_H_
