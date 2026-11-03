// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_STRETCH_IMAGE_FILTER_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_STRETCH_IMAGE_FILTER_H_

#include "flutter/display_list/effects/dl_image_filter.h"

namespace flutter {

class DlStretchImageFilter final : public DlImageFilter {
 public:
  DlStretchImageFilter(DlScalar overscroll_x,
                       DlScalar overscroll_y,
                       DlScalar interpolation_strength = 0.7f,
                       const DlRect& stretch_bounds = DlRect())
      : overscroll_x_(overscroll_x),
        overscroll_y_(overscroll_y),
        interpolation_strength_(interpolation_strength),
        stretch_bounds_(stretch_bounds) {}

  explicit DlStretchImageFilter(const DlStretchImageFilter* filter)
      : DlStretchImageFilter(filter->overscroll_x_,
                             filter->overscroll_y_,
                             filter->interpolation_strength_,
                             filter->stretch_bounds_) {}

  static std::shared_ptr<DlImageFilter> Make(
      DlScalar overscroll_x,
      DlScalar overscroll_y,
      DlScalar interpolation_strength = 0.7f,
      const DlRect& stretch_bounds = DlRect()) {
    if (!std::isfinite(overscroll_x) || !std::isfinite(overscroll_y) ||
        !std::isfinite(interpolation_strength)) {
      return nullptr;
    }
    if (impeller::ScalarNearlyZero(overscroll_x) &&
        impeller::ScalarNearlyZero(overscroll_y)) {
      return nullptr;
    }
    overscroll_x =
        impeller::ScalarNearlyZero(overscroll_x) ? 0.0f : overscroll_x;
    overscroll_y =
        impeller::ScalarNearlyZero(overscroll_y) ? 0.0f : overscroll_y;
    return std::make_shared<DlStretchImageFilter>(
        overscroll_x, overscroll_y, interpolation_strength, stretch_bounds);
  }

  DlImageFilterType type() const override {
    return DlImageFilterType::kStretch;
  }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlStretchImageFilter>(this);
  }

  const DlStretchImageFilter* asStretch() const override { return this; }

  bool modifies_transparent_black() const override { return false; }

  DlRect* map_local_bounds(const DlRect& input_bounds,
                           DlRect& output_bounds) const override;

  DlIRect* map_device_bounds(const DlIRect& input_bounds,
                             const DlMatrix& ctm,
                             DlIRect& output_bounds) const override;

  DlIRect* get_input_device_bounds(const DlIRect& output_bounds,
                                   const DlMatrix& ctm,
                                   DlIRect& input_bounds) const override;

  DlScalar overscroll_x() const { return overscroll_x_; }
  DlScalar overscroll_y() const { return overscroll_y_; }
  DlScalar interpolation_strength() const { return interpolation_strength_; }
  const DlRect& stretch_bounds() const { return stretch_bounds_; }

  static DlScalar ComputeStretchedNormalizedPosition(
      DlScalar src_norm,
      DlScalar overscroll,
      DlScalar interpolation_strength);

  static DlScalar ComputeUnstretchedNormalizedPosition(
      DlScalar dst_norm,
      DlScalar overscroll,
      DlScalar interpolation_strength);

  static DlRect MapRect(const DlRect& input_bounds,
                        const DlRect& container_bounds,
                        DlScalar overscroll_x,
                        DlScalar overscroll_y,
                        DlScalar interpolation_strength);

 protected:
  bool equals_(const DlImageFilter& other) const override;

 private:
  DlScalar overscroll_x_;
  DlScalar overscroll_y_;
  DlScalar interpolation_strength_;
  DlRect stretch_bounds_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_STRETCH_IMAGE_FILTER_H_
