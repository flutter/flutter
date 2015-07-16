// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "metrics.h"

#include "head.h"
#include "maxp.h"

// OpenType horizontal and vertical common header format
// http://www.microsoft.com/typography/otspec/hhea.htm
// http://www.microsoft.com/typography/otspec/vhea.htm

#define TABLE_NAME "metrics" // XXX: use individual table names

namespace ots {

bool ParseMetricsHeader(OpenTypeFile *file, Buffer *table,
                        OpenTypeMetricsHeader *header) {
  if (!table->ReadS16(&header->ascent) ||
      !table->ReadS16(&header->descent) ||
      !table->ReadS16(&header->linegap) ||
      !table->ReadU16(&header->adv_width_max) ||
      !table->ReadS16(&header->min_sb1) ||
      !table->ReadS16(&header->min_sb2) ||
      !table->ReadS16(&header->max_extent) ||
      !table->ReadS16(&header->caret_slope_rise) ||
      !table->ReadS16(&header->caret_slope_run) ||
      !table->ReadS16(&header->caret_offset)) {
    return OTS_FAILURE_MSG("Failed to read metrics header");
  }

  if (header->ascent < 0) {
    OTS_WARNING("bad ascent: %d", header->ascent);
    header->ascent = 0;
  }
  if (header->linegap < 0) {
    OTS_WARNING("bad linegap: %d", header->linegap);
    header->linegap = 0;
  }

  if (!file->head) {
    return OTS_FAILURE_MSG("Missing head font table");
  }

  // if the font is non-slanted, caret_offset should be zero.
  if (!(file->head->mac_style & 2) &&
      (header->caret_offset != 0)) {
    OTS_WARNING("bad caret offset: %d", header->caret_offset);
    header->caret_offset = 0;
  }

  // skip the reserved bytes
  if (!table->Skip(8)) {
    return OTS_FAILURE_MSG("Failed to skip reserverd bytes");
  }

  int16_t data_format;
  if (!table->ReadS16(&data_format)) {
    return OTS_FAILURE_MSG("Failed to read data format");
  }
  if (data_format) {
    return OTS_FAILURE_MSG("Bad data format %d", data_format);
  }

  if (!table->ReadU16(&header->num_metrics)) {
    return OTS_FAILURE_MSG("Failed to read number of metrics");
  }

  if (!file->maxp) {
    return OTS_FAILURE_MSG("Missing maxp font table");
  }

  if (header->num_metrics > file->maxp->num_glyphs) {
    return OTS_FAILURE_MSG("Bad number of metrics %d", header->num_metrics);
  }

  return true;
}

bool SerialiseMetricsHeader(const ots::OpenTypeFile *file,
                            OTSStream *out,
                            const OpenTypeMetricsHeader *header) {
  if (!out->WriteU32(header->version) ||
      !out->WriteS16(header->ascent) ||
      !out->WriteS16(header->descent) ||
      !out->WriteS16(header->linegap) ||
      !out->WriteU16(header->adv_width_max) ||
      !out->WriteS16(header->min_sb1) ||
      !out->WriteS16(header->min_sb2) ||
      !out->WriteS16(header->max_extent) ||
      !out->WriteS16(header->caret_slope_rise) ||
      !out->WriteS16(header->caret_slope_run) ||
      !out->WriteS16(header->caret_offset) ||
      !out->WriteR64(0) ||  // reserved
      !out->WriteS16(0) ||  // metric data format
      !out->WriteU16(header->num_metrics)) {
    return OTS_FAILURE_MSG("Failed to write metrics");
  }

  return true;
}

bool ParseMetricsTable(const ots::OpenTypeFile *file,
                       Buffer *table,
                       const uint16_t num_glyphs,
                       const OpenTypeMetricsHeader *header,
                       OpenTypeMetricsTable *metrics) {
  // |num_metrics| is a uint16_t, so it's bounded < 65536. This limits that
  // amount of memory that we'll allocate for this to a sane amount.
  const unsigned num_metrics = header->num_metrics;

  if (num_metrics > num_glyphs) {
    return OTS_FAILURE_MSG("Bad number of metrics %d", num_metrics);
  }
  if (!num_metrics) {
    return OTS_FAILURE_MSG("No metrics!");
  }
  const unsigned num_sbs = num_glyphs - num_metrics;

  metrics->entries.reserve(num_metrics);
  for (unsigned i = 0; i < num_metrics; ++i) {
    uint16_t adv = 0;
    int16_t sb = 0;
    if (!table->ReadU16(&adv) || !table->ReadS16(&sb)) {
      return OTS_FAILURE_MSG("Failed to read metric %d", i);
    }

    // This check is bogus, see https://github.com/khaledhosny/ots/issues/36
#if 0
    // Since so many fonts don't have proper value on |adv| and |sb|,
    // we should not call ots_failure() here. For example, about 20% of fonts
    // in http://www.princexml.com/fonts/ (200+ fonts) fails these tests.
    if (adv > header->adv_width_max) {
      OTS_WARNING("bad adv: %u > %u", adv, header->adv_width_max);
      adv = header->adv_width_max;
    }

    if (sb < header->min_sb1) {
      OTS_WARNING("bad sb: %d < %d", sb, header->min_sb1);
      sb = header->min_sb1;
    }
#endif

    metrics->entries.push_back(std::make_pair(adv, sb));
  }

  metrics->sbs.reserve(num_sbs);
  for (unsigned i = 0; i < num_sbs; ++i) {
    int16_t sb;
    if (!table->ReadS16(&sb)) {
      // Some Japanese fonts (e.g., mona.ttf) fail this test.
      return OTS_FAILURE_MSG("Failed to read side bearing %d", i + num_metrics);
    }

    // This check is bogus, see https://github.com/khaledhosny/ots/issues/36
#if 0
    if (sb < header->min_sb1) {
      // The same as above. Three fonts in http://www.fontsquirrel.com/fontface
      // (e.g., Notice2Std.otf) have weird lsb values.
      OTS_WARNING("bad lsb: %d < %d", sb, header->min_sb1);
      sb = header->min_sb1;
    }
#endif

    metrics->sbs.push_back(sb);
  }

  return true;
}

bool SerialiseMetricsTable(const ots::OpenTypeFile *file,
                           OTSStream *out,
                           const OpenTypeMetricsTable *metrics) {
  for (unsigned i = 0; i < metrics->entries.size(); ++i) {
    if (!out->WriteU16(metrics->entries[i].first) ||
        !out->WriteS16(metrics->entries[i].second)) {
      return OTS_FAILURE_MSG("Failed to write metric %d", i);
    }
  }

  for (unsigned i = 0; i < metrics->sbs.size(); ++i) {
    if (!out->WriteS16(metrics->sbs[i])) {
      return OTS_FAILURE_MSG("Failed to write side bearing %ld", i + metrics->entries.size());
    }
  }

  return true;
}

}  // namespace ots

#undef TABLE_NAME
