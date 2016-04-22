// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_LAYERS_CHILD_SCENE_LAYER_H_
#define FLOW_LAYERS_CHILD_SCENE_LAYER_H_

#include "flow/layers/layer.h"
#include "mojo/services/gfx/composition/interfaces/scenes.mojom.h"

namespace flow {

class ChildSceneLayer : public Layer {
 public:
  ChildSceneLayer();
  ~ChildSceneLayer() override;

  void set_offset(const SkPoint& offset) { offset_ = offset; }

  void set_device_pixel_ratio(float device_pixel_ratio) {
    device_pixel_ratio_ = device_pixel_ratio;
  }

  void set_physical_size(const SkISize& physical_size) {
    physical_size_ = physical_size;
  }

  void set_scene_token(mojo::gfx::composition::SceneTokenPtr scene_token) {
    scene_token_ = scene_token.Pass();
  }

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) override;
  void UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                   mojo::gfx::composition::Node* container) override;

 private:
  SkPoint offset_;
  float device_pixel_ratio_;
  SkISize physical_size_;
  mojo::gfx::composition::SceneTokenPtr scene_token_;
  SkMatrix transform_;

  DISALLOW_COPY_AND_ASSIGN(ChildSceneLayer);
};

}  // namespace flow

#endif  // FLOW_LAYERS_CHILD_SCENE_LAYER_H_
