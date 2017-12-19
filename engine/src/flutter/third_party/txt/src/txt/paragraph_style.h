/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef LIB_TXT_SRC_PARAGRAPH_STYLE_H_
#define LIB_TXT_SRC_PARAGRAPH_STYLE_H_

#include <climits>
#include <string>

#include "font_style.h"
#include "font_weight.h"
#include "minikin/LineBreaker.h"
#include "text_style.h"

namespace txt {

enum class TextAlign {
  left,
  right,
  center,
  justify,
  start,
  end,
};

enum class TextDirection {
  rtl,
  ltr,
};

class ParagraphStyle {
 public:
  FontWeight font_weight = FontWeight::w400;
  FontStyle font_style = FontStyle::normal;
  std::string font_family = "";
  double font_size = 14;

  TextAlign text_align = TextAlign::start;
  TextDirection text_direction = TextDirection::ltr;
  size_t max_lines = std::numeric_limits<size_t>::max();
  double line_height = 1.0;
  std::u16string ellipsis;
  // Default strategy is kBreakStrategy_Greedy. Sometimes,
  // kBreakStrategy_HighQuality will produce more desireable layouts (eg, very
  // long words are more likely to be reasonably placed).
  // kBreakStrategy_Balanced will balance between the two.
  minikin::BreakStrategy break_strategy =
      minikin::BreakStrategy::kBreakStrategy_Greedy;

  TextStyle GetTextStyle() const;

  bool unlimited_lines() const;
  bool ellipsized() const;
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_STYLE_H_
