// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_
#define FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_

#include <memory>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/macros.h"
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
  static std::unique_ptr<LayerBuilder> Create();

  LayerBuilder();

  virtual ~LayerBuilder();

  virtual void PushTransform(const SkMatrix& matrix) = 0;

  virtual void PushClipRect(const SkRect& rect,
                            Clip clip_behavior = Clip::antiAlias) = 0;

  virtual void PushClipRoundedRect(const SkRRect& rect,
                                   Clip clip_behavior = Clip::antiAlias) = 0;

  virtual void PushClipPath(const SkPath& path,
                            Clip clip_behavior = Clip::antiAlias) = 0;

  virtual void PushOpacity(int alpha) = 0;

  virtual void PushColorFilter(SkColor color, SkBlendMode blend_mode) = 0;

  virtual void PushBackdropFilter(sk_sp<SkImageFilter> filter) = 0;

  virtual void PushShaderMask(sk_sp<SkShader> shader,
                              const SkRect& rect,
                              SkBlendMode blend_mode) = 0;

  virtual void PushPhysicalShape(const SkPath& path,
                                 double elevation,
                                 SkColor color,
                                 SkColor shadow_color,
                                 SkScalar device_pixel_ratio,
                                 Clip clip_behavior) = 0;

  virtual void PushPerformanceOverlay(uint64_t enabled_options,
                                      const SkRect& rect) = 0;

  virtual void PushPicture(const SkPoint& offset,
                           SkiaGPUObject<SkPicture> picture,
                           bool picture_is_complex,
                           bool picture_will_change) = 0;

  virtual void PushTexture(const SkPoint& offset,
                           const SkSize& size,
                           int64_t texture_id,
                           bool freeze) = 0;

#if defined(OS_FUCHSIA)
  virtual void PushChildScene(
      const SkPoint& offset,
      const SkSize& size,
      fml::RefPtr<flow::ExportNodeHolder> export_token_holder,
      bool hit_testable) = 0;
#endif  // defined(OS_FUCHSIA)

  virtual void Pop() = 0;

  virtual std::unique_ptr<flow::Layer> TakeLayer() = 0;

  int GetRasterizerTracingThreshold() const;

  bool GetCheckerboardRasterCacheImages() const;

  bool GetCheckerboardOffscreenLayers() const;

  void SetRasterizerTracingThreshold(uint32_t frameInterval);

  void SetCheckerboardRasterCacheImages(bool checkerboard);

  void SetCheckerboardOffscreenLayers(bool checkerboard);

 private:
  int rasterizer_tracing_threshold_ = 0;
  bool checkerboard_raster_cache_images_ = false;
  bool checkerboard_offscreen_layers_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerBuilder);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_LAYER_BUILDER_H_
