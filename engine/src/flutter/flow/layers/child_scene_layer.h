// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_

#include "flutter/flow/export_node.h"
#include "flutter/flow/layers/layer.h"

namespace flow {

// Layer that represents an embedded child.
class ChildSceneLayer : public Layer {
 public:
  ChildSceneLayer();
  ~ChildSceneLayer() override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }

  void set_size(const SkSize& size) { size_ = size; }

  void set_export_node_holder(
      fxl::RefPtr<ExportNodeHolder> export_node_holder) {
    export_node_holder_ = std::move(export_node_holder);
  }

  void set_hit_testable(bool hit_testable) { hit_testable_ = hit_testable; }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) override;

  void UpdateScene(SceneUpdateContext& context) override;

 private:
  SkPoint offset_;
  SkSize size_;
  fxl::RefPtr<ExportNodeHolder> export_node_holder_;
  bool hit_testable_ = true;

  FXL_DISALLOW_COPY_AND_ASSIGN(ChildSceneLayer);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_CHILD_SCENE_LAYER_H_
