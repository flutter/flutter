// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_POST_H_
#define OTS_POST_H_

#include "ots.h"

#include <map>
#include <string>
#include <vector>

namespace ots {

struct OpenTypePOST {
  uint32_t version;
  uint32_t italic_angle;
  int16_t underline;
  int16_t underline_thickness;
  uint32_t is_fixed_pitch;

  std::vector<uint16_t> glyph_name_index;
  std::vector<std::string> names;
};

}  // namespace ots

#endif  // OTS_POST_H_
