// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_utils.h"

#include <math.h>
#include <optional>
#include <type_traits>

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

// clang-format off
constexpr float kInvertColorMatrix[20] = {
  -1.0,    0,    0, 1.0, 0,
     0, -1.0,    0, 1.0, 0,
     0,    0, -1.0, 1.0, 0,
   1.0,  1.0,  1.0, 1.0, 0
};
// clang-format on

void SkPaintDispatchHelper::save_opacity(SkScalar child_opacity) {
  save_stack_.emplace_back(opacity_);
  set_opacity(child_opacity);
}
void SkPaintDispatchHelper::restore_opacity() {
  if (save_stack_.empty()) {
    return;
  }
  set_opacity(save_stack_.back().opacity);
  save_stack_.pop_back();
}

void SkPaintDispatchHelper::setAntiAlias(bool aa) {
  paint_.setAntiAlias(aa);
}
void SkPaintDispatchHelper::setDither(bool dither) {
  paint_.setDither(dither);
}
void SkPaintDispatchHelper::setInvertColors(bool invert) {
  invert_colors_ = invert;
  paint_.setColorFilter(makeColorFilter());
}
void SkPaintDispatchHelper::setStrokeCap(DlStrokeCap cap) {
  paint_.setStrokeCap(ToSk(cap));
}
void SkPaintDispatchHelper::setStrokeJoin(DlStrokeJoin join) {
  paint_.setStrokeJoin(ToSk(join));
}
void SkPaintDispatchHelper::setStyle(DlDrawStyle style) {
  paint_.setStyle(ToSk(style));
}
void SkPaintDispatchHelper::setStrokeWidth(SkScalar width) {
  paint_.setStrokeWidth(width);
}
void SkPaintDispatchHelper::setStrokeMiter(SkScalar limit) {
  paint_.setStrokeMiter(limit);
}
void SkPaintDispatchHelper::setColor(DlColor color) {
  current_color_ = color;
  paint_.setColor(color);
  if (has_opacity()) {
    paint_.setAlphaf(paint_.getAlphaf() * opacity());
  }
}
void SkPaintDispatchHelper::setBlendMode(DlBlendMode mode) {
  paint_.setBlendMode(ToSk(mode));
}
void SkPaintDispatchHelper::setColorSource(const DlColorSource* source) {
  paint_.setShader(source ? source->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setImageFilter(const DlImageFilter* filter) {
  paint_.setImageFilter(filter ? filter->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setColorFilter(const DlColorFilter* filter) {
  color_filter_ = filter ? filter->shared() : nullptr;
  paint_.setColorFilter(makeColorFilter());
}
void SkPaintDispatchHelper::setPathEffect(const DlPathEffect* effect) {
  paint_.setPathEffect(effect ? effect->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setMaskFilter(const DlMaskFilter* filter) {
  paint_.setMaskFilter(filter ? filter->skia_object() : nullptr);
}

sk_sp<SkColorFilter> SkPaintDispatchHelper::makeColorFilter() const {
  if (!invert_colors_) {
    return color_filter_ ? color_filter_->skia_object() : nullptr;
  }
  sk_sp<SkColorFilter> invert_filter =
      SkColorFilters::Matrix(kInvertColorMatrix);
  if (color_filter_) {
    invert_filter = invert_filter->makeComposed(color_filter_->skia_object());
  }
  return invert_filter;
}

void RectBoundsAccumulator::accumulate(const SkRect& r, int index) {
  if (r.fLeft < r.fRight && r.fTop < r.fBottom) {
    rect_.accumulate(r.fLeft, r.fTop);
    rect_.accumulate(r.fRight, r.fBottom);
  }
}

void RectBoundsAccumulator::save() {
  saved_rects_.emplace_back(rect_);
  rect_ = AccumulationRect();
}
void RectBoundsAccumulator::restore() {
  if (!saved_rects_.empty()) {
    SkRect layer_bounds = rect_.bounds();
    pop_and_accumulate(layer_bounds, nullptr);
  }
}
bool RectBoundsAccumulator::restore(
    std::function<bool(const SkRect&, SkRect&)> mapper,
    const SkRect* clip) {
  bool success = true;
  if (!saved_rects_.empty()) {
    SkRect layer_bounds = rect_.bounds();
    success = mapper(layer_bounds, layer_bounds);
    pop_and_accumulate(layer_bounds, clip);
  }
  return success;
}
void RectBoundsAccumulator::pop_and_accumulate(SkRect& layer_bounds,
                                               const SkRect* clip) {
  FML_DCHECK(!saved_rects_.empty());

  rect_ = saved_rects_.back();
  saved_rects_.pop_back();

  if (clip == nullptr || layer_bounds.intersect(*clip)) {
    accumulate(layer_bounds, -1);
  }
}

RectBoundsAccumulator::AccumulationRect::AccumulationRect() {
  min_x_ = std::numeric_limits<SkScalar>::infinity();
  min_y_ = std::numeric_limits<SkScalar>::infinity();
  max_x_ = -std::numeric_limits<SkScalar>::infinity();
  max_y_ = -std::numeric_limits<SkScalar>::infinity();
}
void RectBoundsAccumulator::AccumulationRect::accumulate(SkScalar x,
                                                         SkScalar y) {
  if (min_x_ > x) {
    min_x_ = x;
  }
  if (min_y_ > y) {
    min_y_ = y;
  }
  if (max_x_ < x) {
    max_x_ = x;
  }
  if (max_y_ < y) {
    max_y_ = y;
  }
}
SkRect RectBoundsAccumulator::AccumulationRect::bounds() const {
  return (max_x_ >= min_x_ && max_y_ >= min_y_)
             ? SkRect::MakeLTRB(min_x_, min_y_, max_x_, max_y_)
             : SkRect::MakeEmpty();
}

void RTreeBoundsAccumulator::accumulate(const SkRect& r, int index) {
  if (r.fLeft < r.fRight && r.fTop < r.fBottom) {
    rects_.push_back(r);
    rect_indices_.push_back(index);
  }
}
void RTreeBoundsAccumulator::save() {
  saved_offsets_.push_back(rects_.size());
}
void RTreeBoundsAccumulator::restore() {
  if (saved_offsets_.empty()) {
    return;
  }

  saved_offsets_.pop_back();
}
bool RTreeBoundsAccumulator::restore(
    std::function<bool(const SkRect& original, SkRect& modified)> map,
    const SkRect* clip) {
  if (saved_offsets_.empty()) {
    return true;
  }

  size_t previous_size = saved_offsets_.back();
  saved_offsets_.pop_back();

  bool success = true;
  for (size_t i = previous_size; i < rects_.size(); i++) {
    SkRect original = rects_[i];
    if (!map(original, original)) {
      success = false;
    }
    if (clip == nullptr || original.intersect(*clip)) {
      rect_indices_[previous_size] = rect_indices_[i];
      rects_[previous_size] = original;
      previous_size++;
    }
  }
  rects_.resize(previous_size);
  rect_indices_.resize(previous_size);
  return success;
}

SkRect RTreeBoundsAccumulator::bounds() const {
  FML_DCHECK(saved_offsets_.empty());
  RectBoundsAccumulator accumulator;
  for (auto& rect : rects_) {
    accumulator.accumulate(rect, 0);
  }
  return accumulator.bounds();
}

sk_sp<DlRTree> RTreeBoundsAccumulator::rtree() const {
  FML_DCHECK(saved_offsets_.empty());
  return sk_make_sp<DlRTree>(rects_.data(), rects_.size(), rect_indices_.data(),
                             [](int id) { return id >= 0; });
}

}  // namespace flutter
