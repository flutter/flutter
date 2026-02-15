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
   * @param tile_mode Defines how to sample from areas outside the bounds of the
   * input texture.
   *
   * If `bounds` is std::nullopt, a standard Gaussian blur is applied and to the
   * entire surface.
   *
   * If `bounds` is not std::nullopt, the filter performs a "bounded blur": the
   * image filter substitutes transparent black for any sample it reads from
   * outside the defined bounding rectangle. The final weighted sum is then
   * divided by the total weight of the non-transparent samples (the effective
   * alpha), resulting in opaque output.
   *
   * The bounded mode prevents color bleeding from content adjacent to the
   * bounds into the blurred area, and is typically used when the blur must be
   * strictly contained within a clipped region, such as for iOS-style frosted
   * glass effects.
   *
   * The `bounds` rectangle is specified in the canvas's current coordinate
   * space and is affected by the current transform; consequently, the bounds
   * may not be axis-aligned in the final canvas coordinates.
   */
  DlBlurImageFilter(DlScalar sigma_x,
                    DlScalar sigma_y,
                    DlTileMode tile_mode,
                    std::optional<DlRect> bounds = std::nullopt)
      : sigma_x_(sigma_x),
        sigma_y_(sigma_y),
        tile_mode_(tile_mode),
        bounds_(bounds) {}
  explicit DlBlurImageFilter(const DlBlurImageFilter* filter)
      : DlBlurImageFilter(filter->sigma_x_,
                          filter->sigma_y_,
                          filter->tile_mode_,
                          filter->bounds_) {}
  DlBlurImageFilter(const DlBlurImageFilter& filter)
      : DlBlurImageFilter(&filter) {}

  static std::shared_ptr<DlImageFilter> Make(
      DlScalar sigma_x,
      DlScalar sigma_y,
      DlTileMode tile_mode,
      std::optional<DlRect> bounds = std::nullopt);

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
  DlTileMode tile_mode() const { return tile_mode_; }
  std::optional<DlRect> bounds() const { return bounds_; }

 protected:
  bool equals_(const DlImageFilter& other) const override;

 private:
  DlScalar sigma_x_;
  DlScalar sigma_y_;
  DlTileMode tile_mode_;
  std::optional<DlRect> bounds_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_BLUR_IMAGE_FILTER_H_
