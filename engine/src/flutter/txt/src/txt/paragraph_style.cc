// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "paragraph_style.h"

#include <vector>

namespace txt {

TextStyle ParagraphStyle::GetTextStyle() const {
  TextStyle result;
  result.font_weight = font_weight;
  result.font_style = font_style;
  result.font_families = std::vector<std::string>({font_family});
  if (font_size >= 0) {
    result.font_size = font_size;
  }
  result.locale = locale;
  result.height = height;
  result.has_height_override = has_height_override;
  return result;
}

bool ParagraphStyle::unlimited_lines() const {
  return max_lines == std::numeric_limits<size_t>::max();
};

bool ParagraphStyle::ellipsized() const {
  return !ellipsis.empty();
}

TextAlign ParagraphStyle::effective_align() const {
  if (text_align == TextAlign::start) {
    return (text_direction == TextDirection::ltr) ? TextAlign::left
                                                  : TextAlign::right;
  } else if (text_align == TextAlign::end) {
    return (text_direction == TextDirection::ltr) ? TextAlign::right
                                                  : TextAlign::left;
  } else {
    return text_align;
  }
}

}  // namespace txt
