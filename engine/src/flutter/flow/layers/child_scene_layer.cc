// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/child_scene_layer.h"

#include "mojo/skia/type_converters.h"

namespace flow {

// TODO(abarth): We need to figure out how to allocate these ids sensibly.
static uint32_t next_id = 10;

ChildSceneLayer::ChildSceneLayer() : device_pixel_ratio_(1.0f) {}

ChildSceneLayer::~ChildSceneLayer() {}

void ChildSceneLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  transform_ = matrix;
  transform_.preTranslate(offset_.x(), offset_.y());
  float inverse_device_pixel_ratio = 1.f / device_pixel_ratio_;
  transform_.preScale(inverse_device_pixel_ratio, inverse_device_pixel_ratio);
}

void ChildSceneLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ChildSceneLayer::Paint");
}

void ChildSceneLayer::UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                                  mojo::gfx::composition::Node* container) {
  uint32_t id = next_id++;

  auto child_resource = mojo::gfx::composition::Resource::New();
  child_resource->set_scene(mojo::gfx::composition::SceneResource::New());
  child_resource->get_scene()->scene_token = scene_token_.Clone();
  update->resources.insert(id, child_resource.Pass());

  auto child_node = mojo::gfx::composition::Node::New();
  child_node->op = mojo::gfx::composition::NodeOp::New();
  child_node->op->set_scene(mojo::gfx::composition::SceneNodeOp::New());
  child_node->op->get_scene()->scene_resource_id = id;
  child_node->content_clip = mojo::RectF::New();
  child_node->content_clip->width = physical_size_.width();
  child_node->content_clip->height = physical_size_.height();
  child_node->content_transform = mojo::Transform::From(transform_);
  update->nodes.insert(id, child_node.Pass());
  container->child_node_ids.push_back(id);
}

}  // namespace flow
