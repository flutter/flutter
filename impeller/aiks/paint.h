// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"

namespace impeller {

struct Paint {
  using ImageFilterProc =
      std::function<std::shared_ptr<FilterContents>(FilterInput::Ref)>;
  using ColorFilterProc = ImageFilterProc;
  using MaskFilterProc =
      std::function<std::shared_ptr<FilterContents>(FilterInput::Ref,
                                                    bool is_solid_color)>;

  enum class Style {
    kFill,
    kStroke,
  };

  Color color = Color::Black();
  std::shared_ptr<LinearGradientContents> contents;

  Scalar stroke_width = 0.0;
  SolidStrokeContents::Cap stroke_cap = SolidStrokeContents::Cap::kButt;
  SolidStrokeContents::Join stroke_join = SolidStrokeContents::Join::kMiter;
  Scalar stroke_miter = 4.0;
  Style style = Style::kFill;
  Entity::BlendMode blend_mode = Entity::BlendMode::kSourceOver;

  std::optional<ImageFilterProc> image_filter;
  std::optional<ColorFilterProc> color_filter;
  std::optional<MaskFilterProc> mask_filter;

  /// @brief      Wrap this paint's configured filters to the given contents.
  /// @param[in]  input           The contents to wrap with paint's filters.
  /// @param[in]  is_solid_color  Affects mask blurring behavior. If false, use
  ///                             the image border for mask blurring. If true,
  ///                             do a Gaussian blur to achieve the mask
  ///                             blurring effect for arbitrary paths. If unset,
  ///                             use the current paint configuration to infer
  ///                             the result.
  /// @return     The filter-wrapped contents. If there are no filters that need
  ///             to be wrapped for the current paint configuration, the
  ///             original contents is returned.
  std::shared_ptr<Contents> WithFilters(
      std::shared_ptr<Contents> input,
      std::optional<bool> is_solid_color = std::nullopt) const;

  std::shared_ptr<Contents> CreateContentsForEntity(Path path = {},
                                                    bool cover = false) const;
};

}  // namespace impeller
