// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"

namespace impeller {

std::shared_ptr<Contents> Paint::CreateContentsForEntity(Path path,
                                                         bool cover) const {
  if (color_source.has_value()) {
    auto& source = color_source.value();
    auto contents = source();
    contents->SetPath(std::move(path));
    contents->SetAlpha(color.alpha);
    contents->SetCover(cover);
    return contents;
  }

  switch (style) {
    case Style::kFill: {
      auto solid_color = std::make_shared<SolidColorContents>();
      solid_color->SetPath(std::move(path));
      solid_color->SetColor(color);
      solid_color->SetCover(cover);
      return solid_color;
    }
    case Style::kStroke: {
      auto solid_stroke = std::make_shared<SolidStrokeContents>();
      solid_stroke->SetPath(std::move(path));
      solid_stroke->SetColor(color);
      solid_stroke->SetStrokeSize(stroke_width);
      solid_stroke->SetStrokeMiter(stroke_miter);
      solid_stroke->SetStrokeCap(stroke_cap);
      solid_stroke->SetStrokeJoin(stroke_join);
      return solid_stroke;
    }
  }

  return nullptr;
}

std::shared_ptr<Contents> Paint::WithFilters(
    std::shared_ptr<Contents> input,
    std::optional<bool> is_solid_color,
    const Matrix& effect_transform) const {
  bool is_solid_color_val = is_solid_color.value_or(!color_source);

  if (mask_blur_descriptor.has_value()) {
    input = mask_blur_descriptor->CreateMaskBlur(
        FilterInput::Make(input), is_solid_color_val, effect_transform);
  }

  if (image_filter.has_value()) {
    const ImageFilterProc& filter = image_filter.value();
    input = filter(FilterInput::Make(input), effect_transform);
  }

  if (color_filter.has_value()) {
    const ColorFilterProc& filter = color_filter.value();
    input = filter(FilterInput::Make(input));
  }

  return input;
}

std::shared_ptr<FilterContents> Paint::MaskBlurDescriptor::CreateMaskBlur(
    FilterInput::Ref input,
    bool is_solid_color,
    const Matrix& effect_transform) const {
  if (is_solid_color) {
    return FilterContents::MakeGaussianBlur(
        input, sigma, sigma, style, Entity::TileMode::kDecal, effect_transform);
  }
  return FilterContents::MakeBorderMaskBlur(input, sigma, sigma, style,
                                            effect_transform);
}

}  // namespace impeller
