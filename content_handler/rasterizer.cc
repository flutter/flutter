// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/rasterizer.h"

#include <utility>

#include "apps/mozart/lib/skia/skia_vmo_surface.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace flutter_runner {

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
  // TODO(abarth): Support incremental updates.
  update->clear_resources = true;
  update->clear_nodes = true;

  if (frame_size.isEmpty()) {
    update->nodes.insert(mozart::kSceneRootNodeId, mozart::Node::New());
    // Publish the updated scene contents.
    // TODO(jeffbrown): We should set the metadata's presentation_time here too.
    scene_->Update(std::move(update));
    auto metadata = mozart::SceneMetadata::New();
    metadata->version = layer_tree->scene_version();
    scene_->Publish(std::move(metadata));
    callback();
    return;
  }

  flow::CompositorContext::ScopedFrame frame =
      compositor_context_.AcquireFrame(nullptr, nullptr);

  layer_tree->Preroll(frame);

  flow::SceneUpdateContext context(update.get(), buffer_producer_.get());
  auto root_node = mozart::Node::New();
  layer_tree->UpdateScene(context, root_node.get());
  update->nodes.insert(mozart::kSceneRootNodeId, std::move(root_node));

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
  context.ExecutePaintTasks(frame);

  callback();
}

}  // namespace flutter_runner
