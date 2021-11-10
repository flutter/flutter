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
      original_layer_id_(unique_id_),
      subtree_has_platform_view_(false) {}

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

Layer::AutoSaveLayer::AutoSaveLayer(const PaintContext& paint_context,
                                    const SkRect& bounds,
                                    const SkPaint* paint,
                                    SaveMode save_mode)
    : paint_context_(paint_context),
      bounds_(bounds),
      canvas_(save_mode == SaveMode::kInternalNodesCanvas
                  ? *(paint_context.internal_nodes_canvas)
                  : *(paint_context.leaf_nodes_canvas)) {
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  canvas_.saveLayer(bounds_, paint);
}

Layer::AutoSaveLayer::AutoSaveLayer(const PaintContext& paint_context,
                                    const SkCanvas::SaveLayerRec& layer_rec,
                                    SaveMode save_mode)
    : paint_context_(paint_context),
      bounds_(*layer_rec.fBounds),
      canvas_(save_mode == SaveMode::kInternalNodesCanvas
                  ? *(paint_context.internal_nodes_canvas)
                  : *(paint_context.leaf_nodes_canvas)) {
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  canvas_.saveLayer(layer_rec);
}

Layer::AutoSaveLayer Layer::AutoSaveLayer::Create(
    const PaintContext& paint_context,
    const SkRect& bounds,
    const SkPaint* paint,
    SaveMode save_mode) {
  return Layer::AutoSaveLayer(paint_context, bounds, paint, save_mode);
}

Layer::AutoSaveLayer Layer::AutoSaveLayer::Create(
    const PaintContext& paint_context,
    const SkCanvas::SaveLayerRec& layer_rec,
    SaveMode save_mode) {
  return Layer::AutoSaveLayer(paint_context, layer_rec, save_mode);
}

Layer::AutoSaveLayer::~AutoSaveLayer() {
  if (paint_context_.checkerboard_offscreen_layers) {
    DrawCheckerboard(&canvas_, bounds_);
  }
  canvas_.restore();
}

}  // namespace flutter
