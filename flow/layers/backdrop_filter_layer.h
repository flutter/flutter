// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_
#define FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_

#include "flow/layers/container_layer.h"

namespace flow {

class BackdropFilterLayer : public ContainerLayer {
 public:
  BackdropFilterLayer();
  ~BackdropFilterLayer() override;

  void set_filter(sk_sp<SkImageFilter> filter) { filter_ = std::move(filter); }

 protected:
  void Paint(PaintContext& context) override;

 private:
  sk_sp<SkImageFilter> filter_;

  FTL_DISALLOW_COPY_AND_ASSIGN(BackdropFilterLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_BACKDROP_FILTER_LAYER_H_
