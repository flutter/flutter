// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"

#include <utility>

#include "apps/mozart/services/composition/interfaces/image.mojom.h"
#include "flutter/content_handler/skia_surface_holder.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter_content_handler {

namespace {
constexpr uint32_t kContentImageResourceId = 1;
constexpr uint32_t kRootNodeId = mozart::kSceneRootNodeId;
}  // namespace

Rasterizer::Rasterizer() {}

Rasterizer::~Rasterizer() {}

void Rasterizer::SetScene(mojo::InterfaceHandle<mozart::Scene> scene) {
  scene_.Bind(std::move(scene));
}

void Rasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                      ftl::Closure callback) {
  FTL_DCHECK(layer_tree);
  if (!scene_) {
    callback();
    return;
  }

  const SkISize& frame_size = layer_tree->frame_size();
  auto update = mozart::SceneUpdate::New();

  if (!frame_size.isEmpty()) {
    // TODO(jeffbrown): Maintain a pool of images and recycle them.
    SkiaSurfaceHolder surface_holder(frame_size);

    SkCanvas* canvas = surface_holder.surface()->getCanvas();
    flow::CompositorContext::ScopedFrame frame =
        compositor_context_.AcquireFrame(nullptr, *canvas);
    canvas->clear(SK_ColorBLACK);
    layer_tree->Raster(frame);
    canvas->flush();

    mojo::RectF bounds;
    bounds.width = frame_size.width();
    bounds.height = frame_size.height();

    auto content_resource = mozart::Resource::New();
    content_resource->set_image(mozart::ImageResource::New());
    content_resource->get_image()->image = surface_holder.TakeImage();
    update->resources.insert(kContentImageResourceId, content_resource.Pass());

    auto root_node = mozart::Node::New();
    root_node->hit_test_behavior = mozart::HitTestBehavior::New();
    root_node->op = mozart::NodeOp::New();
    root_node->op->set_image(mozart::ImageNodeOp::New());
    root_node->op->get_image()->content_rect = bounds.Clone();
    root_node->op->get_image()->image_resource_id = kContentImageResourceId;
    update->nodes.insert(kRootNodeId, root_node.Pass());

    layer_tree->UpdateScene(update.get(), root_node.get());
  } else {
    auto root_node = mozart::Node::New();
    update->nodes.insert(kRootNodeId, root_node.Pass());
  }

  scene_->Update(std::move(update));

  auto metadata = mozart::SceneMetadata::New();
  metadata->version = layer_tree->scene_version();
  scene_->Publish(std::move(metadata));

  callback();
}

}  // namespace flutter_content_handler
