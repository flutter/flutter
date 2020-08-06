// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

ContainerLayer::ContainerLayer() {}

void ContainerLayer::Add(std::shared_ptr<Layer> layer) {
  layers_.emplace_back(std::move(layer));
}

void ContainerLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ContainerLayer::Preroll");

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);
  set_paint_bounds(child_paint_bounds);
}

void ContainerLayer::Paint(PaintContext& context) const {
  FML_DCHECK(needs_painting());

  PaintChildren(context);
}

void ContainerLayer::PrerollChildren(PrerollContext* context,
                                     const SkMatrix& child_matrix,
                                     SkRect* child_paint_bounds) {
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  child_layer_exists_below_ = context->child_scene_layer_exists_below;
  context->child_scene_layer_exists_below = false;
#endif

  // Platform views have no children, so context->has_platform_view should
  // always be false.
  FML_DCHECK(!context->has_platform_view);
  bool child_has_platform_view = false;
  for (auto& layer : layers_) {
    // Reset context->has_platform_view to false so that layers aren't treated
    // as if they have a platform view based on one being previously found in a
    // sibling tree.
    context->has_platform_view = false;

    layer->Preroll(context, child_matrix);

    if (layer->needs_system_composite()) {
      set_needs_system_composite(true);
    }
    child_paint_bounds->join(layer->paint_bounds());

    child_has_platform_view =
        child_has_platform_view || context->has_platform_view;
  }

  context->has_platform_view = child_has_platform_view;

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  if (child_layer_exists_below_) {
    set_needs_system_composite(true);
  }
  context->child_scene_layer_exists_below =
      context->child_scene_layer_exists_below || child_layer_exists_below_;
#endif
}

void ContainerLayer::PaintChildren(PaintContext& context) const {
  FML_DCHECK(needs_painting());

  // Intentionally not tracing here as there should be no self-time
  // and the trace event on this common function has a small overhead.
  for (auto& layer : layers_) {
    if (layer->needs_painting()) {
      layer->Paint(context);
    }
  }
}

void ContainerLayer::TryToPrepareRasterCache(PrerollContext* context,
                                             Layer* layer,
                                             const SkMatrix& matrix) {
  if (!context->has_platform_view && context->raster_cache &&
      SkRect::Intersects(context->cull_rect, layer->paint_bounds())) {
    context->raster_cache->Prepare(context, layer, matrix);
  }
}

#if defined(LEGACY_FUCHSIA_EMBEDDER)

void ContainerLayer::CheckForChildLayerBelow(PrerollContext* context) {
  // All ContainerLayers make the check in PrerollChildren.
}

void ContainerLayer::UpdateScene(SceneUpdateContext& context) {
  UpdateSceneChildren(context);
}

void ContainerLayer::UpdateSceneChildren(SceneUpdateContext& context) {
  auto update_scene_layers = [&] {
    // Paint all of the layers which need to be drawn into the container.
    // These may be flattened down to a containing Scenic Frame.
    for (auto& layer : layers_) {
      if (layer->needs_system_composite()) {
        layer->UpdateScene(context);
      }
    }
  };

  FML_DCHECK(needs_system_composite());

  // If there is embedded Fuchsia content in the scene (a ChildSceneLayer),
  // PhysicalShapeLayers that appear above the embedded content will be turned
  // into their own Scenic layers.
  if (child_layer_exists_below_) {
    float global_scenic_elevation =
        context.GetGlobalElevationForNextScenicLayer();
    float local_scenic_elevation =
        global_scenic_elevation - context.scenic_elevation();
    float z_translation = -local_scenic_elevation;

    // Retained rendering: speedup by reusing a retained entity node if
    // possible. When an entity node is reused, no paint layer is added to the
    // frame so we won't call PhysicalShapeLayer::Paint.
    LayerRasterCacheKey key(unique_id(), context.Matrix());
    if (context.HasRetainedNode(key)) {
      TRACE_EVENT_INSTANT0("flutter", "retained layer cache hit");
      scenic::EntityNode* retained_node = context.GetRetainedNode(key);
      FML_DCHECK(context.top_entity());
      FML_DCHECK(retained_node->session() == context.session());

      // Re-adjust the elevation.
      retained_node->SetTranslation(0.f, 0.f, z_translation);

      context.top_entity()->entity_node().AddChild(*retained_node);
      return;
    }

    TRACE_EVENT_INSTANT0("flutter", "cache miss, creating");
    // If we can't find an existing retained surface, create one.
    SceneUpdateContext::Frame frame(
        context, SkRRect::MakeRect(paint_bounds()), SK_ColorTRANSPARENT,
        SkScalarRoundToInt(context.alphaf() * 255),
        "flutter::PhysicalShapeLayer", z_translation, this);

    frame.AddPaintLayer(this);

    // Node: UpdateSceneChildren needs to be called here so that |frame| is
    // still in scope (and therefore alive) while UpdateSceneChildren is being
    // called.
    float scenic_elevation = context.scenic_elevation();
    context.set_scenic_elevation(scenic_elevation + local_scenic_elevation);
    update_scene_layers();
    context.set_scenic_elevation(scenic_elevation);
  } else {
    update_scene_layers();
  }
}

#endif

MergedContainerLayer::MergedContainerLayer() {
  // Ensure the layer has only one direct child.
  //
  // Any children will actually be added as children of this empty
  // ContainerLayer which can be accessed via ::GetContainerLayer().
  // If only one child is ever added to this layer then that child
  // will become the layer returned from ::GetCacheableChild().
  // If multiple child layers are added, then this implicit container
  // child becomes the cacheable child, but at the potential cost of
  // not being as stable in the raster cache from frame to frame.
  ContainerLayer::Add(std::make_shared<ContainerLayer>());
}

void MergedContainerLayer::Add(std::shared_ptr<Layer> layer) {
  GetChildContainer()->Add(std::move(layer));
}

ContainerLayer* MergedContainerLayer::GetChildContainer() const {
  FML_DCHECK(layers().size() == 1);

  return static_cast<ContainerLayer*>(layers()[0].get());
}

Layer* MergedContainerLayer::GetCacheableChild() const {
  ContainerLayer* child_container = GetChildContainer();
  if (child_container->layers().size() == 1) {
    return child_container->layers()[0].get();
  }

  return child_container;
}

}  // namespace flutter
