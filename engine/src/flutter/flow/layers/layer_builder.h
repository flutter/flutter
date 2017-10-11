// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_
#define FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_

#include <memory>
#include <stack>

#include "flutter/flow/layers/container_layer.h"
#include "garnet/public/lib/fxl/macros.h"
#include "third_party/skia/include/core/SkBlendMode.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkShader.h"

namespace flow {

class LayerBuilder {
 public:
  LayerBuilder();

  ~LayerBuilder();

  void PushTransform(const SkMatrix& matrix);

  void PushClipRect(const SkRect& rect);

  void PushClipRoundedRect(const SkRRect& rect);

  void PushClipPath(const SkPath& path);

  void PushOpacity(int alpha);

  void PushColorFilter(SkColor color, SkBlendMode blend_mode);

  void PushBackdropFilter(sk_sp<SkImageFilter> filter);

  void PushShaderMask(sk_sp<SkShader> shader,
                      const SkRect& rect,
                      SkBlendMode blend_mode);

  void PushPhysicalModel(const SkRRect& rect,
                         double elevation,
                         SkColor color,
                         SkScalar device_pixel_ratio);

  void PushPerformanceOverlay(uint64_t enabled_options, const SkRect& rect);

  void PushPicture(const SkPoint& offset,
                   sk_sp<SkPicture> picture,
                   bool picture_is_complex,
                   bool picture_will_change);

#if defined(OS_FUCHSIA)
  void PushChildScene(const SkPoint& offset,
                      const SkSize& size,
                      fxl::RefPtr<flow::ExportNodeHolder> export_token_holder,
                      bool hit_testable);
#endif  // defined(OS_FUCHSIA)

  void Pop();

  int GetRasterizerTracingThreshold() const;

  bool GetCheckerboardRasterCacheImages() const;

  bool GetCheckerboardOffscreenLayers() const;

  void SetRasterizerTracingThreshold(uint32_t frameInterval);

  void SetCheckerboardRasterCacheImages(bool checkerboard);

  void SetCheckerboardOffscreenLayers(bool checkerboard);

  std::unique_ptr<flow::Layer> TakeLayer();

 private:
  std::unique_ptr<flow::ContainerLayer> root_layer_;
  flow::ContainerLayer* current_layer_ = nullptr;
  int rasterizer_tracing_threshold_ = 0;
  bool checkerboard_raster_cache_images_ = false;
  bool checkerboard_offscreen_layers_ = false;
  std::stack<SkRect> cull_rects_;

  void PushLayer(std::unique_ptr<flow::ContainerLayer> layer,
                 const SkRect& cullRect);

  FXL_DISALLOW_COPY_AND_ASSIGN(LayerBuilder);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_
