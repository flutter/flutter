// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/geometry.h"

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
    std::unique_ptr<Geometry> geometry) const {
  if (color_source.has_value()) {
    auto& source = color_source.value();
    auto contents = source();
    contents->SetGeometry(std::move(geometry));
    contents->SetAlpha(color.alpha);
    return contents;
  }
  auto solid_color = std::make_shared<SolidColorContents>();
  solid_color->SetGeometry(std::move(geometry));
  solid_color->SetColor(color);
  return solid_color;
}

std::shared_ptr<Contents> Paint::CreateContentsForGeometry(
    const std::shared_ptr<Geometry>& geometry) const {
  if (color_source.has_value()) {
    auto& source = color_source.value();
    auto contents = source();
    contents->SetGeometry(geometry);
    contents->SetAlpha(color.alpha);
    return contents;
  }
  auto solid_color = std::make_shared<SolidColorContents>();
  solid_color->SetGeometry(geometry);
  solid_color->SetColor(color);
  return solid_color;
}

std::shared_ptr<Contents> Paint::WithFilters(
    std::shared_ptr<Contents> input,
    std::optional<bool> is_solid_color,
    const Matrix& effect_transform) const {
  bool is_solid_color_val = is_solid_color.value_or(!color_source);
  input = WithColorFilter(input);
  input = WithMaskBlur(input, is_solid_color_val, effect_transform);
  input = WithImageFilter(input, effect_transform);
  return input;
}

std::shared_ptr<Contents> Paint::WithFiltersForSubpassTarget(
    std::shared_ptr<Contents> input,
    const Matrix& effect_transform) const {
  input = WithMaskBlur(input, false, effect_transform);
  input = WithImageFilter(input, effect_transform);
  input = WithColorFilter(input, /**absorb_opacity=*/true);
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
    const Matrix& effect_transform) const {
  if (image_filter.has_value()) {
    const ImageFilterProc& filter = image_filter.value();
    input = filter(FilterInput::Make(input), effect_transform);
  }
  return input;
}

std::shared_ptr<Contents> Paint::WithColorFilter(
    std::shared_ptr<Contents> input,
    bool absorb_opacity) const {
  // Image input types will directly set their color filter,
  // if any. See `TiledTextureContents.SetColorFilter`.
  if (color_source_type == ColorSourceType::kImage) {
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
