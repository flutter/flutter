// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_BLUR_IMAGE_FILTER_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_BLUR_IMAGE_FILTER_H_

#include "flutter/display_list/effects/dl_image_filter.h"

#include "flutter/display_list/dl_tile_mode.h"

namespace flutter {

class DlBlurImageFilter final : public DlImageFilter {
 public:
  /**
   * @brief Creates an ImageFilter that applies a Gaussian blur to its input.
   *
   * @param sigma_x The standard deviation of the Gaussian kernel in the X
   * direction.
   * @param sigma_y The standard deviation of the Gaussian kernel in the Y
   * direction.
   * @param bounds An optional rectangle that enables "bounded blur" mode.
   * @param tile_mode The tile mode used for sampling pixels at the edges
   * when performing a standard, unbounded blur.
   *
   * The [bounds] parameter is optional and dictates the blur's sampling
   * behavior:
   *
   * - If [bounds] is std::nullopt, a standard, unbounded blur is performed,
   * with edge behavior defined by [tile_mode].
   *
   * - If [bounds] is provided (i.e., not std::nullopt), the filter performs a
   * "bounded blur". This means the blur kernel will only sample pixels from
   * *within* this rectangle, treating all pixels outside of it as transparent,
   * and the resulting pixels are opaque. This mode is used to implement
   * iOS-style blurs.
   *
   * The [bounds] rectangle must be specified in the current coordinate space
   * of the canvas (i.e., it is subject to the canvas's current transform).
   * In other words, in the canvas coordinate space, the bounds might not be an
   * axis-aligned rectangle.
   */
  DlBlurImageFilter(DlScalar sigma_x,
                    DlScalar sigma_y,
                    std::optional<DlRect> bounds,
                    DlTileMode tile_mode)
      : sigma_x_(sigma_x),
        sigma_y_(sigma_y),
        bounds_(bounds),
        tile_mode_(tile_mode) {}
  explicit DlBlurImageFilter(const DlBlurImageFilter* filter)
      : DlBlurImageFilter(filter->sigma_x_,
                          filter->sigma_y_,
                          filter->bounds_,
                          filter->tile_mode_) {}
  DlBlurImageFilter(const DlBlurImageFilter& filter)
      : DlBlurImageFilter(&filter) {}

  static std::shared_ptr<DlImageFilter> Make(DlScalar sigma_x,
                                             DlScalar sigma_y,
                                             std::optional<DlRect> bounds,
                                             DlTileMode tile_mode);

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlBlurImageFilter>(this);
  }

  DlImageFilterType type() const override { return DlImageFilterType::kBlur; }
  size_t size() const override { return sizeof(*this); }

  const DlBlurImageFilter* asBlur() const override { return this; }

  bool modifies_transparent_black() const override { return false; }

  DlRect* map_local_bounds(const DlRect& input_bounds,
                           DlRect& output_bounds) const override;

  DlIRect* map_device_bounds(const DlIRect& input_bounds,
                             const DlMatrix& ctm,
                             DlIRect& output_bounds) const override;

  DlIRect* get_input_device_bounds(const DlIRect& output_bounds,
                                   const DlMatrix& ctm,
                                   DlIRect& input_bounds) const override;

  DlScalar sigma_x() const { return sigma_x_; }
  DlScalar sigma_y() const { return sigma_y_; }
  std::optional<DlRect> bounds() const { return bounds_; }
  DlTileMode tile_mode() const { return tile_mode_; }

 protected:
  bool equals_(const DlImageFilter& other) const override;

 private:
  DlScalar sigma_x_;
  DlScalar sigma_y_;
  std::optional<DlRect> bounds_;
  DlTileMode tile_mode_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_BLUR_IMAGE_FILTER_H_
