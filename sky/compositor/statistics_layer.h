// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_STATISTICS_LAYER_H_
#define SKY_COMPOSITOR_STATISTICS_LAYER_H_

#include "base/macros.h"
#include "sky/compositor/compositor_options.h"
#include "sky/compositor/layer.h"

namespace sky {
namespace compositor {

class StatisticsLayer : public Layer {
 public:
  StatisticsLayer(uint64_t enabledOptions);

  void Paint(PaintContext::ScopedFrame& frame) override;

 private:
  CompositorOptions options_;

  DISALLOW_COPY_AND_ASSIGN(StatisticsLayer);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_STATISTICS_LAYER_H_
