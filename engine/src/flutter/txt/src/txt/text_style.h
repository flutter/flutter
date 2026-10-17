// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TEXT_STYLE_H_
#define FLUTTER_TXT_SRC_TXT_TEXT_STYLE_H_

#include <optional>
#include <string>
#include <vector>

#include "flutter/display_list/dl_paint.h"
#include "font_features.h"
#include "font_style.h"
#include "font_weight.h"
#include "text_baseline.h"
#include "text_decoration.h"
#include "text_shadow.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace txt {

// Primitive fields are value-initialized (`= {}`); default values for
// `dart:ui` are defined on `TextStyle._` in `lib/ui/text.dart` and seeded onto
// `ParagraphStyle::default_text_style` by `flutter::ParagraphBuilder`.
class TextStyle {
 public:
  SkColor color = {};
  int decoration = {};
  // Does not make sense to draw a transparent object, so SK_ColorTRANSPARENT
  // (0) is used as a sentinel to indicate no decoration color was set.
  SkColor decoration_color = {};
  TextDecorationStyle decoration_style = {};
  // Thickness is applied as a multiplier to the default thickness of the font.
  double decoration_thickness_multiplier = {};
  int font_weight = {};
  FontStyle font_style = {};
  TextBaseline text_baseline = {};
  bool half_leading = {};
  // An ordered list of fonts in order of priority. The first font is more
  // highly preferred than the last font.
  std::vector<std::string> font_families;
  double font_size = {};
  double letter_spacing = {};
  double word_spacing = {};
  double height = {};
  bool has_height_override = {};
  std::string locale;
  std::optional<flutter::DlPaint> background;
  std::optional<flutter::DlPaint> foreground;
  // An ordered list of shadows where the first shadow will be drawn first (at
  // the bottom).
  std::vector<TextShadow> text_shadows;
  FontFeatures font_features;
  FontVariations font_variations;

  TextStyle();

  bool equals(const TextStyle& other) const;
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TEXT_STYLE_H_
