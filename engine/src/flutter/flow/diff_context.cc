// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/diff_context.h"
#include "flutter/flow/layers/layer.h"

namespace flutter {

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

DiffContext::DiffContext(SkISize frame_size,
                         double frame_device_pixel_ratio,
                         PaintRegionMap& this_frame_paint_region_map,
                         const PaintRegionMap& last_frame_paint_region_map)
    : rects_(std::make_shared<std::vector<SkRect>>()),
      frame_size_(frame_size),
      frame_device_pixel_ratio_(frame_device_pixel_ratio),
      this_frame_paint_region_map_(this_frame_paint_region_map),
      last_frame_paint_region_map_(last_frame_paint_region_map) {}

void DiffContext::BeginSubtree() {
  state_stack_.push_back(state_);
  state_.rect_index_ = rects_->size();
}

void DiffContext::EndSubtree() {
  FML_DCHECK(!state_stack_.empty());
  state_ = std::move(state_stack_.back());
  state_stack_.pop_back();
}

DiffContext::State::State()
    : dirty(false), cull_rect(kGiantRect), rect_index_(0) {}

void DiffContext::PushTransform(const SkMatrix& transform) {
  state_.transform.preConcat(transform);
  SkMatrix inverse_transform;
  // Perspective projections don't produce rectangles that are useful for
  // culling for some reason.
  if (!transform.hasPerspective() && transform.invert(&inverse_transform)) {
    inverse_transform.mapRect(&state_.cull_rect);
  } else {
    state_.cull_rect = kGiantRect;
  }
}

Damage DiffContext::ComputeDamage(
    const SkIRect& accumulated_buffer_damage) const {
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
  return res;
}

bool DiffContext::PushCullRect(const SkRect& clip) {
  return state_.cull_rect.intersect(clip);
}

void DiffContext::MarkSubtreeDirty(const PaintRegion& previous_paint_region) {
  FML_DCHECK(!IsSubtreeDirty());
  if (previous_paint_region.is_valid()) {
    AddDamage(previous_paint_region);
  }
  state_.dirty = true;
}

void DiffContext::AddLayerBounds(const SkRect& rect) {
  SkRect r(rect);
  if (r.intersect(state_.cull_rect)) {
    state_.transform.mapRect(&r);
    if (!r.isEmpty()) {
      rects_->push_back(r);
      if (IsSubtreeDirty()) {
        AddDamage(r);
      }
    }
  }
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
  return PaintRegion(rects_, state_.rect_index_, rects_->size(), has_readback);
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

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

}  // namespace flutter
