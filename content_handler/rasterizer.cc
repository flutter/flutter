// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"

#include <utility>

#include "apps/mozart/lib/skia/skia_vmo_surface.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter_runner {

namespace {
constexpr uint32_t kContentImageResourceId = 1;
constexpr uint32_t kRootNodeId = mozart::kSceneRootNodeId;
}  // namespace

Rasterizer::Rasterizer() {}

Rasterizer::~Rasterizer() {}

void Rasterizer::SetScene(fidl::InterfaceHandle<mozart::Scene> scene) {
  scene_.Bind(std::move(scene));
  buffer_producer_.reset(new mozart::BufferProducer());
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

  if (frame_size.isEmpty()) {
    update->nodes.insert(kRootNodeId, mozart::Node::New());
    // Publish the updated scene contents.
    // TODO(jeffbrown): We should set the metadata's presentation_time here too.
    scene_->Update(std::move(update));
    auto metadata = mozart::SceneMetadata::New();
    metadata->version = layer_tree->scene_version();
    scene_->Publish(std::move(metadata));
    callback();
    return;
  }

  // Get a surface to draw the contents.
  mozart::ImagePtr image;
  sk_sp<SkSurface> surface =
      mozart::MakeSkSurface(frame_size, buffer_producer_.get(), &image);

  FTL_CHECK(surface);

  flow::CompositorContext::ScopedFrame frame =
      compositor_context_.AcquireFrame(nullptr, *surface->getCanvas());

  layer_tree->Preroll(frame);

  // Update the scene contents.
  mozart::RectF bounds;
  bounds.width = frame_size.width();
  bounds.height = frame_size.height();

  auto content_resource = mozart::Resource::New();
  content_resource->set_image(mozart::ImageResource::New());
  content_resource->get_image()->image = std::move(image);
  update->resources.insert(kContentImageResourceId,
                           std::move(content_resource));

  auto root_node = mozart::Node::New();
  root_node->hit_test_behavior = mozart::HitTestBehavior::New();
  root_node->op = mozart::NodeOp::New();
  root_node->op->set_image(mozart::ImageNodeOp::New());
  root_node->op->get_image()->content_rect = bounds.Clone();
  root_node->op->get_image()->image_resource_id = kContentImageResourceId;

  layer_tree->UpdateScene(update.get(), root_node.get());

  update->nodes.insert(kRootNodeId, std::move(root_node));

  // Publish the updated scene contents.
  // TODO(jeffbrown): We should set the metadata's presentation_time here too.
  scene_->Update(std::move(update));
  auto metadata = mozart::SceneMetadata::New();
  metadata->version = layer_tree->scene_version();
  scene_->Publish(std::move(metadata));

  // Draw the contents of the scene to a surface.
  // We do this after publishing to take advantage of pipelining.
  // The image buffer's fence is signalled automatically when the surface
  // goes out of scope.
  SkCanvas* canvas = surface->getCanvas();
  canvas->clear(SK_ColorBLACK);
  layer_tree->Paint(frame);
  canvas->flush();

  callback();
}

}  // namespace flutter_runner
