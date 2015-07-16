// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_METRICS_H_
#define OTS_METRICS_H_

#include <new>
#include <utility>
#include <vector>

#include "ots.h"

namespace ots {

struct OpenTypeMetricsHeader {
  uint32_t version;
  int16_t ascent;
  int16_t descent;
  int16_t linegap;
  uint16_t adv_width_max;
  int16_t min_sb1;
  int16_t min_sb2;
  int16_t max_extent;
  int16_t caret_slope_rise;
  int16_t caret_slope_run;
  int16_t caret_offset;
  uint16_t num_metrics;
};

struct OpenTypeMetricsTable {
  std::vector<std::pair<uint16_t, int16_t> > entries;
  std::vector<int16_t> sbs;
};

bool ParseMetricsHeader(OpenTypeFile *file, Buffer *table,
                        OpenTypeMetricsHeader *header);
bool SerialiseMetricsHeader(const ots::OpenTypeFile *file,
                            OTSStream *out,
                            const OpenTypeMetricsHeader *header);

bool ParseMetricsTable(const ots::OpenTypeFile *file,
                       Buffer *table,
                       const uint16_t num_glyphs,
                       const OpenTypeMetricsHeader *header,
                       OpenTypeMetricsTable *metrics);
bool SerialiseMetricsTable(const ots::OpenTypeFile *file,
                           OTSStream *out,
                           const OpenTypeMetricsTable *metrics);

}  // namespace ots

#endif  // OTS_METRICS_H_

