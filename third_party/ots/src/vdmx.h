// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_VDMX_H_
#define OTS_VDMX_H_

#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeVDMXRatioRecord {
  uint8_t charset;
  uint8_t x_ratio;
  uint8_t y_start_ratio;
  uint8_t y_end_ratio;
};

struct OpenTypeVDMXVTable {
  uint16_t y_pel_height;
  int16_t y_max;
  int16_t y_min;
};

struct OpenTypeVDMXGroup {
  uint16_t recs;
  uint8_t startsz;
  uint8_t endsz;
  std::vector<OpenTypeVDMXVTable> entries;
};

struct OpenTypeVDMX {
  uint16_t version;
  uint16_t num_recs;
  uint16_t num_ratios;
  std::vector<OpenTypeVDMXRatioRecord> rat_ranges;
  std::vector<uint16_t> offsets;
  std::vector<OpenTypeVDMXGroup> groups;
};

}  // namespace ots

#endif  // OTS_VDMX_H_
