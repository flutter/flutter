// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/aiks/color_filter.h"
#include "impeller/aiks/color_source.h"
#include "impeller/aiks/image_filter.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct Paint {
  using ImageFilterProc = std::function<std::shared_ptr<FilterContents>(
      FilterInput::Ref,
      const Matrix& effect_transform,
      bool is_subpass)>;
  using MaskFilterProc = std::function<std::shared_ptr<FilterContents>(
      FilterInput::Ref,
      bool is_solid_color,
      const Matrix& effect_transform)>;
  using ColorSourceProc = std::function<std::shared_ptr<ColorSourceContents>()>;

  enum class Style {
    kFill,
    kStroke,
  };

  struct MaskBlurDescriptor {
    FilterContents::BlurStyle style;
    Sigma sigma;

    std::shared_ptr<FilterContents> CreateMaskBlur(
        std::shared_ptr<ColorSourceContents> color_source_contents,
        const std::shared_ptr<ColorFilter>& color_filter) const;

    std::shared_ptr<FilterContents> CreateMaskBlur(
        const FilterInput::Ref& input,
        bool is_solid_color) const;
  };

  Color color = Color::Black();
  ColorSource color_source;
  bool dither = false;

  Scalar stroke_width = 0.0;
  Cap stroke_cap = Cap::kButt;
  Join stroke_join = Join::kMiter;
  Scalar stroke_miter = 4.0;
  Style style = Style::kFill;
  BlendMode blend_mode = BlendMode::kSourceOver;
  bool invert_colors = false;

  std::shared_ptr<ImageFilter> image_filter;
  std::shared_ptr<ColorFilter> color_filter;
  std::optional<MaskBlurDescriptor> mask_blur_descriptor;

  /// @brief      Wrap this paint's configured filters to the given contents.
  /// @param[in]  input           The contents to wrap with paint's filters.
  /// @return     The filter-wrapped contents. If there are no filters that need
  ///             to be wrapped for the current paint configuration, the
  ///             original contents is returned.
  std::shared_ptr<Contents> WithFilters(std::shared_ptr<Contents> input) const;

  /// @brief      Wrap this paint's configured filters to the given contents of
  ///             subpass target.
  /// @param[in]  input  The contents of subpass target to wrap with paint's
  ///                    filters.
  ///
  /// @return     The filter-wrapped contents. If there are no filters that need
  ///             to be wrapped for the current paint configuration, the
  ///             original contents is returned.
  std::shared_ptr<Contents> WithFiltersForSubpassTarget(
      std::shared_ptr<Contents> input,
      const Matrix& effect_transform = Matrix()) const;

  std::shared_ptr<Contents> CreateContentsForEntity(const Path& path = {},
                                                    bool cover = false) const;

  std::shared_ptr<Contents> CreateContentsForGeometry(
      std::shared_ptr<Geometry> geometry) const;

  /// @brief   Whether this paint has a color filter that can apply opacity
  bool HasColorFilter() const;

  std::shared_ptr<Contents> WithMaskBlur(std::shared_ptr<Contents> input,
                                         bool is_solid_color) const;

 private:
  std::shared_ptr<Contents> WithImageFilter(std::shared_ptr<Contents> input,
                                            const Matrix& effect_transform,
                                            bool is_subpass) const;

  std::shared_ptr<Contents> WithColorFilter(std::shared_ptr<Contents> input,
                                            bool absorb_opacity = false) const;

  std::shared_ptr<Contents> WithInvertFilter(
      std::shared_ptr<Contents> input) const;
};

}  // namespace impeller
