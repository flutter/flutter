// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PERFORMANCE_OVERLAY_LAYER_H_
#define SKY_COMPOSITOR_PERFORMANCE_OVERLAY_LAYER_H_

#include "base/macros.h"
#include "sky/compositor/layer.h"

namespace sky {
namespace compositor {

const int kDisplayRasterizerStatistics = 0x01;
const int kVisualizeRasterizerStatistics = 0x02;
const int kDisplayEngineStatistics = 0x04;
const int kVisualizeEngineStatistics = 0x08;

class PerformanceOverlayLayer : public Layer {
 public:
  explicit PerformanceOverlayLayer(uint64_t enabledOptions);

  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  int options_;

  DISALLOW_COPY_AND_ASSIGN(PerformanceOverlayLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PERFORMANCE_OVERLAY_LAYER_H_
