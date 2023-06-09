// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"

#include <memory>

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
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
  if (mask_blur_descriptor.has_value()) {
    return mask_blur_descriptor->CreateMaskBlur(contents);
  }
  return contents;
}

std::shared_ptr<Contents> Paint::WithFilters(
    std::shared_ptr<Contents> input,
    std::optional<bool> is_solid_color) const {
  bool is_solid_color_val = is_solid_color.value_or(color_source.GetType() ==
                                                    ColorSource::Type::kColor);
  input = WithColorFilter(input, /*absorb_opacity=*/true);
  input = WithInvertFilter(input);
  input = WithMaskBlur(input, is_solid_color_val);
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

std::shared_ptr<Contents> Paint::WithMaskBlur(std::shared_ptr<Contents> input,
                                              bool is_solid_color) const {
  if (mask_blur_descriptor.has_value()) {
    input = mask_blur_descriptor->CreateMaskBlur(FilterInput::Make(input),
                                                 is_solid_color);
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
constexpr ColorMatrix kColorInversion = {
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
    std::shared_ptr<ColorSourceContents> color_source_contents) const {
  /// 1. Create an opaque white mask of the original geometry.

  auto mask = std::make_shared<SolidColorContents>();
  mask->SetColor(Color::White());
  mask->SetGeometry(color_source_contents->GetGeometry());

  /// 2. Blur the mask.

  auto blurred_mask = FilterContents::MakeGaussianBlur(
      FilterInput::Make(mask), sigma, sigma, style, Entity::TileMode::kDecal,
      Matrix());

  /// 3. Replace the geometry of the original color source with a rectangle that
  ///    covers the full region of the blurred mask. Note that geometry is in
  ///    local bounds.

  auto expanded_local_bounds = blurred_mask->GetCoverage({});
  if (!expanded_local_bounds.has_value()) {
    return nullptr;
  }
  color_source_contents->SetGeometry(
      Geometry::MakeRect(*expanded_local_bounds));

  /// 4. Composite the color source and mask together.

  return ColorFilterContents::MakeBlend(
      BlendMode::kSourceIn, {FilterInput::Make(blurred_mask),
                             FilterInput::Make(color_source_contents)});
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    const FilterInput::Ref& input,
    bool is_solid_color) const {
  if (is_solid_color) {
    return FilterContents::MakeGaussianBlur(input, sigma, sigma, style,
                                            Entity::TileMode::kDecal, Matrix());
  }
  return FilterContents::MakeBorderMaskBlur(input, sigma, sigma, style,
                                            Matrix());
}

bool Paint::HasColorFilter() const {
  return color_filter.has_value();
}

}  // namespace impeller
