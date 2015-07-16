// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_VORG_H_
#define OTS_VORG_H_

#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeVORGMetrics {
  uint16_t glyph_index;
  int16_t vert_origin_y;
};

struct OpenTypeVORG {
  uint16_t major_version;
  uint16_t minor_version;
  int16_t default_vert_origin_y;
  std::vector<OpenTypeVORGMetrics> metrics;
};

}  // namespace ots

#endif  // OTS_VORG_H_
