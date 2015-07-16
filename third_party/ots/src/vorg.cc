// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vorg.h"

#include <vector>

// VORG - Vertical Origin Table
// http://www.microsoft.com/typography/otspec/vorg.htm

#define TABLE_NAME "VORG"

#define DROP_THIS_TABLE(...) \
  do { \
    OTS_FAILURE_MSG_(file, TABLE_NAME ": " __VA_ARGS__); \
    OTS_FAILURE_MSG("Table discarded"); \
    delete file->vorg; \
    file->vorg = 0; \
  } while (0)

namespace ots {

bool ots_vorg_parse(OpenTypeFile *file, const uint8_t *data, size_t length) {
  Buffer table(data, length);
  file->vorg = new OpenTypeVORG;
  OpenTypeVORG * const vorg = file->vorg;

  uint16_t num_recs;
  if (!table.ReadU16(&vorg->major_version) ||
      !table.ReadU16(&vorg->minor_version) ||
      !table.ReadS16(&vorg->default_vert_origin_y) ||
      !table.ReadU16(&num_recs)) {
    return OTS_FAILURE_MSG("Failed to read header");
  }
  if (vorg->major_version != 1) {
    DROP_THIS_TABLE("bad major version: %u", vorg->major_version);
    return true;
  }
  if (vorg->minor_version != 0) {
    DROP_THIS_TABLE("bad minor version: %u", vorg->minor_version);
    return true;
  }

  // num_recs might be zero (e.g., DFHSMinchoPro5-W3-Demo.otf).
  if (!num_recs) {
    return true;
  }

  uint16_t last_glyph_index = 0;
  vorg->metrics.reserve(num_recs);
  for (unsigned i = 0; i < num_recs; ++i) {
    OpenTypeVORGMetrics rec;

    if (!table.ReadU16(&rec.glyph_index) ||
        !table.ReadS16(&rec.vert_origin_y)) {
      return OTS_FAILURE_MSG("Failed to read record %d", i);
    }
    if ((i != 0) && (rec.glyph_index <= last_glyph_index)) {
      DROP_THIS_TABLE("the table is not sorted");
      return true;
    }
    last_glyph_index = rec.glyph_index;

    vorg->metrics.push_back(rec);
  }

  return true;
}

bool ots_vorg_should_serialise(OpenTypeFile *file) {
  if (!file->cff) return false;  // this table is not for fonts with TT glyphs.
  return file->vorg != NULL;
}

bool ots_vorg_serialise(OTSStream *out, OpenTypeFile *file) {
  OpenTypeVORG * const vorg = file->vorg;
  
  const uint16_t num_metrics = static_cast<uint16_t>(vorg->metrics.size());
  if (num_metrics != vorg->metrics.size() ||
      !out->WriteU16(vorg->major_version) ||
      !out->WriteU16(vorg->minor_version) ||
      !out->WriteS16(vorg->default_vert_origin_y) ||
      !out->WriteU16(num_metrics)) {
    return OTS_FAILURE_MSG("Failed to write table header");
  }

  for (uint16_t i = 0; i < num_metrics; ++i) {
    const OpenTypeVORGMetrics& rec = vorg->metrics[i];
    if (!out->WriteU16(rec.glyph_index) ||
        !out->WriteS16(rec.vert_origin_y)) {
      return OTS_FAILURE_MSG("Failed to write record %d", i);
    }
  }

  return true;
}

void ots_vorg_free(OpenTypeFile *file) {
  delete file->vorg;
}

}  // namespace ots

#undef TABLE_NAME
#undef DROP_THIS_TABLE
