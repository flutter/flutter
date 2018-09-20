// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

#include "third_party/skia/include/core/SkImageFilter.h"

namespace flow {

class BackdropFilterLayer : public ContainerLayer {
 public:
  BackdropFilterLayer();
  ~BackdropFilterLayer() override;

  void set_filter(sk_sp<SkImageFilter> filter) { filter_ = std::move(filter); }

  void Paint(PaintContext& context) const override;

 private:
  sk_sp<SkImageFilter> filter_;

  FML_DISALLOW_COPY_AND_ASSIGN(BackdropFilterLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_
