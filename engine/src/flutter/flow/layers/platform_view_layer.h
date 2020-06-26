// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_

#include "flutter/flow/layers/layer.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class PlatformViewLayer : public Layer {
 public:
  PlatformViewLayer(const SkPoint& offset, const SkSize& size, int64_t view_id);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  // Updates the system composited scene.
  void UpdateScene(SceneUpdateContext& context) override;
#endif

 private:
  SkPoint offset_;
  SkSize size_;
  int64_t view_id_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_PLATFORM_VIEW_LAYER_H_
