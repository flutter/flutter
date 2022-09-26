// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/diff_context.h"
#include "flutter/flow/layers/layer.h"

namespace flutter {

DiffContext::DiffContext(SkISize frame_size,
                         double frame_device_pixel_ratio,
                         PaintRegionMap& this_frame_paint_region_map,
                         const PaintRegionMap& last_frame_paint_region_map,
                         bool has_raster_cache)
    : rects_(std::make_shared<std::vector<SkRect>>()),
      frame_size_(frame_size),
      frame_device_pixel_ratio_(frame_device_pixel_ratio),
      this_frame_paint_region_map_(this_frame_paint_region_map),
      last_frame_paint_region_map_(last_frame_paint_region_map),
      has_raster_cache_(has_raster_cache) {}

void DiffContext::BeginSubtree() {
  state_stack_.push_back(state_);
  state_.rect_index_ = rects_->size();
  state_.has_filter_bounds_adjustment = false;
  state_.has_texture = false;
  if (state_.transform_override) {
    state_.transform = *state_.transform_override;
    state_.transform_override = std::nullopt;
  }
}

void DiffContext::EndSubtree() {
  FML_DCHECK(!state_stack_.empty());
  if (state_.has_filter_bounds_adjustment) {
    filter_bounds_adjustment_stack_.pop_back();
  }
  state_ = std::move(state_stack_.back());
  state_stack_.pop_back();
}

DiffContext::State::State()
    : dirty(false),
      cull_rect(kGiantRect),
      rect_index_(0),
      has_filter_bounds_adjustment(false),
      has_texture(false) {}

void DiffContext::PushTransform(const SkMatrix& transform) {
  state_.transform.preConcat(transform);
}

void DiffContext::SetTransform(const SkMatrix& transform) {
  state_.transform_override = transform;
}

void DiffContext::PushFilterBoundsAdjustment(FilterBoundsAdjustment filter) {
  FML_DCHECK(state_.has_filter_bounds_adjustment == false);
  state_.has_filter_bounds_adjustment = true;
  filter_bounds_adjustment_stack_.push_back(filter);
}

SkRect DiffContext::ApplyFilterBoundsAdjustment(SkRect rect) const {
  // Apply filter bounds adjustment in reverse order
  for (auto i = filter_bounds_adjustment_stack_.rbegin();
       i != filter_bounds_adjustment_stack_.rend(); ++i) {
    rect = (*i)(rect);
  }
  return rect;
}

void DiffContext::AlignRect(SkIRect& rect,
                            int horizontal_alignment,
                            int vertical_alignment) const {
  auto top = rect.top();
  auto left = rect.left();
  auto right = rect.right();
  auto bottom = rect.bottom();
  if (top % vertical_alignment != 0) {
    top -= top % vertical_alignment;
  }
  if (left % horizontal_alignment != 0) {
    left -= left % horizontal_alignment;
  }
  if (right % horizontal_alignment != 0) {
    right += horizontal_alignment - right % horizontal_alignment;
  }
  if (bottom % vertical_alignment != 0) {
    bottom += vertical_alignment - bottom % vertical_alignment;
  }
  right = std::min(right, frame_size_.width());
  bottom = std::min(bottom, frame_size_.height());
  rect = SkIRect::MakeLTRB(left, top, right, bottom);
}

Damage DiffContext::ComputeDamage(const SkIRect& accumulated_buffer_damage,
                                  int horizontal_clip_alignment,
                                  int vertical_clip_alignment) const {
  SkRect buffer_damage = SkRect::Make(accumulated_buffer_damage);
  buffer_damage.join(damage_);
  SkRect frame_damage(damage_);

  for (const auto& r : readbacks_) {
    SkRect rect = SkRect::Make(r.rect);
    if (rect.intersects(frame_damage)) {
      frame_damage.join(rect);
    }
    if (rect.intersects(buffer_damage)) {
      buffer_damage.join(rect);
    }
  }

  Damage res;
  buffer_damage.roundOut(&res.buffer_damage);
  frame_damage.roundOut(&res.frame_damage);

  SkIRect frame_clip = SkIRect::MakeSize(frame_size_);
  res.buffer_damage.intersect(frame_clip);
  res.frame_damage.intersect(frame_clip);

  if (horizontal_clip_alignment > 1 || vertical_clip_alignment > 1) {
    AlignRect(res.buffer_damage, horizontal_clip_alignment,
              vertical_clip_alignment);
    AlignRect(res.frame_damage, horizontal_clip_alignment,
              vertical_clip_alignment);
  }
  return res;
}

bool DiffContext::PushCullRect(const SkRect& clip) {
  SkRect cull_rect = state_.transform.mapRect(clip);
  return state_.cull_rect.intersect(cull_rect);
}

SkRect DiffContext::GetCullRect() const {
  SkMatrix inverse_transform;
  // Perspective projections don't produce rectangles that are useful for
  // culling for some reason.
  if (!state_.transform.hasPerspective() &&
      state_.transform.invert(&inverse_transform)) {
    return inverse_transform.mapRect(state_.cull_rect);
  } else {
    return kGiantRect;
  }
}

void DiffContext::MarkSubtreeDirty(const PaintRegion& previous_paint_region) {
  FML_DCHECK(!IsSubtreeDirty());
  if (previous_paint_region.is_valid()) {
    AddDamage(previous_paint_region);
  }
  state_.dirty = true;
}

void DiffContext::MarkSubtreeDirty(const SkRect& previous_paint_region) {
  FML_DCHECK(!IsSubtreeDirty());
  AddDamage(previous_paint_region);
  state_.dirty = true;
}

void DiffContext::AddLayerBounds(const SkRect& rect) {
  // During painting we cull based on non-overriden transform and then
  // override the transform right before paint. Do the same thing here to get
  // identical paint rect.
  auto transformed_rect =
      ApplyFilterBoundsAdjustment(state_.transform.mapRect(rect));
  if (transformed_rect.intersects(state_.cull_rect)) {
    auto paint_rect = state_.transform_override
                          ? ApplyFilterBoundsAdjustment(
                                state_.transform_override->mapRect(rect))
                          : transformed_rect;
    rects_->push_back(paint_rect);
    if (IsSubtreeDirty()) {
      AddDamage(paint_rect);
    }
  }
}

void DiffContext::MarkSubtreeHasTextureLayer() {
  // Set the has_texture flag on current state and all parent states. That
  // way we'll know that we can't skip diff for retained layers because
  // they contain a TextureLayer.
  for (auto& state : state_stack_) {
    state.has_texture = true;
  }
  state_.has_texture = true;
}

void DiffContext::AddExistingPaintRegion(const PaintRegion& region) {
  // Adding paint region for retained layer implies that current subtree is not
  // dirty, so we know, for example, that the inherited transforms must match
  FML_DCHECK(!IsSubtreeDirty());
  if (region.is_valid()) {
    rects_->insert(rects_->end(), region.begin(), region.end());
  }
}

void DiffContext::AddReadbackRegion(const SkIRect& rect) {
  Readback readback;
  readback.rect = rect;
  readback.position = rects_->size();
  // Push empty rect as a placeholder for position in current subtree
  rects_->push_back(SkRect::MakeEmpty());
  readbacks_.push_back(std::move(readback));
}

PaintRegion DiffContext::CurrentSubtreeRegion() const {
  bool has_readback = std::any_of(
      readbacks_.begin(), readbacks_.end(),
      [&](const Readback& r) { return r.position >= state_.rect_index_; });
  return PaintRegion(rects_, state_.rect_index_, rects_->size(), has_readback,
                     state_.has_texture);
}

void DiffContext::AddDamage(const PaintRegion& damage) {
  FML_DCHECK(damage.is_valid());
  for (const auto& r : damage) {
    damage_.join(r);
  }
}

void DiffContext::AddDamage(const SkRect& rect) {
  damage_.join(rect);
}

void DiffContext::SetLayerPaintRegion(const Layer* layer,
                                      const PaintRegion& region) {
  this_frame_paint_region_map_[layer->unique_id()] = region;
}

PaintRegion DiffContext::GetOldLayerPaintRegion(const Layer* layer) const {
  auto i = last_frame_paint_region_map_.find(layer->unique_id());
  if (i != last_frame_paint_region_map_.end()) {
    return i->second;
  } else {
    // This is valid when Layer::PreservePaintRegion is called for retained
    // layer with zero sized parent clip (these layers are not diffed)
    return PaintRegion();
  }
}

void DiffContext::Statistics::LogStatistics() {
#if !FLUTTER_RELEASE
  FML_TRACE_COUNTER("flutter", "DiffContext", reinterpret_cast<int64_t>(this),
                    "NewPictures", new_pictures_, "PicturesTooComplexToCompare",
                    pictures_too_complex_to_compare_, "DeepComparePictures",
                    deep_compare_pictures_, "SameInstancePictures",
                    same_instance_pictures_,
                    "DifferentInstanceButEqualPictures",
                    different_instance_but_equal_pictures_);
#endif  // !FLUTTER_RELEASE
}

}  // namespace flutter
