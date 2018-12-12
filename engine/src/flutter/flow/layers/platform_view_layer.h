// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_

#include "flutter/flow/layers/layer.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flow {

class PlatformViewLayer : public Layer {
 public:
  PlatformViewLayer();
  ~PlatformViewLayer() override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }
  void set_size(const SkSize& size) { size_ = size; }
  void set_view_id(int64_t view_id) { view_id_ = view_id; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  SkSize size_;
  int64_t view_id_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_
