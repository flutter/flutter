// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/container_layer.h"

#include <memory>

#include "flutter/flow/layers/transform_layer.h"

namespace flutter {

static float ClampElevation(float elevation,
                            float parent_elevation,
                            float max_elevation) {
  // TODO(mklim): Deal with bounds overflow more elegantly. We'd like to be
  // able to have developers specify the behavior here to alternatives besides
  // clamping, like normalization on some arbitrary curve.
  float clamped_elevation = elevation;
  if (max_elevation > -1 && (parent_elevation + elevation) > max_elevation) {
    // Clamp the local z coordinate at our max bound. Take into account the
    // parent z position here to fix clamping in cases where the child is
    // overflowing because of its parents.
    clamped_elevation = max_elevation - parent_elevation;
  }

  return clamped_elevation;
}

ContainerLayer::ContainerLayer(bool force_single_child) {
  // Place all "child" layers under a single child if requested.
  if (force_single_child) {
    single_child_ = std::make_shared<TransformLayer>(SkMatrix::I());
    single_child_->set_parent(this);
    layers_.push_back(single_child_);
  }
}
void ContainerLayer::Add(std::shared_ptr<Layer> layer) {
  // Place all "child" layers under a single child if requested.
  if (single_child_) {
    single_child_->Add(std::move(layer));
    return;
  }

  layer->set_parent(this);
  layers_.push_back(std::move(layer));
}

void ContainerLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ContainerLayer::Preroll");

  // Track total elevation as we walk the tree, in order to deal with bounds
  // overflow in z.
  parent_elevation_ = context->total_elevation;
  clamped_elevation_ = ClampElevation(elevation_, parent_elevation_,
                                      context->frame_physical_depth);
  context->total_elevation += clamped_elevation_;

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  for (auto& layer : layers_) {
    layer->Preroll(context, matrix);

    if (layer->needs_system_composite()) {
      set_needs_system_composite(true);
    }
    child_paint_bounds.join(layer->paint_bounds());
  }
  set_paint_bounds(child_paint_bounds);

  // Restore the elevation for our parent.
  context->total_elevation = parent_elevation_;
}

void ContainerLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting());

  // Intentionally not tracing here as there should be no self-time
  // and the trace event on this common function has a small overhead.
  for (auto& layer : layers_) {
    if (layer->needs_painting()) {
      layer->Paint(context);
    }
  }
}

void ContainerLayer::UpdateScene(SceneUpdateContext& context) {
#if defined(OS_FUCHSIA)
  if (should_render_as_frame()) {
    FML_DCHECK(needs_system_composite());

    // Retained rendering: speedup by reusing a retained entity node if
    // possible. When an entity node is reused, no paint layer is added to the
    // frame so we won't call Paint.
    LayerRasterCacheKey key(unique_id(), context.Matrix());
    if (context.HasRetainedNode(key)) {
      const scenic::EntityNode& retained_node = context.GetRetainedNode(key);
      FML_DCHECK(context.top_entity());
      FML_DCHECK(retained_node.session() == context.session());
      context.top_entity()->embedder_node().AddChild(retained_node);
      return;
    }

    SceneUpdateContext::Frame frame(context, frame_rrect_, frame_color_,
                                    frame_opacity_, elevation(), this);
    // Paint the child layers into the Frame as well as allowing them to create
    // their own scene entities.
    for (auto& layer : layers()) {
      if (layer->needs_painting()) {
        frame.AddPaintLayer(layer.get());
      }
      if (layer->needs_system_composite()) {
        layer->UpdateScene(context);
      }
    }
  } else {
    // Update all of the Layers which are part of the container.  This may cause
    // additional scene entities to be created.
    for (auto& layer : layers()) {
      if (layer->needs_system_composite()) {
        layer->UpdateScene(context);
      }
    }
  }
#endif  // defined(OS_FUCHSIA)
}

}  // namespace flutter
