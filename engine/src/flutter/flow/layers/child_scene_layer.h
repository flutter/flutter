// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/scene_update_context.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

// Layer that represents an embedded child.
class ChildSceneLayer : public Layer {
 public:
  ChildSceneLayer(zx_koid_t layer_id,
                  const SkPoint& offset,
                  const SkSize& size,
                  bool hit_testable);
  ~ChildSceneLayer() override = default;

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

  void UpdateScene(std::shared_ptr<SceneUpdateContext> context) override;

 private:
  zx_koid_t layer_id_ = ZX_KOID_INVALID;
  SkPoint offset_;
  SkSize size_;
  bool hit_testable_ = true;

  FML_DISALLOW_COPY_AND_ASSIGN(ChildSceneLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_
