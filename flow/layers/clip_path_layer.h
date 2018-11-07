// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CLIP_PATH_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CLIP_PATH_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class ClipPathLayer : public ContainerLayer {
 public:
  ClipPathLayer(Clip clip_behavior = Clip::antiAlias);
  ~ClipPathLayer() override;

  void set_clip_path(const SkPath& clip_path) { clip_path_ = clip_path; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  SkPath clip_path_;
  Clip clip_behavior_;

  FML_DISALLOW_COPY_AND_ASSIGN(ClipPathLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_CLIP_PATH_LAYER_H_
