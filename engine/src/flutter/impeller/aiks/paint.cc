// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

std::shared_ptr<Contents> Paint::CreateContentsForEntity(const Path& path,
                                                         bool cover) const {
  std::unique_ptr<Geometry> geometry;
  switch (style) {
    case Style::kFill:
      geometry = cover ? Geometry::MakeCover() : Geometry::MakeFillPath(path);
      break;
    case Style::kStroke:
      geometry =
          cover ? Geometry::MakeCover()
                : Geometry::MakeStrokePath(path, stroke_width, stroke_miter,
                                           stroke_cap, stroke_join);
      break;
  }
  return CreateContentsForGeometry(std::move(geometry));
}

std::shared_ptr<Contents> Paint::CreateContentsForGeometry(
    std::shared_ptr<Geometry> geometry) const {
  auto contents = color_source.GetContents(*this);
  contents->SetGeometry(std::move(geometry));
  return contents;
}

std::shared_ptr<Contents> Paint::WithFilters(
    std::shared_ptr<Contents> input,
    std::optional<bool> is_solid_color) const {
  bool is_solid_color_val = is_solid_color.value_or(color_source.GetType() ==
                                                    ColorSource::Type::kColor);
  input = WithColorFilter(input, /*absorb_opacity=*/true);
  input = WithInvertFilter(input);
  input = WithMaskBlur(input, is_solid_color_val, Matrix());
  input = WithImageFilter(input, Matrix(), /*is_subpass=*/false);
  return input;
}

std::shared_ptr<Contents> Paint::WithFiltersForSubpassTarget(
    std::shared_ptr<Contents> input,
    const Matrix& effect_transform) const {
  input = WithImageFilter(input, effect_transform, /*is_subpass=*/true);
  input = WithColorFilter(input, /*absorb_opacity=*/true);
  return input;
}

std::shared_ptr<Contents> Paint::WithMaskBlur(
    std::shared_ptr<Contents> input,
    bool is_solid_color,
    const Matrix& effect_transform) const {
  if (mask_blur_descriptor.has_value()) {
    input = mask_blur_descriptor->CreateMaskBlur(
        FilterInput::Make(input), is_solid_color, effect_transform);
  }
  return input;
}

std::shared_ptr<Contents> Paint::WithImageFilter(
    std::shared_ptr<Contents> input,
    const Matrix& effect_transform,
    bool is_subpass) const {
  if (image_filter.has_value()) {
    const ImageFilterProc& filter = image_filter.value();
    input = filter(FilterInput::Make(input), effect_transform, is_subpass);
  }
  return input;
}

std::shared_ptr<Contents> Paint::WithColorFilter(
    std::shared_ptr<Contents> input,
    bool absorb_opacity) const {
  // Image input types will directly set their color filter,
  // if any. See `TiledTextureContents.SetColorFilter`.
  if (color_source.GetType() == ColorSource::Type::kImage) {
    return input;
  }
  if (color_filter.has_value()) {
    const ColorFilterProc& filter = color_filter.value();
    auto color_filter_contents = filter(FilterInput::Make(input));
    if (color_filter_contents) {
      color_filter_contents->SetAbsorbOpacity(absorb_opacity);
    }
    input = color_filter_contents;
  }
  return input;
}

/// A color matrix which inverts colors.
// clang-format off
constexpr ColorFilterContents::ColorMatrix kColorInversion = {
  .array = {
    -1.0,    0,    0, 1.0, 0, //
       0, -1.0,    0, 1.0, 0, //
       0,    0, -1.0, 1.0, 0, //
     1.0,  1.0,  1.0, 1.0, 0  //
  }
};
// clang-format on

std::shared_ptr<Contents> Paint::WithInvertFilter(
    std::shared_ptr<Contents> input) const {
  if (!invert_colors) {
    return input;
  }

  return ColorFilterContents::MakeColorMatrix(
      {FilterInput::Make(std::move(input))}, kColorInversion);
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    const FilterInput::Ref& input,
    bool is_solid_color,
    const Matrix& effect_transform) const {
  if (is_solid_color) {
    return FilterContents::MakeGaussianBlur(
        input, sigma, sigma, style, Entity::TileMode::kDecal, effect_transform);
  }
  return FilterContents::MakeBorderMaskBlur(input, sigma, sigma, style,
                                            effect_transform);
}

bool Paint::HasColorFilter() const {
  return color_filter.has_value();
}

}  // namespace impeller
