// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_
#define FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_

#include "flow/layers/layer.h"
#include "lib/ftl/macros.h"

namespace flow {

const int kDisplayRasterizerStatistics = 0x01;
const int kVisualizeRasterizerStatistics = 0x02;
const int kDisplayEngineStatistics = 0x04;
const int kVisualizeEngineStatistics = 0x08;

class PerformanceOverlayLayer : public Layer {
 public:
  explicit PerformanceOverlayLayer(uint64_t options);

  void Paint(PaintContext& context) override;

 private:
  int options_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PerformanceOverlayLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_PERFORMANCE_OVERLAY_LAYER_H_
