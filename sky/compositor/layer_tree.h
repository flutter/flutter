// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_TREE_H_
#define SKY_COMPOSITOR_LAYER_TREE_H_

#include <memory>

#include "base/macros.h"
#include "base/time/time.h"
#include "sky/compositor/layer.h"
#include "third_party/skia/include/core/SkSize.h"

namespace sky {
namespace compositor {

class LayerTree {
 public:
  LayerTree();
  ~LayerTree();

  Layer* root_layer() const { return root_layer_.get(); }

  void set_root_layer(std::unique_ptr<Layer> root_layer) {
    root_layer_ = std::move(root_layer);
  }

  const SkISize& frame_size() const { return frame_size_; }

  void set_frame_size(const SkISize& frame_size) { frame_size_ = frame_size; }

  void set_construction_time(const base::TimeDelta& delta) {
    construction_time_ = delta;
  }

  const base::TimeDelta& construction_time() const {
    return construction_time_;
  }

 private:
  SkISize frame_size_;  // Physical pixels.
  std::unique_ptr<Layer> root_layer_;

  base::TimeDelta construction_time_;

  DISALLOW_COPY_AND_ASSIGN(LayerTree);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_TREE_H_
