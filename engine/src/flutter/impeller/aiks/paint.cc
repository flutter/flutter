// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"

namespace impeller {

std::shared_ptr<Contents> Paint::CreateContentsForEntity(Path path,
                                                         bool cover) const {
  if (contents) {
    contents->SetPath(std::move(path));
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
    std::optional<bool> is_solid_color) const {
  bool is_solid_color_val = is_solid_color.value_or(!contents);

  if (mask_blur.has_value()) {
    if (is_solid_color_val) {
      input = FilterContents::MakeGaussianBlur(
          FilterInput::Make(input), mask_blur->sigma, mask_blur->sigma,
          mask_blur->blur_style);
    } else {
      input = FilterContents::MakeBorderMaskBlur(
          FilterInput::Make(input), mask_blur->sigma, mask_blur->sigma,
          mask_blur->blur_style);
    }
  }

  return input;
}

}  // namespace impeller
