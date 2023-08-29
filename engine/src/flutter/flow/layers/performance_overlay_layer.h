// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_

#include <string>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/stopwatch.h"
#include "flutter/fml/macros.h"

class SkTextBlob;

namespace flutter {

const int kDisplayRasterizerStatistics = 1 << 0;
const int kVisualizeRasterizerStatistics = 1 << 1;
const int kDisplayEngineStatistics = 1 << 2;
const int kVisualizeEngineStatistics = 1 << 3;

class PerformanceOverlayLayer : public Layer {
 public:
  static sk_sp<SkTextBlob> MakeStatisticsText(const Stopwatch& stopwatch,
                                              const std::string& label_prefix,
                                              const std::string& font_path);

  bool IsReplacing(DiffContext* context, const Layer* layer) const override {
    return layer->as_performance_overlay_layer() != nullptr;
  }

  void Diff(DiffContext* context, const Layer* old_layer) override;

  const PerformanceOverlayLayer* as_performance_overlay_layer() const override {
    return this;
  }

  explicit PerformanceOverlayLayer(uint64_t options,
                                   const char* font_path = nullptr);

  void Preroll(PrerollContext* context) override {}
  void Paint(PaintContext& context) const override;

 private:
  int options_;
  std::string font_path_;

  FML_DISALLOW_COPY_AND_ASSIGN(PerformanceOverlayLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_
