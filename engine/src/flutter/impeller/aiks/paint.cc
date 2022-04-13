// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"

namespace impeller {

std::shared_ptr<Contents> Paint::CreateContentsForEntity() const {
  if (contents) {
    return contents;
  }

  switch (style) {
    case Style::kFill: {
      auto solid_color = std::make_shared<SolidColorContents>();
      solid_color->SetColor(color);
      return solid_color;
    }
    case Style::kStroke: {
      auto solid_stroke = std::make_shared<SolidStrokeContents>();
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

}  // namespace impeller
