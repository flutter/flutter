// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_TEXT_TEXT_TYPES_H_
#define FLUTTER_SKWASM_TEXT_TEXT_TYPES_H_

#include <optional>
#include <vector>

#include "flutter/display_list/dl_paint.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

namespace Skwasm {
struct TextStyle {
  skia::textlayout::TextStyle skia_style;
  std::optional<flutter::DlPaint> foreground;
  std::optional<flutter::DlPaint> background;

  void PopulatePaintIds(std::vector<flutter::DlPaint>& paints) {
    if (background) {
      skia_style.setBackgroundPaintID(paints.size());
      paints.push_back(*background);
    }
    if (foreground) {
      skia_style.setForegroundPaintID(paints.size());
      paints.push_back(*foreground);
    } else {
      flutter::DlPaint paint;
      paint.setColor(flutter::DlColor(skia_style.getColor()));
      skia_style.setForegroundPaintID(paints.size());
      paints.push_back(std::move(paint));
    }
  }
};

struct ParagraphStyle {
  skia::textlayout::ParagraphStyle skia_paragraph_style;
  TextStyle text_style;
};

struct ParagraphBuilder {
  std::unique_ptr<skia::textlayout::ParagraphBuilder> skia_paragraph_builder;
  std::vector<flutter::DlPaint> paints;
};

struct Paragraph {
  std::unique_ptr<skia::textlayout::Paragraph> skia_paragraph;
  std::vector<flutter::DlPaint> paints;
};
}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_TEXT_TEXT_TYPES_H_
