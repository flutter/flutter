// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

namespace flow {
namespace {

mozart::TransformPtr GetTransformFromSkMatrix(const SkMatrix& input) {
  // Expand 3x3 to 4x4.
  auto output = mozart::Transform::New();
  output->matrix.resize(16u);
  output->matrix[0] = input[0];
  output->matrix[1] = input[1];
  output->matrix[2] = 0.f;
  output->matrix[3] = input[2];
  output->matrix[4] = input[3];
  output->matrix[5] = input[4];
  output->matrix[6] = 0.f;
  output->matrix[7] = input[5];
  output->matrix[8] = 0.f;
  output->matrix[9] = 0.f;
  output->matrix[10] = 1.f;
  output->matrix[11] = 0.f;
  output->matrix[12] = input[6];
  output->matrix[13] = input[7];
  output->matrix[14] = 0.f;
  output->matrix[15] = input[8];
  return output;
}

// TODO(abarth): We need to figure out how to allocate these ids sensibly.
static uint32_t next_id = 10;

}  // namespace

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

void ChildSceneLayer::UpdateScene(mozart::SceneUpdate* update,
                                  mozart::Node* container) {
  uint32_t id = next_id++;

  auto child_resource = mozart::Resource::New();
  child_resource->set_scene(mozart::SceneResource::New());
  child_resource->get_scene()->scene_token = mozart::SceneToken::New();
  child_resource->get_scene()->scene_token->value = scene_token_;
  update->resources.insert(id, std::move(child_resource));

  auto child_node = mozart::Node::New();
  child_node->op = mozart::NodeOp::New();
  child_node->op->set_scene(mozart::SceneNodeOp::New());
  child_node->op->get_scene()->scene_resource_id = id;
  child_node->content_clip = mozart::RectF::New();
  child_node->content_clip->width = physical_size_.width();
  child_node->content_clip->height = physical_size_.height();
  child_node->content_transform = GetTransformFromSkMatrix(transform_);
  update->nodes.insert(id, std::move(child_node));
  container->child_node_ids.push_back(id);
}

}  // namespace flow
