// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/scene_update_context.h"

#if defined(OS_FUCHSIA)

#include "apps/mozart/lib/skia/skia_vmo_surface.h"
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/scenes.fidl.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/glue/trace_event.h"

namespace flow {

SceneUpdateContext::CurrentPaintTask::CurrentPaintTask()
    : bounds(SkRect::MakeEmpty()) {}

void SceneUpdateContext::CurrentPaintTask::Clear() {
  bounds = SkRect::MakeEmpty();
  layers.clear();
}

SceneUpdateContext::SceneUpdateContext(mozart::SceneUpdate* update,
                                       mozart::BufferProducer* buffer_producer)
    : update_(update), buffer_producer_(buffer_producer) {}

SceneUpdateContext::~SceneUpdateContext() = default;

void SceneUpdateContext::AddLayerToCurrentPaintTask(Layer* layer) {
  current_paint_task_.bounds.join(layer->paint_bounds());
  current_paint_task_.layers.push_back(layer);
}

void SceneUpdateContext::FinalizeCurrentPaintTaskIfNeeded(
    mozart::Node* container,
    const SkMatrix& ctm) {
  if (mozart::NodePtr node = FinalizeCurrentPaintTask(ctm))
    AddChildNode(container, std::move(node));
}

mozart::NodePtr SceneUpdateContext::FinalizeCurrentPaintTask(
    const SkMatrix& ctm) {
  if (current_paint_task_.layers.empty())
    return nullptr;

  const SkRect& bounds = current_paint_task_.bounds;

  SkScalar scaleX = ctm.getScaleX();
  SkScalar scaleY = ctm.getScaleY();

  SkISize physical_size =
      SkISize::Make(bounds.width() * scaleX, bounds.height() * scaleY);

  if (physical_size.isEmpty()) {
    current_paint_task_.Clear();
    return nullptr;
  }

  mozart::ImagePtr image;
  PaintTask task;
  task.surface = mozart::MakeSkSurface(physical_size, buffer_producer_, &image);
  task.left = bounds.left();
  task.top = bounds.top();
  task.scaleX = scaleX;
  task.scaleY = scaleY;
  task.layers = std::move(current_paint_task_.layers);

  FTL_DCHECK(task.surface) << "Failed to create surface size="
                           << physical_size.width() << "x"
                           << physical_size.height();

  paint_tasks_.push_back(task);

  auto resource = mozart::Resource::New();
  resource->set_image(mozart::ImageResource::New());
  resource->get_image()->image = std::move(image);

  auto node = mozart::Node::New();
  node->hit_test_behavior = mozart::HitTestBehavior::New();
  node->op = mozart::NodeOp::New();
  node->op->set_image(mozart::ImageNodeOp::New());
  node->op->get_image()->content_rect = mozart::RectF::From(bounds);
  node->op->get_image()->image_resource_id = AddResource(std::move(resource));

  current_paint_task_.Clear();
  return node;
}

uint32_t SceneUpdateContext::AddResource(mozart::ResourcePtr resource) {
  uint32_t resource_id = next_resource_id_++;
  update_->resources.insert(resource_id, std::move(resource));
  return resource_id;
}

void SceneUpdateContext::AddChildNode(mozart::Node* container,
                                      mozart::NodePtr child) {
  uint32_t node_id = next_node_id_++;
  update_->nodes.insert(node_id, std::move(child));
  container->child_node_ids.push_back(node_id);
}

void SceneUpdateContext::ExecutePaintTasks(
    CompositorContext::ScopedFrame& frame) {
  TRACE_EVENT0("flutter", "SceneUpdateContext::ExecutePaintTasks");

  for (auto& task : paint_tasks_) {
    FTL_DCHECK(task.surface);
    SkCanvas* canvas = task.surface->getCanvas();
    Layer::PaintContext context = {*canvas, frame.context().frame_time(),
                                   frame.context().engine_time()};

    canvas->clear(SK_ColorTRANSPARENT);
    canvas->scale(task.scaleX, task.scaleY);
    canvas->translate(-task.left, -task.top);
    for (Layer* layer : task.layers)
      layer->Paint(context);
    canvas->flush();
  }

  paint_tasks_.clear();
}

}  // namespace flow

#endif  // defined(OS_FUCHSIA)
