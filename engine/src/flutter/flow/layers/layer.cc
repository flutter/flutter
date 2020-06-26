// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer.h"

#include "flutter/flow/paint_utils.h"
#include "third_party/skia/include/core/SkColorFilter.h"

namespace flutter {

Layer::Layer()
    : paint_bounds_(SkRect::MakeEmpty()),
      unique_id_(NextUniqueID()),
      needs_system_composite_(false) {}

Layer::~Layer() = default;

uint64_t Layer::NextUniqueID() {
  static std::atomic<uint64_t> nextID(1);
  uint64_t id;
  do {
    id = nextID.fetch_add(1);
  } while (id == 0);  // 0 is reserved for an invalid id.
  return id;
}

void Layer::Preroll(PrerollContext* context, const SkMatrix& matrix) {}

Layer::AutoPrerollSaveLayerState::AutoPrerollSaveLayerState(
    PrerollContext* preroll_context,
    bool save_layer_is_active,
    bool layer_itself_performs_readback)
    : preroll_context_(preroll_context),
      save_layer_is_active_(save_layer_is_active),
      layer_itself_performs_readback_(layer_itself_performs_readback) {
  if (save_layer_is_active_) {
    prev_surface_needs_readback_ = preroll_context_->surface_needs_readback;
    preroll_context_->surface_needs_readback = false;
  }
}

Layer::AutoPrerollSaveLayerState Layer::AutoPrerollSaveLayerState::Create(
    PrerollContext* preroll_context,
    bool save_layer_is_active,
    bool layer_itself_performs_readback) {
  return Layer::AutoPrerollSaveLayerState(preroll_context, save_layer_is_active,
                                          layer_itself_performs_readback);
}

Layer::AutoPrerollSaveLayerState::~AutoPrerollSaveLayerState() {
  if (save_layer_is_active_) {
    preroll_context_->surface_needs_readback =
        (prev_surface_needs_readback_ || layer_itself_performs_readback_);
  }
}

#if defined(LEGACY_FUCHSIA_EMBEDDER)

void Layer::CheckForChildLayerBelow(PrerollContext* context) {
  child_layer_exists_below_ = context->child_scene_layer_exists_below;
  if (child_layer_exists_below_) {
    set_needs_system_composite(true);
  }
}

void Layer::UpdateScene(SceneUpdateContext& context) {
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
  }
}

#endif

Layer::AutoSaveLayer::AutoSaveLayer(const PaintContext& paint_context,
                                    const SkRect& bounds,
                                    const SkPaint* paint)
    : paint_context_(paint_context), bounds_(bounds) {
  paint_context_.internal_nodes_canvas->saveLayer(bounds_, paint);
}

Layer::AutoSaveLayer::AutoSaveLayer(const PaintContext& paint_context,
                                    const SkCanvas::SaveLayerRec& layer_rec)
    : paint_context_(paint_context), bounds_(*layer_rec.fBounds) {
  paint_context_.internal_nodes_canvas->saveLayer(layer_rec);
}

Layer::AutoSaveLayer Layer::AutoSaveLayer::Create(
    const PaintContext& paint_context,
    const SkRect& bounds,
    const SkPaint* paint) {
  return Layer::AutoSaveLayer(paint_context, bounds, paint);
}

Layer::AutoSaveLayer Layer::AutoSaveLayer::Create(
    const PaintContext& paint_context,
    const SkCanvas::SaveLayerRec& layer_rec) {
  return Layer::AutoSaveLayer(paint_context, layer_rec);
}

Layer::AutoSaveLayer::~AutoSaveLayer() {
  if (paint_context_.checkerboard_offscreen_layers) {
    DrawCheckerboard(paint_context_.internal_nodes_canvas, bounds_);
  }
  paint_context_.internal_nodes_canvas->restore();
}

}  // namespace flutter
