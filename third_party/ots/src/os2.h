// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_OS2_H_
#define OTS_OS2_H_

#include "ots.h"

namespace ots {

struct OpenTypeOS2 {
  uint16_t version;
  int16_t avg_char_width;
  uint16_t weight_class;
  uint16_t width_class;
  uint16_t type;
  int16_t subscript_x_size;
  int16_t subscript_y_size;
  int16_t subscript_x_offset;
  int16_t subscript_y_offset;
  int16_t superscript_x_size;
  int16_t superscript_y_size;
  int16_t superscript_x_offset;
  int16_t superscript_y_offset;
  int16_t strikeout_size;
  int16_t strikeout_position;
  int16_t family_class;
  uint8_t panose[10];
  uint32_t unicode_range_1;
  uint32_t unicode_range_2;
  uint32_t unicode_range_3;
  uint32_t unicode_range_4;
  uint32_t vendor_id;
  uint16_t selection;
  uint16_t first_char_index;
  uint16_t last_char_index;
  int16_t typo_ascender;
  int16_t typo_descender;
  int16_t typo_linegap;
  uint16_t win_ascent;
  uint16_t win_descent;
  uint32_t code_page_range_1;
  uint32_t code_page_range_2;
  int16_t x_height;
  int16_t cap_height;
  uint16_t default_char;
  uint16_t break_char;
  uint16_t max_context;
};

}  // namespace ots

#endif  // OTS_OS2_H_
