// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/image_filters/dl_stretch_image_filter.h"

#include <algorithm>
#include <cmath>

namespace flutter {
namespace {

DlRect MapRectWithNormalizedFn(const DlRect& input_bounds,
                               const DlRect& container_bounds,
                               DlScalar overscroll_x,
                               DlScalar overscroll_y,
                               DlScalar interpolation_strength,
                               DlScalar (*map_fn)(DlScalar,
                                                  DlScalar,
                                                  DlScalar)) {
  if (container_bounds.IsEmpty() || input_bounds.IsEmpty()) {
    return input_bounds;
  }
  DlScalar c_left = container_bounds.GetLeft();
  DlScalar c_top = container_bounds.GetTop();
  DlScalar c_width = container_bounds.GetWidth();
  DlScalar c_height = container_bounds.GetHeight();

  DlScalar mapped_left = input_bounds.GetLeft();
  DlScalar mapped_right = input_bounds.GetRight();
  if (c_width > 0.0f && !impeller::ScalarNearlyZero(overscroll_x)) {
    DlScalar norm_l = (input_bounds.GetLeft() - c_left) / c_width;
    if (norm_l >= 0.0f && norm_l <= 1.0f) {
      mapped_left =
          c_left +
          map_fn(norm_l, overscroll_x, interpolation_strength) * c_width;
    }
    DlScalar norm_r = (input_bounds.GetRight() - c_left) / c_width;
    if (norm_r >= 0.0f && norm_r <= 1.0f) {
      mapped_right =
          c_left +
          map_fn(norm_r, overscroll_x, interpolation_strength) * c_width;
    }
  }

  DlScalar mapped_top = input_bounds.GetTop();
  DlScalar mapped_bottom = input_bounds.GetBottom();
  if (c_height > 0.0f && !impeller::ScalarNearlyZero(overscroll_y)) {
    DlScalar norm_t = (input_bounds.GetTop() - c_top) / c_height;
    if (norm_t >= 0.0f && norm_t <= 1.0f) {
      mapped_top =
          c_top +
          map_fn(norm_t, overscroll_y, interpolation_strength) * c_height;
    }
    DlScalar norm_b = (input_bounds.GetBottom() - c_top) / c_height;
    if (norm_b >= 0.0f && norm_b <= 1.0f) {
      mapped_bottom =
          c_top +
          map_fn(norm_b, overscroll_y, interpolation_strength) * c_height;
    }
  }

  return DlRect::MakeLTRB(
      std::min(mapped_left, mapped_right), std::min(mapped_top, mapped_bottom),
      std::max(mapped_left, mapped_right), std::max(mapped_top, mapped_bottom));
}

DlRect ScaleRectAroundStretchPivot(const DlRect& rect,
                                   const DlRect& container_bounds,
                                   DlScalar overscroll_x,
                                   DlScalar overscroll_y) {
  if (container_bounds.IsEmpty() || rect.IsEmpty()) {
    return rect;
  }
  const DlScalar scale_x = 1.0f + std::abs(overscroll_x);
  const DlScalar scale_y = 1.0f + std::abs(overscroll_y);
  const DlScalar pivot_x = overscroll_x >= 0.0f ? container_bounds.GetLeft()
                                                : container_bounds.GetRight();
  const DlScalar pivot_y = overscroll_y >= 0.0f ? container_bounds.GetTop()
                                                : container_bounds.GetBottom();
  const DlScalar left = pivot_x + (rect.GetLeft() - pivot_x) * scale_x;
  const DlScalar right = pivot_x + (rect.GetRight() - pivot_x) * scale_x;
  const DlScalar top = pivot_y + (rect.GetTop() - pivot_y) * scale_y;
  const DlScalar bottom = pivot_y + (rect.GetBottom() - pivot_y) * scale_y;
  return DlRect::MakeLTRB(std::min(left, right), std::min(top, bottom),
                          std::max(left, right), std::max(top, bottom));
}

}  // namespace

DlScalar DlStretchImageFilter::ComputeStretchedNormalizedPosition(
    DlScalar src_norm,
    DlScalar overscroll,
    DlScalar interpolation_strength) {
  if (impeller::ScalarNearlyZero(overscroll)) {
    return src_norm;
  }
  DlScalar p = std::abs(overscroll);
  DlScalar d = 1.0f / (1.0f + p);
  DlScalar a = 1.0f + p * (1.0f - interpolation_strength);
  DlScalar b = p * interpolation_strength;
  if (overscroll > 0.0f) {
    DlScalar delta = d - src_norm;
    if (delta <= 0.0f) {
      return 1.0f;
    }
    DlScalar denom = 1.0f - delta * b;
    if (denom <= 1e-6f) {
      return 1.0f;
    }
    DlScalar u = (delta * a) / denom;
    return std::clamp(1.0f - u, 0.0f, 1.0f);
  } else {
    DlScalar delta = d - (1.0f - src_norm);
    if (delta <= 0.0f) {
      return 0.0f;
    }
    DlScalar denom = 1.0f - delta * b;
    if (denom <= 1e-6f) {
      return 0.0f;
    }
    DlScalar u = (delta * a) / denom;
    return std::clamp(u, 0.0f, 1.0f);
  }
}

DlScalar DlStretchImageFilter::ComputeUnstretchedNormalizedPosition(
    DlScalar dst_norm,
    DlScalar overscroll,
    DlScalar interpolation_strength) {
  if (impeller::ScalarNearlyZero(overscroll)) {
    return dst_norm;
  }
  DlScalar p = std::abs(overscroll);
  DlScalar u_d = 1.0f / (1.0f + p);
  DlScalar u_s = 1.0f + p * (1.0f - interpolation_strength);
  if (overscroll > 0.0f) {
    DlScalar e = 1.0f - dst_norm;
    DlScalar c = e / (u_s + (p * e) * interpolation_strength);
    return std::clamp(u_d - c, 0.0f, 1.0f);
  } else {
    DlScalar e = dst_norm;
    DlScalar c = e / (u_s + (p * e) * interpolation_strength);
    return std::clamp(1.0f - u_d + c, 0.0f, 1.0f);
  }
}

DlRect DlStretchImageFilter::MapRect(const DlRect& input_bounds,
                                     const DlRect& container_bounds,
                                     DlScalar overscroll_x,
                                     DlScalar overscroll_y,
                                     DlScalar interpolation_strength) {
  return MapRectWithNormalizedFn(input_bounds, container_bounds, overscroll_x,
                                 overscroll_y, interpolation_strength,
                                 &ComputeStretchedNormalizedPosition);
}

DlRect* DlStretchImageFilter::map_local_bounds(const DlRect& input_bounds,
                                               DlRect& output_bounds) const {
  if (stretch_bounds_.IsEmpty()) {
    output_bounds = input_bounds;
    return &output_bounds;
  }
  DlRect mapped =
      input_bounds.Union(MapRect(input_bounds, stretch_bounds_, overscroll_x_,
                                 overscroll_y_, interpolation_strength_));
  DlRect scaled_stretch = ScaleRectAroundStretchPivot(
      stretch_bounds_, stretch_bounds_, overscroll_x_, overscroll_y_);
  DlRect scaled_input = ScaleRectAroundStretchPivot(
      input_bounds, stretch_bounds_, overscroll_x_, overscroll_y_);
  output_bounds =
      mapped.Union(stretch_bounds_).Union(scaled_stretch).Union(scaled_input);
  return &output_bounds;
}

DlIRect* DlStretchImageFilter::map_device_bounds(const DlIRect& input_bounds,
                                                 const DlMatrix& ctm,
                                                 DlIRect& output_bounds) const {
  if (!ctm.IsFinite()) {
    output_bounds = input_bounds;
    return nullptr;
  }
  if (stretch_bounds_.IsEmpty()) {
    output_bounds = input_bounds;
    return &output_bounds;
  }
  DlRect dev_stretch = stretch_bounds_.TransformAndClipBounds(ctm);
  DlRect input_rect = DlRect::Make(input_bounds);
  DlRect mapped =
      input_rect.Union(MapRect(input_rect, dev_stretch, overscroll_x_,
                               overscroll_y_, interpolation_strength_));
  DlRect scaled_stretch = ScaleRectAroundStretchPivot(
      dev_stretch, dev_stretch, overscroll_x_, overscroll_y_);
  DlRect scaled_input = ScaleRectAroundStretchPivot(
      input_rect, dev_stretch, overscroll_x_, overscroll_y_);
  output_bounds = DlIRect::RoundOut(
      mapped.Union(dev_stretch).Union(scaled_stretch).Union(scaled_input));
  return &output_bounds;
}

DlIRect* DlStretchImageFilter::get_input_device_bounds(
    const DlIRect& output_bounds,
    const DlMatrix& ctm,
    DlIRect& input_bounds) const {
  if (!ctm.IsFinite()) {
    input_bounds = output_bounds;
    return nullptr;
  }
  if (stretch_bounds_.IsEmpty()) {
    input_bounds = output_bounds;
    return &input_bounds;
  }
  DlRect dev_stretch = stretch_bounds_.TransformAndClipBounds(ctm);
  DlRect output_rect = DlRect::Make(output_bounds);
  DlRect mapped = output_rect.Union(MapRectWithNormalizedFn(
      output_rect, dev_stretch, overscroll_x_, overscroll_y_,
      interpolation_strength_, &ComputeUnstretchedNormalizedPosition));
  input_bounds = DlIRect::RoundOut(mapped.Union(dev_stretch));
  return &input_bounds;
}

bool DlStretchImageFilter::equals_(const DlImageFilter& other) const {
  FML_DCHECK(other.type() == DlImageFilterType::kStretch);
  auto that = static_cast<const DlStretchImageFilter*>(&other);
  return overscroll_x_ == that->overscroll_x_ &&
         overscroll_y_ == that->overscroll_y_ &&
         interpolation_strength_ == that->interpolation_strength_ &&
         stretch_bounds_ == that->stretch_bounds_;
}

}  // namespace flutter
