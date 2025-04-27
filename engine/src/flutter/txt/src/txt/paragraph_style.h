// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_PARAGRAPH_STYLE_H_
#define FLUTTER_TXT_SRC_TXT_PARAGRAPH_STYLE_H_

#include <climits>
#include <string>

#include "font_style.h"
#include "font_weight.h"
#include "text_style.h"

namespace txt {

enum class TextAlign {
  // NOLINTBEGIN(readability-identifier-naming)
  left,
  right,
  center,
  justify,
  start,
  end,
  // NOLINTEND(readability-identifier-naming)
};

enum class TextDirection {
  // NOLINTBEGIN(readability-identifier-naming)
  rtl,
  ltr,
  // NOLINTEND(readability-identifier-naming)
};

// Adjusts the leading over and under text.
//
// kDisableFirstAscent and kDisableLastDescent allow disabling height
// adjustments to first line's ascent and the last line's descent. If disabled,
// the line will use the default font metric provided ascent/descent and
// ParagraphStyle.height or TextStyle.height will not take effect.
//
// The default behavior is kAll where height adjustments are enabled for all
// lines.
//
// Multiple behaviors can be applied at once with a bitwise | operator. For
// example, disabling first ascent and last descent can achieved with:
//
//   (kDisableFirstAscent | kDisableLastDescent).
enum TextHeightBehavior {
  kAll = 0x0,
  kDisableFirstAscent = 0x1,
  kDisableLastDescent = 0x2,
  kDisableAll = 0x1 | 0x2,
};

class ParagraphStyle {
 public:
  // Default TextStyle. Used in GetTextStyle() to obtain the base TextStyle to
  // inherit off of.
  FontWeight font_weight = FontWeight::w400;
  FontStyle font_style = FontStyle::normal;
  std::string font_family = "";
  double font_size = 14;
  double height = 1;
  bool has_height_override = false;
  size_t text_height_behavior = TextHeightBehavior::kAll;

  // Strut properties. strut_enabled must be set to true for the rest of the
  // properties to take effect.
  // TODO(garyq): Break the strut properties into a separate class.
  bool strut_enabled = false;
  FontWeight strut_font_weight = FontWeight::w400;
  FontStyle strut_font_style = FontStyle::normal;
  std::vector<std::string> strut_font_families;
  double strut_font_size = 14;
  double strut_height = 1;
  bool strut_has_height_override = false;
  bool strut_half_leading = false;
  double strut_leading = -1;  // Negative to use font's default leading. [0,inf)
                              // to use custom leading as a ratio of font size.
  bool force_strut_height = false;

  // General paragraph properties.
  TextAlign text_align = TextAlign::start;
  TextDirection text_direction = TextDirection::ltr;
  size_t max_lines = std::numeric_limits<size_t>::max();
  std::u16string ellipsis;
  std::string locale;

  TextStyle GetTextStyle() const;

  bool unlimited_lines() const;
  bool ellipsized() const;

  // Return a text alignment value that is not dependent on the text direction.
  TextAlign effective_align() const;
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_PARAGRAPH_STYLE_H_
