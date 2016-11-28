// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"

namespace flow {

ChildSceneLayer::ChildSceneLayer() = default;

ChildSceneLayer::~ChildSceneLayer() = default;

void ChildSceneLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  set_needs_system_composite(true);
  transform_.setIdentity();
  transform_.preTranslate(offset_.x(), offset_.y());
  float inverse_device_pixel_ratio = 1.f / device_pixel_ratio_;
  transform_.preScale(inverse_device_pixel_ratio, inverse_device_pixel_ratio);

  SkRect bounds =
      SkRect::MakeXYWH(offset_.x(), offset_.y(),
                       physical_size_.width() * inverse_device_pixel_ratio,
                       physical_size_.height() * inverse_device_pixel_ratio);
  set_paint_bounds(bounds);
  context->child_paint_bounds = bounds;
}

void ChildSceneLayer::Paint(PaintContext& context) {
  FTL_DCHECK(false) << "Failed to composite child scene.";
}

void ChildSceneLayer::UpdateScene(SceneUpdateContext& context,
                                  mozart::Node* container) {
  FTL_DCHECK(needs_system_composite());

  auto resource = mozart::Resource::New();
  resource->set_scene(mozart::SceneResource::New());
  resource->get_scene()->scene_token = mozart::SceneToken::New();
  resource->get_scene()->scene_token->value = scene_token_;

  auto node = mozart::Node::New();
  if (!hittable_) {
    node->hit_test_behavior = mozart::HitTestBehavior::New();
    node->hit_test_behavior->prune = true;
  }
  node->op = mozart::NodeOp::New();
  node->op->set_scene(mozart::SceneNodeOp::New());
  node->op->get_scene()->scene_resource_id =
      context.AddResource(std::move(resource));
  node->content_clip = mozart::RectF::New();
  node->content_clip->width = physical_size_.width();
  node->content_clip->height = physical_size_.height();
  node->content_transform = mozart::Transform::From(transform_);

  context.AddChildNode(container, std::move(node));
}

}  // namespace flow
