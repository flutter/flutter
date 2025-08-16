// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_TEXT_TEXT_TYPES_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_TEXT_TEXT_TYPES_H_

#include "flutter/display_list/dl_paint.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

#include <optional>
#include <vector>

namespace Skwasm {
struct TextStyle {
  skia::textlayout::TextStyle skiaStyle;
  std::optional<flutter::DlPaint> foreground;
  std::optional<flutter::DlPaint> background;

  void populatePaintIds(std::vector<flutter::DlPaint>& paints) {
    if (background) {
      skiaStyle.setBackgroundPaintID(paints.size());
      paints.push_back(*background);
    }
    if (foreground) {
      skiaStyle.setForegroundPaintID(paints.size());
      paints.push_back(*foreground);
    } else {
      flutter::DlPaint paint;
      paint.setColor(flutter::DlColor(skiaStyle.getColor()));
      skiaStyle.setForegroundPaintID(paints.size());
      paints.push_back(std::move(paint));
    }
  }
};

struct ParagraphStyle {
  skia::textlayout::ParagraphStyle skiaParagraphStyle;
  TextStyle textStyle;
};

struct ParagraphBuilder {
  std::unique_ptr<skia::textlayout::ParagraphBuilder> skiaParagraphBuilder;
  std::vector<flutter::DlPaint> paints;
};

struct Paragraph {
  std::unique_ptr<skia::textlayout::Paragraph> skiaParagraph;
  std::vector<flutter::DlPaint> paints;
};
}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_TEXT_TEXT_TYPES_H_
